package handlers

import (
	"log"
	"net/http"
	"regexp"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
	"hub-registry/web-api/internal/storage"
)

// 北京时间时区
var beijingLoc = time.FixedZone("CST", 8*3600)

// 命名空间名称正则：小写字母、数字、下划线、点、连字符，不能以点或连字符开头或结尾
var namespaceNameRegex = regexp.MustCompile(`^[a-z0-9]+([._-][a-z0-9]+)*$`)

// isValidNamespaceName 验证命名空间名称是否符合Docker镜像命名规范
func isValidNamespaceName(name string) bool {
	if len(name) < 2 || len(name) > 255 {
		return false
	}
	return namespaceNameRegex.MatchString(name)
}

// isValidRepositoryName 验证仓库名称是否符合Docker镜像命名规范
func isValidRepositoryName(name string) bool {
	if len(name) < 2 || len(name) > 255 {
		return false
	}
	return namespaceNameRegex.MatchString(name)
}

// isValidTagName 验证标签名称是否符合Docker镜像命名规范
func isValidTagName(name string) bool {
	if len(name) < 1 || len(name) > 128 {
		return false
	}
	// 标签可以包含字母、数字、下划线、点、连字符
	tagRegex := regexp.MustCompile(`^[a-zA-Z0-9_.-]+$`)
	return tagRegex.MatchString(name)
}

// formatBeijingTime 将时间格式化为北京时间字符串
func formatBeijingTime(t time.Time) string {
	return t.In(beijingLoc).Format("2006-01-02 15:04")
}

// NamespaceHandler 命名空间处理器
type NamespaceHandler struct {
	DB          *gorm.DB
	AuditLogger *AuditLogHandler
	Storage     *storage.StorageClient
}

// NewNamespaceHandler 创建 NamespaceHandler
func NewNamespaceHandler(db *gorm.DB, storageClient *storage.StorageClient) *NamespaceHandler {
	return &NamespaceHandler{
		DB:          db,
		AuditLogger: NewAuditLogHandler(db),
		Storage:     storageClient,
	}
}

// ListNamespacesRequest 列出命名空间请求
type ListNamespacesRequest struct {
	Page     int    `form:"page"`
	PageSize int    `form:"page_size"`
	Search   string `form:"search"`
}

// NamespaceResponse 命名空间响应
type NamespaceResponse struct {
	ID              string `json:"id"`
	Name            string `json:"name"`
	DisplayName     string `json:"display_name"`
	Description     string `json:"description"`
	IsPublic        bool   `json:"is_public"`
	OwnerID         string `json:"owner_id"`
	OwnerName       string `json:"owner_name"`
	RepositoryCount int    `json:"repository_count"`
	ImageCount      int    `json:"image_count"`
	PullCount       int64  `json:"pull_count"`
	CreatedAt       string `json:"created_at"`
	UpdatedAt       string `json:"updated_at"`
}

// ListNamespaces 列出命名空间
func (h *NamespaceHandler) ListNamespaces(c *gin.Context) {
	var req ListNamespacesRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "查询参数无效",
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

	// 权限过滤：普通用户只能看到公开的命名空间和自己创建的命名空间
	isAdmin, exists := c.Get("is_admin")
	userIDStr, _ := c.Get("user_id")

	if exists && !isAdmin.(bool) {
		// 普通用户：公开 OR 自己创建的
		userUUID, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			query = query.Where("is_public = true OR owner_id = ?", userUUID)
		}
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取分页数据（按创建时间正序排序）
	var namespaces []models.Namespace
	offset := (req.Page - 1) * req.PageSize
	query.Order("created_at ASC").Offset(offset).Limit(req.PageSize).Preload("Owner").Find(&namespaces)

	// 构建响应
	response := make([]NamespaceResponse, len(namespaces))
	for i, ns := range namespaces {
		// 获取仓库数量
		var repoCount int64
		h.DB.Model(&models.Repository{}).Where("namespace_id = ?", ns.ID).Count(&repoCount)

		// 获取镜像数量（标签数量）
		var imageCount int64
		h.DB.Table("tags").
			Joins("JOIN repositories ON repositories.id = tags.repository_id").
			Where("repositories.namespace_id = ?", ns.ID).
			Count(&imageCount)

		// 获取下载次数
		var pullCount int64
		h.DB.Model(&models.Repository{}).Where("namespace_id = ?", ns.ID).Select("COALESCE(SUM(pull_count), 0)").Scan(&pullCount)

		ownerName := ""
		if ns.Owner.Username != "" {
			ownerName = ns.Owner.Username
		} else if !UUIDPtrIsNil(ns.OwnerID) {
			// 如果没有预加载Owner，单独查询
			var owner models.User
			if err := h.DB.First(&owner, "id = ?", ns.OwnerID).Error; err == nil {
				ownerName = owner.Username
			}
		}

		response[i] = NamespaceResponse{
			ID:              ns.ID.String(),
			Name:            ns.Name,
			DisplayName:     ns.DisplayName,
			Description:     ns.Description,
			IsPublic:        ns.IsPublic,
			OwnerID:         UUIDPtrToString(ns.OwnerID),
			OwnerName:       ownerName,
			RepositoryCount: int(repoCount),
			ImageCount:      int(imageCount),
			PullCount:       pullCount,
			CreatedAt:       formatBeijingTime(ns.CreatedAt),
			UpdatedAt:       formatBeijingTime(ns.UpdatedAt),
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
	if err := h.DB.Preload("Owner").First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "命名空间不存在",
		})
		return
	}

	// 权限检查：私有命名空间只有管理员和所有者可以查看
	isAdmin, _ := c.Get("is_admin")
	userIDStr, _ := c.Get("user_id")

	if !namespace.IsPublic {
		if isAdmin == nil || !isAdmin.(bool) {
			if userIDStr == nil || userIDStr.(string) != UUIDPtrToString(namespace.OwnerID) {
				c.JSON(http.StatusForbidden, gin.H{
					"code":    "FORBIDDEN",
					"message": "无权限访问此命名空间",
				})
				return
			}
		}
	}

	// 获取仓库数量
	var repoCount int64
	h.DB.Model(&models.Repository{}).Where("namespace_id = ?", namespace.ID).Count(&repoCount)

	// 获取镜像数量
	var imageCount int64
	h.DB.Table("tags").
		Joins("JOIN repositories ON repositories.id = tags.repository_id").
		Where("repositories.namespace_id = ?", namespace.ID).
		Count(&imageCount)

	// 获取下载次数
	var pullCount int64
	h.DB.Model(&models.Repository{}).Where("namespace_id = ?", namespace.ID).Select("COALESCE(SUM(pull_count), 0)").Scan(&pullCount)

	ownerName := ""
	if namespace.Owner.Username != "" {
		ownerName = namespace.Owner.Username
	} else if !UUIDPtrIsNil(namespace.OwnerID) {
		var owner models.User
		if err := h.DB.First(&owner, "id = ?", namespace.OwnerID).Error; err == nil {
			ownerName = owner.Username
		}
	}

	c.JSON(http.StatusOK, NamespaceResponse{
		ID:              namespace.ID.String(),
		Name:            namespace.Name,
		DisplayName:     namespace.DisplayName,
		Description:     namespace.Description,
		IsPublic:        namespace.IsPublic,
		OwnerID:         UUIDPtrToString(namespace.OwnerID),
		OwnerName:       ownerName,
		RepositoryCount: int(repoCount),
		ImageCount:      int(imageCount),
		PullCount:       pullCount,
		CreatedAt:       formatBeijingTime(namespace.CreatedAt),
		UpdatedAt:       formatBeijingTime(namespace.UpdatedAt),
	})
}

// CreateNamespaceRequest 创建命名空间请求
type CreateNamespaceRequest struct {
	Name        string `json:"name" binding:"required"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
	IsPublic    bool   `json:"is_public"`
}

// CreateNamespace 创建命名空间
func (h *NamespaceHandler) CreateNamespace(c *gin.Context) {
	var req CreateNamespaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
			"error":   err.Error(),
		})
		return
	}

	// 验证命名空间名称格式
	if !isValidNamespaceName(req.Name) {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_NAME",
			"message": "命名空间名称只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾，长度2-255个字符",
		})
		return
	}

	// 强制打印请求值用于调试
	log.Printf("DEBUG CreateNamespace: name=%s, is_public=%v (type: %T)", req.Name, req.IsPublic, req.IsPublic)

	// 检查命名空间是否已存在（包括软删除的记录）
	var existing models.Namespace
	err := h.DB.Unscoped().Where("name = ?", req.Name).First(&existing).Error

	if err == nil {
		// 如果找到记录
		if existing.DeletedAt.Valid {
			// 软删除的记录，恢复它
			existing.DeletedAt = gorm.DeletedAt{}
			existing.DisplayName = req.DisplayName
			existing.Description = req.Description
			existing.IsPublic = req.IsPublic

			// 获取当前用户ID作为所有者
			userIDStr, exists := c.Get("user_id")
			if exists && userIDStr != nil {
				existing.OwnerID = ParseUUIDToPtr(userIDStr.(string))
			}

			if err := h.DB.Unscoped().Save(&existing).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"code":    "INTERNAL_ERROR",
					"message": "恢复命名空间失败",
				})
				return
			}

			// 获取所有者名称
			ownerName := ""
			if !UUIDPtrIsNil(existing.OwnerID) {
				var owner models.User
				if err := h.DB.First(&owner, "id = ?", existing.OwnerID).Error; err == nil {
					ownerName = owner.Username
				}
			}

			// 记录审计日志 - 恢复命名空间
			h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceNamespace, existing.ID.String(), existing.Name,
				"恢复已删除的命名空间", true, "")

			c.JSON(http.StatusCreated, NamespaceResponse{
				ID:          existing.ID.String(),
				Name:        existing.Name,
				DisplayName: existing.DisplayName,
				Description: existing.Description,
				IsPublic:    existing.IsPublic,
				OwnerID:     UUIDPtrToString(existing.OwnerID),
				OwnerName:   ownerName,
				CreatedAt:   formatBeijingTime(existing.CreatedAt),
				UpdatedAt:   formatBeijingTime(existing.UpdatedAt),
			})
			return
		} else {
			// 活跃记录，已存在
			c.JSON(http.StatusConflict, gin.H{
				"code":    "ALREADY_EXISTS",
				"message": "命名空间已存在",
			})
			return
		}
	}

	// 获取当前用户ID作为所有者
	userIDStr, exists := c.Get("user_id")
	var ownerID *uuid.UUID
	if exists && userIDStr != nil {
		ownerID = ParseUUIDToPtr(userIDStr.(string))
	}

	// 创建命名空间
	namespace := models.Namespace{
		Name:        req.Name,
		DisplayName: req.DisplayName,
		Description: req.Description,
		IsPublic:    req.IsPublic,
		OwnerID:     ownerID,
	}

	// 使用 Select 强制包含所有字段，确保零值字段也能被正确插入
	if err := h.DB.Select("Name", "DisplayName", "Description", "IsPublic", "OwnerID", "CreatedAt", "UpdatedAt").Create(&namespace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "创建命名空间失败",
		})
		return
	}

	// 获取所有者名称
	var owner models.User
	ownerName := ""
	if !UUIDPtrIsNil(namespace.OwnerID) {
		if err := h.DB.First(&owner, "id = ?", namespace.OwnerID).Error; err == nil {
			ownerName = owner.Username
		}
	}

	// 记录审计日志 - 创建命名空间
	h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceNamespace, namespace.ID.String(), namespace.Name,
		"创建命名空间", true, "")

	c.JSON(http.StatusCreated, NamespaceResponse{
		ID:          namespace.ID.String(),
		Name:        namespace.Name,
		DisplayName: namespace.DisplayName,
		Description: namespace.Description,
		IsPublic:    namespace.IsPublic,
		OwnerID:     UUIDPtrToString(namespace.OwnerID),
		OwnerName:   ownerName,
		CreatedAt:   formatBeijingTime(namespace.CreatedAt),
		UpdatedAt:   formatBeijingTime(namespace.UpdatedAt),
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
			"message": "请求体无效",
		})
		return
	}

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "命名空间不存在",
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
			"message": "更新命名空间失败",
		})
		return
	}

	// 记录审计日志 - 更新命名空间
	h.AuditLogger.CreateAuditLog(c, models.ActionUpdate, models.ResourceNamespace, namespace.ID.String(), namespace.Name,
		"更新命名空间", true, "")

	c.JSON(http.StatusOK, NamespaceResponse{
		ID:          namespace.ID.String(),
		Name:        namespace.Name,
		DisplayName: namespace.DisplayName,
		Description: namespace.Description,
		CreatedAt:   formatBeijingTime(namespace.CreatedAt),
		UpdatedAt:     formatBeijingTime(namespace.UpdatedAt),
	})
}

// DeleteNamespace 删除命名空间
func (h *NamespaceHandler) DeleteNamespace(c *gin.Context) {
	id := c.Param("id")

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "命名空间不存在",
		})
		return
	}

	// 检查是否有关联的仓库
	var repoCount int64
	h.DB.Model(&models.Repository{}).Where("namespace_id = ?", namespace.ID).Count(&repoCount)
	if repoCount > 0 {
		c.JSON(http.StatusConflict, gin.H{
			"code":    "NOT_EMPTY",
			"message": "命名空间下有仓库，不能删除。请先删除所有仓库。",
		})
		return
	}

	// 清理 MinIO 中可能残留的 blobs（以防万一）
	if namespace.Name != "" && h.Storage != nil {
		h.Storage.DeleteNamespaceBlobs(namespace.Name)
	}

	// 删除命名空间
	if err := h.DB.Delete(&namespace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "删除命名空间失败",
		})
		return
	}

	// 记录审计日志 - 删除命名空间
	h.AuditLogger.CreateAuditLog(c, models.ActionDelete, models.ResourceNamespace, namespace.ID.String(), namespace.Name,
		"删除命名空间", true, "")

	c.Status(http.StatusNoContent)
}

// GetNamespaceRepositories 获取命名空间下的仓库列表
func (h *NamespaceHandler) GetNamespaceRepositories(c *gin.Context) {
	id := c.Param("id")

	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "命名空间不存在",
		})
		return
	}

	// 权限检查：私有命名空间只有管理员和所有者可以查看其仓库列表
	isAdmin, _ := c.Get("is_admin")
	userIDStr, _ := c.Get("user_id")

	if !namespace.IsPublic {
		if isAdmin == nil || !isAdmin.(bool) {
			if userIDStr == nil || userIDStr.(string) != UUIDPtrToString(namespace.OwnerID) {
				c.JSON(http.StatusForbidden, gin.H{
					"code":    "FORBIDDEN",
					"message": "无权限访问此命名空间",
				})
				return
			}
		}
	}

	// 构建仓库查询，并过滤权限
	query := h.DB.Where("namespace_id = ?", namespace.ID)

	// 对于普通用户，只显示公开的仓库和自己创建的仓库
	if isAdmin == nil || !isAdmin.(bool) {
		userUUID, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			query = query.Where("is_public = true OR owner_id = ?", userUUID)
		}
	}

	var repos []models.Repository
	query.Preload("Owner").Find(&repos)

	response := make([]gin.H, len(repos))
	for i, repo := range repos {
		ownerName := ""
		if repo.Owner.Username != "" {
			ownerName = repo.Owner.Username
		} else if !UUIDPtrIsNil(repo.OwnerID) {
			var owner models.User
			if err := h.DB.First(&owner, "id = ?", repo.OwnerID).Error; err == nil {
				ownerName = owner.Username
			}
		}

		// 获取镜像数量
		var imageCount int64
		h.DB.Model(&models.Tag{}).Where("repository_id = ?", repo.ID).Count(&imageCount)

		response[i] = gin.H{
			"id":           repo.ID.String(),
			"name":         repo.Name,
			"full_name":    namespace.Name + "/" + repo.Name,
			"description":  repo.Description,
			"is_public":    repo.IsPublic,
			"owner_id":     UUIDPtrToString(repo.OwnerID),
			"owner_name":   ownerName,
			"pull_count":   repo.PullCount,
			"image_count":  int(imageCount),
			"created_at":   formatBeijingTime(repo.CreatedAt),
			"updated_at":   formatBeijingTime(repo.UpdatedAt),
		}
	}

	c.JSON(http.StatusOK, response)
}