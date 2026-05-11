package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
	"hub-registry/web-api/internal/config"
	"hub-registry/web-api/internal/middleware"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	DB          *gorm.DB
	Config      *config.Config
	AuditLogger *AuditLogHandler
}

// NewAuthHandler 创建 AuthHandler
func NewAuthHandler(db *gorm.DB, cfg *config.Config) *AuthHandler {
	return &AuthHandler{
		DB:          db,
		Config:      cfg,
		AuditLogger: NewAuditLogHandler(db),
	}
}

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
	User         UserInfo `json:"user"`
}

// UserInfo 用户信息
type UserInfo struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Email       string `json:"email"`
	IsAdmin     bool   `json:"is_admin"`
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    "INVALID_REQUEST",
			"message": "请求体无效",
		})
		return
	}

	// 查找用户
	var user models.User
	if err := h.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// 记录登录失败审计日志
			h.AuditLogger.CreateAuditLog(c, models.ActionLogin, models.ResourceSystem, "", "",
				"用户登录失败：用户名不存在", false, "Invalid username or password")
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    "INVALID_CREDENTIALS",
				"message": "用户名或密码错误",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "用户认证失败",
		})
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		// 记录登录失败审计日志
		h.AuditLogger.CreateAuditLog(c, models.ActionLogin, models.ResourceSystem, "", "",
			"用户登录失败：密码错误", false, "Invalid username or password")
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    "INVALID_CREDENTIALS",
			"message": "用户名或密码错误",
		})
		return
	}

	// 生成 JWT token
	token, err := middleware.GenerateToken(
		user.ID.String(),
		user.Username,
		user.IsAdmin,
		h.Config.Auth.JWTSecret,
		h.Config.Auth.TokenExpiry,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    "INTERNAL_ERROR",
			"message": "生成令牌失败",
		})
		return
	}

	// 更新最后登录时间
	now := time.Now()
	user.LastLoginAt = &now
	h.DB.Save(&user)

	// 记录登录成功审计日志
	h.AuditLogger.CreateAuditLog(c, models.ActionLogin, models.ResourceSystem, user.ID.String(), user.Username,
		"用户登录成功", true, "")

	// 返回响应
	c.JSON(http.StatusOK, LoginResponse{
		Token:     token,
		ExpiresIn: h.Config.Auth.TokenExpiry * 3600,
		User: UserInfo{
			ID:          user.ID.String(),
			Username:    user.Username,
			DisplayName: user.DisplayName,
			Email:       user.Email,
			IsAdmin:     user.IsAdmin,
		},
	})
}

// Logout 用户登出
func (h *AuthHandler) Logout(c *gin.Context) {
	// 获取当前用户信息
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")

	// 记录登出审计日志
	if userID != nil && username != nil {
		h.AuditLogger.CreateAuditLog(c, models.ActionLogout, models.ResourceSystem, userID.(string), username.(string),
			"用户登出", true, "")
	}

	// 在实际应用中，这里可以将 token 加入黑名单
	// 或者更新用户的 token 版本号使旧 token 失效
	c.JSON(http.StatusOK, gin.H{
		"message": "登出成功",
	})
}

// GetProfile 获取用户信息
func (h *AuthHandler) GetProfile(c *gin.Context) {
	// 从上下文中获取用户信息（由 JWT 中间件设置）
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    "UNAUTHORIZED",
			"message": "用户未认证",
		})
		return
	}

	// 查询用户信息
	var user models.User
	if err := h.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "USER_NOT_FOUND",
			"message": "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, UserInfo{
		ID:          user.ID.String(),
		Username:    user.Username,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		IsAdmin:     user.IsAdmin,
	})
}
