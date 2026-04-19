module hub-registry/web-api

go 1.21

require (
	github.com/gin-gonic/gin v1.10.0
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/google/uuid v1.6.0
	golang.org/x/crypto v0.24.0
	gorm.io/driver/postgres v1.5.7
	gorm.io/gorm v1.25.10
	hub-registry/shared v0.0.0
)

replace hub-registry/shared => ../shared
