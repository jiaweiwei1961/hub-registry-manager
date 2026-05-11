package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// AuditLogHandler 审计日志处理器
type AuditLogHandler struct {
	DB *gorm.DB
}

// NewAuditLogHandler 创建 AuditLogHandler
func NewAuditLogHandler(db *gorm.DB) *AuditLogHandler {
	return &AuditLogHandler{DB: db}
}

// ListAuditLogsRequest 列出审计日志请求
type ListAuditLogsRequest struct {
	Page         int    `form:"page"`
	PageSize     int    `form:"page_size"`
	UserID       string `form:"user_id"`
	Username     string `form:"username"`
	Action       string `form:"action"`
	ResourceType string `form:"resource_type"`
	ResourceName string `form:"resource_name"`
	StartTime    string `form:"start_time"`
	EndTime      string `form:"end_time"`
	Success      string `form:"success"`
}

// ListAuditLogs 列出审计日志
func (h *AuditLogHandler) ListAuditLogs(c *gin.Context) {
	var req ListAuditLogsRequest
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
	if req.PageSize > 100 {
		req.PageSize = 100
	}

	// 构建查询
	query := h.DB.Model(&models.AuditLog{}).Order("created_at DESC")

	// 应用筛选条件
	if req.UserID != "" {
		query = query.Where("user_id = ?", req.UserID)
	}
	if req.Username != "" {
		query = query.Where("username ILIKE ?", "%"+req.Username+"%")
	}
	if req.Action != "" {
		query = query.Where("action = ?", req.Action)
	}
	if req.ResourceType != "" {
		query = query.Where("resource_type = ?", req.ResourceType)
	}
	if req.ResourceName != "" {
		query = query.Where("resource_name ILIKE ?", "%"+req.ResourceName+"%")
	}
	if req.Success != "" {
		if req.Success == "true" {
			query = query.Where("success = ?", true)
		} else if req.Success == "false" {
			query = query.Where("success = ?", false)
		}
	}

	// 时间范围筛选
	if req.StartTime != "" {
		if startTime, err := time.Parse(time.RFC3339, req.StartTime); err == nil {
			query = query.Where("created_at >= ?", startTime)
		}
	}
	if req.EndTime != "" {
		if endTime, err := time.Parse(time.RFC3339, req.EndTime); err == nil {
			query = query.Where("created_at <= ?", endTime)
		}
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取分页数据
	var logs []models.AuditLog
	offset := (req.Page - 1) * req.PageSize
	query.Offset(offset).Limit(req.PageSize).Find(&logs)

	// 构建响应
	response := make([]models.AuditLogResponse, len(logs))
	for i, log := range logs {
		response[i] = models.AuditLogResponse{
			ID:           log.ID,
			UserID:       log.UserID,
			Username:     log.Username,
			Action:       log.Action,
			ResourceType: log.ResourceType,
			ResourceID:   log.ResourceID,
			ResourceName: log.ResourceName,
			Detail:       log.Detail,
			IPAddress:    log.IPAddress,
			Success:      log.Success,
			ErrorMessage: log.ErrorMessage,
			CreatedAt:    log.CreatedAt,
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

// GetAuditLog 获取审计日志详情
func (h *AuditLogHandler) GetAuditLog(c *gin.Context) {
	id := c.Param("id")

	var log models.AuditLog
	if err := h.DB.First(&log, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "审计日志不存在",
		})
		return
	}

	c.JSON(http.StatusOK, models.AuditLogResponse{
		ID:           log.ID,
		UserID:       log.UserID,
		Username:     log.Username,
		Action:       log.Action,
		ResourceType: log.ResourceType,
		ResourceID:   log.ResourceID,
		ResourceName: log.ResourceName,
		Detail:       log.Detail,
		IPAddress:    log.IPAddress,
		Success:      log.Success,
		ErrorMessage: log.ErrorMessage,
		CreatedAt:    log.CreatedAt,
	})
}

// GetAuditActions 获取所有操作类型列表
func (h *AuditLogHandler) GetAuditActions(c *gin.Context) {
	actions := []gin.H{
		{"value": "login", "label": "登录"},
		{"value": "logout", "label": "登出"},
		{"value": "create", "label": "创建"},
		{"value": "update", "label": "更新"},
		{"value": "delete", "label": "删除"},
		{"value": "download", "label": "下载"},
		{"value": "upload", "label": "上传"},
		{"value": "pull", "label": "拉取镜像"},
		{"value": "push", "label": "推送镜像"},
		{"value": "replicate", "label": "复制镜像"},
		{"value": "view", "label": "查看"},
		{"value": "change_status", "label": "修改状态"},
	}

	c.JSON(http.StatusOK, gin.H{
		"data": actions,
	})
}

// GetAuditResourceTypes 获取所有资源类型列表
func (h *AuditLogHandler) GetAuditResourceTypes(c *gin.Context) {
	resourceTypes := []gin.H{
		{"value": "namespace", "label": "命名空间"},
		{"value": "repository", "label": "仓库"},
		{"value": "tag", "label": "标签"},
		{"value": "user", "label": "用户"},
		{"value": "system", "label": "系统"},
		{"value": "replication", "label": "复制任务"},
		{"value": "image", "label": "镜像"},
	}

	c.JSON(http.StatusOK, gin.H{
		"data": resourceTypes,
	})
}

// CreateAuditLog 创建审计日志（内部使用）
func (h *AuditLogHandler) CreateAuditLog(c *gin.Context, action models.AuditAction, resourceType models.AuditResourceType,
	resourceID string, resourceName string, detail string, success bool, errorMessage string) {

	// 从上下文中获取用户信息
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")

	var userIDPtr *uuid.UUID
	if userID != nil {
		if uid, err := uuid.Parse(userID.(string)); err == nil {
			userIDPtr = &uid
		}
	}

	log := models.AuditLog{
		UserID:       userIDPtr,
		Username:     "",
		Action:       action,
		ResourceType: resourceType,
		ResourceID:   resourceID,
		ResourceName: resourceName,
		Detail:       detail,
		IPAddress:    c.ClientIP(),
		UserAgent:    c.Request.UserAgent(),
		Success:      success,
		ErrorMessage: errorMessage,
	}

	if username != nil {
		log.Username = username.(string)
	}

	// 异步保存日志，不影响主流程
	h.DB.Create(&log)
}
