package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hub-registry/web-api/internal/config"
	"hub-registry/web-api/internal/handlers"
	"hub-registry/web-api/internal/middleware"
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

	// Create router
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "healthy",
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
			nsHandler := handlers.NewNamespaceHandler(db)
			authRequired.GET("/namespaces", nsHandler.ListNamespaces)
			authRequired.POST("/namespaces", nsHandler.CreateNamespace)
			authRequired.GET("/namespaces/:id", nsHandler.GetNamespace)
			authRequired.PUT("/namespaces/:id", nsHandler.UpdateNamespace)
			authRequired.DELETE("/namespaces/:id", nsHandler.DeleteNamespace)
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
