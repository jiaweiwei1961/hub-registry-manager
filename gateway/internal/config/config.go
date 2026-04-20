package config

import (
	"os"
	"strconv"
)

// Config 网关配置
type Config struct {
	Server   ServerConfig
	Auth     AuthConfig
	Upstream UpstreamConfig
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port         int
	ReadTimeout  int
	WriteTimeout int
}

// AuthConfig 认证配置
type AuthConfig struct {
	JWTSecret     string
	TokenExpiry   int
	RefreshExpiry int
}

// UpstreamConfig 上游服务配置
type UpstreamConfig struct {
	RegistryCore string
	WebAPI       string
}

// Load 从环境变量加载配置
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port:         getEnvInt("GATEWAY_PORT", 8080),
			ReadTimeout:  getEnvInt("READ_TIMEOUT", 30),
			WriteTimeout: getEnvInt("WRITE_TIMEOUT", 30),
		},
		Auth: AuthConfig{
			JWTSecret:     getEnv("JWT_SECRET", ""),
			TokenExpiry:   getEnvInt("TOKEN_EXPIRY_HOURS", 24),
			RefreshExpiry: getEnvInt("REFRESH_EXPIRY_HOURS", 168),
		},
		Upstream: UpstreamConfig{
			RegistryCore: getEnv("REGISTRY_CORE_URL", "http://localhost:5000"),
			WebAPI:       getEnv("WEB_API_URL", "http://localhost:8081"),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
