package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hub-registry/replication-service/internal/config"
	"hub-registry/replication-service/internal/worker"
	"hub-registry/shared/pkg/models"
)

var (
	db        *gorm.DB
	workerPool *worker.WorkerPool
)

func main() {
	gin.SetMode(gin.ReleaseMode)

	// 加载配置
	cfg := loadConfig()

	// 初始化数据库
	db = initDB(cfg)

	// 自动迁移
	err := db.AutoMigrate(
		&models.ReplicationPolicy{},
		&models.ReplicationTask{},
		&models.ReplicationTaskDetail{},
		&models.RegistryEndpoint{},
		&models.Namespace{},
		&models.Repository{},
		&models.Manifest{},
		&models.Tag{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// 创建工作池
	registryEndpoint := os.Getenv("REGISTRY_ENDPOINT")
	if registryEndpoint == "" {
		registryEndpoint = "registry-core:5000"
	}
	workerPool = worker.NewWorkerPool(db, registryEndpoint, cfg.Worker.MaxConcurrency)
	workerPool.Start()

	// 创建路由
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(corsMiddleware())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "replication-service",
		})
	})

	// API路由
	api := r.Group("/api/v1")
	{
		api.POST("/tasks", handleCreateTask)
		api.GET("/tasks/:id", handleGetTask)
		api.GET("/tasks/:id/details", handleGetTaskDetails)
		api.POST("/tasks/:id/stop", handleStopTask)
		api.GET("/registries/:id/test", handleTestRegistry)
	}

	port := os.Getenv("REPLICATION_PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("Starting replication-service on port %s...", port)
	log.Printf("Registry endpoint: %s", registryEndpoint)
	log.Printf("Worker pool size: %d", cfg.Worker.MaxConcurrency)

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func loadConfig() *config.Config {
	return &config.Config{
		Server: config.ServerConfig{
			Port: 8082,
		},
		Database: config.DatabaseConfig{
			Host:     getEnvOrDefault("DB_HOST", "postgres"),
			Port:     getEnvOrDefaultInt("DB_PORT", 5432),
			User:     getEnvOrDefault("DB_USER", "registry"),
			Password: getEnvOrDefault("DB_PASSWORD", "registry"),
			Database: getEnvOrDefault("DB_NAME", "registry"),
		},
		Worker: config.WorkerConfig{
			MaxConcurrency: getEnvOrDefaultInt("WORKER_CONCURRENCY", 5),
			DefaultTimeout: getEnvOrDefaultInt("WORKER_TIMEOUT", 1800),
		},
	}
}

func getEnvOrDefault(key, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	return val
}

func getEnvOrDefaultInt(key string, defaultVal int) int {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	var intVal int
	fmt.Sscanf(val, "%d", &intVal)
	return intVal
}

func initDB(cfg *config.Config) *gorm.DB {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Database,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Connected to database")
	return db
}

func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, Authorization, accept, origin")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

// CreateTaskRequest 创建任务请求
type CreateTaskRequest struct {
	SourceImage        string `json:"source_image" binding:"required"`
	DestNamespace      string `json:"dest_namespace" binding:"required"`
	DestRepository     string `json:"dest_repository"`
	DestTag            string `json:"dest_tag"`
	Username           string `json:"username"`
	Password           string `json:"password"`
	InsecureSkipVerify bool   `json:"insecure_skip_verify"`
	RegistryEndpointID string `json:"registry_endpoint_id"`
}

func handleCreateTask(c *gin.Context) {
	var req CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "请求参数无效"})
		return
	}

	// 解析源镜像地址
	sourceImage := req.SourceImage
	destNamespace := req.DestNamespace
	destRepo := req.DestRepository
	destTag := req.DestTag

	// 如果源镜像不包含registry前缀，添加docker.io前缀
	// 格式: namespace/image:tag -> docker.io/namespace/image:tag
	// 格式: image:tag -> docker.io/library/image:tag
	if !strings.Contains(sourceImage, "/") || (!strings.Contains(sourceImage, ".") && !strings.HasPrefix(sourceImage, "localhost")) {
		// 没有registry前缀
		parts := strings.Split(sourceImage, "/")
		if len(parts) == 1 {
			// 格式: image:tag -> docker.io/library/image:tag
			sourceImage = "docker.io/library/" + sourceImage
		} else {
			// 格式: namespace/image:tag -> docker.io/namespace/image:tag
			sourceImage = "docker.io/" + sourceImage
		}
	}

	// 如果目标仓库未指定，从源镜像提取
	if destRepo == "" {
		destRepo = extractRepoFromImage(sourceImage)
	}

	// 如果目标标签未指定，从源镜像提取
	if destTag == "" {
		destTag = extractTagFromImage(sourceImage)
	}

	// 创建任务记录
	task := models.ReplicationTask{
		ID:             uuid.New(),
		Status:         "pending",
		SourceRegistry: extractRegistryFromImage(sourceImage),
		DestRegistry:   "local",
		TotalResources: 1,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	if err := db.Create(&task).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR", "message": "创建任务失败"})
		return
	}

	// 构建复制请求
	replicateReq := &worker.ReplicateRequest{
		TaskID:            task.ID.String(),
		SourceImage:        sourceImage,
		DestNamespace:      destNamespace,
		DestRepository:     destRepo,
		DestTag:            destTag,
		Username:           req.Username,
		Password:           req.Password,
		InsecureSkipVerify: req.InsecureSkipVerify,
	}

	// 如果提供了registry endpoint ID，获取认证信息
	if req.RegistryEndpointID != "" {
		var endpoint models.RegistryEndpoint
		if err := db.Where("id = ?", req.RegistryEndpointID).First(&endpoint).Error; err == nil {
			replicateReq.Username = endpoint.Username
			replicateReq.Password = endpoint.Password
			replicateReq.InsecureSkipVerify = endpoint.InsecureSkipVerify
		}
	}

	// 提交到工作池
	if err := workerPool.Submit(replicateReq); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR", "message": "提交任务失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    "success",
		"message": "任务已创建",
		"data": gin.H{
			"task_id":        task.ID.String(),
			"status":         "pending",
			"source_image":   sourceImage,
			"dest_image":     fmt.Sprintf("%s/%s/%s:%s", "registry-core:5000", destNamespace, destRepo, destTag),
		},
	})
}

func handleGetTask(c *gin.Context) {
	taskID := c.Param("id")

	var task models.ReplicationTask
	if err := db.Where("id = ?", taskID).First(&task).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "任务不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": "success",
		"data": gin.H{
			"task_id":          task.ID.String(),
			"status":           task.Status,
			"progress":         task.Progress,
			"started_at":       task.StartedAt,
			"ended_at":         task.EndedAt,
			"total_resources":  task.TotalResources,
			"succeeded_count":  task.SucceededCount,
			"failed_count":     task.FailedCount,
			"skipped_count":    task.SkippedCount,
			"error_message":    task.ErrorMessage,
		},
	})
}

func handleGetTaskDetails(c *gin.Context) {
	taskID := c.Param("id")

	var details []models.ReplicationTaskDetail
	if err := db.Where("task_id = ?", taskID).Find(&details).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR", "message": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": "success",
		"data": details,
	})
}

func handleStopTask(c *gin.Context) {
	taskID := c.Param("id")

	var task models.ReplicationTask
	if err := db.Where("id = ?", taskID).First(&task).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "任务不存在"})
		return
	}

	if task.Status == "running" {
		task.Status = "stopped"
		now := time.Now()
		task.EndedAt = &now
		db.Save(&task)
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    "success",
		"message": "任务已停止",
		"data": gin.H{
			"task_id": task.ID.String(),
			"status":  task.Status,
		},
	})
}

func handleTestRegistry(c *gin.Context) {
	endpointID := c.Param("id")

	var endpoint models.RegistryEndpoint
	if err := db.Where("id = ?", endpointID).First(&endpoint).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "Registry配置不存在"})
		return
	}

	// 测试连接 - 使用skopeo inspect
	config := &worker.SkopeoConfig{
		SourceImage:        endpoint.URL + "/library/alpine:latest",
		Username:           endpoint.Username,
		Password:           endpoint.Password,
		InsecureSkipVerify: endpoint.InsecureSkipVerify,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 使用skopeo inspect测试连接
	args := []string{"inspect"}
	if config.Username != "" {
		args = append(args, fmt.Sprintf("--creds=%s:%s", config.Username, config.Password))
	}
	args = append(args, fmt.Sprintf("--tls-verify=%v", !config.InsecureSkipVerify))
	args = append(args, "docker://"+config.SourceImage)

	// 执行测试
	cmd := exec.CommandContext(ctx, "skopeo", args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	now := time.Now()
	endpoint.LastTestTime = &now
	if err != nil {
		success := false
		endpoint.LastTestResult = &success
		endpoint.LastErrorMessage = stderr.String()
		db.Save(&endpoint)

		c.JSON(http.StatusOK, gin.H{
			"code":    "success",
			"message": "连接测试失败",
			"data": gin.H{
				"success":       false,
				"error_message": stderr.String(),
			},
		})
	} else {
		success := true
		endpoint.LastTestResult = &success
		endpoint.LastErrorMessage = ""
		db.Save(&endpoint)

		c.JSON(http.StatusOK, gin.H{
			"code":    "success",
			"message": "连接测试成功",
			"data": gin.H{
				"success": true,
				"output":  stdout.String(),
			},
		})
	}
}

// 辅助函数：从镜像地址提取registry
func extractRegistryFromImage(image string) string {
	parts := strings.Split(image, "/")
	if len(parts) >= 3 {
		return parts[0]
	}
	return "docker.io"
}

// 辅助函数：从镜像地址提取仓库名
func extractRepoFromImage(image string) string {
	parts := strings.Split(image, "/")
	if len(parts) >= 3 {
		repoParts := strings.Split(parts[2], ":")
		return repoParts[0]
	}
	if len(parts) == 2 {
		repoParts := strings.Split(parts[1], ":")
		return repoParts[0]
	}
	return ""
}

// 辅助函数：从镜像地址提取标签
func extractTagFromImage(image string) string {
	parts := strings.Split(image, ":")
	if len(parts) > 1 {
		return parts[len(parts)-1]
	}
	return "latest"
}