package router

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"

	"github.com/gin-gonic/gin"
	"hub-registry/gateway/internal/config"
	"hub-registry/gateway/internal/middleware"
)

// Router 路由管理器
type Router struct {
	engine *gin.Engine
	config *config.Config
}

// New 创建路由器
func New(cfg *config.Config) *Router {
	gin.SetMode(gin.ReleaseMode)
	engine := gin.New()

	router := &Router{
		engine: engine,
		config: cfg,
	}

	router.setupMiddleware()
	router.setupRoutes()

	return router
}

// setupMiddleware 设置中间件
func (r *Router) setupMiddleware() {
	r.engine.Use(middleware.Logger())
	r.engine.Use(middleware.Recovery())
	r.engine.Use(middleware.CORS())
}

// setupRoutes 设置路由
func (r *Router) setupRoutes() {
	// 健康检查
	r.engine.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "gateway",
		})
	})

	// Docker Registry API 路由
	registry := r.engine.Group("/v2")
	{
		// 所有 v2 路由通过代理处理
		registry.Any("/*allPaths", r.proxyToRegistryCore())
	}

	// Web UI API 路由
	api := r.engine.Group("/api/v1")
	{
		// 认证路由
		api.POST("/auth/login", r.proxyToWebAPI())
		api.POST("/auth/logout", r.proxyToWebAPI())
		api.GET("/auth/profile", r.proxyToWebAPI())

		// 命名空间路由
		api.GET("/namespaces", r.proxyToWebAPI())
		api.POST("/namespaces", r.proxyToWebAPI())
		api.GET("/namespaces/:id", r.proxyToWebAPI())
		api.GET("/namespaces/:id/repos", r.proxyToWebAPI())
		api.PUT("/namespaces/:id", r.proxyToWebAPI())
		api.DELETE("/namespaces/:id", r.proxyToWebAPI())

		// 仓库路由
		api.GET("/repositories", r.proxyToWebAPI())
		api.POST("/repositories", r.proxyToWebAPI())
		api.GET("/repositories/:id", r.proxyToWebAPI())
		api.PUT("/repositories/:id", r.proxyToWebAPI())
		api.DELETE("/repositories/:id", r.proxyToWebAPI())
		api.GET("/repos/:id/tags", r.proxyToWebAPI())
		api.DELETE("/repos/:id/tags/:tag_id", r.proxyToWebAPI())

		// 系统路由
		api.GET("/system/stats", r.proxyToWebAPI())
		api.GET("/system/config", r.proxyToWebAPI())

		// 用户管理路由
		api.GET("/users", r.proxyToWebAPI())
		api.GET("/users/:id", r.proxyToWebAPI())
		api.POST("/users", r.proxyToWebAPI())
		api.PUT("/users/:id", r.proxyToWebAPI())
		api.DELETE("/users/:id", r.proxyToWebAPI())

		// 镜像路由
		api.POST("/images/upload", r.proxyToWebAPI())
		api.GET("/images/export", r.proxyToWebAPI())
		api.GET("/images/list", r.proxyToWebAPI())
		api.POST("/images/replicate", r.proxyToWebAPI())

		// 健康检查代理路由（需要修改目标路径）
		api.GET("/health/web-api", r.proxyToWebAPIHealth())
		api.GET("/health/registry", r.proxyToRegistryHealth())
		api.GET("/health/minio", r.checkMinIOHealth())

		// 镜像复制路由
		api.GET("/replication/policies", r.proxyToWebAPI())
		api.POST("/replication/policies", r.proxyToWebAPI())
		api.GET("/replication/policies/:id", r.proxyToWebAPI())
		api.PUT("/replication/policies/:id", r.proxyToWebAPI())
		api.DELETE("/replication/policies/:id", r.proxyToWebAPI())
		api.POST("/replication/policies/:id/execute", r.proxyToWebAPI())
		api.GET("/replication/tasks", r.proxyToWebAPI())
		api.GET("/replication/tasks/:id", r.proxyToWebAPI())

		// 审计日志路由
		api.GET("/audit-logs", r.proxyToWebAPI())
		api.GET("/audit-logs/:id", r.proxyToWebAPI())
		api.GET("/audit-logs/actions", r.proxyToWebAPI())
		api.GET("/audit-logs/resource-types", r.proxyToWebAPI())
	}
}

// handleRegistryRoot 处理 Docker Registry 根路径
func (r *Router) handleRegistryRoot(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")
	c.JSON(200, gin.H{"status": "ok"})
}

// proxyToRegistryCore 代理请求到 registry-core 服务
func (r *Router) proxyToRegistryCore() gin.HandlerFunc {
	target, _ := url.Parse(r.config.Upstream.RegistryCore)
	proxy := httputil.NewSingleHostReverseProxy(target)

	return func(c *gin.Context) {
		c.Header("Docker-Distribution-API-Version", "registry/2.0")
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// proxyToWebAPI 代理请求到 web-api 服务（保持原始路径）
func (r *Router) proxyToWebAPI() gin.HandlerFunc {
	target, _ := url.Parse(r.config.Upstream.WebAPI)
	proxy := httputil.NewSingleHostReverseProxy(target)

	return func(c *gin.Context) {
		c.Request.URL.Host = target.Host
		c.Request.URL.Scheme = target.Scheme
		c.Request.Header.Set("X-Forwarded-Host", c.Request.Header.Get("Host"))
		c.Request.Host = target.Host
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// proxyToWebAPIHealth 代理到 web-api 的健康检查（修改目标路径）
func (r *Router) proxyToWebAPIHealth() gin.HandlerFunc {
	target, _ := url.Parse(r.config.Upstream.WebAPI)
	proxy := httputil.NewSingleHostReverseProxy(target)

	return func(c *gin.Context) {
		c.Request.URL.Path = "/health"
		c.Request.URL.RawPath = "/health"
		c.Request.URL.Host = target.Host
		c.Request.URL.Scheme = target.Scheme
		c.Request.Header.Set("X-Forwarded-Host", c.Request.Header.Get("Host"))
		c.Request.Host = target.Host
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// proxyToRegistryHealth 代理到 registry-core 的健康检查
func (r *Router) proxyToRegistryHealth() gin.HandlerFunc {
	target, _ := url.Parse(r.config.Upstream.RegistryCore)
	proxy := httputil.NewSingleHostReverseProxy(target)

	return func(c *gin.Context) {
		c.Request.URL.Path = "/v2/"
		c.Request.URL.RawPath = "/v2/"
		c.Header("Docker-Distribution-API-Version", "registry/2.0")
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// checkMinIOHealth 检查 MinIO 健康状态
func (r *Router) checkMinIOHealth() gin.HandlerFunc {
	return func(c *gin.Context) {
		target := r.config.Upstream.MinIO
		if target == "" {
			target = "http://localhost:9000"
		}

		// 检查 MinIO 健康状态
		healthURL := target + "/minio/health/live"
		resp, err := http.Get(healthURL)
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status":  "unhealthy",
				"service": "minio",
				"error":   err.Error(),
			})
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			c.JSON(http.StatusOK, gin.H{
				"status":  "healthy",
				"service": "minio",
			})
		} else {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status":  "unhealthy",
				"service": "minio",
				"code":    resp.StatusCode,
			})
		}
	}
}

// Run 启动 HTTP 服务器
func (r *Router) Run() error {
	addr := fmt.Sprintf(":%d", r.config.Server.Port)
	return r.engine.Run(addr)
}