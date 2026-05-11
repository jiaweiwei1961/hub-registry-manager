package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// UserHandler 用户管理处理器
type UserHandler struct {
	DB          *gorm.DB
	AuditLogger *AuditLogHandler
}

// NewUserHandler 创建 UserHandler
func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{
		DB:          db,
		AuditLogger: NewAuditLogHandler(db),
	}
}

// ListUsersRequest 列出用户请求
type ListUsersRequest struct {
	Page     int    `form:"page"`
	PageSize int    `form:"page_size"`
	Search   string `form:"search"`
}

// UserResponse 用户响应
type UserResponse struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Email       string `json:"email"`
	IsAdmin     bool   `json:"is_admin"`
	IsActive    bool   `json:"is_active"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

// ListUsers 列出用户
func (h *UserHandler) ListUsers(c *gin.Context) {
	var req ListUsersRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "查询参数无效",
		})
		return
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 20
	}

	query := h.DB.Model(&models.User{})
	if req.Search != "" {
		query = query.Where("username ILIKE ? OR display_name ILIKE ? OR email ILIKE ?",
			"%"+req.Search+"%", "%"+req.Search+"%", "%"+req.Search+"%")
	}

	var total int64
	query.Count(&total)

	var users []models.User
	offset := (req.Page - 1) * req.PageSize
	query.Order("created_at DESC").Offset(offset).Limit(req.PageSize).Find(&users)

	response := make([]UserResponse, len(users))
	for i, user := range users {
		response[i] = UserResponse{
			ID:          user.ID.String(),
			Username:    user.Username,
			DisplayName: user.DisplayName,
			Email:       user.Email,
			IsAdmin:     user.IsAdmin,
			IsActive:    user.IsActive,
			CreatedAt:   formatBeijingTime(user.CreatedAt),
			UpdatedAt:   formatBeijingTime(user.UpdatedAt),
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

// GetUser 获取用户详情
func (h *UserHandler) GetUser(c *gin.Context) {
	id := c.Param("id")

	var user models.User
	if err := h.DB.First(&user, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, UserResponse{
		ID:          user.ID.String(),
		Username:    user.Username,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		IsAdmin:     user.IsAdmin,
		IsActive:    user.IsActive,
		CreatedAt:   formatBeijingTime(user.CreatedAt),
		UpdatedAt:   formatBeijingTime(user.UpdatedAt),
	})
}

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	Username    string `json:"username" binding:"required"`
	Password    string `json:"password" binding:"required,min=6"`
	DisplayName string `json:"display_name"`
	Email       string `json:"email"`
	IsAdmin     bool   `json:"is_admin"`
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	// 检查用户名是否已存在
	var existing models.User
	if err := h.DB.Where("username = ?", req.Username).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{
			"code":    "ALREADY_EXISTS",
			"message": "用户名已存在",
		})
		return
	}

	// 加密密码
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "密码加密失败",
		})
		return
	}

	user := models.User{
		Username:     req.Username,
		PasswordHash: string(passwordHash),
		DisplayName:  req.DisplayName,
		Email:        req.Email,
		IsAdmin:      req.IsAdmin,
		IsActive:     true,
	}

	if err := h.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "创建用户失败",
		})
		return
	}

	// 记录审计日志 - 创建用户
	h.AuditLogger.CreateAuditLog(c, models.ActionCreate, models.ResourceUser, user.ID.String(), user.Username,
		"创建用户", true, "")

	c.JSON(http.StatusCreated, UserResponse{
		ID:          user.ID.String(),
		Username:    user.Username,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		IsAdmin:     user.IsAdmin,
		IsActive:    user.IsActive,
		CreatedAt:   formatBeijingTime(user.CreatedAt),
		UpdatedAt:   formatBeijingTime(user.UpdatedAt),
	})
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	DisplayName string `json:"display_name"`
	Email       string `json:"email"`
	IsAdmin     bool   `json:"is_admin"`
	IsActive    bool   `json:"is_active"`
	Password    string `json:"password"` // 可选，如果提供则更新密码
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	id := c.Param("id")

	var req UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	var user models.User
	if err := h.DB.First(&user, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "用户不存在",
		})
		return
	}

	// 更新字段
	if req.DisplayName != "" {
		user.DisplayName = req.DisplayName
	}
	if req.Email != "" {
		user.Email = req.Email
	}
	user.IsAdmin = req.IsAdmin
	user.IsActive = req.IsActive

	// 如果提供了密码，则更新密码
	if req.Password != "" {
		passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "密码加密失败",
			})
			return
		}
		user.PasswordHash = string(passwordHash)
	}

	if err := h.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "更新用户失败",
		})
		return
	}

	// 记录审计日志 - 更新用户
	h.AuditLogger.CreateAuditLog(c, models.ActionUpdate, models.ResourceUser, user.ID.String(), user.Username,
		"更新用户信息", true, "")

	c.JSON(http.StatusOK, UserResponse{
		ID:          user.ID.String(),
		Username:    user.Username,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		IsAdmin:     user.IsAdmin,
		IsActive:    user.IsActive,
		CreatedAt:   formatBeijingTime(user.CreatedAt),
		UpdatedAt:   formatBeijingTime(user.UpdatedAt),
	})
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	id := c.Param("id")

	// 获取当前用户ID，防止删除自己
	currentUserID, _ := c.Get("user_id")
	if currentUserID == id {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "CANNOT_DELETE_SELF",
			"message": "不能删除自己",
		})
		return
	}

	var user models.User
	if err := h.DB.First(&user, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "NOT_FOUND",
			"message": "用户不存在",
		})
		return
	}

	if err := h.DB.Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "删除用户失败",
		})
		return
	}

	// 记录审计日志 - 删除用户
	h.AuditLogger.CreateAuditLog(c, models.ActionDelete, models.ResourceUser, user.ID.String(), user.Username,
		"删除用户", true, "")

	c.JSON(http.StatusOK, gin.H{
		"message": "用户删除成功",
	})
}