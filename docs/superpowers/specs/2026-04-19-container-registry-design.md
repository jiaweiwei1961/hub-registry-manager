# 私有化容器镜像仓库设计文档

**版本**: 1.0  
**日期**: 2026-04-19  
**状态**: 已批准

---

## 1. 概述

### 1.1 项目背景

设计一个私有化部署的容器镜像仓库，参考 Docker Hub 功能，满足企业内部镜像管理需求。

### 1.2 设计目标

- **核心功能**：支持镜像的上传、下载、删除管理
- **CLI 兼容**：完整支持 `docker pull` / `docker push` 命令
- **Web UI**：提供友好的图形界面操作
- **复制同步**：支持多仓库间的镜像复制和同步
- **私有化部署**：支持企业内部独立部署

### 1.3 非目标

- 漏洞扫描功能
- 与企业 IAM 系统（LDAP/SSO）集成
- 公有云 SaaS 服务

---

## 2. 架构设计

### 2.1 整体架构

采用三层微服务架构：

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Router    │  │   Auth      │  │   Rate Limiter      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Core Services                              │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐  │
│  │  Repository  │ │    Image     │ │      Tag            │  │
│  │   Service    │ │   Service    │ │    Service          │  │
│  └──────────────┘ └──────────────┘ └─────────────────────┘  │
│  ┌──────────────┐ ┌──────────────┐                            │
│  │ Replication  │ │   Audit      │                            │
│  │   Service    │ │   Service    │                            │
│  └──────────────┘ └──────────────┘                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Storage Adapters                            │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐   │
│  │  S3 Adapter  │ │  MinIO       │ │   Local (dev)       │   │
│  └──────────────┘ └──────────────┘ └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 组件职责

| 组件 | 职责 |
|------|------|
| **API Gateway** | 统一入口，处理认证、路由、限流、日志 |
| **Repository Service** | 管理命名空间/仓库的创建、删除、元数据 |
| **Image Service** | 处理镜像层(blob)的存储、检索、垃圾回收 |
| **Tag Service** | 管理标签与镜像Manifest的映射关系 |
| **Replication Service** | 管理镜像复制策略、调度复制任务 |
| **Audit Service** | 记录操作审计日志 |
| **Storage Adapter** | 抽象底层存储，支持S3/MinIO/本地文件系统 |

---

## 3. 数据模型

### 3.1 核心实体关系

```
┌────────────────┐       ┌────────────────┐       ┌────────────────┐
│   Namespace    │1────N│  Repository    │1────N│   Manifest     │
│  (命名空间)    │       │   (仓库)       │       │   (镜像版本)   │
└────────────────┘       └────────────────┘       └───────┬────────┘
         │                                                │
         │                                                N
         │                                         ┌──────┴──────┐
         │                                         │    Blob     │
         │                                         │  (镜像层)   │
         │                                         └─────────────┘
         │
         │                ┌────────────────┐
         └───────────────N│      Tag       │
                          │    (标签)      │
                          └────────────────┘
```

### 3.2 关键数据表（摘要）

详见数据库Schema定义文件。核心表包括：

- `namespaces` - 命名空间（组织/团队隔离）
- `repositories` - 镜像仓库
- `manifests` - 镜像Manifest（版本定义）
- `blobs` - 镜像层(blob)元数据
- `manifest_blobs` - Manifest与Blob关联
- `tags` - 标签管理
- `replication_policies` - 复制策略
- `replication_tasks` - 复制任务
- `registry_endpoints` - 远端Registry配置
- `audit_logs` - 审计日志

---

## 4. API 设计

### 4.1 Docker Registry API（兼容 Docker Client）

支持 Docker Registry HTTP API V2 规范，客户端可使用标准 `docker pull/push` 命令。

关键端点：

```
GET    /v2/                         # 检查registry可用性
HEAD   /v2/<name>/blobs/<digest>   # 检查blob是否存在
GET    /v2/<name>/blobs/<digest>   # 下载blob
POST   /v2/<name>/blobs/uploads/  # 初始化blob上传
PATCH  /v2/<name>/blobs/uploads/<uuid>  # 上传blob分片
PUT    /v2/<name>/blobs/uploads/<uuid>?digest=<digest>  # 完成blob上传
GET    /v2/<name>/manifests/<reference>  # 获取manifest
PUT    /v2/<name>/manifests/<reference>  # 上传manifest
DELETE /v2/<name>/manifests/<reference>  # 删除manifest
DELETE /v2/<name>/blobs/<digest>         # 删除blob
```

### 4.2 Web UI API

#### 认证
```
POST   /api/v1/auth/login              # 登录
POST   /api/v1/auth/logout             # 登出
GET    /api/v1/auth/profile            # 获取当前用户信息
```

#### 命名空间管理
```
GET    /api/v1/namespaces                # 列出命名空间
POST   /api/v1/namespaces                # 创建命名空间
GET    /api/v1/namespaces/:id            # 获取命名空间详情
PUT    /api/v1/namespaces/:id            # 更新命名空间
DELETE /api/v1/namespaces/:id            # 删除命名空间（空时）
```

#### 仓库管理
```
GET    /api/v1/namespaces/:ns/repos      # 列出仓库
POST   /api/v1/namespaces/:ns/repos      # 创建仓库
GET    /api/v1/repos/:id                 # 获取仓库详情
DELETE /api/v1/repos/:id                 # 删除仓库
```

#### 镜像/标签管理
```
GET    /api/v1/repos/:id/tags            # 列出标签
GET    /api/v1/tags/:id                  # 获取标签详情（镜像信息）
DELETE /api/v1/tags/:id                  # 删除标签
POST   /api/v1/tags/:id/retag            # 重新打标签
```

#### Web UI 镜像上传/下载
```
# 上传镜像
POST   /api/v1/repos/:id/upload              # 初始化上传（返回session ID）
PUT    /api/v1/upload/:session/chunk         # 上传分片（支持断点续传）
POST   /api/v1/upload/:session/complete      # 完成上传，创建manifest

# 下载镜像
GET    /api/v1/images/:id/download           # 获取下载链接（临时预签名URL）
GET    /api/v1/images/:id/export             # 导出为 tar 包（docker save 格式）
```

### 4.3 复制/同步 API

#### 远端 Registry 管理
```
GET    /api/v1/registries                    # 列出远端Registry配置
POST   /api/v1/registries                    # 添加远端Registry
GET    /api/v1/registries/:id                # 获取远端Registry详情
PUT    /api/v1/registries/:id                # 更新远端Registry
DELETE /api/v1/registries/:id                # 删除远端Registry
POST   /api/v1/registries/:id/test           # 测试连接
```

#### 复制策略管理
```
GET    /api/v1/replication/policies          # 列出复制策略
POST   /api/v1/replication/policies          # 创建复制策略
GET    /api/v1/replication/policies/:id      # 获取复制策略详情
PUT    /api/v1/replication/policies/:id      # 更新复制策略
DELETE /api/v1/replication/policies/:id      # 删除复制策略
POST   /api/v1/replication/policies/:id/enable   # 启用策略
POST   /api/v1/replication/policies/:id/disable  # 禁用策略
POST   /api/v1/replication/policies/:id/execute  # 手动执行
```

#### 复制任务管理
```
GET    /api/v1/replication/tasks             # 列出复制任务
GET    /api/v1/replication/tasks/:id         # 获取任务详情
GET    /api/v1/replication/tasks/:id/logs     # 获取任务日志
DELETE /api/v1/replication/tasks/:id         # 删除任务（仅已完成/失败）
POST   /api/v1/replication/tasks/:id/stop     # 停止运行中的任务
POST   /api/v1/replication/tasks/:id/retry    # 重试失败任务
```

---

这个包含镜像复制/同步功能的完整设计是否符合你的预期？特别是复制策略的触发方式和冲突解决策略是否满足你的需求？如果确认无误，我将编写完整的设计文档。"""
        }
      }
    ]
  }
],
"request_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}        
