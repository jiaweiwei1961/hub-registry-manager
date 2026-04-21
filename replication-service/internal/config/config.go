package config

import (
	"hub-registry/shared/pkg/config"
)

// Config 复制服务配置
type Config struct {
	Server    ServerConfig
	Database  DatabaseConfig
	Scheduler SchedulerConfig
	Worker    WorkerConfig
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port int
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

// SchedulerConfig 调度器配置
type SchedulerConfig struct {
	CheckInterval int // 秒
}

// WorkerConfig Worker 配置
type WorkerConfig struct {
	MaxConcurrency  int
	DefaultTimeout int // 分钟
}

// Load 加载配置
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port: config.GetEnvInt("REPLICATION_PORT", 8082),
		},
		Database: DatabaseConfig{
			Host:     config.GetEnv("DB_HOST", "localhost"),
			Port:     config.GetEnvInt("DB_PORT", 5432),
			User:     config.GetEnv("DB_USER", "registry"),
			Password: config.GetEnv("DB_PASSWORD", "registry"),
			Database: config.GetEnv("DB_NAME", "registry"),
			SSLMode:  config.GetEnv("DB_SSLMODE", "disable"),
		},
		Scheduler: SchedulerConfig{
			CheckInterval: config.GetEnvInt("SCHEDULER_INTERVAL", 60),
		},
		Worker: WorkerConfig{
			MaxConcurrency:  config.GetEnvInt("WORKER_CONCURRENCY", 5),
			DefaultTimeout: config.GetEnvInt("WORKER_TIMEOUT", 30),
		},
	}
}
