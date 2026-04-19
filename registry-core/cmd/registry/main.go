package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"hub-registry/registry-core/internal/handlers"
)

func main() {
	// 设置生产模式
	gin.SetMode(gin.ReleaseMode)

	// 创建路由器
	r := gin.New()
	r.Use(gin.Recovery())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "registry-core",
		})
	})

	// Docker Registry API v2
	v2 := r.Group("/v2")
	{
		// 基础端点
		v2.GET("/", func(c *gin.Context) {
			c.Header("Docker-Distribution-API-Version", "registry/2.0")
			c.JSON(200, gin.H{})
		})

		// Blob 端点
		blobs := v2.Group("/:name/blobs")
		{
			blobs.HEAD("/:digest", func(c *gin.Context) {
				c.Header("Docker-Distribution-API-Version", "registry/2.0")
				c.Header("Docker-Content-Digest", c.Param("digest"))
				c.Header("Content-Length", "0")
				c.Status(200)
			})

			blobs.GET("/:digest", func(c *gin.Context) {
				c.Header("Docker-Distribution-API-Version", "registry/2.0")
				c.Header("Docker-Content-Digest", c.Param("digest"))
				c.JSON(200, gin.H{
					"message": "blob content would be here",
					"digest":  c.Param("digest"),
				})
			})

			blobs.POST("/uploads", func(c *gin.Context) {
				c.Header("Docker-Distribution-API-Version", "registry/2.0")
				c.Header("Location", c.Request.URL.Path+"/upload-id")
				c.Header("Docker-Upload-UUID", "upload-id")
				c.Status(202)
			})
		}

		// Manifest 端点
		manifests := v2.Group("/:name/manifests")
		{
			manifests.GET("/:reference", func(c *gin.Context) {
				c.Header("Docker-Distribution-API-Version", "registry/2.0")
				c.Header("Docker-Content-Digest", "sha256:example")
				c.JSON(200, gin.H{
					"schemaVersion": 2,
					"mediaType":     "application/vnd.docker.distribution.manifest.v2+json",
					"config": gin.H{
						"digest": "sha256:config",
						"size":   1234,
					},
					"layers": []gin.H{},
				})
			})

			manifests.PUT("/:reference", func(c *gin.Context) {
				c.Header("Docker-Distribution-API-Version", "registry/2.0")
				c.Header("Docker-Content-Digest", "sha256:example")
				c.Header("Location", c.Request.URL.Path)
				c.Status(201)
			})
		}
	}

	// 启动服务
	port := os.Getenv("PORT")
	if port == "" {
		port = "5000"
	}

	log.Printf("Starting registry-core on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
