#!/bin/bash
# 在服务器上执行此脚本，加载所有 Docker 震像

set -e

IMAGE_DIR="./images"

echo "=== 加载 Hub Registry Docker 震像 ==="

if [ ! -d "$IMAGE_DIR" ]; then
    # 如果存在压缩包，先解压
    if [ -f "images.tar.gz" ]; then
        echo "解压镜像包..."
        mkdir -p $IMAGE_DIR
        tar -xzvf images.tar.gz -C $IMAGE_DIR/
    else
        echo "错误: 未找到镜像文件"
        exit 1
    fi
fi

# 加载每个镜像
for tarfile in $IMAGE_DIR/*.tar; do
    if [ -f "$tarfile" ]; then
        echo "加载: $tarfile"
        sudo docker load -i $tarfile
    fi
done

echo ""
echo "=== 验证加载的镜像 ==="
sudo docker images | grep hub-registry

echo ""
echo "=== 加载完成 ==="