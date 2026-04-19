package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Namespace 表示一个命名空间（组织或团队）
type Namespace struct {
	ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string         `gorm:"size:255;not null;uniqueIndex" json:"name"`
	DisplayName string         `gorm:"size:255" json:"display_name"`
	Description string         `gorm:"type:text" json:"description"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	Repositories []Repository `json:"repositories,omitempty"`
}

// TableName 指定表名
func (Namespace) TableName() string {
	return "namespaces"
}
