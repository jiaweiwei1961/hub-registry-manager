# 导出镜像操作指南

## 步骤一: 在服务器上导出镜像

将 `export-images-server.sh` 脚本上传到服务器并执行:

```bash
# 方式一: 直接在服务器执行
scp deployment/scripts/export-images-server.sh jvv@192.168.50.60:/home/jvv/

ssh jvv@192.168.50.60
chmod +x export-images-server.sh
./export-images-server.sh
```

脚本会导出以下镜像到 `/home/jvv/hub-registry/images/` 目录:
- hub-registry-gateway:latest
- hub-registry-core:latest  
- hub-registry-web-api:latest
- hub-registry-replication:latest
- hub-registry-web-ui:latest

## 步骤二: 下载镜像文件

从服务器下载镜像打包文件:

```bash
# 下载打包的镜像
scp jvv@192.168.50.60:/home/jvv/hub-registry/images.tar.gz deployment/

# 或者下载单独的镜像文件
scp -r jvv@192.168.50.60:/home/jvv/hub-registry/images deployment/
```

## 步骤三: 验证镜像文件

验证下载的镜像文件:

```bash
# 检查文件大小
ls -lh deployment/images.tar.gz
ls -lh deployment/images/

# 验证镜像完整性 (加载测试)
sudo docker load -i deployment/images/web-api.tar
sudo docker images | grep hub-registry
```

## 步骤四: 重新打包完整部署包

如果需要创建包含镜像的完整部署包:

```bash
cd deployment
# 解压镜像到 images 目录 (如果是 tar.gz)
mkdir -p images
tar -xzvf images.tar.gz -C images/

# 创建完整部署包 (包含镜像)
tar -czvf hub-registry-full-deploy.tar.gz \
    docker-compose.prod.yml \
    docker-compose.yml \
    images/ \
    sql/ \
    config/ \
    docs/ \
    scripts/ \
    README.md
```

## 手动导出镜像 (如果脚本失败)

如果自动脚本失败，可以手动导出:

```bash
ssh jvv@192.168.50.60

# 查看所有镜像
sudo docker images | grep hub-registry

# 创建目录
mkdir -p /home/jvv/hub-registry/images

# 导出各个镜像
sudo docker save hub-registry-gateway:latest -o /home/jvv/hub-registry/images/gateway.tar
sudo docker save hub-registry-core:latest -o /home/jvv/hub-registry/images/core.tar
sudo docker save hub-registry-web-api:latest -o /home/jvv/hub-registry/images/web-api.tar
sudo docker save hub-registry-replication:latest -o /home/jvv/hub-registry/images/replication.tar
sudo docker save hub-registry-web-ui:latest -o /home/jvv/hub-registry/images/web-ui.tar

# 打包
cd /home/jvv/hub-registry/images
tar -czvf ../images.tar.gz *.tar

# 查看结果
ls -lh ../images.tar.gz
```

## 预估镜像大小

根据已部署服务，预计各镜像大小:

| 镜像 | 预估大小 |
|------|----------|
| gateway.tar | ~50MB |
| core.tar | ~50MB |
| web-api.tar | ~50MB |
| replication.tar | ~50MB |
| web-ui.tar | ~100MB |
| images.tar.gz (打包后) | ~100-150MB |

## 注意事项

1. 导出镜像需要 sudo 权限
2. 确保服务器有足够磁盘空间存放镜像文件
3. 镜像导出时间取决于镜像大小，约5-10分钟
4. 建议在导出后验证镜像完整性