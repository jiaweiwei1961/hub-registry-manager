package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Tag 表示一个镜像标签
type Tag struct {
	ID         uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	RepositoryID uuid.UUID    `gorm:"type:uuid;not null;index:idx_repo_tag,unique" json:"repository_id"`
	Name       string         `gorm:"size:255;not null;index:idx_repo_tag,unique" json:"name"`
	ManifestID uuid.UUID      `gorm:"type:uuid;not null;index" json:"manifest_id"`
	PushedBy   string         `gorm:"size:255" json:"pushed_by"`
	PushedAt   time.Time      `json:"pushed_at"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Repository Repository `json:"repository,omitempty"`
	Manifest   Manifest `json:"manifest,omitempty"`
}

// TableName 指定表名
func (Tag) TableName() string {
	return "tags"
}
