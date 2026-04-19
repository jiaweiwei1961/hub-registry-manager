module hub-registry/gateway

go 1.21

require (
	github.com/gin-gonic/gin v1.10.0
	github.com/golang-jwt/jwt/v5 v5.2.1
	go.uber.org/zap v1.27.0
	hub-registry/shared v0.0.0
)

replace hub-registry/shared => ../shared
