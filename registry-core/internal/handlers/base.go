package handlers

import (
	"net/http"
	"strings"

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
	// 支持多级路径 name1/name2/...
	name := c.Param("name")
	if name == "" {
		// 尝试从多个路径参数组合
		parts := []string{}
		for i := 1; i <= 10; i++ {
			part := c.Param(fmt.Sprintf("name%d", i))
			if part == "" {
				break
			}
			parts = append(parts, part)
		}
		name = strings.Join(parts, "/")
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
