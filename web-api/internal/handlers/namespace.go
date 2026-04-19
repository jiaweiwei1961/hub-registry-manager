package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// NamespaceHandler 命名空间处理器
type NamespaceHandler struct {
	DB *gorm.DB
}

// NewNamespaceHandler 创建 NamespaceHandler
func NewNamespaceHandler(db *gorm.DB) *NamespaceHandler {
	return &NamespaceHandler{DB: db}
}

// ListNamespacesRequest 列出命名空间请求
type ListNamespacesRequest struct {
	Page     int    `form:"page"`
	PageSize int    `form:"page_size"`
	Search   string `form:"search"`
}

// NamespaceResponse 命名空间响应
type NamespaceResponse struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	DisplayName   string `json:"display_name"`
	Description   string `json:"description"`
	RepositoryCount int  `json:"repository_count"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
}

// ListNamespaces 列出命名空间
func (h *NamespaceHandler) ListNamespaces(c *gin.Context) {
	var req ListNamespacesRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "Invalid query parameters",
		})
		return
	}

	// 设置默认值
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 20
	}

	// 构建查询
	query := h.DB.Model(&models.Namespace{})
	if req.Search != "" {
		query = query.Where("name ILIKE ? OR display_name ILIKE ?", "%"+req.Search+"%", "%"+req.Search+"%")
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取分页数据
	var namespaces []models.Namespace
	offset := (req.Page - 1) * req.PageSize
	query.Offset(offset).Limit(req.PageSize).Find(&namespaces)

	// 构建响应
	response := make([]NamespaceResponse, len(namespaces))
	for i, ns := range namespaces {
		// 获取仓库数量
		var repoCount int64
		h.DB.Model(&models.Repository{}).Where("namespace_id = ?", ns.ID).Count(&repoCount)

		response[i] = NamespaceResponse{
			ID:              ns.ID.String(),
			Name:            ns.Name,
			DisplayName:     ns.DisplayName,
			Description:     ns.Description,
			RepositoryCount: int(repoCount),
			CreatedAt:       ns.CreatedAt.Format("2006-01-02T15:04:05Z"),
			UpdatedAt:       ns.UpdatedAt.Format("2006-01-02T15:04:05Z"),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"data": response,
		"pagination": gin.H{
			"page":       req.Page,
			"page_size":  req.PageSize,
			"total":      total,
			"total_pages": (int(total) + req.PageSize - 1) / req.PageSize,
		},
	})
}

// GetNamespace 获取命名空间详情
func (h *NamespaceHandler) GetNamespace(c *gin.Context) {
	id := c.Param("id")

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "Namespace not found",
		})
		return
	}

	// 获取仓库数量
	var repoCount int64
	h.DB.Model(&models.Repository{}).Where("namespace_id = ?", namespace.ID).Count(&repoCount)

	c.JSON(http.StatusOK, NamespaceResponse{
		ID:              namespace.ID.String(),
		Name:            namespace.Name,
		DisplayName:     namespace.DisplayName,
		Description:     namespace.Description,
		RepositoryCount: int(repoCount),
		CreatedAt:       namespace.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:       namespace.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	})
}

// CreateNamespaceRequest 创建命名空间请求
type CreateNamespaceRequest struct {
	Name        string `json:"name" binding:"required"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
}

// CreateNamespace 创建命名空间
func (h *NamespaceHandler) CreateNamespace(c *gin.Context) {
	var req CreateNamespaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "Invalid request body",
		})
		return
	}

	// 检查命名空间是否已存在
	var existing models.Namespace
	if err := h.DB.Where("name = ?", req.Name).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{
			"code":    "ALREADY_EXISTS",
			"message": "Namespace already exists",
		})
		return
	}

	// 创建命名空间
	namespace := models.Namespace{
		Name:        req.Name,
		DisplayName: req.DisplayName,
		Description: req.Description,
	}

	if err := h.DB.Create(&namespace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "Failed to create namespace",
		})
		return
	}

	c.JSON(http.StatusCreated, NamespaceResponse{
		ID:          namespace.ID.String(),
		Name:        namespace.Name,
		DisplayName: namespace.DisplayName,
		Description: namespace.Description,
		CreatedAt:   namespace.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:     namespace.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	})
}

// UpdateNamespaceRequest 更新命名空间请求
type UpdateNamespaceRequest struct {
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
}

// UpdateNamespace 更新命名空间
func (h *NamespaceHandler) UpdateNamespace(c *gin.Context) {
	id := c.Param("id")

	var req UpdateNamespaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "Invalid request body",
		})
		return
	}

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "Namespace not found",
		})
		return
	}

	// 更新字段
	if req.DisplayName != "" {
		namespace.DisplayName = req.DisplayName
	}
	if req.Description != "" {
		namespace.Description = req.Description
	}

	if err := h.DB.Save(&namespace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "Failed to update namespace",
		})
		return
	}

	c.JSON(http.StatusOK, NamespaceResponse{
		ID:          namespace.ID.String(),
		Name:        namespace.Name,
		DisplayName: namespace.DisplayName,
		Description: namespace.Description,
		CreatedAt:   namespace.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:     namespace.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	})
}

// DeleteNamespace 删除命名空间
func (h *NamespaceHandler) DeleteNamespace(c *gin.Context) {
	id := c.Param("id")

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "Namespace not found",
		})
		return
	}

	// 检查是否有关联的仓库
	var repoCount int64
	h.DB.Model(&models.Repository{}).Where("namespace_id = ?", namespace.ID).Count(&repoCount)
	if repoCount > 0 {
		c.JSON(http.StatusConflict, gin.H{
			"code":    "NOT_EMPTY",
			"message": "Cannot delete namespace with associated repositories",
		})
		return
	}

	// 删除命名空间
	if err := h.DB.Delete(&namespace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "Failed to delete namespace",
		})
		return
	}

	c.Status(http.StatusNoContent)
}

// Helper imports for this file - already included in imports above
