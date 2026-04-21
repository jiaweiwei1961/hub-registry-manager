package config

import (
	"fmt"
	"hub-registry/shared/pkg/config"
)

// Config Web API 配置
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Auth     AuthConfig
	Redis    RedisConfig
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port         int
	ReadTimeout  int
	WriteTimeout int
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
	SSLMode  string
}

// ConnectionString 返回数据库连接字符串
func (c DatabaseConfig) ConnectionString() string {
	return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.Database, c.SSLMode)
}

// AuthConfig 认证配置
type AuthConfig struct {
	JWTSecret     string
	TokenExpiry   int
	RefreshExpiry int
	PasswordCost  int
}

// RedisConfig Redis 配置
type RedisConfig struct {
	Host     string
	Port     int
	Password string
	DB       int
}

// Load 从环境变量加载配置
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port:         config.GetEnvInt("WEB_API_PORT", 8081),
			ReadTimeout:  config.GetEnvInt("READ_TIMEOUT", 30),
			WriteTimeout: config.GetEnvInt("WRITE_TIMEOUT", 30),
		},
		Database: DatabaseConfig{
			Host:     config.GetEnv("DB_HOST", "localhost"),
			Port:     config.GetEnvInt("DB_PORT", 5432),
			User:     config.GetEnv("DB_USER", "registry"),
			Password: config.GetEnv("DB_PASSWORD", "registry"),
			Database: config.GetEnv("DB_NAME", "registry"),
			SSLMode:  config.GetEnv("DB_SSLMODE", "disable"),
		},
		Auth: AuthConfig{
			JWTSecret:     config.GetEnv("JWT_SECRET", ""),
			TokenExpiry:   config.GetEnvInt("TOKEN_EXPIRY_HOURS", 24),
			RefreshExpiry: config.GetEnvInt("REFRESH_EXPIRY_HOURS", 168),
			PasswordCost:  config.GetEnvInt("BCRYPT_COST", 12),
		},
		Redis: RedisConfig{
			Host:     config.GetEnv("REDIS_HOST", "localhost"),
			Port:     config.GetEnvInt("REDIS_PORT", 6379),
			Password: config.GetEnv("REDIS_PASSWORD", ""),
			DB:       config.GetEnvInt("REDIS_DB", 0),
		},
	}
}
