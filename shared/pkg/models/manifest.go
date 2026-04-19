package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Manifest 表示一个镜像的 manifest
type Manifest struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	RepositoryID uuid.UUID      `gorm:"type:uuid;not null;index" json:"repository_id"`
	Digest       string         `gorm:"size:71;not null;uniqueIndex" json:"digest"` // sha256:xxxxx
	MediaType    string         `gorm:"size:255" json:"media_type"`
	ConfigDigest string         `gorm:"size:71" json:"config_digest"`
	ConfigSize   int64          `json:"config_size"`
	LayersCount  int            `json:"layers_count"`
	TotalSize    int64          `json:"total_size"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Repository Repository `json:"repository,omitempty"`
	Blobs      []Blob     `gorm:"many2many:manifest_blobs;" json:"blobs,omitempty"`
}

// TableName 指定表名
func (Manifest) TableName() string {
	return "manifests"
}
