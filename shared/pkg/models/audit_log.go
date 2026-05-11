package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AuditAction 审计操作类型
type AuditAction string

const (
	ActionLogin        AuditAction = "login"         // 登录
	ActionLogout       AuditAction = "logout"        // 登出
	ActionCreate       AuditAction = "create"        // 创建
	ActionUpdate       AuditAction = "update"        // 更新
	ActionDelete       AuditAction = "delete"        // 删除
	ActionDownload     AuditAction = "download"      // 下载
	ActionUpload       AuditAction = "upload"        // 上传
	ActionPull         AuditAction = "pull"          // 拉取镜像
	ActionPush         AuditAction = "push"          // 推送镜像
	ActionReplicate    AuditAction = "replicate"     // 复制镜像
	ActionView         AuditAction = "view"          // 查看
	ActionChangeStatus AuditAction = "change_status" // 修改状态
)

// AuditResourceType 资源类型
type AuditResourceType string

const (
	ResourceNamespace   AuditResourceType = "namespace"    // 命名空间
	ResourceRepository  AuditResourceType = "repository"   // 仓库
	ResourceTag         AuditResourceType = "tag"          // 标签
	ResourceUser        AuditResourceType = "user"         // 用户
	ResourceSystem      AuditResourceType = "system"       // 系统
	ResourceReplication AuditResourceType = "replication"  // 复制任务
	ResourceImage       AuditResourceType = "image"        // 镜像
)

// AuditLog 审计日志模型
type AuditLog struct {
	ID           uuid.UUID         `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID       *uuid.UUID        `gorm:"type:uuid;index" json:"user_id"`
	Username     string            `gorm:"size:255;index" json:"username"`
	Action       AuditAction       `gorm:"size:50;index" json:"action"`
	ResourceType AuditResourceType `gorm:"size:50;index" json:"resource_type"`
	ResourceID   string            `gorm:"size:255;index" json:"resource_id"`
	ResourceName string            `gorm:"size:255" json:"resource_name"`
	Detail       string            `gorm:"type:text" json:"detail"`
	IPAddress    string            `gorm:"size:100" json:"ip_address"`
	UserAgent    string            `gorm:"size:500" json:"user_agent"`
	Success      bool              `gorm:"default:true" json:"success"`
	ErrorMessage string            `gorm:"type:text" json:"error_message"`
	CreatedAt    time.Time         `json:"created_at"`
}

// TableName 指定表名
func (AuditLog) TableName() string {
	return "audit_logs"
}

// BeforeCreate 创建前钩子
func (a *AuditLog) BeforeCreate(tx *gorm.DB) error {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return nil
}

// AuditLogFilter 审计日志筛选条件
type AuditLogFilter struct {
	UserID       string
	Username     string
	Action       string
	ResourceType string
	ResourceName string
	StartTime    *time.Time
	EndTime      *time.Time
	Success      *bool
	Page         int
	PageSize     int
}

// AuditLogResponse 审计日志响应
type AuditLogResponse struct {
	ID           uuid.UUID         `json:"id"`
	UserID       *uuid.UUID        `json:"user_id"`
	Username     string            `json:"username"`
	Action       AuditAction       `json:"action"`
	ResourceType AuditResourceType `json:"resource_type"`
	ResourceID   string            `json:"resource_id"`
	ResourceName string            `json:"resource_name"`
	Detail       string            `json:"detail"`
	IPAddress    string            `json:"ip_address"`
	Success      bool              `json:"success"`
	ErrorMessage string            `json:"error_message"`
	CreatedAt    time.Time         `json:"created_at"`
}
