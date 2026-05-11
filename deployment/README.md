# Hub Registry 部署包

私有 Docker Registry 管理系统完整部署文件包

## 目录结构

```
hub-registry/
├── docker-compose.prod.yml     # 生产环境 Docker Compose 配置 (使用预构建镜像)
├── docker-compose.yml          # 开发环境配置 (需要构建)
├── images/                     # Docker 震像文件目录
│   ├── gateway.tar
│   ├── core.tar
│   ├── web-api.tar
│   ├── replication.tar
│   └── web-ui.tar
├── images.tar.gz               # 镜像打包文件 (可选)
├── sql/
│   └── init.sql                # 数据库初始化脚本
├── config/
│   ├── .env.example            # 环境变量模板
│   └── ...                     # 其他配置文件
├── dockerfiles/                # Dockerfile 文件 (用于重新构建)
├── docs/                       # 文档
│   ├── DEPLOY.md
│   ├── DATABASE.md
│   └── API.md
└── scripts/
    ├── deploy-full.sh          # 完整部署脚本
    ├── load-images.sh          # 加载震像脚本
    ├── export-images-server.sh # 服务器端导出震像脚本
    └── package.sh              # 打包脚本
```

## 部署文件说明

### 1. Docker 震像文件 (images/)

包含所有服务的预构建 Docker 震像:

| 震像 | 说明 |
|------|------|
| gateway.tar | API Gateway 服务 |
| core.tar | Registry Core (Docker V2 API) |
| web-api.tar | Web API 后端服务 |
| replication.tar | 镜像复制服务 |
| web-ui.tar | 前端 Web 界面 |

### 2. docker-compose.prod.yml

生产环境配置文件，使用预构建震像启动服务:
- 不需要本地构建
- 包含数据库初始化配置
- 配置服务依赖和健康检查

### 3. 数据库初始化 (sql/init.sql)

PostgreSQL 初始化脚本:
- 创建所有数据表
- 设置外键约束
- 创建默认管理员账户 (admin/admin123)
- 创建默认公共命名空间 (library)

### 4. 配置文件 (config/.env.example)

环境变量模板，需要复制为 .env 并修改:

```bash
cp config/.env.example .env
vim .env
```

主要配置项:
- `DB_USER`, `DB_PASSWORD`, `DB_NAME` - 数据库连接
- `JWT_SECRET` - JWT 密钥
- `S3_ACCESS_KEY`, `S3_SECRET_KEY` - MinIO 访问密钥
- `EXTERNAL_HOST`, `EXTERNAL_PORT` - 外部访问地址

## 部署步骤

### 方式一: 使用完整部署脚本

1. 上传部署包到服务器
   ```bash
   scp hub-registry-deploy-*.tar.gz user@server:/home/user/
   ```

2. 解压并部署
   ```bash
   tar -xzvf hub-registry-deploy-*.tar.gz
   cd hub-registry
   chmod +x scripts/*.sh
   ./scripts/deploy-full.sh
   ```

### 方式二: 手动部署

1. 加载 Docker 震像
   ```bash
   # 如果有 images.tar.gz
   mkdir -p images
   tar -xzvf images.tar.gz -C images/
   
   # 加载震像
   for f in images/*.tar; do sudo docker load -i $f; done
   ```

2. 配置环境变量
   ```bash
   cp config/.env.example .env
   vim .env
   ```

3. 启动服务
   ```bash
   sudo docker-compose -f docker-compose.prod.yml up -d
   ```

4. 验证部署
   ```bash
   sudo docker-compose -f docker-compose.prod.yml ps
   curl http://localhost:8080/health
   ```

## 服务组件

| 服务 | 端口 | 说明 |
|------|------|------|
| postgres | 5432 | PostgreSQL 数据库 |
| redis | 6379 | Redis 缓存 |
| minio | 9000/9001 | MinIO 对象存储 |
| gateway | 8080 | API Gateway |
| registry-core | 5000 | Docker Registry V2 |
| web-api | 8081 | Web API 后端 |
| replication-service | 8082 | 镜像复制服务 |
| web-ui | 3000 | 前端界面 |

## 访问地址

- Web UI: http://192.168.50.60:3000
- API Gateway: http://192.168.50.60:8080
- Registry: http://192.168.50.60:5000/v2/
- MinIO Console: http://192.168.50.60:9001

## 默认账户

- 用户名: `admin`
- 密码: `admin123`

**警告**: 请在生产环境中立即修改默认密码!

## 导出震像 (在服务器上执行)

如果需要从已部署服务器导出震像:

```bash
# 上传脚本到服务器
scp scripts/export-images-server.sh user@server:/home/user/

# 执行导出
chmod +x export-images-server.sh
./export-images-server.sh

# 下载震像包
scp user@server:/home/jvv/hub-registry/images.tar.gz ./deployment/
```

## 常用操作命令

### 查看服务状态
```bash
sudo docker-compose -f docker-compose.prod.yml ps
sudo docker ps | grep hub-registry
```

### 查看服务日志
```bash
# 所有服务
sudo docker-compose -f docker-compose.prod.yml logs -f

# 单个服务
sudo docker logs hub-registry-web-api --tail 50 -f
sudo docker logs hub-registry-gateway --tail 50 -f
sudo docker logs hub-registry-core --tail 50 -f
```

### 重启服务
```bash
# 重启单个服务
sudo docker-compose -f docker-compose.prod.yml restart web-api

# 重启所有服务
sudo docker-compose -f docker-compose.prod.yml restart
```

### 停止服务
```bash
# 停止所有服务
sudo docker-compose -f docker-compose.prod.yml down

# 停止并删除数据卷 (慎用!)
sudo docker-compose -f docker-compose.prod.yml down -v
```

### 更新单个服务
```bash
# 加载新震像
sudo docker load -i images/web-api.tar

# 重启服务
sudo docker-compose -f docker-compose.prod.yml restart web-api
```

## 相关文档

- [部署详细说明](docs/DEPLOY.md)
- [数据库 Schema](docs/DATABASE.md)
- [API 文档](docs/API.md)

## 故障排查

### 数据库连接失败
```bash
# 检查数据库状态
sudo docker logs hub-registry-postgres --tail 50

# 检查数据库连接
sudo docker exec hub-registry-postgres pg_isready -U registry
```

### 镜像推送失败
```bash
# 检查 Registry 服务
sudo docker logs hub-registry-core --tail 50
curl -v http://localhost:5000/v2/
```

### Web UI 无法访问
```bash
# 检查 Gateway 服务
sudo docker logs hub-registry-gateway --tail 50
curl http://localhost:8080/health
```