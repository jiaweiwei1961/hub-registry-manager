package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User 表示一个系统用户
type User struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Username     string         `gorm:"size:255;not null;uniqueIndex" json:"username"`
	PasswordHash string         `gorm:"size:255;not null" json:"-"`
	Email        string         `gorm:"size:255" json:"email"`
	DisplayName  string         `gorm:"size:255" json:"display_name"`
	IsAdmin      bool           `gorm:"default:false" json:"is_admin"`
	LastLoginAt  *time.Time     `json:"last_login_at,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}
