package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Blob 表示一个镜像层（blob）
type Blob struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Digest       string         `gorm:"size:71;not null;uniqueIndex" json:"digest"` // sha256:xxxxx
	Size         int64          `gorm:"not null" json:"size"`
	StoragePath  string         `gorm:"size:512" json:"storage_path"`
	ContentType  string         `gorm:"size:255" json:"content_type"`
	LastAccessed *time.Time     `json:"last_accessed,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Manifests []Manifest `gorm:"many2many:manifest_blobs;" json:"manifests,omitempty"`
}

// TableName 指定表名
func (Blob) TableName() string {
	return "blobs"
}
