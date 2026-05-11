# Hub Registry v1.0 Release Package

## 目录结构

```
v1.0/
├── config/
│   └── docker-compose.yml    # Docker Compose 配置文件（不含 build 部分）
├── images/
│   ├── gateway.tar.gz        # API Gateway 镜像
│   ├── registry-core.tar.gz  # Registry Core 镜像
│   ├── web-api.tar.gz        # Web API 镜像
│   ├── web-ui.tar.gz         # Web UI 前端镜像
│   └── replication-service.tar.gz  # Replication Service 镜像
├── scripts/
│   ├── init.sql              # 数据库完整初始化脚本（含数据）
│   └── schema.sql            # 数据库结构脚本
├── install.sh                # 安装脚本
├── README.md                 # 说明文档
└── VERSION                   # 版本信息
```

## 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 最低 4GB 内存
- 最低 20GB 磁盘空间

## 安装步骤

### 方法一：使用安装脚本

```bash
chmod +x install.sh
sudo ./install.sh
```

### 方法二：手动安装

1. 加载 Docker 镜像：
```bash
cd images
for img in *.tar.gz; do
    docker load < "$img"
done
```

2. 启动服务：
```bash
cd config
docker-compose up -d
```

3. 验证服务状态：
```bash
docker-compose ps
```

## 配置说明

可通过环境变量或 `.env` 文件修改配置：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| DB_USER | registry | 数据库用户名 |
| DB_PASSWORD | registry | 数据库密码 |
| DB_NAME | registry | 数据库名称 |
| JWT_SECRET | hub-registry-jwt-secret-2024 | JWT 密钥 |
| S3_BUCKET | registry | MinIO 存储桶 |
| S3_ACCESS_KEY | minioadmin | MinIO 访问密钥 |
| S3_SECRET_KEY | minioadmin | MinIO 密钥 |

## 访问地址

安装完成后可访问：

- **Web UI**: http://localhost:3000
- **API Gateway**: http://localhost:8080  
- **Registry**: http://localhost:5000
- **MinIO Console**: http://localhost:9001

## 默认账户

- **管理员账户**: admin / admin123

## 服务管理

```bash
# 查看服务状态
docker-compose -f config/docker-compose.yml ps

# 停止所有服务
docker-compose -f config/docker-compose.yml down

# 重启服务
docker-compose -f config/docker-compose.yml restart

# 查看日志
docker-compose -f config/docker-compose.yml logs -f [service_name]
```

## 数据持久化

以下数据会持久化存储在 Docker volumes 中：

- `postgres_data`: PostgreSQL 数据
- `redis_data`: Redis 缓存数据
- `minio_data`: MinIO 对象存储
- `blob_data`: 镜像 Blob 存储

## 版本信息

- 版本号: 1.0.0
- 发布日期: 2026-05-08
- Git Commit: 请参考实际部署时的版本

## 技术支持

如有问题请联系技术支持团队。