package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// ManifestHandler 处理 manifest 相关请求
type ManifestHandler struct {
	BaseHandler
	DB *gorm.DB
}

// NewManifestHandler 创建 ManifestHandler
func NewManifestHandler(db *gorm.DB) *ManifestHandler {
	return &ManifestHandler{
		BaseHandler: NewBaseHandler(db),
		DB:          db,
	}
}

// GetManifest 获取 manifest
func (h *ManifestHandler) GetManifest(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	reference := c.Param("reference")

	if name == "" || reference == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or reference is required")
		return
	}

	// 解析命名空间和仓库名
	namespace, repoName := parseRepositoryName(name)

	// 查找仓库
	var repo models.Repository
	if err := h.DB.Where("name = ?", repoName).First(&repo).Error; err != nil {
		RespondError(c, http.StatusNotFound, "REPOSITORY_NOT_FOUND", "repository not found")
		return
	}

	// 查找 manifest
	var manifest models.Manifest
	var err error

	// 尝试通过 digest 查找
	if isDigest(reference) {
		err = h.DB.Where("repository_id = ? AND digest = ?", repo.ID, reference).First(&manifest).Error
	} else {
		// 通过 tag 查找
		var tag models.Tag
		if err = h.DB.Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error; err == nil {
			err = h.DB.First(&manifest, tag.ManifestID).Error
		}
	}

	if err != nil {
		RespondError(c, http.StatusNotFound, "MANIFEST_NOT_FOUND", "manifest not found")
		return
	}

	// 更新 pull 计数
	h.DB.Model(&repo).Update("pull_count", gorm.Expr("pull_count + 1"))

	// 构建 manifest 响应
	manifestData := buildManifestResponse(&manifest)
	manifestJSON, _ := json.Marshal(manifestData)

	c.Header("Docker-Content-Digest", manifest.Digest)
	c.Header("Content-Type", manifest.MediaType)
	c.Header("Content-Length", fmt.Sprintf("%d", len(manifestJSON)))
	c.Data(http.StatusOK, manifest.MediaType, manifestJSON)
}

// PutManifest 上传 manifest
func (h *ManifestHandler) PutManifest(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	reference := c.Param("reference")

	if name == "" || reference == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or reference is required")
		return
	}

	// 读取请求体
	data, err := c.GetRawData()
	if err != nil {
		RespondError(c, http.StatusBadRequest, "INVALID_DATA", "failed to read request data")
		return
	}

	// 解析 manifest
	var manifestData map[string]interface{}
	if err := json.Unmarshal(data, &manifestData); err != nil {
		RespondError(c, http.StatusBadRequest, "INVALID_MANIFEST", "invalid manifest format")
		return
	}

	// 计算 digest（简化版本）
	digest := calculateDigest(data)

	// 解析命名空间和仓库名
	namespace, repoName := parseRepositoryName(name)

	// 查找或创建仓库
	var repo models.Repository
	if err := h.DB.Where("name = ?", repoName).First(&repo).Error; err != nil {
		// 创建新仓库
		repo = models.Repository{
			Name:        repoName,
			NamespaceID: uuid.Nil, // TODO: 查找或创建命名空间
		}
		if err := h.DB.Create(&repo).Error; err != nil {
			RespondError(c, http.StatusInternalServerError, "DATABASE_ERROR", "failed to create repository")
			return
		}
	}

	// 检查 manifest 是否已存在
	var existingManifest models.Manifest
	if err := h.DB.Where("repository_id = ? AND digest = ?", repo.ID, digest).First(&existingManifest).Error; err == nil {
		// manifest 已存在
		c.Header("Docker-Content-Digest", digest)
		c.Header("Location", fmt.Sprintf("/v2/%s/manifests/%s", name, reference))
		c.Status(http.StatusCreated)
		return
	}

	// 创建 manifest 记录
	manifest := models.Manifest{
		RepositoryID: repo.ID,
		Digest:       digest,
		MediaType:    c.ContentType(),
		TotalSize:    int64(len(data)),
	}

	if configDigest, ok := manifestData["config"].(map[string]interface{}); ok {
		if digest, ok := configDigest["digest"].(string); ok {
			manifest.ConfigDigest = digest
		}
		if size, ok := configDigest["size"].(float64); ok {
			manifest.ConfigSize = int64(size)
		}
	}

	if layers, ok := manifestData["layers"].([]interface{}); ok {
		manifest.LayersCount = len(layers)
	}

	if err := h.DB.Create(&manifest).Error; err != nil {
		RespondError(c, http.StatusInternalServerError, "DATABASE_ERROR", "failed to create manifest")
		return
	}

	// 如果是标签引用，创建或更新标签
	if !isDigest(reference) {
		var tag models.Tag
		if err := h.DB.Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error; err == nil {
			// 更新现有标签
			tag.ManifestID = manifest.ID
			tag.PushedAt = time.Now()
			h.DB.Save(&tag)
		} else {
			// 创建新标签
			tag = models.Tag{
				RepositoryID: repo.ID,
				Name:         reference,
				ManifestID:   manifest.ID,
				PushedAt:     time.Now(),
			}
			h.DB.Create(&tag)
		}
	}

	c.Header("Docker-Content-Digest", digest)
	c.Header("Location", fmt.Sprintf("/v2/%s/manifests/%s", name, reference))
	c.Status(http.StatusCreated)
}

// DeleteManifest 删除 manifest
func (h *ManifestHandler) DeleteManifest(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	reference := c.Param("reference")

	if name == "" || reference == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or reference is required")
		return
	}

	// 解析命名空间和仓库名
	namespace, repoName := parseRepositoryName(name)

	// 查找仓库
	var repo models.Repository
	if err := h.DB.Where("name = ?", repoName).First(&repo).Error; err != nil {
		RespondError(c, http.StatusNotFound, "REPOSITORY_NOT_FOUND", "repository not found")
		return
	}

	// 查找 manifest
	var manifest models.Manifest
	var err error

	if isDigest(reference) {
		err = h.DB.Where("repository_id = ? AND digest = ?", repo.ID, reference).First(&manifest).Error
	} else {
		// 通过 tag 查找
		var tag models.Tag
		if err = h.DB.Where("repository_id = ? AND name = ?", repo.ID, reference).First(&tag).Error; err == nil {
			err = h.DB.First(&manifest, tag.ManifestID).Error
		}
	}

	if err != nil {
		RespondError(c, http.StatusNotFound, "MANIFEST_NOT_FOUND", "manifest not found")
		return
	}

	// 删除关联的标签
	h.DB.Where("manifest_id = ?", manifest.ID).Delete(&models.Tag{})

	// 删除 manifest
	h.DB.Delete(&manifest)

	c.Status(http.StatusAccepted)
}

// Helper functions

func parseRepositoryName(name string) (namespace, repoName string) {
	parts := strings.Split(name, "/")
	if len(parts) == 1 {
		return "", parts[0]
	}
	return parts[0], strings.Join(parts[1:], "/")
}

func isDigest(ref string) bool {
	return strings.HasPrefix(ref, "sha256:") || strings.HasPrefix(ref, "sha512:")
}

func calculateDigest(data []byte) string {
	// 简化版本，实际应该使用 crypto/sha256
	return fmt.Sprintf("sha256:%x", len(data))
}

func buildManifestResponse(m *models.Manifest) map[string]interface{} {
	return map[string]interface{}{
		"schemaVersion": 2,
		"mediaType":     m.MediaType,
		"config": map[string]interface{}{
			"digest": m.ConfigDigest,
			"size":   m.ConfigSize,
		},
		"layers": []map[string]interface{}{},
	}
}
