# 数据库 Schema 说明

## 数据表结构

### users - 用户表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键，自动生成 |
| username | VARCHAR(255) | 用户名，唯一索引 |
| password_hash | VARCHAR(255) | 密码哈希 |
| email | VARCHAR(255) | 邮箱 |
| display_name | VARCHAR(255) | 显示名称 |
| is_admin | BOOLEAN | 是否管理员 |
| is_active | BOOLEAN | 是否激活 |
| last_login_at | TIMESTAMP | 最后登录时间 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### namespaces - 命名空间表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | VARCHAR(255) | 名称，唯一索引 |
| display_name | VARCHAR(255) | 显示名称 |
| description | TEXT | 描述 |
| is_public | BOOLEAN | 是否公开 |
| owner_id | UUID | 所有者ID，索引 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

**注意**: 私有命名空间下的所有仓库必须为私有

### repositories - 仓库表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| namespace_id | UUID | 命名空间ID，复合唯一索引 |
| name | VARCHAR(255) | 仓库名，复合唯一索引 |
| description | TEXT | 描述 |
| is_public | BOOLEAN | 是否公开 |
| owner_id | UUID | 所有者ID，索引 |
| pull_count | BIGINT | 拉取次数 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

**约束**: 
- `(namespace_id, name)` 唯一
- 如果所属命名空间为私有，仓库必须为私有

### tags - 标签表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| repository_id | UUID | 仓库ID，复合唯一索引 |
| name | VARCHAR(255) | 标签名，复合唯一索引 |
| manifest_id | UUID | Manifest ID，索引 |
| pushed_by | VARCHAR(255) | 推送者 |
| pushed_at | TIMESTAMP | 推送时间 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

**约束**: `(repository_id, name)` 唯一

### manifests - Manifest表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| repository_id | UUID | 仓库ID，复合唯一索引 |
| digest | VARCHAR(71) | SHA256摘要，复合唯一索引 |
| media_type | VARCHAR(255) | 媒体类型 |
| config_digest | VARCHAR(71) | 配置摘要 |
| config_size | BIGINT | 配置大小 |
| layers_count | INT | 层数 |
| total_size | BIGINT | 总大小 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

**约束**: `(repository_id, digest)` 唯一

### blobs - Blob表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| digest | VARCHAR(71) | SHA256摘要，唯一索引 |
| size | BIGINT | 大小 |
| storage_path | VARCHAR(512) | 存储路径 |
| content_type | VARCHAR(255) | 内容类型 |
| last_accessed | TIMESTAMP | 最后访问时间 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### manifest_blobs - Manifest-Blob关联表

| 字段 | 类型 | 说明 |
|------|------|------|
| manifest_id | UUID | Manifest ID，主键 |
| blob_id | UUID | Blob ID，主键 |
| layer_order | INT | 层顺序 |
| created_at | TIMESTAMP | 创建时间 |

### replication_policies - 复制策略表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | VARCHAR(255) | 策略名称 |
| description | TEXT | 描述 |
| source_registry | VARCHAR(255) | 源Registry |
| source_namespace | VARCHAR(255) | 源命名空间 |
| source_repository | VARCHAR(255) | 源仓库 |
| source_tag_pattern | VARCHAR(255) | 源标签匹配模式 |
| dest_registry | VARCHAR(255) | 目标Registry |
| dest_namespace | VARCHAR(255) | 目标命名空间 |
| dest_repository | VARCHAR(255) | 目标仓库 |
| trigger_type | VARCHAR(20) | 触发类型: manual/scheduled/event |
| trigger_cron | VARCHAR(50) | Cron表达式 |
| trigger_event | VARCHAR(50) | 触发事件 |
| delete_remote | BOOLEAN | 删除远端 |
| override | BOOLEAN | 覆盖 |
| enabled | BOOLEAN | 启用 |
| last_trigger_time | TIMESTAMP | 最后触发时间 |
| last_success_time | TIMESTAMP | 最后成功时间 |
| last_failure_time | TIMESTAMP | 最后失败时间 |
| success_count | INT | 成功次数 |
| failure_count | INT | 失败次数 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### replication_tasks - 复制任务表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| policy_id | UUID | 策略ID，索引 |
| status | VARCHAR(20) | 状态: pending/running/success/failed/stopped |
| progress | INT | 进度百分比 0-100 |
| source_registry | VARCHAR(255) | 源Registry |
| dest_registry | VARCHAR(255) | 目标Registry |
| started_at | TIMESTAMP | 开始时间 |
| ended_at | TIMESTAMP | 结束时间 |
| total_resources | INT | 总资源数 |
| succeeded_count | INT | 成功数 |
| failed_count | INT | 失败数 |
| skipped_count | INT | 跳过数 |
| error_message | TEXT | 错误信息 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### replication_task_details - 复制任务详情表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| task_id | UUID | 任务ID，索引 |
| resource_type | VARCHAR(20) | 资源类型: image/chart/blob |
| source_namespace | VARCHAR(255) | 源命名空间 |
| source_repository | VARCHAR(255) | 源仓库 |
| source_tag | VARCHAR(255) | 源标签 |
| source_digest | VARCHAR(71) | 源摘要 |
| status | VARCHAR(20) | 状态: success/failed/skipped |
| dest_namespace | VARCHAR(255) | 目标命名空间 |
| dest_repository | VARCHAR(255) | 目标仓库 |
| dest_tag | VARCHAR(255) | 目标标签 |
| started_at | TIMESTAMP | 开始时间 |
| ended_at | TIMESTAMP | 结束时间 |
| bytes_transferred | BIGINT | 传输字节数 |
| error_message | TEXT | 错误信息 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### registry_endpoints - Registry端点配置表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | VARCHAR(255) | 名称，唯一索引 |
| url | VARCHAR(512) | URL |
| type | VARCHAR(20) | 类型: harbor/docker-hub/ecr/acr/generic |
| auth_type | VARCHAR(20) | 认证类型: basic/token/oauth |
| username | VARCHAR(255) | 用户名 |
| password | VARCHAR(255) | 密码 |
| access_token | TEXT | 访问令牌 |
| refresh_token | TEXT | 刷新令牌 |
| insecure_skip_verify | BOOLEAN | 跳过TLS验证 |
| timeout_seconds | INT | 超时时间 |
| is_enabled | BOOLEAN | 启用 |
| last_test_time | TIMESTAMP | 最后测试时间 |
| last_test_result | BOOLEAN | 最后测试结果 |
| last_error_message | TEXT | 最后错误信息 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

### audit_logs - 审计日志表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| timestamp | TIMESTAMP | 时间戳，索引 |
| action | VARCHAR(50) | 操作 |
| resource_type | VARCHAR(50) | 资源类型 |
| resource_id | VARCHAR(255) | 资源ID |
| user_name | VARCHAR(255) | 用户名 |
| ip_address | VARCHAR(45) | IP地址 |
| status | VARCHAR(20) | 状态 |
| details | TEXT | 详情 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| deleted_at | TIMESTAMP | 软删除时间 |

## ER 图

```
┌─────────┐     ┌──────────────┐     ┌─────────────┐
│  users  │────<│ namespaces   │────<│repositories │
└─────────┘     └──────────────┘     └─────────────┘
                                          │
                                          │
                     ┌────────────────────┼────────────────────┐
                     │                    │                    │
              ┌──────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐
              │    tags     │─────<│ manifests   │─────<│   blobs     │
              └─────────────┘      └─────────────┘      └─────────────┘
                                          │
                                          │
                                   ┌──────▼──────┐
                                   │manifest_blobs│
                                   └─────────────┘
```

## 默认账户

部署后默认创建的管理员账户：
- 用户名: `admin`
- 密码: `admin123`

**建议**: 部署后立即修改默认密码