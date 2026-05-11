package handlers

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// SystemHandler 系统处理器
type SystemHandler struct {
	DB *gorm.DB
}

// NewSystemHandler 创建 SystemHandler
func NewSystemHandler(db *gorm.DB) *SystemHandler {
	return &SystemHandler{DB: db}
}

// SystemStatsResponse 系统统计响应
type SystemStatsResponse struct {
	TotalRepositories int64  `json:"total_repositories"`
	TotalNamespaces   int64  `json:"total_namespaces"`
	TotalImages       int64  `json:"total_images"`
	TotalPullCount    int64  `json:"total_pull_count"`
	StorageUsed       int64  `json:"storage_used"`
}

// GetStats 获取系统统计
func (h *SystemHandler) GetStats(c *gin.Context) {
	var stats SystemStatsResponse

	// 获取命名空间总数
	h.DB.Model(&models.Namespace{}).Count(&stats.TotalNamespaces)

	// 获取仓库总数
	h.DB.Model(&models.Repository{}).Count(&stats.TotalRepositories)

	// 获取镜像总数（标签数）
	h.DB.Model(&models.Tag{}).Count(&stats.TotalImages)

	// 获取总下载量
	h.DB.Model(&models.Repository{}).Select("SUM(pull_count)").Scan(&stats.TotalPullCount)

	// 获取存储使用量
	h.DB.Model(&models.Blob{}).Select("SUM(size)").Scan(&stats.StorageUsed)

	c.JSON(http.StatusOK, stats)
}

// RegistryConfig Registry配置响应
type RegistryConfig struct {
	RegistryHost     string `json:"registry_host"`
	RegistryPort     string `json:"registry_port"`
	ExternalHost     string `json:"external_host"`
	ExternalPort     string `json:"external_port"`
	FullRegistryAddr string `json:"full_registry_addr"`
}

// GetRegistryConfig 获取Registry配置
func (h *SystemHandler) GetRegistryConfig(c *gin.Context) {
	// 从环境变量获取配置，如果没有则使用默认值
	registryHost := os.Getenv("REGISTRY_HOST")
	if registryHost == "" {
		registryHost = "localhost"
	}

	registryPort := os.Getenv("REGISTRY_PORT")
	if registryPort == "" {
		registryPort = "5000"
	}

	externalHost := os.Getenv("EXTERNAL_HOST")
	if externalHost == "" {
		// 使用请求的Host作为外部访问地址
		hostFromRequest := c.Request.Host
		if hostFromRequest != "" {
			// 去掉端口部分
			for idx := 0; idx < len(hostFromRequest); idx++ {
				if hostFromRequest[idx] == ':' {
					externalHost = hostFromRequest[:idx]
					break
				}
			}
			if externalHost == "" {
				externalHost = hostFromRequest
			}
		} else {
			externalHost = "hub.auok.online"
		}
	}

	externalPort := os.Getenv("EXTERNAL_PORT")
	if externalPort == "" {
		externalPort = "50000"
	}

	// 构建完整的registry地址
	fullAddr := externalHost + ":" + externalPort

	c.JSON(http.StatusOK, RegistryConfig{
		RegistryHost:     registryHost,
		RegistryPort:     registryPort,
		ExternalHost:     externalHost,
		ExternalPort:     externalPort,
		FullRegistryAddr: fullAddr,
	})
}