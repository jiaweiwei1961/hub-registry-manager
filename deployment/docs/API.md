# API 端点文档

## API Gateway (端口 8080)

所有 API 通过 Gateway 统一入口访问: `http://192.168.50.60:8080`

### 基础路径

- Web API: `/api/v1/*`
- Docker Registry V2 API: `/v2/*`

---

## 认证 API

### 登录
```
POST /api/v1/auth/login
```
请求体:
```json
{
  "username": "admin",
  "password": "admin123"
}
```
响应:
```json
{
  "token": "jwt-token",
  "user": {
    "id": "uuid",
    "username": "admin",
    "is_admin": true
  }
}
```

### 登出
```
POST /api/v1/auth/logout
```
Header: `Authorization: Bearer <token>`

### 获取当前用户信息
```
GET /api/v1/auth/profile
```
Header: `Authorization: Bearer <token>`

---

## 命名空间 API

### 列出命名空间
```
GET /api/v1/namespaces?page=1&page_size=10&search=xxx
```
响应:
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "library",
      "display_name": "公共库",
      "description": "描述",
      "is_public": true,
      "owner_id": "uuid",
      "owner_name": "admin",
      "repository_count": 5,
      "image_count": 10,
      "pull_count": 100,
      "created_at": "2026-04-01 10:00",
      "updated_at": "2026-04-01 10:00"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 10,
    "total": 50,
    "total_pages": 5
  }
}
```

### 创建命名空间
```
POST /api/v1/namespaces
```
请求体:
```json
{
  "name": "my-namespace",
  "display_name": "我的命名空间",
  "description": "描述",
  "is_public": false
}
```

### 获取命名空间详情
```
GET /api/v1/namespaces/:id
```

### 获取命名空间下的仓库
```
GET /api/v1/namespaces/:id/repos
```

### 更新命名空间
```
PUT /api/v1/namespaces/:id
```
请求体:
```json
{
  "display_name": "新名称",
  "description": "新描述"
}
```

### 删除命名空间
```
DELETE /api/v1/namespaces/:id
```
注意: 命名空间下有仓库时无法删除

---

## 仓库 API

### 列出仓库
```
GET /api/v1/repositories?namespace_id=xxx&search=xxx&page=1&page_size=10
```

### 创建仓库
```
POST /api/v1/repositories
```
请求体:
```json
{
  "namespace_id": "uuid",
  "name": "my-image",
  "description": "描述",
  "is_public": false
}
```
注意: 私有命名空间下的仓库自动为私有

### 获取仓库详情
```
GET /api/v1/repositories/:id
```

### 更新仓库
```
PUT /api/v1/repositories/:id
```
请求体:
```json
{
  "description": "新描述",
  "is_public": true
}
```
注意: 私有命名空间下的仓库无法改为公开

### 删除仓库
```
DELETE /api/v1/repositories/:id
```
注意: 仓库下有镜像时无法删除

### 获取仓库标签列表
```
GET /api/v1/repos/:id/tags
```

### 删除标签
```
DELETE /api/v1/repos/:id/tags/:tag_id
```

---

## 用户管理 API

### 列出用户
```
GET /api/v1/users
```
需要管理员权限

### 创建用户
```
POST /api/v1/users
```
请求体:
```json
{
  "username": "newuser",
  "password": "password123",
  "email": "user@example.com",
  "display_name": "新用户",
  "is_admin": false
}
```

### 获取用户详情
```
GET /api/v1/users/:id
```

### 更新用户
```
PUT /api/v1/users/:id
```

### 删除用户
```
DELETE /api/v1/users/:id
```

---

## 镜像操作 API

### 上传镜像
```
POST /api/v1/images/upload
```

### 导出镜像
```
GET /api/v1/images/export?repository=xxx&tag=xxx
```

### 列出镜像
```
GET /api/v1/images/list
```

### 复制镜像
```
POST /api/v1/images/replicate
```
请求体:
```json
{
  "source_registry": "docker.io",
  "source_image": "library/nginx:latest",
  "dest_namespace": "my-namespace",
  "dest_repository": "nginx",
  "dest_tag": "latest"
}
```

---

## 复制策略 API

### 列出复制策略
```
GET /api/v1/replication/policies
```

### 创建复制策略
```
POST /api/v1/replication/policies
```

### 获取策略详情
```
GET /api/v1/replication/policies/:id
```

### 更新策略
```
PUT /api/v1/replication/policies/:id
```

### 删除策略
```
DELETE /api/v1/replication/policies/:id
```

### 执行策略
```
POST /api/v1/replication/policies/:id/execute
```

### 列出复制任务
```
GET /api/v1/replication/tasks
```

### 获取任务详情
```
GET /api/v1/replication/tasks/:id
```

---

## 系统 API

### 获取系统统计
```
GET /api/v1/system/stats
```
响应:
```json
{
  "namespace_count": 10,
  "repository_count": 50,
  "image_count": 100,
  "user_count": 5,
  "total_pull_count": 5000,
  "storage_used_bytes": 1073741824
}
```

---

## Docker Registry V2 API

Registry V2 API 端点: `/v2/*`

### 版本检查
```
GET /v2/
```
响应: `{"status": "ok"}`

### 镜像操作 (标准 Docker V2 API)

- `GET /v2/<name>/manifests/<reference>` - 获取 Manifest
- `GET /v2/<name>/blobs/<digest>` - 获取 Blob
- `PUT /v2/<name>/manifests/<reference>` - 推送 Manifest
- `POST /v2/<name>/blobs/uploads/` - 开始 Blob 上传
- `PUT /v2/<name>/blobs/uploads/<uuid>` - 完成 Blob 上传
- `DELETE /v2/<name>/manifests/<reference>` - 删除 Manifest
- `DELETE /v2/<name>/blobs/<digest>` - 删除 Blob

---

## 健康检查 API

### Gateway 健康检查
```
GET /health
```

### Web API 健康检查
```
GET /api/v1/health/web-api
```

### Registry 健康检查
```
GET /api/v1/health/registry
```

---

## 错误响应格式

所有错误响应使用统一格式:
```json
{
  "code": "ERROR_CODE",
  "message": "错误描述"
}
```

常见错误码:
- `INVALID_REQUEST` - 请求参数无效
- `NOT_FOUND` - 资源不存在
- `FORBIDDEN` - 无权限访问
- `ALREADY_EXISTS` - 资源已存在
- `NOT_EMPTY` - 资源非空无法删除
- `INTERNAL_ERROR` - 内部服务器错误