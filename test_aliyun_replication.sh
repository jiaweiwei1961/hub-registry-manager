#!/bin/bash
set +H

echo "========================================"
echo "阿里云镜像复制功能测试"
echo "========================================"

# 登录获取 token
echo "1. 登录获取认证 token..."
LOGIN_RESPONSE=$(curl -s -X POST http://192.168.50.60:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}')
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "登录失败: $LOGIN_RESPONSE"
    exit 1
fi
echo "✓ 登录成功，获取到 token"

# 创建命名空间
echo ""
echo "2. 创建测试命名空间..."
NS_RESPONSE=$(curl -s -X POST http://192.168.50.60:8080/api/v1/namespaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"aliyun-test","display_name":"阿里云测试","description":"阿里云镜像复制测试","is_public":true}')
echo "命名空间创建响应: $NS_RESPONSE"

# 创建镜像复制任务
echo ""
echo "3. 创建镜像复制任务..."
echo "   源镜像: registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1"
echo "   目标: ocloudhub/nginx-proxy-manager:2.12.1"

REPLICATE_RESPONSE=$(curl -s -X POST http://192.168.50.60:8080/api/v1/images/replicate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "source_image": "registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1",
    "dest_namespace": "aliyun-test",
    "dest_repository": "nginx-proxy-manager",
    "dest_tag": "2.12.1",
    "username": "",
    "password": "",
    "insecure_skip_verify": false
  }')

echo "复制任务创建响应: $REPLICATE_RESPONSE"

TASK_ID=$(echo $REPLICATE_RESPONSE | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TASK_ID" ]; then
    echo "创建任务失败"
    exit 1
fi

echo ""
echo "✓ 复制任务已创建"
echo "   任务ID: $TASK_ID"

# 等待任务执行
echo ""
echo "4. 等待任务执行（最多60秒）..."
for i in {1..12}; do
    sleep 5
    TASK_STATUS=$(curl -s http://192.168.50.60:8080/api/v1/replication/tasks/$TASK_ID \
      -H "Authorization: Bearer $TOKEN")
    
    STATUS=$(echo $TASK_STATUS | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "   [$i/12] 任务状态: $STATUS"
    
    if [ "$STATUS" = "success" ] || [ "$STATUS" = "failed" ]; then
        break
    fi
done

# 显示最终结果
echo ""
echo "5. 任务执行结果:"
echo "   $TASK_STATUS" | python3 -m json.tool 2>/dev/null || echo "   $TASK_STATUS"

echo ""
echo "========================================"
