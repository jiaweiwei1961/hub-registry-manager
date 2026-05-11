#!/bin/bash
# 快速部署脚本

set -e

DEPLOY_DIR="/home/jvv/hub-registry"

echo "=== Hub Registry 部署脚本 ==="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装"
    exit 1
fi

# 创建部署目录
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

# 检查必要文件
if [ ! -f "docker-compose.yml" ]; then
    echo "错误: docker-compose.yml 未找到"
    echo "请先上传部署文件到 $DEPLOY_DIR"
    exit 1
fi

# 配置环境变量（如果不存在）
if [ ! -f ".env" ]; then
    echo "创建默认环境变量配置..."
    cat > .env << 'EOF'
DB_USER=registry
DB_PASSWORD=registry
DB_NAME=registry
JWT_SECRET=hub-registry-jwt-secret-2024
S3_BUCKET=registry
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
REGISTRY_HOST=localhost
REGISTRY_PORT=5000
EXTERNAL_HOST=hub.auok.online
EXTERNAL_PORT=50000
EOF
fi

echo ""
echo "=== 构建镜像 ==="
docker-compose build

echo ""
echo "=== 启动服务 ==="
docker-compose up -d

echo ""
echo "=== 等待服务启动 ==="
sleep 10

echo ""
echo "=== 服务状态 ==="
docker-compose ps

echo ""
echo "=== 部署完成 ==="
echo ""
echo "访问地址:"
echo "  Web UI:         http://localhost:3000"
echo "  API Gateway:    http://localhost:8080"
echo "  Registry V2:    http://localhost:5000/v2/"
echo "  MinIO Console:  http://localhost:9001"
echo ""
echo "常用命令:"
echo "  查看日志: docker-compose logs -f [service]"
echo "  重启服务: docker-compose restart [service]"
echo "  停止服务: docker-compose down"