package handlers

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// BlobHandler 处理 blob 相关请求
type BlobHandler struct {
	*BaseHandler
	Storage Storage
}

// Storage 存储接口
type Storage interface {
	UploadBlob(digest string, data []byte) error
	DownloadBlob(digest string) ([]byte, error)
	DeleteBlob(digest string) error
	BlobExists(digest string) bool
}

// NewBlobHandler 创建 BlobHandler
func NewBlobHandler(db *gorm.DB, storage Storage) *BlobHandler {
	return &BlobHandler{
		BaseHandler: NewBaseHandler(db),
		Storage:     storage,
	}
}

// HeadBlob 检查 blob 是否存在
func (h *BlobHandler) HeadBlob(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	digest := c.Param("digest")

	if name == "" || digest == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or digest is required")
		return
	}

	// 检查数据库中是否存在
	var blob models.Blob
	if err := h.DB.Where("digest = ?", digest).First(&blob).Error; err != nil {
		c.Status(http.StatusNotFound)
		return
	}

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Length", fmt.Sprintf("%d", blob.Size))
	c.Header("Content-Type", blob.ContentType)
	c.Status(http.StatusOK)
}

// GetBlob 下载 blob
func (h *BlobHandler) GetBlob(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	digest := c.Param("digest")

	if name == "" || digest == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or digest is required")
		return
	}

	// 从数据库获取 blob 信息
	var blob models.Blob
	if err := h.DB.Where("digest = ?", digest).First(&blob).Error; err != nil {
		RespondError(c, http.StatusNotFound, "BLOB_NOT_FOUND", "blob not found")
		return
	}

	// 从存储读取数据
	data, err := h.Storage.DownloadBlob(digest)
	if err != nil {
		RespondError(c, http.StatusInternalServerError, "STORAGE_ERROR", "failed to read blob")
		return
	}

	// 更新访问时间
	h.DB.Model(&blob).Update("last_accessed", time.Now())

	c.Header("Docker-Content-Digest", digest)
	c.Header("Content-Type", blob.ContentType)
	c.Header("Content-Length", fmt.Sprintf("%d", len(data)))
	c.Data(http.StatusOK, blob.ContentType, data)
}

// InitiateBlobUpload 初始化 blob 上传
func (h *BlobHandler) InitiateBlobUpload(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	if name == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name is required")
		return
	}

	// 生成上传会话ID
	uploadID := uuid.New().String()

	// 返回上传URL
	uploadURL := fmt.Sprintf("/v2/%s/blobs/uploads/%s", name, uploadID)

	c.Header("Location", uploadURL)
	c.Header("Docker-Upload-UUID", uploadID)
	c.Header("Range", "0-0")
	c.Status(http.StatusAccepted)
}

// UploadBlobChunk 上传 blob 分片
func (h *BlobHandler) UploadBlobChunk(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	uploadID := c.Param("uuid")

	if name == "" || uploadID == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or uuid is required")
		return
	}

	// 读取请求体数据
	data, err := c.GetRawData()
	if err != nil {
		RespondError(c, http.StatusBadRequest, "INVALID_DATA", "failed to read request data")
		return
	}

	// 返回响应（实际实现需要存储分片数据）
	rangeEnd := len(data)
	c.Header("Location", fmt.Sprintf("/v2/%s/blobs/uploads/%s", name, uploadID))
	c.Header("Range", fmt.Sprintf("0-%d", rangeEnd))
	c.Status(http.StatusAccepted)
}

// CompleteBlobUpload 完成 blob 上传
func (h *BlobHandler) CompleteBlobUpload(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	uploadID := c.Param("uuid")
	digest := c.Query("digest")

	if name == "" || uploadID == "" || digest == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name, uuid or digest is required")
		return
	}

	// 读取请求体数据（最终数据）
	data, err := c.GetRawData()
	if err != nil {
		RespondError(c, http.StatusBadRequest, "INVALID_DATA", "failed to read request data")
		return
	}

	// 验证 digest（简化版本）
	if !strings.HasPrefix(digest, "sha256:") {
		RespondError(c, http.StatusBadRequest, "INVALID_DIGEST", "unsupported digest algorithm")
		return
	}

	// 存储 blob 数据
	if err := h.Storage.UploadBlob(digest, data); err != nil {
		RespondError(c, http.StatusInternalServerError, "STORAGE_ERROR", "failed to store blob")
		return
	}

	// 创建 blob 记录
	blob := models.Blob{
		Digest:      digest,
		Size:        int64(len(data)),
		ContentType: "application/octet-stream",
		StoragePath: digest,
	}
	if err := h.DB.Create(&blob).Error; err != nil {
		RespondError(c, http.StatusInternalServerError, "DATABASE_ERROR", "failed to create blob record")
		return
	}

	// 返回成功响应
	c.Header("Docker-Content-Digest", digest)
	c.Header("Location", fmt.Sprintf("/v2/%s/blobs/%s", name, digest))
	c.Status(http.StatusCreated)
}

// DeleteBlob 删除 blob
func (h *BlobHandler) DeleteBlob(c *gin.Context) {
	CheckDockerAPIVersion(c)

	name := GetNameFromPath(c)
	digest := c.Param("digest")

	if name == "" || digest == "" {
		RespondError(c, http.StatusBadRequest, "INVALID_PARAMETER", "name or digest is required")
		return
	}

	// 查找 blob
	var blob models.Blob
	if err := h.DB.Where("digest = ?", digest).First(&blob).Error; err != nil {
		RespondError(c, http.StatusNotFound, "BLOB_NOT_FOUND", "blob not found")
		return
	}

	// 从存储删除
	if err := h.Storage.DeleteBlob(digest); err != nil {
		RespondError(c, http.StatusInternalServerError, "STORAGE_ERROR", "failed to delete blob")
		return
	}

	// 从数据库删除
	if err := h.DB.Delete(&blob).Error; err != nil {
		RespondError(c, http.StatusInternalServerError, "DATABASE_ERROR", "failed to delete blob record")
		return
	}

	c.Status(http.StatusAccepted)
}
