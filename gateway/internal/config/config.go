package config

import (
	"hub-registry/shared/pkg/config"
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
	RefreshExpiryInt int
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
			Port:         config.GetEnvInt("GATEWAY_PORT", 8080),
			ReadTimeout:  config.GetEnvInt("READ_TIMEOUT", 30),
			WriteTimeout: config.GetEnvInt("WRITE_TIMEOUT", 30),
		},
		Auth: AuthConfig{
			JWTSecret:     config.GetEnv("JWT_SECRET", ""),
			TokenExpiry:   config.GetEnvInt("TOKEN_EXPIRY_HOURS", 24),
			RefreshExpiryInt: config.GetEnvInt("REFRESH_EXPIRY_HOURS", 168),
		},
		Upstream: UpstreamConfig{
			RegistryCore: config.GetEnv("REGISTRY_CORE_URL", "http://localhost:5000"),
			WebAPI:       config.GetEnv("WEB_API_URL", "http://localhost:8081"),
		},
	}
}
