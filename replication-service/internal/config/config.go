package config

import (
	"os"
	"strconv"
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
			Port: getEnvInt("REPLICATION_PORT", 8082),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvInt("DB_PORT", 5432),
			User:     getEnv("DB_USER", "registry"),
			Password: getEnv("DB_PASSWORD", "registry"),
			Database: getEnv("DB_NAME", "registry"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		Scheduler: SchedulerConfig{
			CheckInterval: getEnvInt("SCHEDULER_INTERVAL", 60),
		},
		Worker: WorkerConfig{
			MaxConcurrency:  getEnvInt("WORKER_CONCURRENCY", 5),
			DefaultTimeout: getEnvInt("WORKER_TIMEOUT", 30),
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
