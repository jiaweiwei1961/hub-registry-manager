package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// ReplicationHandler 复制策略处理器
type ReplicationHandler struct {
	DB          *gorm.DB
	AuditLogger *AuditLogHandler
}

// NewReplicationHandler 创建 ReplicationHandler
func NewReplicationHandler(db *gorm.DB) *ReplicationHandler {
	return &ReplicationHandler{
		DB:          db,
		AuditLogger: NewAuditLogHandler(db),
	}
}

// PolicyResponse 复制策略响应
type PolicyResponse struct {
	ID              string `json:"id"`
	Name            string `json:"name"`
	Description     string `json:"description"`
	SourceRegistry  string `json:"source_registry"`
	SourceNamespace string `json:"source_namespace"`
	SourceRepository string `json:"source_repository"`
	SourceTagPattern string `json:"source_tag_pattern"`
	DestNamespace   string `json:"dest_namespace"`
	DestRepository  string `json:"dest_repository"`
	TriggerType     string `json:"trigger_type"`
	Enabled         bool   `json:"enabled"`
	LastTriggerTime string `json:"last_trigger_time"`
	CreatedAt       string `json:"created_at"`
	UpdatedAt       string `json:"updated_at"`
}

// ListPolicies 列出复制策略
func (h *ReplicationHandler) ListPolicies(c *gin.Context) {
	var policies []models.ReplicationPolicy
	h.DB.Find(&policies)

	response := make([]PolicyResponse, len(policies))
	for i, p := range policies {
		lastTrigger := "-"
		if p.LastTriggerTime != nil {
			lastTrigger = formatBeijingTime(*p.LastTriggerTime)
		}
		response[i] = PolicyResponse{
			ID:              p.ID.String(),
			Name:            p.Name,
			Description:     p.Description,
			SourceRegistry:  p.SourceRegistry,
			SourceNamespace: p.SourceNamespace,
			SourceRepository: p.SourceRepository,
			SourceTagPattern: p.SourceTagPattern,
			DestNamespace:    p.DestNamespace,
			DestRepository:   p.DestRepository,
			TriggerType:      p.TriggerType,
			Enabled:          p.Enabled,
			LastTriggerTime:  lastTrigger,
			CreatedAt:        formatBeijingTime(p.CreatedAt),
			UpdatedAt:        formatBeijingTime(p.UpdatedAt),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"data": response,
	})
}

// CreatePolicyRequest 创建策略请求
type CreatePolicyRequest struct {
	Name            string `json:"name" binding:"required"`
	Description     string `json:"description"`
	SourceRegistry  string `json:"source_registry" binding:"required"`
	SourceNamespace string `json:"source_namespace"`
	SourceRepository string `json:"source_repository"`
	SourceTagPattern string `json:"source_tag_pattern"`
	DestNamespace   string `json:"dest_namespace" binding:"required"`
	DestRepository  string `json:"dest_repository"`
	TriggerType     string `json:"trigger_type"`
	Enabled         bool   `json:"enabled"`
}

// CreatePolicy 创建复制策略
func (h *ReplicationHandler) CreatePolicy(c *gin.Context) {
	var req CreatePolicyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	triggerType := req.TriggerType
	if triggerType == "" {
		triggerType = "manual"
	}

	policy := models.ReplicationPolicy{
		Name:            req.Name,
		Description:     req.Description,
		SourceRegistry:  req.SourceRegistry,
		SourceNamespace: req.SourceNamespace,
		SourceRepository: req.SourceRepository,
		SourceTagPattern: req.SourceTagPattern,
		DestNamespace:    req.DestNamespace,
		DestRepository:   req.DestRepository,
		TriggerType:      triggerType,
		Enabled:          req.Enabled,
	}

	if err := h.DB.Create(&policy).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "创建策略失败",
		})
		return
	}

	// 记录审计日志 - 创建复制策略
	h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceReplication, policy.ID.String(), policy.Name,
		"创建复制策略", true, "")

	c.JSON(http.StatusCreated, PolicyResponse{
		ID:              policy.ID.String(),
		Name:            policy.Name,
		Description:     policy.Description,
		SourceRegistry:  policy.SourceRegistry,
		SourceNamespace: policy.SourceNamespace,
		SourceRepository: policy.SourceRepository,
		SourceTagPattern: policy.SourceTagPattern,
		DestNamespace:    policy.DestNamespace,
		DestRepository:   policy.DestRepository,
		TriggerType:      policy.TriggerType,
		Enabled:          policy.Enabled,
		CreatedAt:        formatBeijingTime(policy.CreatedAt),
		UpdatedAt:        formatBeijingTime(policy.UpdatedAt),
	})
}

// GetPolicy 获取策略详情
func (h *ReplicationHandler) GetPolicy(c *gin.Context) {
	id := c.Param("id")

	policyUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "策略ID无效",
		})
		return
	}

	var policy models.ReplicationPolicy
	if err := h.DB.First(&policy, "id = ?", policyUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "策略不存在",
		})
		return
	}

	lastTrigger := "-"
	if policy.LastTriggerTime != nil {
		lastTrigger = formatBeijingTime(*policy.LastTriggerTime)
	}

	c.JSON(http.StatusOK, PolicyResponse{
		ID:              policy.ID.String(),
		Name:            policy.Name,
		Description:     policy.Description,
		SourceRegistry:  policy.SourceRegistry,
		SourceNamespace: policy.SourceNamespace,
		SourceRepository: policy.SourceRepository,
		SourceTagPattern: policy.SourceTagPattern,
		DestNamespace:    policy.DestNamespace,
		DestRepository:   policy.DestRepository,
		TriggerType:      policy.TriggerType,
		Enabled:          policy.Enabled,
		LastTriggerTime:  lastTrigger,
		CreatedAt:        formatBeijingTime(policy.CreatedAt),
		UpdatedAt:        formatBeijingTime(policy.UpdatedAt),
	})
}

// UpdatePolicyRequest 更新策略请求
type UpdatePolicyRequest struct {
	Name            string `json:"name"`
	Description     string `json:"description"`
	SourceRegistry  string `json:"source_registry"`
	SourceNamespace string `json:"source_namespace"`
	SourceRepository string `json:"source_repository"`
	SourceTagPattern string `json:"source_tag_pattern"`
	DestNamespace   string `json:"dest_namespace"`
	DestRepository  string `json:"dest_repository"`
	TriggerType     string `json:"trigger_type"`
	Enabled         bool   `json:"enabled"`
}

// UpdatePolicy 更新复制策略
func (h *ReplicationHandler) UpdatePolicy(c *gin.Context) {
	id := c.Param("id")

	policyUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "策略ID无效",
		})
		return
	}

	var req UpdatePolicyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	var policy models.ReplicationPolicy
	if err := h.DB.First(&policy, "id = ?", policyUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "策略不存在",
		})
		return
	}

	// 更新字段
	if req.Name != "" {
		policy.Name = req.Name
	}
	if req.Description != "" {
		policy.Description = req.Description
	}
	if req.SourceRegistry != "" {
		policy.SourceRegistry = req.SourceRegistry
	}
	policy.SourceNamespace = req.SourceNamespace
	policy.SourceRepository = req.SourceRepository
	policy.SourceTagPattern = req.SourceTagPattern
	if req.DestNamespace != "" {
		policy.DestNamespace = req.DestNamespace
	}
	policy.DestRepository = req.DestRepository
	if req.TriggerType != "" {
		policy.TriggerType = req.TriggerType
	}
	policy.Enabled = req.Enabled

	if err := h.DB.Save(&policy).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "更新策略失败",
		})
		return
	}

	// 记录审计日志 - 更新复制策略
	h.AuditLogger.CreateAuditLog(c, models.ActionUpdate, models.ResourceReplication, policy.ID.String(), policy.Name,
		"更新复制策略", true, "")

	lastTrigger := "-"
	if policy.LastTriggerTime != nil {
		lastTrigger = formatBeijingTime(*policy.LastTriggerTime)
	}

	c.JSON(http.StatusOK, PolicyResponse{
		ID:              policy.ID.String(),
		Name:            policy.Name,
		Description:     policy.Description,
		SourceRegistry:  policy.SourceRegistry,
		SourceNamespace: policy.SourceNamespace,
		SourceRepository: policy.SourceRepository,
		SourceTagPattern: policy.SourceTagPattern,
		DestNamespace:    policy.DestNamespace,
		DestRepository:   policy.DestRepository,
		TriggerType:      policy.TriggerType,
		Enabled:          policy.Enabled,
		LastTriggerTime:  lastTrigger,
		CreatedAt:        formatBeijingTime(policy.CreatedAt),
		UpdatedAt:        formatBeijingTime(policy.UpdatedAt),
	})
}

// DeletePolicy 删除复制策略
func (h *ReplicationHandler) DeletePolicy(c *gin.Context) {
	id := c.Param("id")

	policyUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "策略ID无效",
		})
		return
	}

	var policy models.ReplicationPolicy
	if err := h.DB.First(&policy, "id = ?", policyUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "策略不存在",
		})
		return
	}

	// 删除关联的任务详情
	h.DB.Where("task_id IN (SELECT id FROM replication_tasks WHERE policy_id = ?)", policy.ID).Delete(&models.ReplicationTaskDetail{})

	// 删除关联的任务
	h.DB.Where("policy_id = ?", policy.ID).Delete(&models.ReplicationTask{})

	// 删除策略
	if err := h.DB.Delete(&policy).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "删除策略失败",
		})
		return
	}

	// 记录审计日志 - 删除复制策略
	h.AuditLogger.CreateAuditLog(c, models.ActionDelete, models.ResourceReplication, policy.ID.String(), policy.Name,
		"删除复制策略", true, "")

	c.JSON(http.StatusOK, gin.H{
		"message": "策略删除成功",
	})
}

// ExecutePolicy 执行复制策略
func (h *ReplicationHandler) ExecutePolicy(c *gin.Context) {
	id := c.Param("id")

	policyUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "策略ID无效",
		})
		return
	}

	var policy models.ReplicationPolicy
	if err := h.DB.First(&policy, "id = ?", policyUUID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "策略不存在",
		})
		return
	}

	// 创建执行任务
	now := time.Now()
	task := models.ReplicationTask{
		PolicyID:       &policy.ID,
		Status:         "pending",
		SourceRegistry: policy.SourceRegistry,
		DestRegistry:   "local",
		StartedAt:      &now,
	}

	if err := h.DB.Create(&task).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "创建任务失败",
		})
		return
	}

	// 更新策略的最后执行时间
	policy.LastTriggerTime = &now
	h.DB.Save(&policy)

	// 记录审计日志 - 执行复制策略
	h.AuditLogger.CreateAuditLog(c, models.ActionReplicate, models.ResourceReplication, policy.ID.String(), policy.Name,
		"执行镜像复制策略", true, "")

	c.JSON(http.StatusOK, gin.H{
		"message":  "Replication task created",
		"task_id":  task.ID.String(),
		"status":   task.Status,
	})
}

// TaskResponse 复制任务响应
type TaskResponse struct {
	ID            string `json:"id"`
	PolicyID      string `json:"policy_id"`
	PolicyName    string `json:"policy_name"`
	Status        string `json:"status"`
	StartedAt     string `json:"started_at"`
	EndedAt       string `json:"ended_at"`
	TotalResources int   `json:"total_resources"`
	SucceededCount int   `json:"succeeded_count"`
	FailedCount    int   `json:"failed_count"`
}

// ListTasks 列出复制任务
func (h *ReplicationHandler) ListTasks(c *gin.Context) {
	var tasks []models.ReplicationTask
	h.DB.Preload("Policy").Order("created_at DESC").Limit(50).Find(&tasks)

	response := make([]TaskResponse, len(tasks))
	for i, t := range tasks {
		policyName := ""
		policyID := ""
		if t.PolicyID != nil {
			policyID = t.PolicyID.String()
			if t.Policy.Name != "" {
				policyName = t.Policy.Name
			}
		}

		startedAt := "-"
		if t.StartedAt != nil {
			startedAt = formatBeijingTime(*t.StartedAt)
		}

		endedAt := "-"
		if t.EndedAt != nil {
			endedAt = formatBeijingTime(*t.EndedAt)
		}

		response[i] = TaskResponse{
			ID:            t.ID.String(),
			PolicyID:      policyID,
			PolicyName:    policyName,
			Status:        t.Status,
			StartedAt:     startedAt,
			EndedAt:       endedAt,
			TotalResources: t.TotalResources,
			SucceededCount: t.SucceededCount,
			FailedCount:    t.FailedCount,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"data": response,
	})
}

// GetTask 获取单个复制任务状态
func (h *ReplicationHandler) GetTask(c *gin.Context) {
	taskID := c.Param("id")
	if taskID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "缺少任务ID"})
		return
	}

	id, err := uuid.Parse(taskID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "无效的任务ID"})
		return
	}

	var task models.ReplicationTask
	if err := h.DB.Where("id = ?", id).First(&task).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "任务不存在"})
		return
	}

	policyName := ""
	policyID := ""
	if task.PolicyID != nil {
		policyID = task.PolicyID.String()
		// 加载策略名称
		var policy models.ReplicationPolicy
		if err := h.DB.Where("id = ?", task.PolicyID).First(&policy).Error; err == nil {
			policyName = policy.Name
		}
	}

	startedAt := "-"
	if task.StartedAt != nil {
		startedAt = formatBeijingTime(*task.StartedAt)
	}

	endedAt := "-"
	if task.EndedAt != nil {
		endedAt = formatBeijingTime(*task.EndedAt)
	}

	errorMessage := ""
	if task.ErrorMessage != "" {
		errorMessage = task.ErrorMessage
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"id":              task.ID.String(),
			"policy_id":        policyID,
			"policy_name":      policyName,
			"status":           task.Status,
				"progress":         task.Progress,
			"started_at":       startedAt,
			"ended_at":         endedAt,
			"total_resources":  task.TotalResources,
			"succeeded_count":  task.SucceededCount,
			"failed_count":     task.FailedCount,
			"error_message":    errorMessage,
		},
	})
}