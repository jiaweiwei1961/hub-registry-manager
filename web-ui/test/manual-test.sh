#!/bin/bash

# Web UI 页面功能测试脚本

set -e

BASE_URL="${TEST_URL:-http://localhost:3000}"
echo "Testing Web UI at: $BASE_URL"
echo "========================================"

# 检查页面是否可访问
echo "1. 检查首页是否可访问..."
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" | grep -q "200"; then
  echo "   ✓ 首页可访问"
else
  echo "   ✗ 首页无法访问"
  exit 1
fi

# 检查登录页面
echo "2. 检查登录页面..."
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/login" | grep -q "200"; then
  echo "   ✓ 登录页面可访问"
else
  echo "   ✗ 登录页面无法访问"
fi

# 检查静态资源
echo "3. 检查静态资源..."
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/logo.svg" | grep -q "200"; then
  echo "   ✓ Logo 可访问"
else
  echo "   ✗ Logo 无法访问"
fi

echo ""
echo "========================================"
echo "基础测试完成"
echo ""
echo "请手动验证以下功能："
echo ""
echo "【登录页面】"
echo "  □ 输入用户名和密码"
echo "  □ 点击登录按钮"
echo "  □ 验证登录成功后跳转到仪表板"
echo ""
echo "【仪表板】"
echo "  □ 查看统计卡片显示"
echo "  □ 验证数据加载正常"
echo ""
echo "【命名空间】"
echo "  □ 点击左侧菜单：命名空间"
echo "  □ 点击"新建"按钮"
echo "  □ 填写表单并创建命名空间"
echo "  □ 验证命名空间显示在列表中"
echo ""
echo "【镜像仓库】"
echo "  □ 点击左侧菜单：镜像仓库"
echo "  □ 验证仓库列表加载"
echo "  □ 使用搜索框搜索镜像"
echo ""
echo "【镜像复制】"
echo "  □ 点击左侧菜单：镜像复制"
echo "  □ 验证"镜像上传"标签页显示"
echo "  □ 切换到"镜像复制"标签页"
echo "  □ 点击"新建策略"按钮"
echo "  □ 填写表单字段：策略名称、源Registry、目标命名空间"
echo "  □ 保存策略"
echo ""
echo "【系统状态】"
echo "  □ 点击左侧菜单：系统状态"
echo "  □ 验证服务状态卡片显示"
echo "  □ 检查数据库、Redis、MinIO状态"
echo ""
echo "【用户管理】"
echo "  □ 点击左侧菜单：用户管理"
echo "  □ 验证用户列表加载"
echo ""
echo "【通用功能】"
echo "  □ 测试侧边栏折叠/展开"
echo "  □ 测试退出登录"
echo "  □ 测试页面刷新后保持登录状态"
echo ""
echo "========================================"
