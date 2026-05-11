package config

import (
	envconfig "hub-registry/shared/pkg/config"
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
	MinIO        string
}

// Load 从环境变量加载配置
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port:         envconfig.GetEnvInt("GATEWAY_PORT", 8080),
			ReadTimeout:  envconfig.GetEnvInt("READ_TIMEOUT", 30),
			WriteTimeout: envconfig.GetEnvInt("WRITE_TIMEOUT", 30),
		},
		Auth: AuthConfig{
			JWTSecret:     envconfig.GetEnv("JWT_SECRET", ""),
			TokenExpiry:   envconfig.GetEnvInt("TOKEN_EXPIRY_HOURS", 24),
			RefreshExpiry: envconfig.GetEnvInt("REFRESH_EXPIRY_HOURS", 168),
		},
		Upstream: UpstreamConfig{
			RegistryCore: envconfig.GetEnv("REGISTRY_CORE_URL", "http://localhost:5000"),
			WebAPI:       envconfig.GetEnv("WEB_API_URL", "http://localhost:8081"),
			MinIO:        envconfig.GetEnv("MINIO_URL", "http://localhost:9000"),
		},
	}
}
