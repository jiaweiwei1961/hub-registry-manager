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
		registry.GET("/", r.handleRegistryRoot)
		registry.GET("/_catalog", r.handleCatalog)
		registry.Any("/*path", r.proxyToRegistryCore())
	}

	// Web UI API 路由
	api := r.engine.Group("/api/v1")
	{
		api.POST("/auth/login", r.proxyToWebAPI("/auth/login"))
		api.POST("/auth/logout", r.proxyToWebAPI("/auth/logout"))
		api.GET("/auth/profile", r.proxyToWebAPI("/auth/profile"))
		api.GET("/namespaces", r.proxyToWebAPI("/namespaces"))
		api.POST("/namespaces", r.proxyToWebAPI("/namespaces"))
		api.GET("/namespaces/:id", r.proxyToWebAPI("/namespaces/:id"))
		api.GET("/namespaces/:ns/repos", r.proxyToWebAPI("/namespaces/:ns/repos"))
		api.GET("/repos/:id/tags", r.proxyToWebAPI("/repos/:id/tags"))
		api.GET("/system/stats", r.proxyToWebAPI("/system/stats"))
	}
}

// handleRegistryRoot 处理 Docker Registry 根路径
func (r *Router) handleRegistryRoot(c *gin.Context) {
	c.Header("Docker-Distribution-API-Version", "registry/2.0")
	c.JSON(200, gin.H{"status": "ok"})
}

// handleCatalog 处理仓库列表请求
func (r *Router) handleCatalog(c *gin.Context) {
	r.proxyToRegistryCore()(c)
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

// proxyToWebAPI 代理请求到 web-api 服务
func (r *Router) proxyToWebAPI(path string) gin.HandlerFunc {
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

// Run 启动 HTTP 服务器
func (r *Router) Run() error {
	addr := fmt.Sprintf(":%d", r.config.Server.Port)
	return r.engine.Run(addr)
}
