package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
	"hub-registry/web-api/internal/storage"
)

// RepositoryHandler 仓库处理器
type RepositoryHandler struct {
	DB          *gorm.DB
	AuditLogger *AuditLogHandler
	Storage     *storage.StorageClient
}

// NewRepositoryHandler 创建 RepositoryHandler
func NewRepositoryHandler(db *gorm.DB, storageClient *storage.StorageClient) *RepositoryHandler {
	return &RepositoryHandler{
		DB:          db,
		AuditLogger: NewAuditLogHandler(db),
		Storage:     storageClient,
	}
}

// ListRepositoriesRequest 列出仓库请求
type ListRepositoriesRequest struct {
	NamespaceID string `form:"namespace_id"`
	Search      string `form:"search"`
	Page        int    `form:"page"`
	PageSize    int    `form:"page_size"`
}

// RepositoryResponse 仓库响应
type RepositoryResponse struct {
	ID          string `json:"id"`
	NamespaceID string `json:"namespace_id"`
	Namespace   string `json:"namespace"`
	Name        string `json:"name"`
	FullName    string `json:"full_name"`
	Description string `json:"description"`
	IsPublic    bool   `json:"is_public"`
	OwnerID     string `json:"owner_id"`
	OwnerName   string `json:"owner_name"`
	PullCount   int64  `json:"pull_count"`
	ImageCount  int    `json:"image_count"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

// ListRepositories 获取仓库列表
func (h *RepositoryHandler) ListRepositories(c *gin.Context) {
	var req ListRepositoriesRequest
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

	query := h.DB.Model(&models.Repository{}).Preload("Namespace").Preload("Owner")

	// 过滤条件
	if req.NamespaceID != "" {
		query = query.Where("namespace_id = ?", req.NamespaceID)
	}
	if req.Search != "" {
		query = query.Where("name ILIKE ?", "%"+req.Search+"%")
	}

	// 权限过滤：普通用户只能看到公开的仓库和自己创建的仓库
	isAdmin, exists := c.Get("is_admin")
	userIDStr, _ := c.Get("user_id")

	if exists && !isAdmin.(bool) {
		// 普通用户：公开 OR 自己创建的
		userUUID, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			query = query.Where("is_public = true OR owner_id = ?", userUUID)
		}
	}

	// 计算总数
	var total int64
	query.Count(&total)

	// 分页查询（按创建时间正序排序）
	var repos []models.Repository
	offset := (req.Page - 1) * req.PageSize
	query.Order("created_at ASC").Offset(offset).Limit(req.PageSize).Find(&repos)

	// 构建响应
	response := make([]RepositoryResponse, len(repos))
	for i, repo := range repos {
		nsName := ""
		if repo.Namespace.Name != "" {
			nsName = repo.Namespace.Name
		}

		ownerName := ""
		if repo.Owner.Username != "" {
			ownerName = repo.Owner.Username
		} else if !UUIDPtrIsNil(repo.OwnerID) {
			var owner models.User
			if err := h.DB.First(&owner, "id = ?", repo.OwnerID).Error; err == nil {
				ownerName = owner.Username
			}
		}

		// 获取镜像数量（标签数量）
		var imageCount int64
		h.DB.Model(&models.Tag{}).Where("repository_id = ?", repo.ID).Count(&imageCount)

		response[i] = RepositoryResponse{
			ID:          repo.ID.String(),
			NamespaceID: repo.NamespaceID.String(),
			Namespace:   nsName,
			Name:        repo.Name,
			FullName:    nsName + "/" + repo.Name,
			Description: repo.Description,
			IsPublic:    repo.IsPublic,
			OwnerID:     UUIDPtrToString(repo.OwnerID),
			OwnerName:   ownerName,
			PullCount:   repo.PullCount,
			ImageCount:  int(imageCount),
			CreatedAt:   formatBeijingTime(repo.CreatedAt),
			UpdatedAt:   formatBeijingTime(repo.UpdatedAt),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"data": response,
		"pagination": gin.H{
			"page":        req.Page,
			"page_size":   req.PageSize,
			"total":       total,
			"total_pages": (int(total) + req.PageSize - 1) / req.PageSize,
		},
	})
}

// GetRepository 获取单个仓库详情
func (h *RepositoryHandler) GetRepository(c *gin.Context) {
	id := c.Param("id")

	var repo models.Repository
	if err := h.DB.Preload("Namespace").Preload("Owner").First(&repo, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "仓库不存在",
		})
		return
	}

	// 权限检查：私有仓库只有管理员和所有者可以查看
	isAdmin, _ := c.Get("is_admin")
	userIDStr, _ := c.Get("user_id")

	if !repo.IsPublic {
		if isAdmin == nil || !isAdmin.(bool) {
			if userIDStr == nil || userIDStr.(string) != UUIDPtrToString(repo.OwnerID) {
				c.JSON(http.StatusForbidden, gin.H{
					"code":    "FORBIDDEN",
					"message": "无权限访问此仓库",
				})
				return
			}
		}
	}

	// 获取标签列表（包含 manifest 信息）
	var tags []models.Tag
	h.DB.Preload("Manifest").Where("repository_id = ?", repo.ID).Find(&tags)

	// 获取镜像数量
	var imageCount int64
	h.DB.Model(&models.Tag{}).Where("repository_id = ?", repo.ID).Count(&imageCount)

	nsName := ""
	if repo.Namespace.Name != "" {
		nsName = repo.Namespace.Name
	}

	ownerName := ""
	if repo.Owner.Username != "" {
		ownerName = repo.Owner.Username
	} else if !UUIDPtrIsNil(repo.OwnerID) {
		var owner models.User
		if err := h.DB.First(&owner, "id = ?", repo.OwnerID).Error; err == nil {
			ownerName = owner.Username
		}
	}

	response := gin.H{
		"id":          repo.ID.String(),
		"namespace_id": repo.NamespaceID.String(),
		"namespace":    nsName,
		"name":         repo.Name,
		"full_name":    nsName + "/" + repo.Name,
		"description":  repo.Description,
		"is_public":    repo.IsPublic,
		"owner_id":     UUIDPtrToString(repo.OwnerID),
		"owner_name":   ownerName,
		"pull_count":   repo.PullCount,
		"image_count":  int(imageCount),
		"created_at":   formatBeijingTime(repo.CreatedAt),
		"updated_at":   formatBeijingTime(repo.UpdatedAt),
		"tags":         tags,
	}

	c.JSON(http.StatusOK, response)
}

// CreateRepositoryRequest 创建仓库请求
type CreateRepositoryRequest struct {
	NamespaceID string `json:"namespace_id" binding:"required"`
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	IsPublic    bool   `json:"is_public"`
}

// CreateRepository 创建仓库
func (h *RepositoryHandler) CreateRepository(c *gin.Context) {
	var req CreateRepositoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	// 解析namespace_id
	namespaceUUID, err := uuid.Parse(req.NamespaceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "命名空间ID无效",
		})
		return
	}

	// 验证仓库名称格式
	if !isValidRepositoryName(req.Name) {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_NAME",
			"message": "仓库名称只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾，长度2-255个字符",
		})
		return
	}

	// 检查命名空间是否存在
	var namespace models.Namespace
	if err := h.DB.First(&namespace, "id = ?", namespaceUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "命名空间不存在",
		})
		return
	}

	// 强制打印请求值用于调试
	log.Printf("DEBUG CreateRepository: name=%s, is_public=%v (type: %T), namespace_is_public=%v", req.Name, req.IsPublic, req.IsPublic, namespace.IsPublic)

	// 如果命名空间是私有的，仓库必须也是私有的
	actualIsPublic := req.IsPublic
	if !namespace.IsPublic {
		actualIsPublic = false
		log.Printf("DEBUG CreateRepository: namespace is private, forcing repository to be private")
	}

	// 检查仓库是否已存在（包括软删除的记录）
	var existing models.Repository
	err = h.DB.Unscoped().Where("namespace_id = ? AND name = ?", namespaceUUID, req.Name).First(&existing).Error

	if err == nil {
		// 如果找到记录
		if existing.DeletedAt.Valid {
			// 软删除的记录，恢复它
			existing.DeletedAt = gorm.DeletedAt{}
			existing.Description = req.Description
			existing.IsPublic = actualIsPublic

			// 获取当前用户ID作为所有者
			userIDStr, exists := c.Get("user_id")
			if exists && userIDStr != nil {
				existing.OwnerID = ParseUUIDToPtr(userIDStr.(string))
			}

			if err := h.DB.Unscoped().Save(&existing).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"code":    "INTERNAL_ERROR",
					"message": "恢复仓库失败",
				})
				return
			}

			ownerName := ""
			if !UUIDPtrIsNil(existing.OwnerID) {
				var owner models.User
				if err := h.DB.First(&owner, "id = ?", existing.OwnerID).Error; err == nil {
					ownerName = owner.Username
				}
			}

			// 记录审计日志 - 恢复仓库
			h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceRepository, existing.ID.String(), existing.Name,
				"恢复已删除的仓库", true, "")

			c.JSON(http.StatusCreated, RepositoryResponse{
				ID:          existing.ID.String(),
				NamespaceID: existing.NamespaceID.String(),
				Namespace:   namespace.Name,
				Name:        existing.Name,
				FullName:    namespace.Name + "/" + existing.Name,
				Description: existing.Description,
				IsPublic:    existing.IsPublic,
				OwnerID:     UUIDPtrToString(existing.OwnerID),
				OwnerName:   ownerName,
				PullCount:   existing.PullCount,
				ImageCount:  0,
				CreatedAt:   formatBeijingTime(existing.CreatedAt),
				UpdatedAt:   formatBeijingTime(existing.UpdatedAt),
			})
			return
		} else {
			// 活跃记录，已存在
			c.JSON(http.StatusConflict, gin.H{
				"code":    "ALREADY_EXISTS",
				"message": "仓库已存在",
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

	// 创建仓库
	repo := models.Repository{
		NamespaceID: namespaceUUID,
		Name:        req.Name,
		Description: req.Description,
		IsPublic:    actualIsPublic,
		OwnerID:     ownerID,
	}

	// 使用 Select 强制包含所有字段，确保零值字段也能被正确插入
	if err := h.DB.Select("NamespaceID", "Name", "Description", "IsPublic", "OwnerID", "PullCount", "CreatedAt", "UpdatedAt").Create(&repo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "创建仓库失败",
		})
		return
	}

	// 获取所有者名称
	ownerName := ""
	if !UUIDPtrIsNil(repo.OwnerID) {
		var owner models.User
		if err := h.DB.First(&owner, "id = ?", repo.OwnerID).Error; err == nil {
			ownerName = owner.Username
		}
	}

	// 记录审计日志 - 创建仓库
	h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceRepository, repo.ID.String(), repo.Name,
		"在命名空间 "+namespace.Name+" 下创建仓库", true, "")

	c.JSON(http.StatusCreated, RepositoryResponse{
		ID:          repo.ID.String(),
		NamespaceID: repo.NamespaceID.String(),
		Namespace:   namespace.Name,
		Name:        repo.Name,
		FullName:    namespace.Name + "/" + repo.Name,
		Description: repo.Description,
		IsPublic:    repo.IsPublic,
		OwnerID:     UUIDPtrToString(repo.OwnerID),
		OwnerName:   ownerName,
		PullCount:   0,
		ImageCount:  0,
		CreatedAt:   formatBeijingTime(repo.CreatedAt),
		UpdatedAt:   formatBeijingTime(repo.UpdatedAt),
	})
}

// UpdateRepositoryRequest 更新仓库请求
type UpdateRepositoryRequest struct {
	Description string `json:"description"`
	IsPublic    bool   `json:"is_public"`
}

// UpdateRepository 更新仓库
func (h *RepositoryHandler) UpdateRepository(c *gin.Context) {
	id := c.Param("id")

	var req UpdateRepositoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	repoUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "仓库ID无效",
		})
		return
	}

	var repo models.Repository
	if err := h.DB.Preload("Namespace").Preload("Owner").First(&repo, "id = ?", repoUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "仓库不存在",
		})
		return
	}

	// 权限检查：只有所有者或管理员可以更新
	userIDStr, _ := c.Get("user_id")
	isAdmin, _ := c.Get("is_admin")

	if !isAdmin.(bool) && userIDStr.(string) != UUIDPtrToString(repo.OwnerID) {
		c.JSON(http.StatusForbidden, gin.H{
			"code":    "FORBIDDEN",
			"message": "无权限修改此仓库",
		})
		return
	}

	// 更新字段
	if req.Description != "" {
		repo.Description = req.Description
	}

	// 如果命名空间是私有的，仓库必须也是私有的
	if repo.Namespace.IsPublic {
		repo.IsPublic = req.IsPublic
	} else {
		repo.IsPublic = false
		log.Printf("DEBUG UpdateRepository: namespace is private, forcing repository to remain private")
	}

	if err := h.DB.Save(&repo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "更新仓库失败",
		})
		return
	}

	// 获取镜像数量
	var imageCount int64
	h.DB.Model(&models.Tag{}).Where("repository_id = ?", repo.ID).Count(&imageCount)

	nsName := ""
	if repo.Namespace.Name != "" {
		nsName = repo.Namespace.Name
	}

	ownerName := ""
	if repo.Owner.Username != "" {
		ownerName = repo.Owner.Username
	} else if !UUIDPtrIsNil(repo.OwnerID) {
		var owner models.User
		if err := h.DB.First(&owner, "id = ?", repo.OwnerID).Error; err == nil {
			ownerName = owner.Username
		}
	}

	// 记录审计日志 - 更新仓库
	h.AuditLogger.CreateAuditLog(c, models.ActionUpdate, models.ResourceRepository, repo.ID.String(), repo.Name,
		"更新仓库", true, "")

	c.JSON(http.StatusOK, RepositoryResponse{
		ID:          repo.ID.String(),
		NamespaceID: repo.NamespaceID.String(),
		Namespace:   nsName,
		Name:        repo.Name,
		FullName:    nsName + "/" + repo.Name,
		Description: repo.Description,
		IsPublic:    repo.IsPublic,
		OwnerID:     UUIDPtrToString(repo.OwnerID),
		OwnerName:   ownerName,
		PullCount:   repo.PullCount,
		ImageCount:  int(imageCount),
		CreatedAt:   formatBeijingTime(repo.CreatedAt),
		UpdatedAt:   formatBeijingTime(repo.UpdatedAt),
	})
}

// DeleteRepository 删除仓库
func (h *RepositoryHandler) DeleteRepository(c *gin.Context) {
	id := c.Param("id")

	repoUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "仓库ID无效",
		})
		return
	}

	var repo models.Repository
	if err := h.DB.Preload("Namespace").First(&repo, "id = ?", repoUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "仓库不存在",
		})
		return
	}

	// 权限检查：只有所有者或管理员可以删除
	userIDStr, _ := c.Get("user_id")
	isAdmin, _ := c.Get("is_admin")

	if !isAdmin.(bool) && userIDStr.(string) != UUIDPtrToString(repo.OwnerID) {
		c.JSON(http.StatusForbidden, gin.H{
			"code":    "FORBIDDEN",
			"message": "无权限删除此仓库",
		})
		return
	}

	// 检查是否有镜像（标签）
	var tagCount int64
	h.DB.Model(&models.Tag{}).Where("repository_id = ?", repo.ID).Count(&tagCount)
	if tagCount > 0 {
		c.JSON(http.StatusConflict, gin.H{
			"code":    "NOT_EMPTY",
			"message": "仓库下有镜像，不能删除。请先删除所有镜像版本。",
		})
		return
	}

	// 清理 MinIO 中可能残留的 blobs（以防万一）
	namespaceName := repo.Namespace.Name
	if namespaceName != "" && h.Storage != nil {
		h.Storage.DeleteAllRepositoryBlobs(namespaceName, repo.Name)
	}

	// 删除仓库
	if err := h.DB.Delete(&repo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "删除仓库失败",
		})
		return
	}

	// 记录审计日志 - 删除仓库
	h.AuditLogger.CreateAuditLog(c, models.ActionDelete, models.ResourceRepository, repo.ID.String(), repo.Name,
		"删除仓库", true, "")

	c.JSON(http.StatusOK, gin.H{
		"message": "仓库删除成功",
	})
}

// GetRepositoryTags 获取仓库的标签列表
func (h *RepositoryHandler) GetRepositoryTags(c *gin.Context) {
	id := c.Param("id")

	var repo models.Repository
	if err := h.DB.First(&repo, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "仓库不存在",
		})
		return
	}

	var tags []models.Tag
	h.DB.Preload("Manifest").Where("repository_id = ?", repo.ID).Find(&tags)

	c.JSON(http.StatusOK, tags)
}

// DeleteTag 删除仓库的标签
func (h *RepositoryHandler) DeleteTag(c *gin.Context) {
	repoID := c.Param("id")
	tagID := c.Param("tag_id")

	repoUUID, err := uuid.Parse(repoID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "仓库ID无效",
		})
		return
	}

	var repo models.Repository
	if err := h.DB.Preload("Namespace").First(&repo, "id = ?", repoUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "仓库不存在",
		})
		return
	}

	// 权限检查：只有所有者或管理员可以删除标签
	userIDStr, _ := c.Get("user_id")
	isAdmin, _ := c.Get("is_admin")

	if !isAdmin.(bool) && userIDStr.(string) != UUIDPtrToString(repo.OwnerID) {
		c.JSON(http.StatusForbidden, gin.H{
			"code":    "FORBIDDEN",
			"message": "无权限删除此标签",
		})
		return
	}

	tagUUID, err := uuid.Parse(tagID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "标签ID无效",
		})
		return
	}

	var tag models.Tag
	if err := h.DB.Preload("Manifest").Where("repository_id = ? AND id = ?", repo.ID, tagUUID).First(&tag).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "标签不存在",
		})
		return
	}

	manifestID := tag.ManifestID
	digest := tag.Manifest.Digest

	// 删除标签
	if err := h.DB.Delete(&tag).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "删除标签失败",
		})
		return
	}

	// 检查 manifest 是否还有其他标签引用
	var remainingTagCount int64
	h.DB.Model(&models.Tag{}).Where("manifest_id = ?", manifestID).Count(&remainingTagCount)

	// 如果没有其他标签引用，删除 manifest 和关联的 blobs
	if remainingTagCount == 0 {
		// 获取 manifest 关联的 blobs
		var manifest models.Manifest
		if err := h.DB.Preload("Blobs").First(&manifest, "id = ?", manifestID).Error; err == nil {
			// 删除 manifest_blobs 关联记录
			h.DB.Exec("DELETE FROM manifest_blobs WHERE manifest_id = ?", manifestID)

			// 删除 manifest 记录
			h.DB.Delete(&manifest)

			// 删除 MinIO 中的 manifest blob
			namespaceName := repo.Namespace.Name
			if namespaceName != "" && digest != "" {
				h.Storage.DeleteManifest(namespaceName, repo.Name, digest)
				log.Printf("Deleted manifest blob from MinIO: %s/%s/%s", namespaceName, repo.Name, digest)
			}

			// 删除关联的 layer blobs (config + layers)
			for _, blob := range manifest.Blobs {
				// 检查 blob 是否还被其他 manifest 引用
				var blobRefCount int64
				h.DB.Table("manifest_blobs").Where("blob_id = ?", blob.ID).Count(&blobRefCount)
				if blobRefCount == 0 {
					// 删除 blob 记录
					h.DB.Delete(&blob)
					// 删除 MinIO 中的 blob
					if namespaceName != "" && blob.StoragePath != "" {
						h.Storage.DeleteBlob(blob.StoragePath)
						log.Printf("Deleted blob from MinIO: %s", blob.StoragePath)
					}
				}
			}
		}
	}

	// 记录审计日志 - 删除标签
	h.AuditLogger.CreateAuditLog(c, models.ActionDelete, models.ResourceTag, tag.ID.String(), tag.Name,
		"删除仓库 "+repo.Name+" 的标签", true, "")

	c.JSON(http.StatusOK, gin.H{
		"message": "标签删除成功",
	})
}

// parseIntQuery 解析整数查询参数
func parseIntQuery(s string) (int, error) {
	if s == "" {
		return 0, nil
	}
	return strconv.Atoi(s)
}