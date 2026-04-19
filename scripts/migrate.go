package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"hub-registry/shared/pkg/database"
	"hub-registry/shared/pkg/models"
)

func main() {
	var (
		host     = flag.String("host", getEnv("DB_HOST", "localhost"), "Database host")
		port     = flag.Int("port", getEnvInt("DB_PORT", 5432), "Database port")
		user     = flag.String("user", getEnv("DB_USER", "registry"), "Database user")
		password = flag.String("password", getEnv("DB_PASSWORD", "registry"), "Database password")
		database = flag.String("database", getEnv("DB_NAME", "registry"), "Database name")
	)
	flag.Parse()

	config := &database.Config{
		Host:     *host,
		Port:     *port,
		User:     *user,
		Password: *password,
		Database: *database,
		SSLMode:  "disable",
	}

	db, err := database.New(config)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	fmt.Println("Connected to database, running migrations...")

	// 自动迁移所有模型
	err = db.AutoMigrate(
		&models.Namespace{},
		&models.Repository{},
		&models.Manifest{},
		&models.Blob{},
		&models.Tag{},
		&models.User{},
		&models.ReplicationPolicy{},
		&models.ReplicationTask{},
		&models.ReplicationTaskDetail{},
		&models.RegistryEndpoint{},
		&models.AuditLog{},
		&models.ManifestBlob{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	fmt.Println("Migrations completed successfully!")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var result int
		fmt.Sscanf(value, "%d", &result)
		return result
	}
	return defaultValue
}
