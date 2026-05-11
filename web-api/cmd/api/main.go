package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hub-registry/web-api/internal/config"
	"hub-registry/web-api/internal/handlers"
	"hub-registry/web-api/internal/middleware"
	"hub-registry/web-api/internal/storage"
	"hub-registry/shared/pkg/models"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Set gin mode
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize database
	db, err := initDB(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Auto migrate models
	err = db.AutoMigrate(&models.User{}, &models.Namespace{}, &models.Repository{}, &models.Tag{}, &models.Manifest{}, &models.Blob{}, &models.AuditLog{})
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// Create default admin user if not exists
	createDefaultAdmin(db)

	// Initialize storage client
	storageClient := storage.NewStorageClient(&cfg.S3)

	// Create router
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(gin.Logger())
	r.Use(corsMiddleware())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "web-api",
		})
	})

	// API routes
	api := r.Group("/api/v1")
	{
		// Auth routes (public)
		authHandler := handlers.NewAuthHandler(db, cfg)
		api.POST("/auth/login", authHandler.Login)
		api.POST("/auth/logout", authHandler.Logout)

		// Protected routes
		authRequired := api.Group("/")
		authRequired.Use(middleware.JWTAuth(cfg.Auth.JWTSecret))
		{
			authRequired.GET("/auth/profile", authHandler.GetProfile)

			// Namespace routes
				nsHandler := handlers.NewNamespaceHandler(db, storageClient)
			authRequired.GET("/namespaces", nsHandler.ListNamespaces)
			authRequired.POST("/namespaces", nsHandler.CreateNamespace)
			authRequired.GET("/namespaces/:id", nsHandler.GetNamespace)
			authRequired.GET("/namespaces/:id/repos", nsHandler.GetNamespaceRepositories)
			authRequired.PUT("/namespaces/:id", nsHandler.UpdateNamespace)
			authRequired.DELETE("/namespaces/:id", nsHandler.DeleteNamespace)

			// Repository routes
			repoHandler := handlers.NewRepositoryHandler(db, storageClient)
			authRequired.GET("/repositories", repoHandler.ListRepositories)
			authRequired.POST("/repositories", repoHandler.CreateRepository)
			authRequired.GET("/repositories/:id", repoHandler.GetRepository)
			authRequired.PUT("/repositories/:id", repoHandler.UpdateRepository)
			authRequired.DELETE("/repositories/:id", repoHandler.DeleteRepository)
			authRequired.GET("/repos/:id/tags", repoHandler.GetRepositoryTags)
			authRequired.DELETE("/repos/:id/tags/:tag_id", repoHandler.DeleteTag)

			// System routes
			sysHandler := handlers.NewSystemHandler(db)
			authRequired.GET("/system/stats", sysHandler.GetStats)
				authRequired.GET("/system/config", sysHandler.GetRegistryConfig)

			// User management routes
			userHandler := handlers.NewUserHandler(db)
			authRequired.GET("/users", userHandler.ListUsers)
			authRequired.GET("/users/:id", userHandler.GetUser)
			authRequired.POST("/users", userHandler.CreateUser)
			authRequired.PUT("/users/:id", userHandler.UpdateUser)
			authRequired.DELETE("/users/:id", userHandler.DeleteUser)

			// Image routes
			blobStoragePath := os.Getenv("BLOB_STORAGE_PATH")
			if blobStoragePath == "" {
				blobStoragePath = "/data/blobs"
			}
			imageHandler := handlers.NewImageHandler(db, "http://registry-core:5000", blobStoragePath)
			authRequired.POST("/images/upload", imageHandler.UploadImage)
			authRequired.GET("/images/export", imageHandler.ExportImage)
			authRequired.GET("/images/list", imageHandler.ListImages)
				authRequired.POST("/images/replicate", imageHandler.ReplicateImage)

			// Replication routes
			repHandler := handlers.NewReplicationHandler(db)
			authRequired.GET("/replication/policies", repHandler.ListPolicies)
			authRequired.POST("/replication/policies", repHandler.CreatePolicy)
			authRequired.GET("/replication/policies/:id", repHandler.GetPolicy)
			authRequired.PUT("/replication/policies/:id", repHandler.UpdatePolicy)
			authRequired.DELETE("/replication/policies/:id", repHandler.DeletePolicy)
			authRequired.POST("/replication/policies/:id/execute", repHandler.ExecutePolicy)
			authRequired.GET("/replication/tasks", repHandler.ListTasks)
			authRequired.GET("/replication/tasks/:id", repHandler.GetTask)

			// Audit log routes
			auditHandler := handlers.NewAuditLogHandler(db)
			authRequired.GET("/audit-logs", auditHandler.ListAuditLogs)
			authRequired.GET("/audit-logs/:id", auditHandler.GetAuditLog)
			authRequired.GET("/audit-logs/actions", auditHandler.GetAuditActions)
			authRequired.GET("/audit-logs/resource-types", auditHandler.GetAuditResourceTypes)
		}
	}

	// Start server
	port := cfg.Server.Port
	if port == 0 {
		port = 8081
	}

	log.Printf("Starting Web API on port %d...", port)
	if err := r.Run(fmt.Sprintf(":%d", port)); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func initDB(cfg *config.Config) (*gorm.DB, error) {
	dsn := cfg.Database.ConnectionString()
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	return db, nil
}

func createDefaultAdmin(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Count(&count)
	if count > 0 {
		return
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte("admin123"), 12)
	if err != nil {
		log.Printf("Failed to hash password: %v", err)
		return
	}

	admin := models.User{
		Username:     "admin",
		PasswordHash: string(passwordHash),
		Email:        "admin@hub-registry.local",
		DisplayName:  "Administrator",
		IsAdmin:      true,
	}

	if err := db.Create(&admin).Error; err != nil {
		log.Printf("Failed to create admin user: %v", err)
		return
	}

	log.Println("Created default admin user: admin / admin123")
}

func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
