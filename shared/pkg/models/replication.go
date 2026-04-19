package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ReplicationPolicy 表示一个复制策略
type ReplicationPolicy struct {
	ID                 uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name               string         `gorm:"size:255;not null" json:"name"`
	Description        string         `gorm:"type:text" json:"description"`
	SourceRegistry     string         `gorm:"size:255;not null" json:"source_registry"`
	SourceNamespace    string         `gorm:"size:255" json:"source_namespace"`
	SourceRepository   string         `gorm:"size:255" json:"source_repository"`
	SourceTagPattern   string         `gorm:"size:255" json:"source_tag_pattern"`
	DestRegistry       string         `gorm:"size:255;not null" json:"dest_registry"`
	DestNamespace      string         `gorm:"size:255" json:"dest_namespace"`
	DestRepository     string         `gorm:"size:255" json:"dest_repository"`
	TriggerType        string         `gorm:"size:20;not null" json:"trigger_type"` // manual, scheduled, event
	TriggerCron        string         `gorm:"size:50" json:"trigger_cron"`
	TriggerEvent       string         `gorm:"size:50" json:"trigger_event"`
	DeleteRemote       bool           `gorm:"default:false" json:"delete_remote"`
	Override           bool           `gorm:"default:true" json:"override"`
	Enabled            bool           `gorm:"default:true" json:"enabled"`
	LastTriggerTime    *time.Time     `json:"last_trigger_time,omitempty"`
	LastSuccessTime    *time.Time     `json:"last_success_time,omitempty"`
	LastFailureTime    *time.Time     `json:"last_failure_time,omitempty"`
	SuccessCount       int            `gorm:"default:0" json:"success_count"`
	FailureCount       int            `gorm:"default:0" json:"failure_count"`
	CreatedAt          time.Time      `json:"created_at"`
	UpdatedAt          time.Time      `json:"updated_at"`
	DeletedAt          gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (ReplicationPolicy) TableName() string {
	return "replication_policies"
}

// ReplicationTask 表示一个复制任务
type ReplicationTask struct {
	ID               uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	PolicyID         uuid.UUID      `gorm:"type:uuid;not null;index" json:"policy_id"`
	Status           string         `gorm:"size:20;not null" json:"status"` // pending, running, success, failed, stopped
	SourceRegistry   string         `gorm:"size:255" json:"source_registry"`
	DestRegistry     string         `gorm:"size:255" json:"dest_registry"`
	StartedAt        *time.Time     `json:"started_at,omitempty"`
	EndedAt          *time.Time     `json:"ended_at,omitempty"`
	TotalResources   int            `gorm:"default:0" json:"total_resources"`
	SucceededCount   int            `gorm:"default:0" json:"succeeded_count"`
	FailedCount      int            `gorm:"default:0" json:"failed_count"`
	SkippedCount     int            `gorm:"default:0" json:"skipped_count"`
	ErrorMessage     string         `gorm:"type:text" json:"error_message,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
	UpdatedAt        time.Time      `json:"updated_at"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Policy  ReplicationPolicy   `json:"policy,omitempty"`
	Details []ReplicationTaskDetail `json:"details,omitempty"`
}

// TableName 指定表名
func (ReplicationTask) TableName() string {
	return "replication_tasks"
}

// ReplicationTaskDetail 表示复制任务的详细记录
type ReplicationTaskDetail struct {
	ID               uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	TaskID           uuid.UUID      `gorm:"type:uuid;not null;index" json:"task_id"`
	ResourceType     string         `gorm:"size:20;not null" json:"resource_type"` // image, chart, blob
	SourceNamespace  string         `gorm:"size:255" json:"source_namespace"`
	SourceRepository string         `gorm:"size:255" json:"source_repository"`
	SourceTag        string         `gorm:"size:255" json:"source_tag"`
	SourceDigest     string         `gorm:"size:71" json:"source_digest"`
	Status           string         `gorm:"size:20" json:"status"` // success, failed, skipped
	DestNamespace    string         `gorm:"size:255" json:"dest_namespace"`
	DestRepository   string         `gorm:"size:255" json:"dest_repository"`
	DestTag          string         `gorm:"size:255" json:"dest_tag"`
	StartedAt        *time.Time     `json:"started_at,omitempty"`
	EndedAt          *time.Time     `json:"ended_at,omitempty"`
	BytesTransferred int64          `json:"bytes_transferred"`
	ErrorMessage     string         `gorm:"type:text" json:"error_message,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
	UpdatedAt        time.Time      `json:"updated_at"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (ReplicationTaskDetail) TableName() string {
	return "replication_task_details"
}

// RegistryEndpoint 表示一个远端 Registry 配置
type RegistryEndpoint struct {
	ID                   uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name                 string         `gorm:"size:255;not null;uniqueIndex" json:"name"`
	URL                  string         `gorm:"size:512;not null" json:"url"`
	Type                 string         `gorm:"size:20" json:"type"` // harbor, docker-hub, ecr, acr, generic
	AuthType             string         `gorm:"size:20" json:"auth_type"` // basic, token, oauth
	Username             string         `gorm:"size:255" json:"-"`
	Password             string         `gorm:"size:255" json:"-"`
	AccessToken          string         `gorm:"type:text" json:"-"`
	RefreshToken         string         `gorm:"type:text" json:"-"`
	InsecureSkipVerify   bool           `gorm:"default:false" json:"insecure_skip_verify"`
	TimeoutSeconds       int            `gorm:"default:30" json:"timeout_seconds"`
	IsEnabled            bool           `gorm:"default:true" json:"is_enabled"`
	LastTestTime         *time.Time     `json:"last_test_time,omitempty"`
	LastTestResult       *bool          `json:"last_test_result,omitempty"`
	LastErrorMessage     string         `gorm:"type:text" json:"last_error_message,omitempty"`
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
	DeletedAt            gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (RegistryEndpoint) TableName() string {
	return "registry_endpoints"
}

// AuditLog 表示审计日志
type AuditLog struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Timestamp    time.Time      `gorm:"index" json:"timestamp"`
	Action       string         `gorm:"size:50" json:"action"`
	ResourceType string         `gorm:"size:50" json:"resource_type"`
	ResourceID   string         `gorm:"size:255" json:"resource_id"`
	UserName     string         `gorm:"size:255" json:"user_name"`
	IPAddress    string         `gorm:"size:45" json:"ip_address"`
	Status       string         `gorm:"size:20" json:"status"`
	Details      string         `gorm:"type:text" json:"details,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (AuditLog) TableName() string {
	return "audit_logs"
}

// ManifestBlob 表示 Manifest 和 Blob 的关联表
type ManifestBlob struct {
	ManifestID  uuid.UUID `gorm:"type:uuid;primary_key" json:"manifest_id"`
	BlobID      uuid.UUID `gorm:"type:uuid;primary_key" json:"blob_id"`
	LayerOrder  int       `json:"layer_order"`
	CreatedAt   time.Time `json:"created_at"`
}

// TableName 指定表名
func (ManifestBlob) TableName() string {
	return "manifest_blobs"
}
