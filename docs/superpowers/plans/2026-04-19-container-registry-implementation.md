# 容器镜像仓库实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现一个私有化部署的容器镜像仓库，支持 Docker CLI 操作和 Web UI 管理，包含镜像复制/同步功能。

**Architecture:** 采用三层微服务架构：API Gateway 统一入口处理认证路由，Core Services 处理业务逻辑（镜像管理、复制同步等），Storage Adapters 抽象 S3/MinIO 等存储后端。

**Tech Stack:** Go (主要后端语言) + PostgreSQL (元数据存储) + Redis (缓存/会话) + S3/MinIO (对象存储) + React (前端)

---

## 文件结构规划

### 服务目录结构
```
hub-registry/
├── gateway/                    # API Gateway
│   ├── cmd/gateway/main.go
│   ├── internal/
│   │   ├── router/
│   │   ├── auth/
│   │   ├── middleware/
│   │   └── proxy/
│   └── go.mod
├── registry-core/              # Docker Registry Core
│   ├── cmd/registry/main.go
│   ├── internal/
│   │   ├── handlers/
│   │   ├── storage/
│   │   ├── manifest/
│   │   └── blob/
│   └── go.mod
├── web-api/                    # Web UI API
│   ├── cmd/api/main.go
│   ├── internal/
│   │   ├── handlers/
│   │   ├── models/
│   │   ├── services/
│   │   └── repository/
│   └── go.mod
├── replication-service/        # Replication Service
│   ├── cmd/replication/main.go
│   ├── internal/
│   │   ├── scheduler/
│   │   ├── worker/
│   │   ├── policy/
│   │   └── registry/
│   └── go.mod
├── web-ui/                     # React Frontend
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── store/
│   └── package.json
├── shared/                     # 共享库
│   ├── pkg/
│   │   ├── database/
│   │   ├── storage/
│   │   ├── auth/
│   │   └── models/
│   └── go.mod
├── scripts/                    # 部署脚本
├── docker/                       # Docker 文件
└── docker-compose.yml
```

---

## 任务列表

### Phase 1: 基础设置和共享库

#### Task 1: 项目初始化和共享库设置

**Files:**
- Create: `go.work`
- Create: `shared/go.mod`
- Create: `shared/pkg/models/namespace.go`
- Create: `shared/pkg/models/repository.go`
- Create: `shared/pkg/models/manifest.go`
- Create: `shared/pkg/models/blob.go`
- Create: `shared/pkg/models/tag.go`
- Create: `shared/pkg/models/user.go`

- [ ] **Step 1: 创建 go.work 文件**

```
go 1.21

use (
    ./gateway
    ./registry-core
    ./web-api
    ./replication-service
    ./shared
)
```

- [ ] **Step 2: 创建共享库 go.mod**

```bash
cd shared
go mod init hub-registry/shared
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
go get -u github.com/google/uuid
go get -u github.com/lib/pq
```

- [ ] **Step 3: 创建基础数据模型**

Create `shared/pkg/models/namespace.go`:

```go
package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

// Namespace 表示一个命名空间（组织或团队）
type Namespace struct {
    ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
    Name        string         `gorm:"size:255;not null;uniqueIndex" json:"name"`
    DisplayName string         `gorm:"size:255" json:"display_name"`
    Description string         `gorm:"type:text" json:"description"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
    
    // 关联
    Repositories []Repository `json:"repositories,omitempty"`
}

// TableName 指定表名
func (Namespace) TableName() string {
    return "namespaces"
}
```

Create `shared/pkg/models/repository.go`:

```go
package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

// Repository 表示一个镜像仓库
type Repository struct {
    ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
    NamespaceID uuid.UUID      `gorm:"type:uuid;not null;index:idx_ns_repo,unique" json:"namespace_id"`
    Name        string         `gorm:"size:255;not null;index:idx_ns_repo,unique" json:"name"`
    Description string         `gorm:"type:text" json:"description"`
    IsPublic    bool           `gorm:"default:false" json:"is_public"`
    PullCount   int64          `gorm:"default:0" json:"pull_count"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
    
    // 关联
    Namespace Namespace `json:"namespace,omitempty"`
    Tags      []Tag      `json:"tags,omitempty"`
}

// TableName 指定表名
func (Repository) TableName() string {
    return "repositories"
}

// FullName 返回完整仓库名（namespace/name）
func (r *Repository) FullName() string {
    if r.Namespace.Name == "" {
        return r.Name
    }
    return r.Namespace.Name + "/" + r.Name
}
```

- [ ] **Step 4: 运行测试确保模型编译通过**

```bash
cd shared
go build ./...
```

- [ ] **Step 5: 提交代码**

```bash
git add go.work shared/
git commit -m "feat: initialize project structure and shared models"
```

#### Task 2: 数据库连接和迁移工具

**Files:**
- Create: `shared/pkg/database/db.go`
- Create: `shared/pkg/database/migrations/001_initial_schema.go`
- Create: `scripts/migrate.go`

- [ ] **Step 1: 创建数据库连接模块**

Create `shared/pkg/database/db.go`:

```go
package database

import (
    "fmt"
    "time"
    
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// Config 数据库配置
type Config struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
    SSLMode  string
}

// DefaultConfig 返回默认配置
func DefaultConfig() *Config {
    return &Config{
        Host:     "localhost",
        Port:     5432,
        User:     "registry",
        Password: "registry",
        Database: "registry",
        SSLMode:  "disable",
    }
}

// ConnectionString 返回连接字符串
func (c *Config) ConnectionString() string {
    return fmt.Sprintf(
        "host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
        c.Host, c.Port, c.User, c.Password, c.Database, c.SSLMode,
    )
}

// DB 数据库连接包装器
type DB struct {
    *gorm.DB
}

// New 创建数据库连接
func New(config *Config) (*DB, error) {
    gormConfig := &gorm.Config{
        Logger: logger.Default.LogMode(logger.Silent),
    }
    
    db, err := gorm.Open(postgres.Open(config.ConnectionString()), gormConfig)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to database: %w", err)
    }
    
    // 配置连接池
    sqlDB, err := db.DB()
    if err != nil {
        return nil, err
    }
    
    sqlDB.SetMaxIdleConns(10)
    sqlDB.SetMaxOpenConns(100)
    sqlDB.SetConnMaxLifetime(time.Hour)
    
    return &DB{db}, nil
}

// AutoMigrate 自动迁移数据库结构
func (db *DB) AutoMigrate(models ...interface{}) error {
    return db.DB.AutoMigrate(models...)
}

// Close 关闭数据库连接
func (db *DB) Close() error {
    sqlDB, err := db.DB.DB()
    if err != nil {
        return err
    }
    return sqlDB.Close()
}
```

- [ ] **Step 2: 创建迁移脚本**

Create `scripts/migrate.go`:

```go
package main

import (
    "flag"
    "fmt"
    "log"
    "os"
    
    "hub-registry/shared/pkg/database"
    "hub-registry/shared/pkg/models"
)

func main() {
    var (
        host     = flag.String("host", getEnv("DB_HOST", "localhost"), "Database host")
        port     = flag.Int("port", getEnvInt("DB_PORT", 5432), "Database port")
        user     = flag.String("user", getEnv("DB_USER", "registry"), "Database user")
        password = flag.String("password", getEnv("DB_PASSWORD", "registry"), "Database password")
        database = flag.String("database", getEnv("DB_NAME", "registry"), "Database name")
    )
    flag.Parse()
    
    config := &database.Config{
        Host:     *host,
        Port:     *port,
        User:     *user,
        Password: *password,
        Database: *database,
        SSLMode:  "disable",
    }
    
    db, err := database.New(config)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }
    defer db.Close()
    
    fmt.Println("Connected to database, running migrations...")
    
    // 自动迁移所有模型
    err = db.AutoMigrate(
        &models.Namespace{},
        &models.Repository{},
        &models.Manifest{},
        &models.Blob{},
        &models.Tag{},
        &models.User{},
        &models.ReplicationPolicy{},
        &models.ReplicationTask{},
        &models.RegistryEndpoint{},
        &models.AuditLog{},
    )
    if err != nil {
        log.Fatalf("Failed to migrate database: %v", err)
    }
    
    fmt.Println("Migrations completed successfully!")
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        var result int
        fmt.Sscanf(value, "%d", &result)
        return result
    }
    return defaultValue
}
```

- [ ] **Step 3: 提交代码**

```bash
git add shared/pkg/database scripts/migrate.go
git commit -m "feat: add database connection and migration tools"
```

---

### Phase 2: API Gateway 实现

#### Task 3: API Gateway 基础框架

**Files:**
- Create: `gateway/go.mod`
- Create: `gateway/cmd/gateway/main.go`
- Create: `gateway/internal/config/config.go`
- Create: `gateway/internal/router/router.go`
- Create: `gateway/internal/middleware/logger.go`

- [ ] **Step 1: 初始化 Gateway 模块**

```bash
mkdir -p gateway
cd gateway
go mod init hub-registry/gateway
go get -u github.com/gin-gonic/gin
go get -u github.com/golang-jwt/jwt/v5
go get -u go.uber.org/zap
```

- [ ] **Step 2: 创建配置文件模块**

Create `gateway/internal/config/config.go`:

```go
package config

import (
    "os"
    "strconv"
)

// Config 网关配置
type Config struct {
    Server   ServerConfig
    Auth     AuthConfig
    Upstream UpstreamConfig
}

// ServerConfig 服务器配置
type ServerConfig struct {
    Port         int
    ReadTimeout  int
    WriteTimeout int
}

// AuthConfig 认证配置
type AuthConfig struct {
    JWTSecret     string
    TokenExpiry   int    // 小时
    RefreshExpiry int    // 小时
}

// UpstreamConfig 上游服务配置
type UpstreamConfig struct {
    RegistryCore string
    WebAPI       string
}

// Load 从环境变量加载配置
func Load() *Config {
    return &Config{
        Server: ServerConfig{
            Port:         getEnvInt("GATEWAY_PORT", 8080),
            ReadTimeout:  getEnvInt("READ_TIMEOUT", 30),
            WriteTimeout: getEnvInt("WRITE_TIMEOUT", 30),
        },
        Auth: AuthConfig{
            JWTSecret:     getEnv("JWT_SECRET", "default-secret-key"),
            TokenExpiry:   getEnvInt("TOKEN_EXPIRY_HOURS", 24),
            RefreshExpiry: getEnvInt("REFRESH_EXPIRY_HOURS", 168),
        },
        Upstream: UpstreamConfig{
            RegistryCore: getEnv("REGISTRY_CORE_URL", "http://registry-core:5000"),
            WebAPI:       getEnv("WEB_API_URL", "http://web-api:8081"),
        },
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}
```

- [ ] **Step 3: 创建路由模块**

Create `gateway/internal/router/router.go`:

```go
package router

import (
    "net/http"
    "strings"
    
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
            "status": "healthy",
            "service": "gateway",
        })
    })
    
    // Docker Registry API 路由
    registry := r.engine.Group("/v2")
    {
        registry.GET("/", r.handleRegistryRoot)
        registry.GET("/_catalog", r.handleCatalog)
        
        // 所有其他 /v2/* 路由代理到 registry-core
        registry.Any("/*path", r.proxyToRegistryCore())
    }
    
    // Web UI API 路由
    api := r.engine.Group("/api/v1")
    {
        // 认证相关
        api.POST("/auth/login", r.proxyToWebAPI("/auth/login"))
        api.POST("/auth/logout", r.proxyToWebAPI("/auth/logout"))
        api.GET("/auth/profile", r.proxyToWebAPI("/auth/profile"))
        
        // 命名空间
        api.GET("/namespaces", r.proxyToWebAPI("/namespaces"))
        api.POST("/namespaces", r.proxyToWebAPI("/namespaces"))
        api.GET("/namespaces/:id", r.proxyToWebAPI("/namespaces/:id"))
        api.PUT("/namespaces/:id", r.proxyToWebAPI("/namespaces/:id"))
        api.DELETE("/namespaces/:id", r.proxyToWebAPI("/namespaces/:id"))
        
        // 仓库
        api.GET("/namespaces/:ns/repos", r.proxyToWebAPI("/namespaces/:ns/repos"))
        api.POST("/namespaces/:ns/repos", r.proxyToWebAPI("/namespaces/:ns/repos"))
        api.GET("/repos/:id", r.proxyToWebAPI("/repos/:id"))
        api.DELETE("/repos/:id", r.proxyToWebAPI("/repos/:id"))
        
        // 标签
        api.GET("/repos/:id/tags", r.proxyToWebAPI("/repos/:id/tags"))
        api.GET("/tags/:id", r.proxyToWebAPI("/tags/:id"))
        api.DELETE("/tags/:id", r.proxyToWebAPI("/tags/:id"))
        api.POST("/tags/:id/retag", r.proxyToWebAPI("/tags/:id/retag"))
        
        // 镜像上传/下载
        api.POST("/repos/:id/upload", r.proxyToWebAPI("/repos/:id/upload"))
        api.PUT("/upload/:session/chunk", r.proxyToWebAPI("/upload/:session/chunk"))
        api.POST("/upload/:session/complete", r.proxyToWebAPI("/upload/:session/complete"))
        api.GET("/images/:id/download", r.proxyToWebAPI("/images/:id/download"))
        api.GET("/images/:id/export", r.proxyToWebAPI("/images/:id/export"))
        
        // 复制/同步
        api.GET("/registries", r.proxyToWebAPI("/registries"))
        api.POST("/registries", r.proxyToWebAPI("/registries"))
        api.GET("/registries/:id", r.proxyToWebAPI("/registries/:id"))
        api.PUT("/registries/:id", r.proxyToWebAPI("/registries/:id"))
        api.DELETE("/registries/:id", r.proxyToWebAPI("/registries/:id"))
        api.POST("/registries/:id/test", r.proxyToWebAPI("/registries/:id/test"))
        
        api.GET("/replication/policies", r.proxyToWebAPI("/replication/policies"))
        api.POST("/replication/policies", r.proxyToWebAPI("/replication/policies"))
        api.GET("/replication/policies/:id", r.proxyToWebAPI("/replication/policies/:id"))
        api.PUT("/replication/policies/:id", r.proxyToWebAPI("/replication/policies/:id"))
        api.DELETE("/replication/policies/:id", r.proxyToWebAPI("/replication/policies/:id"))
        api.POST("/replication/policies/:id/execute", r.proxyToWebAPI("/replication/policies/:id/execute"))
        
        api.GET("/replication/tasks", r.proxyToWebAPI("/replication/tasks"))
        api.GET("/replication/tasks/:id", r.proxyToWebAPI("/replication/tasks/:id"))
        api.GET("/replication/tasks/:id/logs", r.proxyToWebAPI("/replication/tasks/:id/logs"))
        api.DELETE("/replication/tasks/:id", r.proxyToWebAPI("/replication/tasks/:id"))
        api.POST("/replication/tasks/:id/stop", r.proxyToWebAPI("/replication/tasks/:id/stop"))
        api.POST("/replication/tasks/:id/retry", r.proxyToWebAPI("/replication/tasks/:id/retry"))
        
        // 系统
        api.GET("/system/stats", r.proxyToWebAPI("/system/stats"))
        api.GET("/audit-logs", r.proxyToWebAPI("/audit-logs"))
    }
    
    // Web UI 静态文件服务
    r.engine.Static("/", "./web-ui/dist")
}

// handleRegistryRoot 处理 Docker Registry 根路径
func (r *Router) handleRegistryRoot(c *gin.Context) {
    c.Header("Docker-Distribution-API-Version", "registry/2.0")
    c.JSON(200, gin.H{
        "status": "ok",
    })
}

// handleCatalog 处理仓库列表请求
func (r *Router) handleCatalog(c *gin.Context) {
    // 代理到 registry-core
    r.proxyToRegistryCore()(c)
}

// proxyToRegistryCore 代理请求到 registry-core 服务
func (r *Router) proxyToRegistryCore() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 设置 Docker Registry API 版本头
        c.Header("Docker-Distribution-API-Version", "registry/2.0")
        
        // TODO: 实现反向代理到 registry-core
        c.JSON(501, gin.H{
            "error": "registry-core proxy not implemented yet",
        })
    }
}

// proxyToWebAPI 代理请求到 web-api 服务
func (r *Router) proxyToWebAPI(path string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // TODO: 实现反向代理到 web-api
        c.JSON(501, gin.H{
            "error": "web-api proxy not implemented yet",
            "path":  path,
        })
    }
}

// Run 启动 HTTP 服务器
func (r *Router) Run() error {
    addr := fmt.Sprintf(":%d", r.config.Server.Port)
    return r.engine.Run(addr)
}
```

- [ ] **Step 4: 创建中间件**

Create `gateway/internal/middleware/logger.go`:

```go
package middleware

import (
    "time"
    
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

// Logger 返回日志中间件
func Logger() gin.HandlerFunc {
    logger, _ := zap.NewProduction()
    defer logger.Sync()
    
    return func(c *gin.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        query := c.Request.URL.RawQuery
        
        c.Next()
        
        cost := time.Since(start)
        
        logger.Info("request",
            zap.Int("status", c.Writer.Status()),
            zap.String("method", c.Request.Method),
            zap.String("path", path),
            zap.String("query", query),
            zap.String("ip", c.ClientIP()),
            zap.String("user-agent", c.Request.UserAgent()),
            zap.Duration("cost", cost),
        )
    }
}

// Recovery 返回恢复中间件
func Recovery() gin.HandlerFunc {
    return gin.Recovery()
}

// CORS 返回跨域中间件
func CORS() gin.HandlerFunc {
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
```

- [ ] **Step 5: 创建 Gateway 主入口**

Create `gateway/cmd/gateway/main.go`:

```go
package main

import (
    "log"
    
    "hub-registry/gateway/internal/config"
    "hub-registry/gateway/internal/router"
)

func main() {
    // 加载配置
    cfg := config.Load()
    
    // 创建路由器
    r := router.New(cfg)
    
    // 启动服务器
    log.Printf("Starting gateway on port %d...", cfg.Server.Port)
    if err := r.Run(); err != nil {
        log.Fatalf("Failed to start gateway: %v", err)
    }
}
```

- [ ] **Step 6: 编译并测试**

```bash
cd gateway
go build ./...
```

- [ ] **Step 7: 提交代码**

```bash
git add gateway/
git commit -m "feat: implement api gateway with basic routing and middleware"
```

---

### Phase 3: Registry Core 服务

#### Task 4: Registry Core Docker API 实现

**Files:**
- Create: `registry-core/go.mod`
- Create: `registry-core/cmd/registry/main.go`
- Create: `registry-core/internal/handlers/base.go`
- Create: `registry-core/internal/handlers/blob.go`
- Create: `registry-core/internal/handlers/manifest.go`

- [ ] **Step 1: 初始化 Registry Core 模块**

```bash
mkdir -p registry-core
cd registry-core
go mod init hub-registry/registry-core
go get -u github.com/gin-gonic/gin
go get -u github.com/google/uuid
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
go get -u github.com/aws/aws-sdk-go-v2
go get -u github.com/aws/aws-sdk-go-v2/config
go get -u github.com/aws/aws-sdk-go-v2/service/s3
```

- [ ] **Step 2: 创建基础 Handler**

Create `registry-core/internal/handlers/base.go`:

```go
package handlers

import (
    "net/http"
    
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

// BaseHandler 基础处理器
type BaseHandler struct {
    DB *gorm.DB
}

// NewBaseHandler 创建基础处理器
func NewBaseHandler(db *gorm.DB) *BaseHandler {
    return &BaseHandler{DB: db}
}

// APIError API 错误响应
type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Detail  string `json:"detail,omitempty"`
}

// RespondError 返回错误响应
func RespondError(c *gin.Context, status int, code, message string) {
    c.JSON(status, APIError{
        Code:    code,
        Message: message,
    })
}

// CheckDockerAPIVersion 设置 Docker Registry API 版本头
func CheckDockerAPIVersion(c *gin.Context) {
    c.Header("Docker-Distribution-API-Version", "registry/2.0")
}

// GetNameFromPath 从路径参数获取镜像名称
func GetNameFromPath(c *gin.Context) string {
    name := c.Param("name")
    if name == "" {
        name = c.Param("name1")
        if name2 := c.Param("name2"); name2 != "" {
            name = name + "/" + name2
        }
    }
    return name
}

// GetRepositoryFullName 返回完整仓库名
func GetRepositoryFullName(namespace, name string) string {
    if namespace == "" {
        return name
    }
    return namespace + "/" + name
}
```

由于内容过多，我将继续补充 Blob 和 Manifest Handler 的实现，然后继续其他服务的实现计划。