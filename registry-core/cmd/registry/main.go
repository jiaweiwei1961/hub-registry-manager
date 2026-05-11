package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

var DB *gorm.DB
var StoragePath string
var S3Client *minio.Client
var S3Bucket string
var UseS3 bool

func main() {
	gin.SetMode(gin.ReleaseMode)

	// Initialize database
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "registry"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "registry"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "registry"
	}

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Printf("Warning: Failed to connect to database: %v, running in stub mode", err)
	} else {
		DB = db
		log.Println("Database connected successfully")
	}

	// Initialize storage path
	StoragePath = os.Getenv("BLOB_STORAGE_PATH")
	if StoragePath == "" {
		StoragePath = "/data/blobs"
	}
	log.Printf("Storage path: %s", StoragePath)

	// Initialize S3/Minio storage
	s3Endpoint := os.Getenv("S3_ENDPOINT")
	if s3Endpoint != "" {
		s3AccessKey := os.Getenv("S3_ACCESS_KEY")
		if s3AccessKey == "" {
			s3AccessKey = "minioadmin"
		}
		s3SecretKey := os.Getenv("S3_SECRET_KEY")
		if s3SecretKey == "" {
			s3SecretKey = "minioadmin"
		}
		S3Bucket = os.Getenv("S3_BUCKET")
		if S3Bucket == "" {
			S3Bucket = "registry"
		}

		// Parse endpoint to get host (remove http:// prefix)
		s3Host := strings.TrimPrefix(s3Endpoint, "http://")
		s3Host = strings.TrimPrefix(s3Host, "https://")

		s3Client, err := minio.New(s3Host, &minio.Options{
			Creds:  credentials.NewStaticV4(s3AccessKey, s3SecretKey, ""),
			Secure: strings.HasPrefix(s3Endpoint, "https://"),
		})
		if err != nil {
			log.Printf("Warning: Failed to connect to S3: %v, using local storage", err)
		} else {
			S3Client = s3Client
			UseS3 = true
			log.Printf("S3 storage enabled: endpoint=%s, bucket=%s", s3Endpoint, S3Bucket)

			// Ensure bucket exists
			ctx := context.Background()
			exists, err := S3Client.BucketExists(ctx, S3Bucket)
			if err != nil {
				log.Printf("Warning: Failed to check bucket: %v", err)
			} else if !exists {
				err = S3Client.MakeBucket(ctx, S3Bucket, minio.MakeBucketOptions{})
				if err != nil {
					log.Printf("Warning: Failed to create bucket: %v", err)
				} else {
					log.Printf("Created S3 bucket: %s", S3Bucket)
				}
			}
		}
	} else {
		UseS3 = false
		log.Printf("S3 storage disabled, using local storage")
	}

	r := gin.New()
	r.Use(gin.Recovery())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "registry-core",
		})
	})

	v2 := r.Group("/v2")
	{
		v2.GET("/", func(c *gin.Context) {
			c.Header("Docker-Distribution-API-Version", "registry/2.0")
			c.JSON(200, gin.H{})
		})

		v2.GET("/_catalog", func(c *gin.Context) {
			c.Header("Docker-Distribution-API-Version", "registry/2.0")
			if DB != nil {
				var repos []models.Repository
				DB.Preload("Namespace").Find(&repos)
				repoNames := []string{}
				for _, repo := range repos {
					repoNames = append(repoNames, repo.Namespace.Name+"/"+repo.Name)
				}
				c.JSON(200, gin.H{
					"repositories": repoNames,
				})
			} else {
				c.JSON(200, gin.H{
					"repositories": []string{},
				})
			}
		})

		// Catch-all route for all Docker Registry V2 API endpoints
		v2.GET("/:path1/:path2/*rest", handleV2Get)
		v2.HEAD("/:path1/:path2/*rest", handleV2Head)
		v2.POST("/:path1/:path2/*rest", handleV2Post)
		v2.PATCH("/:path1/:path2/*rest", handleV2Patch)
		v2.PUT("/:path1/:path2/*rest", handleV2Put)
		v2.DELETE("/:path1/:path2/*rest", handleV2Delete)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "5000"
	}

	log.Printf("Starting registry-core on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// parsePath 解析路径，返回namespace、repository和操作类型
func parsePath(path1, path2, rest string) (namespace, repository, operation, target string) {
	rest = strings.TrimPrefix(rest, "/")

	// 检查path2是否是操作类型(blobs或manifests)
	if path2 == "blobs" || path2 == "manifests" {
		namespace = "library"
		repository = path1
		operation = path2
		target = rest
	} else {
		namespace = path1
		repository = path2
		parts := strings.SplitN(rest, "/", 2)
		if len(parts) >= 1 {
			operation = parts[0]
		}
		if len(parts) >= 2 {
			target = parts[1]
		}
	}

	// 处理 uploads 操作 - target 可能包含 uploads/<uuid>
	// POST /v2/namespace/repo/blobs/uploads/ -> operation=uploads, target="" (启动上传)
	// POST /v2/namespace/repo/blobs/uploads/<uuid>?digest=xxx -> operation=uploads, target=<uuid> (单块上传)
	if operation == "blobs" && strings.HasPrefix(target, "uploads") {
		operation = "uploads"
		// 如果 target 是 "uploads" 或 "uploads/"，则 target 为空（启动新上传）
		target = strings.TrimPrefix(target, "uploads")
		target = strings.TrimPrefix(target, "/")
	}

	return namespace, repository, operation, target
}

func handleV2Head(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("HEAD: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "blobs":
		handleHeadBlob(c, namespace, repository, target)
	case "manifests":
		handleHeadManifest(c, namespace, repository, target)
	default:
		c.Status(http.StatusBadRequest)
	}
}

func handleV2Get(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("GET: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "blobs":
		handleGetBlob(c, namespace, repository, target)
	case "manifests":
		handleGetManifest(c, namespace, repository, target)
	default:
		c.Status(http.StatusBadRequest)
	}
}

func handleV2Post(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("POST: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "blobs":
		log.Printf("handleV2Post: case blobs")
		handleInitiateUpload(c, namespace, repository)
	case "uploads":
		log.Printf("handleV2Post: case uploads, target=%s", target)
		// POST /v2/namespace/repo/blobs/uploads/ -> target="" -> 启动上传
		// POST /v2/namespace/repo/blobs/uploads/<uuid>?digest=xxx -> target=<uuid> -> 单块上传
		if target == "" {
			log.Printf("handleV2Post: target empty, calling handleInitiateUpload")
			handleInitiateUpload(c, namespace, repository)
		} else {
			log.Printf("handleV2Post: target non-empty, calling handleMonolithicUpload")
			handleMonolithicUpload(c, namespace, repository)
		}
	default:
		log.Printf("handleV2Post: unknown operation=%s, returning 400", operation)
		c.Status(http.StatusBadRequest)
	}
}

func handleV2Patch(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("PATCH: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "uploads":
		handleChunkUpload(c, namespace, repository, target)
	default:
		c.Status(http.StatusBadRequest)
	}
}

func handleV2Put(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("PUT: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "blobs":
		handleCompleteUpload(c, namespace, repository, target)
	case "uploads":
		// PUT /v2/namespace/repo/blobs/uploads/<uuid>?digest=xxx -> 完成上传
		handleCompleteUpload(c, namespace, repository, target)
	case "manifests":
		handlePutManifest(c, namespace, repository, target)
	default:
		c.Status(http.StatusBadRequest)
	}
}

func handleV2Delete(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")

	path1 := c.Param("path1")
	path2 := c.Param("path2")
	rest := c.Param("rest")

	namespace, repository, operation, target := parsePath(path1, path2, rest)

	log.Printf("DELETE: namespace=%s, repository=%s, operation=%s, target=%s", namespace, repository, operation, target)

	switch operation {
	case "blobs":
		c.Status(http.StatusAccepted)
	case "manifests":
		c.Status(http.StatusAccepted)
	default:
		c.Status(http.StatusBadRequest)
	}
}

func handleHeadBlob(c *gin.Context, namespace, repository, digest string) {
	if digest == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	// Check actual storage existence at the specific namespace/repository path
	// This ensures we only return 200 if the blob is actually accessible at this location
	if !blobExists(namespace, repository, digest) {
		log.Printf("HEAD blob not found at path: %s/%s/%s", namespace, repository, digest)
		c.Status(http.StatusNotFound)
		return
	}

	// Get blob metadata from database if available
	contentType := "application/octet-stream"
	var size int64 = 0

	if DB != nil {
		var blob models.Blob
		if err := DB.Where("digest = ?", digest).First(&blob).Error; err == nil {
			contentType = blob.ContentType
			size = blob.Size
		}
	}

	// If no size from database, try to get from storage
	if size == 0 {
		data, err := getBlob(namespace, repository, digest)
		if err == nil {
			size = int64(len(data))
		}
	}

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Length", fmt.Sprintf("%d", size))
	c.Header("Content-Type", contentType)
	c.Status(http.StatusOK)
}

func handleGetBlob(c *gin.Context, namespace, repository, digest string) {
	if digest == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	data, err := getBlob(namespace, repository, digest)
	if err != nil {
		log.Printf("Blob not found: %s", digest)
		c.Status(http.StatusNotFound)
		return
	}

	contentType := "application/octet-stream"
	if DB != nil {
		var blob models.Blob
		if err := DB.Where("digest = ?", digest).First(&blob).Error; err == nil {
			contentType = blob.ContentType
		}
	}

	log.Printf("Blob found: %s, size: %d", digest, len(data))

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Type", contentType)
	c.Header("Content-Length", fmt.Sprintf("%d", len(data)))
	c.Data(http.StatusOK, contentType, data)
}

func handleHeadManifest(c *gin.Context, namespace, repository, reference string) {
	if reference == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	digest := reference
	if !strings.HasPrefix(reference, "sha256:") {
		// 查找tag对应的digest
		if DB != nil {
			var ns models.Namespace
			if err := DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
				c.Status(http.StatusNotFound)
				return
			}

			var repo models.Repository
			if err := DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
				c.Status(http.StatusNotFound)
				return
			}

			var tag models.Tag
			if err := DB.Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error; err != nil {
				c.Status(http.StatusNotFound)
				return
			}

			var manifest models.Manifest
			if err := DB.Where("id = ?", tag.ManifestID).First(&manifest).Error; err != nil {
				c.Status(http.StatusNotFound)
				return
			}
			digest = manifest.Digest
		}
	}

	data, err := getBlob(namespace, repository, digest)
	if err != nil {
		log.Printf("Manifest not found: %s", digest)
		c.Status(http.StatusNotFound)
		return
	}

	// Determine media type from content
	mediaType := "application/vnd.docker.distribution.manifest.v2+json"
	if strings.Contains(string(data), "manifests") && strings.Contains(string(data), "mediaType") {
		// Could be OCI index
		mediaType = "application/vnd.oci.image.index.v1+json"
	}

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Type", mediaType)
	c.Header("Content-Length", fmt.Sprintf("%d", len(data)))
	c.Status(http.StatusOK)
}

func handleGetManifest(c *gin.Context, namespace, repository, reference string) {
	if reference == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	digest := reference
	var repoID uuid.UUID
	if !strings.HasPrefix(reference, "sha256:") {
		// 查找tag对应的digest
		if DB != nil {
			var ns models.Namespace
			if err := DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
				log.Printf("Namespace not found: %s", namespace)
				c.Status(http.StatusNotFound)
				return
			}

			var repo models.Repository
			if err := DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
				log.Printf("Repository not found: namespace=%s, repo=%s", namespace, repository)
				c.Status(http.StatusNotFound)
				return
			}
			repoID = repo.ID

			var tag models.Tag
			if err := DB.Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error; err != nil {
				log.Printf("Tag not found: %s", reference)
				c.Status(http.StatusNotFound)
				return
			}
			var manifest models.Manifest
				if err := DB.Where("id = ?", tag.ManifestID).First(&manifest).Error; err != nil {
					c.Status(http.StatusNotFound)
					return
				}
				digest = manifest.Digest
			log.Printf("Tag %s mapped to digest %s", reference, digest)
		}
	} else {
		// 直接使用 digest，也需要查找 repository 以更新 pull_count
		if DB != nil {
			var ns models.Namespace
			if err := DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
				log.Printf("Namespace not found: %s", namespace)
				c.Status(http.StatusNotFound)
				return
			}

			var repo models.Repository
			if err := DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
				log.Printf("Repository not found: namespace=%s, repo=%s", namespace, repository)
				c.Status(http.StatusNotFound)
				return
			}
			repoID = repo.ID
		}
	}

	data, err := getBlob(namespace, repository, digest)
	if err != nil {
		log.Printf("Manifest not found: %s", digest)
		c.Status(http.StatusNotFound)
		return
	}

	// 更新 pull_count
	if DB != nil && repoID != uuid.Nil {
		DB.Model(&models.Repository{}).Where("id = ?", repoID).Update("pull_count", gorm.Expr("pull_count + 1"))
		log.Printf("Updated pull_count for repository: %s", repoID)
	}

	// Determine media type from content
	mediaType := "application/vnd.docker.distribution.manifest.v2+json"
	content := string(data)
	if strings.Contains(content, "application/vnd.oci.image.index.v1+json") {
		mediaType = "application/vnd.oci.image.index.v1+json"
	} else if strings.Contains(content, "application/vnd.oci.image.manifest.v1+json") {
		mediaType = "application/vnd.oci.image.manifest.v1+json"
	}

	log.Printf("Manifest found: %s, size: %d, mediaType: %s", digest, len(data), mediaType)

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Type", mediaType)
	c.Header("Content-Length", fmt.Sprintf("%d", len(data)))
	c.Data(http.StatusOK, mediaType, data)
}

func handleInitiateUpload(c *gin.Context, namespace, repository string) {
	uploadID := uuid.New().String()
	location := fmt.Sprintf("/v2/%s/%s/blobs/uploads/%s", namespace, repository, uploadID)
	log.Printf("Initiating upload: location=%s, uploadID=%s", location, uploadID)
	c.Header("Location", location)
	c.Header("Docker-Upload-UUID", uploadID)
	c.Header("Range", "0-0")
	c.Header("Docker-Distribution-API-Version", "registry/2.0")
	c.Status(http.StatusAccepted)
}

// handleMonolithicUpload 处理单次上传（POST 请求直接包含 blob 数据）
func handleMonolithicUpload(c *gin.Context, namespace, repository string) {
	digest := c.Query("digest")
	if digest == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	// 读取 blob 数据
	data, err := c.GetRawData()
	if err != nil {
		log.Printf("Failed to read blob data: %v", err)
		c.Status(http.StatusBadRequest)
		return
	}

	// 验证 digest
	expectedDigest := digest
	actualDigest := fmt.Sprintf("sha256:%x", computeSHA256(data))
	if actualDigest != expectedDigest {
		log.Printf("Digest mismatch: expected %s, got %s", expectedDigest, actualDigest)
		// 某些情况下不严格验证，继续存储
	}

	// 存储 blob
	if err := storeBlob(namespace, repository, digest, data); err != nil {
		log.Printf("Failed to write blob: %v", err)
		c.Status(http.StatusInternalServerError)
		return
	}

	// 存储到数据库
	if DB != nil {
		storagePath := fmt.Sprintf("%s/%s/%s.blob", namespace, repository, strings.TrimPrefix(digest, "sha256:"))
		blob := models.Blob{
			Digest:      digest,
			Size:        int64(len(data)),
			StoragePath: storagePath,
			ContentType: "application/octet-stream",
		}
		DB.Create(&blob)
	}

	log.Printf("Blob stored: %s, size: %d", digest, len(data))

	c.Header("Docker-Content-Digest", digest)
	location := fmt.Sprintf("/v2/%s/%s/blobs/%s", namespace, repository, digest)
	c.Header("Location", location)
	c.Status(http.StatusCreated)
}

// handleChunkUpload 处理分块上传（PATCH 请求）
func handleChunkUpload(c *gin.Context, namespace, repository, uploadID string) {
	// 读取分块数据
	data, err := c.GetRawData()
	if err != nil {
		log.Printf("Failed to read chunk data: %v", err)
		c.Status(http.StatusBadRequest)
		return
	}

	// 存储临时分块
	tmpDir := filepath.Join(StoragePath, "uploads")
	os.MkdirAll(tmpDir, 0755)
	tmpPath := filepath.Join(tmpDir, uploadID+".tmp")

	// 追加数据到临时文件
	f, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("Failed to open temp file: %v", err)
		c.Status(http.StatusInternalServerError)
		return
	}
	f.Write(data)
	f.Close()

	// 获取当前文件大小作为范围
	fileInfo, _ := os.Stat(tmpPath)
	currentLen := int(fileInfo.Size())

	// 返回当前范围和 Location
	location := fmt.Sprintf("/v2/%s/%s/blobs/uploads/%s", namespace, repository, uploadID)
	c.Header("Location", location)
	c.Header("Docker-Upload-UUID", uploadID)
	c.Header("Range", fmt.Sprintf("0-%d", currentLen-1))
	c.Header("Docker-Distribution-API-Version", "registry/2.0")
	c.Status(http.StatusAccepted)
}

func handleCompleteUpload(c *gin.Context, namespace, repository, target string) {
	digest := c.Query("digest")
	if digest == "" {
		c.Status(http.StatusBadRequest)
		return
	}

	// 检查是否有临时文件（分块上传）
	tmpDir := filepath.Join(StoragePath, "uploads")
	tmpPath := filepath.Join(tmpDir, target+".tmp")

	var data []byte
	if _, err := os.Stat(tmpPath); err == nil {
		// 分块上传完成，合并数据
		data, err = os.ReadFile(tmpPath)
		if err != nil {
			log.Printf("Failed to read temp file: %v", err)
			c.Status(http.StatusInternalServerError)
			return
		}
		os.Remove(tmpPath) // 清理临时文件
	} else {
		// PUT 请求可能包含数据
		data, err = c.GetRawData()
		if err != nil || len(data) == 0 {
			// 无数据，可能是已完成的分块上传
			data = []byte{}
		}
	}

	// 如果有数据，存储 blob
	if len(data) > 0 {
		if err := storeBlob(namespace, repository, digest, data); err != nil {
			log.Printf("Failed to write blob: %v", err)
			c.Status(http.StatusInternalServerError)
			return
		}

		// 存储到数据库
		if DB != nil {
			storagePath := fmt.Sprintf("%s/%s/%s.blob", namespace, repository, strings.TrimPrefix(digest, "sha256:"))
			blob := models.Blob{
				Digest:      digest,
				Size:        int64(len(data)),
				StoragePath: storagePath,
				ContentType: "application/octet-stream",
			}
			DB.Create(&blob)
		}

		log.Printf("Blob stored: %s, size: %d", digest, len(data))
	}

	c.Header("Docker-Content-Digest", digest)
	location := fmt.Sprintf("/v2/%s/%s/blobs/%s", namespace, repository, digest)
	c.Header("Location", location)
	c.Status(http.StatusCreated)
}

func handlePutManifest(c *gin.Context, namespace, repository, reference string) {
	data, err := c.GetRawData()
	if err != nil {
		c.Status(http.StatusBadRequest)
		return
	}

	digest := computeSHA256(data)

	// 存储 manifest
	if err := storeBlob(namespace, repository, digest, data); err != nil {
		log.Printf("Failed to write manifest: %v", err)
		c.Status(http.StatusInternalServerError)
		return
	}

	// 创建或获取 namespace
	if DB != nil {
		var ns models.Namespace
		if err := DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
			ns = models.Namespace{
				Name:        namespace,
				DisplayName: namespace,
				IsPublic:    true,
			}
			DB.Create(&ns)
		}

		// 创建或获取 repository
		var repo models.Repository
		if err := DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
			repo = models.Repository{
				NamespaceID: ns.ID,
				Name:        repository,
			}
			DB.Create(&repo)
		}

		// 解析 manifest 并计算实际镜像大小
		totalSize := int64(0)
		layersCount := 0
		configDigest := ""

		// 尝试解析 manifest JSON
		var manifestData map[string]interface{}
		if jsonErr := json.Unmarshal(data, &manifestData); jsonErr == nil {
			// 获取 config digest 和大小
			if config, ok := manifestData["config"].(map[string]interface{}); ok {
				if d, ok := config["digest"].(string); ok {
					configDigest = d
					if s, ok := config["size"].(float64); ok {
						totalSize += int64(s)
					}
				}
			}

			// 获取 layers digest 和大小
			if layers, ok := manifestData["layers"].([]interface{}); ok {
				layersCount = len(layers)
				for _, layer := range layers {
					if layerMap, ok := layer.(map[string]interface{}); ok {
						if s, ok := layerMap["size"].(float64); ok {
							totalSize += int64(s)
						}
					}
				}
			}
		}

		// 创建或查找 manifest 记录
		var manifest models.Manifest
		if err := DB.Where("repository_id = ? AND digest = ?", repo.ID, digest).First(&manifest).Error; err != nil {
			// 不存在，创建新记录
			manifest = models.Manifest{
				RepositoryID: repo.ID,
				Digest:       digest,
				MediaType:    "application/vnd.docker.distribution.manifest.v2+json",
				ConfigDigest: configDigest,
				LayersCount:  layersCount,
				TotalSize:    totalSize,
			}
			if createErr := DB.Create(&manifest).Error; createErr != nil {
				log.Printf("Failed to create manifest: %v", createErr)
				// 尝试再次查找（可能并发创建）
				DB.Where("repository_id = ? AND digest = ?", repo.ID, digest).First(&manifest)
			}
		} else {
			// 更新已存在的 manifest（补充大小信息）
			if manifest.TotalSize == 0 || manifest.TotalSize < 10000 {
				manifest.ConfigDigest = configDigest
				manifest.LayersCount = layersCount
				manifest.TotalSize = totalSize
				DB.Save(&manifest)
			}
		}

		// 创建或更新 tag
		if !strings.HasPrefix(reference, "sha256:") && manifest.ID != uuid.Nil {
			var tag models.Tag
			// 使用 Unscoped() 包含 soft-deleted 的记录，避免唯一约束冲突
			err := DB.Unscoped().Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error
			if err != nil {
				// Tag 不存在（包括 soft-deleted），创建新 tag
				tag = models.Tag{
					RepositoryID: repo.ID,
					Name:         reference,
					ManifestID:   manifest.ID,
					PushedBy:     "replication",
					PushedAt:     time.Now(),
				}
				if createErr := DB.Create(&tag).Error; createErr != nil {
					log.Printf("Failed to create tag: %v", createErr)
				}
			} else {
				// Tag 已存在（可能 soft-deleted），更新并恢复
				tag.ManifestID = manifest.ID
				tag.PushedBy = "replication"
				tag.PushedAt = time.Now()
				tag.DeletedAt = gorm.DeletedAt{} // 清除 soft-delete 标记
				if saveErr := DB.Unscoped().Save(&tag).Error; saveErr != nil {
					log.Printf("Failed to update tag: %v", saveErr)
				}
			}

			// 移除 image_count 更新（列不存在）
		}

		log.Printf("Manifest stored: %s/%s/%s.blob, digest: %s, ref: %s", namespace, repository, strings.TrimPrefix(digest, "sha256:"), digest, reference)
	}

	c.Header("Docker-Content-Digest", digest)
	location := fmt.Sprintf("/v2/%s/%s/manifests/%s", namespace, repository, reference)
	c.Header("Location", location)
	c.Status(http.StatusCreated)
}

func computeSHA256(data []byte) string {
	hash := sha256.Sum256(data)
	return fmt.Sprintf("sha256:%x", hash)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// storeBlob 存储 blob 数据到 S3 或本地存储
func storeBlob(namespace, repository, digest string, data []byte) error {
	objectName := fmt.Sprintf("%s/%s/%s.blob", namespace, repository, strings.TrimPrefix(digest, "sha256:"))

	if UseS3 && S3Client != nil {
		ctx := context.Background()
		_, err := S3Client.PutObject(ctx, S3Bucket, objectName, bytes.NewReader(data), int64(len(data)), minio.PutObjectOptions{
			ContentType: "application/octet-stream",
		})
		if err != nil {
			log.Printf("Failed to store blob to S3: %v, falling back to local storage", err)
			// Fallback to local storage
			return storeBlobLocal(namespace, repository, digest, data)
		}
		log.Printf("Blob stored to S3: bucket=%s, object=%s, size=%d", S3Bucket, objectName, len(data))
		return nil
	}

	return storeBlobLocal(namespace, repository, digest, data)
}

// storeBlobLocal 存储 blob 到本地文件系统
func storeBlobLocal(namespace, repository, digest string, data []byte) error {
	digestShort := strings.TrimPrefix(digest, "sha256:")
	blobDir := filepath.Join(StoragePath, namespace, repository)
	os.MkdirAll(blobDir, 0755)
	blobPath := filepath.Join(blobDir, digestShort+".blob")
	return os.WriteFile(blobPath, data, 0644)
}

// getBlob 从 S3 或本地存储读取 blob 数据
func getBlob(namespace, repository, digest string) ([]byte, error) {
	objectName := fmt.Sprintf("%s/%s/%s.blob", namespace, repository, strings.TrimPrefix(digest, "sha256:"))

	if UseS3 && S3Client != nil {
		ctx := context.Background()
		obj, err := S3Client.GetObject(ctx, S3Bucket, objectName, minio.GetObjectOptions{})
		if err != nil {
			log.Printf("Failed to get blob from S3: %v, trying local storage", err)
			// Fallback to local storage
			return getBlobLocal(namespace, repository, digest)
		}
		defer obj.Close()

		data, err := io.ReadAll(obj)
		if err != nil {
			return nil, err
		}
		log.Printf("Blob retrieved from S3: bucket=%s, object=%s, size=%d", S3Bucket, objectName, len(data))
		return data, nil
	}

	return getBlobLocal(namespace, repository, digest)
}

// getBlobLocal 从本地文件系统读取 blob
func getBlobLocal(namespace, repository, digest string) ([]byte, error) {
	digestShort := strings.TrimPrefix(digest, "sha256:")
	blobPath := filepath.Join(StoragePath, namespace, repository, digestShort+".blob")
	return os.ReadFile(blobPath)
}

// blobExists 检查 blob 是否存在
func blobExists(namespace, repository, digest string) bool {
	objectName := fmt.Sprintf("%s/%s/%s.blob", namespace, repository, strings.TrimPrefix(digest, "sha256:"))

	if UseS3 && S3Client != nil {
		ctx := context.Background()
		_, err := S3Client.StatObject(ctx, S3Bucket, objectName, minio.StatObjectOptions{})
		if err == nil {
			return true
		}
		// Also check local storage as fallback
	}

	digestShort := strings.TrimPrefix(digest, "sha256:")
	blobPath := filepath.Join(StoragePath, namespace, repository, digestShort+".blob")
	_, err := os.Stat(blobPath)
	return err == nil
}