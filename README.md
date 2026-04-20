# Hub Registry - 私有化容器镜像仓库

一个功能完善的私有化容器镜像仓库，兼容 Docker Registry HTTP API V2，支持镜像的上传、下载、删除管理，提供友好的 UI 操作界面和命令行操作。

## 功能特性

### 核心功能
- ✅ Docker Registry API 兼容（支持 `docker pull` / `docker push`）
- ✅ 镜像管理（上传、下载、删除）
- ✅ 标签管理
- ✅ 仓库管理
- ✅ 命名空间管理
- ✅ Web UI 界面
- ✅ 镜像复制/同步

### 技术架构
- **微服务架构**：API Gateway + Core Services + Storage Adapters
- **存储后端**：支持 S3/MinIO/本地文件系统
- **数据库**：PostgreSQL + Redis
- **部署方式**：Docker Compose

## 项目结构

```
hub-registry/
├── gateway/              # API Gateway - 统一入口
│   ├── cmd/
│   └── internal/
├── registry-core/        # Docker Registry Core - Docker API 实现
│   ├── cmd/
│   └── internal/
├── web-api/              # Web API - 业务逻辑
│   ├── cmd/
│   └── internal/
├── replication-service/  # Replication Service - 镜像复制同步
│   ├── cmd/
│   └── internal/
├── web-ui/               # Web UI - React 前端
│   └── src/
├── shared/               # 共享库
│   └── pkg/
├── scripts/              # 工具脚本
├── docker-compose.yml  # Docker Compose 部署配置
└── README.md
```

## 快速开始

### 环境要求
- Docker 20.10+
- Docker Compose 2.0+
- Go 1.21+（如需本地开发）

### 部署步骤

1. 克隆项目
```bash
git clone <repository-url>
cd hub-registry
```

2. 配置环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，修改必要的配置
```

3. 启动服务
```bash
docker-compose up -d
```

4. 验证部署
```bash
# 检查健康状态
curl http://localhost:8080/health

# 登录 Docker Registry
docker login localhost:8080
```

## API 文档

### Docker Registry API
- `GET /v2/` - 检查 Registry 状态
- `GET /v2/_catalog` - 列出所有仓库
- `HEAD /v2/{name}/blobs/{digest}` - 检查 blob 是否存在
- `GET /v2/{name}/blobs/{digest}` - 下载 blob
- `POST /v2/{name}/blobs/uploads/` - 初始化 blob 上传
- `PUT /v2/{name}/manifests/{reference}` - 上传 manifest
- `GET /v2/{name}/manifests/{reference}` - 获取 manifest

### Web UI API
- `POST /api/v1/auth/login` - 用户登录
- `GET /api/v1/auth/profile` - 获取用户信息
- `GET /api/v1/namespaces` - 列出命名空间
- `POST /api/v1/namespaces` - 创建命名空间
- `GET /api/v1/repos` - 列出仓库
- `GET /api/v1/tags` - 列出标签

## 开发指南

### 本地开发

1. 安装依赖
```bash
# 安装 Go 依赖
cd shared && go mod download
cd ../gateway && go mod download
cd ../registry-core && go mod download
cd ../web-api && go mod download
cd ../replication-service && go mod download
```

2. 启动数据库
```bash
docker-compose up -d postgres redis minio
```

3. 运行迁移
```bash
cd scripts && go run migrate.go
```

4. 启动各个服务
```bash
# 启动 Gateway
cd gateway && go run cmd/gateway/main.go

# 启动 Registry Core
cd registry-core && go run cmd/registry/main.go

# 启动 Web API
cd web-api && go run cmd/api/main.go
```

### 构建镜像

```bash
# 构建所有镜像
docker-compose build

# 构建单个服务镜像
docker-compose build gateway
docker-compose build registry-core
docker-compose build web-api
```

## 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DB_HOST` | localhost | 数据库主机 |
| `DB_PORT` | 5432 | 数据库端口 |
| `DB_USER` | registry | 数据库用户 |
| `DB_PASSWORD` | registry | 数据库密码 |
| `DB_NAME` | registry | 数据库名称 |
| `JWT_SECRET` | - | JWT 密钥 |
| `S3_ENDPOINT` | - | S3/MinIO 端点 |
| `S3_BUCKET` | registry | S3 Bucket |
| `S3_ACCESS_KEY` | - | S3 Access Key |
| `S3_SECRET_KEY` | - | S3 Secret Key |

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

[MIT License](LICENSE)

## 联系方式

- 项目地址: [GitHub URL]
- 问题反馈: [Issues URL]

---

**注意**: 这是开发中的项目，生产环境使用前请进行充分测试。
