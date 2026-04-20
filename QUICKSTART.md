# 快速启动指南

## 1. 启动基础设施服务

docker-compose up -d postgres redis minio

## 2. 运行数据库迁移

cd scripts && go run migrate.go

## 3. 启动各个服务（分别在多个终端窗口中运行）

# 终端 1: 启动 Gateway
cd gateway && go run cmd/gateway/main.go

# 终端 2: 启动 Registry Core
cd registry-core && go run cmd/registry/main.go

# 终端 3: 启动 Web API
cd web-api && go run cmd/api/main.go

## 4. 测试服务

# 测试 Gateway 健康检查
curl http://localhost:8080/health

# 测试 Registry Core
curl http://localhost:5000/v2/

# 测试 Web API
curl http://localhost:8081/health

## 5. Docker Compose 一键启动所有服务

cd /Users/jiaweiwei/workspace/hub-registry
cp .env.example .env
# 编辑 .env 设置必要的环境变量
docker-compose up -d

