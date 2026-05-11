#!/bin/bash
# 打包部署文件 (不含镜像)

set -e

VERSION=$(date +%Y%m%d)
PACKAGE_NAME="hub-registry-deploy-${VERSION}.tar.gz"

# 获取脚本所在目录
SCRIPT_DIR=$(dirname "$0")
DEPLOY_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
PROJECT_DIR=$(cd "$DEPLOY_DIR/.." && pwd)

echo "=== 打包 Hub Registry 部署文件 (不含镜像) ==="

cd "$DEPLOY_DIR"

# 创建临时目录结构
mkdir -p package/hub-registry

# 复制必要文件
cp docker-compose.prod.yml package/hub-registry/
cp docker-compose.yml package/hub-registry/
cp go.work package/hub-registry/ 2>/dev/null || true
cp go.work.sum package/hub-registry/ 2>/dev/null || true

# 复制 Dockerfile
mkdir -p package/hub-registry/dockerfiles
cp dockerfiles/*.Dockerfile package/hub-registry/dockerfiles/

# 复制配置文件
mkdir -p package/hub-registry/config
cp config/*.mod package/hub-registry/config/ 2>/dev/null || true
cp config/*.json package/hub-registry/config/ 2>/dev/null || true
cp config/.env.example package/hub-registry/config/

# 复制 SQL 文件
mkdir -p package/hub-registry/sql
cp sql/*.sql package/hub-registry/sql/

# 复制文档
mkdir -p package/hub-registry/docs
cp docs/*.md package/hub-registry/docs/

# 复制脚本
mkdir -p package/hub-registry/scripts
cp scripts/*.sh package/hub-registry/scripts/
cp scripts/*.exp package/hub-registry/scripts/ 2>/dev/null || true

# 复制 README
cp README.md package/hub-registry/

# 打包
tar -czvf "$PROJECT_DIR/${PACKAGE_NAME}" -C package hub-registry

# 清理临时目录
rm -rf package

echo ""
echo "=== 打包完成 ==="
echo "文件: ${PACKAGE_NAME}"
echo "位置: $PROJECT_DIR/${PACKAGE_NAME}"
echo "大小: $(du -h "$PROJECT_DIR/${PACKAGE_NAME}" | cut -f1)"
echo ""
echo "注意: 此包不含 Docker 震像文件"
echo ""
echo "如需导出震像，请在服务器上执行:"
echo "  scp scripts/export-images-server.sh jvv@192.168.50.60:/home/jvv/"
echo "  ssh jvv@192.168.50.60 'chmod +x export-images-server.sh && ./export-images-server.sh'"
echo "  scp jvv@192.168.50.60:/home/jvv/hub-registry/images.tar.gz ."
echo ""
echo "上传到服务器:"
echo "  scp ${PACKAGE_NAME} jvv@192.168.50.60:/home/jvv/"
echo ""
echo "解压部署:"
echo "  tar -xzvf ${PACKAGE_NAME}"
echo "  cd hub-registry"
echo "  # 如果有 images.tar.gz，解压到 images 目录"
echo "  mkdir -p images && tar -xzvf images.tar.gz -C images/"
echo "  ./scripts/deploy-full.sh"