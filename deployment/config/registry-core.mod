module hub-registry/registry-core

go 1.23

require (
	github.com/gin-gonic/gin v1.10.0
	github.com/google/uuid v1.6.0
	github.com/minio/minio-go/v7 v7.0.80
	gorm.io/driver/postgres v1.5.7
	gorm.io/gorm v1.25.10
	hub-registry/shared v0.0.0
)

replace hub-registry/shared => ../shared
