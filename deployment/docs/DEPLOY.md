# Hub Registry 部署文档

## 概述

Hub Registry 是一个私有 Docker Registry 管理系统，包含以下服务组件：

| 服务 | 端口 | 说明 |
|------|------|------|
| postgres | 5432 | PostgreSQL 数据库 |
| redis | 6379 | Redis 缓存 |
| minio | 9000/9001 | MinIO 对象存储 |
| gateway | 8080 | API Gateway (反向代理) |
| registry-core | 5000 | Docker Registry V2 核心 |
| web-api | 8081 | Web API 后端服务 |
| replication-service | 8082 | 镜像复制服务 |
| web-ui | 3000 | 前端 Web 界面 |

## 部署要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 内存
- 至少 20GB 存储空间（用于镜像数据）

## 部署步骤

### 1. 准备部署目录

```bash
# 在服务器上创建部署目录
mkdir -p /home/jvv/hub-registry
cd /home/jvv/hub-registry
```

### 2. 上传部署文件

将以下文件上传到服务器：
- `docker-compose.yml`
- `go.work` (可选，用于本地构建)
- `go.work.sum` (可选，用于本地构建)
- `dockerfiles/` 目录下的所有 Dockerfile
- `config/` 目录下的配置文件

### 3. 配置环境变量

```bash
# 复制环境变量模板
cp config/.env.example .env

# 编辑配置（根据实际环境修改）
vim .env
```

### 4. 构建镜像

```bash
# 构建所有服务镜像
docker-compose build

# 或单独构建各服务
docker-compose build gateway
docker-compose build registry-core
docker-compose build web-api
docker-compose build replication-service
docker-compose build web-ui
```

### 5. 启动服务

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]
```

### 6. 验证部署

```bash
# 检查所有容器运行状态
sudo docker ps

# 检查服务健康状态
curl http://localhost:8080/health
curl http://localhost:5000/v2/
curl http://localhost:8081/api/v1/system/stats
curl http://localhost:3000
```

## 访问地址

- Web UI: http://192.168.50.60:3000
- API Gateway: http://192.168.50.60:8080
- Registry V2 API: http://192.168.50.60:5000/v2/
- MinIO Console: http://192.168.50.60:9001

## 常用操作命令

### 查看服务日志
```bash
sudo docker logs hub-registry-[service_name] --tail 50
sudo docker logs hub-registry-web-api --tail 50
sudo docker logs hub-registry-gateway --tail 50
```

### 重启服务
```bash
docker-compose restart [service_name]
docker-compose restart web-api
```

### 停止所有服务
```bash
docker-compose down
```

### 清理数据（慎用）
```bash
# 删除所有数据卷
docker-compose down -v
```

## 服务架构

```
                    ┌─────────────┐
                    │   Web UI    │
                    │   (:3000)   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Gateway   │
                    │   (:8080)   │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
   │ Registry    │  │  Web API    │  │ Replication │
   │ Core        │  │  (:8081)    │  │ Service     │
   │ (:5000)     │  │             │  │ (:8082)     │
   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
   │ PostgreSQL  │  │   Redis     │  │   MinIO     │
   │ (:5432)     │  │  (:6379)    │  │ (:9000)     │
   └─────────────┘  └─────────────┘  └─────────────┘
```

## 注意事项

1. 数据持久化：镜像数据存储在 Docker volumes 中，删除容器不会丢失数据
2. 网络配置：所有服务使用 `hub-registry-network` 网络互通
3. 健康检查：PostgreSQL 和 Redis 有健康检查，其他服务依赖它们启动
4. 自动重启：所有服务配置了 `restart: unless-stopped`

## 更新部署

```bash
# 重新构建并启动
docker-compose up -d --build

# 仅更新某个服务
docker-compose up -d --build [service_name]
```