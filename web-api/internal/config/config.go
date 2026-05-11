package config

import (
	"fmt"
	envconfig "hub-registry/shared/pkg/config"
)

// Config Web API 配置
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Auth     AuthConfig
	Redis    RedisConfig
	S3       S3Config
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

// S3Config S3/MinIO 配置
type S3Config struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	UseSSL    bool
}

// Load 从环境变量加载配置
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port:         envconfig.GetEnvInt("WEB_API_PORT", 8081),
			ReadTimeout:  envconfig.GetEnvInt("READ_TIMEOUT", 30),
			WriteTimeout: envconfig.GetEnvInt("WRITE_TIMEOUT", 30),
		},
		Database: DatabaseConfig{
			Host:     envconfig.GetEnv("DB_HOST", "localhost"),
			Port:     envconfig.GetEnvInt("DB_PORT", 5432),
			User:     envconfig.GetEnv("DB_USER", "registry"),
			Password: envconfig.GetEnv("DB_PASSWORD", "registry"),
			Database: envconfig.GetEnv("DB_NAME", "registry"),
			SSLMode:  envconfig.GetEnv("DB_SSLMODE", "disable"),
		},
		Auth: AuthConfig{
			JWTSecret:     envconfig.GetEnv("JWT_SECRET", ""),
			TokenExpiry:   envconfig.GetEnvInt("TOKEN_EXPIRY_HOURS", 24),
			RefreshExpiry: envconfig.GetEnvInt("REFRESH_EXPIRY_HOURS", 168),
			PasswordCost:  envconfig.GetEnvInt("BCRYPT_COST", 12),
		},
		Redis: RedisConfig{
			Host:     envconfig.GetEnv("REDIS_HOST", "localhost"),
			Port:     envconfig.GetEnvInt("REDIS_PORT", 6379),
			Password: envconfig.GetEnv("REDIS_PASSWORD", ""),
			DB:       envconfig.GetEnvInt("REDIS_DB", 0),
		},
		S3: S3Config{
			Endpoint:  envconfig.GetEnv("S3_ENDPOINT", ""),
			AccessKey: envconfig.GetEnv("S3_ACCESS_KEY", "minioadmin"),
			SecretKey: envconfig.GetEnv("S3_SECRET_KEY", "minioadmin"),
			Bucket:    envconfig.GetEnv("S3_BUCKET", "registry"),
			UseSSL:    envconfig.GetEnvBool("S3_USE_SSL", false),
		},
	}
}
