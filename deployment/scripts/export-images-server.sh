#!/bin/bash
# 在服务器上执行此脚本，导出所有 Docker 镜像

set -e

DEPLOY_DIR="/home/jvv/hub-registry"
IMAGE_DIR="$DEPLOY_DIR/images"

echo "=== 导出 Hub Registry Docker 镜像 ==="

# 创建镜像目录
mkdir -p $IMAGE_DIR

# 镜像列表
IMAGES=(
    "hub-registry-gateway:latest"
    "hub-registry-core:latest"
    "hub-registry-web-api:latest"
    "hub-registry-replication:latest"
    "hub-registry-web-ui:latest"
)

# 导出每个镜像
for img in "${IMAGES[@]}"; do
    filename=$(echo $img | sed 's/:latest//' | sed 's/hub-registry-//')
    echo "导出: $img -> $IMAGE_DIR/${filename}.tar"
    sudo docker save $img -o "$IMAGE_DIR/${filename}.tar"
done

echo ""
echo "=== 验证导出文件 ==="
ls -lh $IMAGE_DIR/

echo ""
echo "=== 打包镜像文件 ==="
cd $IMAGE_DIR
tar -czvf $DEPLOY_DIR/images.tar.gz *.tar

echo ""
echo "=== 导出完成 ==="
echo "镜像包位置: $DEPLOY_DIR/images.tar.gz"
echo ""
echo "下载到本地:"
echo "  scp jvv@192.168.50.60:$DEPLOY_DIR/images.tar.gz ./deployment/"