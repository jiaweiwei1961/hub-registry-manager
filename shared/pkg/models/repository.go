package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository 表示一个镜像仓库
type Repository struct {
	ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	NamespaceID uuid.UUID      `gorm:"type:uuid;not null;index:idx_ns_repo,unique" json:"namespace_id"`
	Name        string         `gorm:"size:255;not null;index:idx_ns_repo,unique" json:"name"`
	Description string         `gorm:"type:text" json:"description"`
	IsPublic    bool           `gorm:"default:false" json:"is_public"`
	PullCount   int64          `gorm:"default:0" json:"pull_count"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Namespace Namespace `json:"namespace,omitempty"`
	Tags      []Tag     `json:"tags,omitempty"`
}

// TableName 指定表名
func (Repository) TableName() string {
	return "repositories"
}

// FullName 返回完整仓库名（namespace/name）
func (r *Repository) FullName() string {
	if r.NamespaceID == uuid.Nil || r.Namespace.Name == "" {
		return r.Name
	}
	return r.Namespace.Name + "/" + r.Name
}
