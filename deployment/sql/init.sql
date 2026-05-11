-- Hub Registry 数据库初始化脚本
-- 数据库: PostgreSQL 15+

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 用户表
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    display_name VARCHAR(255),
    is_admin BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_users_deleted_at ON users(deleted_at);

-- ============================================
-- 命名空间表
-- ============================================
CREATE TABLE IF NOT EXISTS namespaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255),
    description TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    owner_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_namespaces_owner_id ON namespaces(owner_id);
CREATE INDEX idx_namespaces_deleted_at ON namespaces(deleted_at);

-- ============================================
-- 仓库表
-- ============================================
CREATE TABLE IF NOT EXISTS repositories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    owner_id UUID,
    pull_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_repositories_namespace_name ON repositories(namespace_id, name) WHERE deleted_at IS NULL;
CREATE INDEX idx_repositories_owner_id ON repositories(owner_id);
CREATE INDEX idx_repositories_deleted_at ON repositories(deleted_at);

-- ============================================
-- Blob表（镜像层）
-- ============================================
CREATE TABLE IF NOT EXISTS blobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    digest VARCHAR(71) NOT NULL UNIQUE,
    size BIGINT NOT NULL,
    storage_path VARCHAR(512),
    content_type VARCHAR(255),
    last_accessed TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_blobs_deleted_at ON blobs(deleted_at);

-- ============================================
-- Manifest表
-- ============================================
CREATE TABLE IF NOT EXISTS manifests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL,
    digest VARCHAR(71) NOT NULL,
    media_type VARCHAR(255),
    config_digest VARCHAR(71),
    config_size BIGINT,
    layers_count INT,
    total_size BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_manifests_repo_digest ON manifests(repository_id, digest) WHERE deleted_at IS NULL;
CREATE INDEX idx_manifests_repository_id ON manifests(repository_id);
CREATE INDEX idx_manifests_deleted_at ON manifests(deleted_at);

-- ============================================
-- Tag表
-- ============================================
CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    manifest_id UUID NOT NULL,
    pushed_by VARCHAR(255),
    pushed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_tags_repo_name ON tags(repository_id, name) WHERE deleted_at IS NULL;
CREATE INDEX idx_tags_manifest_id ON tags(manifest_id);
CREATE INDEX idx_tags_deleted_at ON tags(deleted_at);

-- ============================================
-- Manifest-Blob关联表
-- ============================================
CREATE TABLE IF NOT EXISTS manifest_blobs (
    manifest_id UUID NOT NULL,
    blob_id UUID NOT NULL,
    layer_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (manifest_id, blob_id)
);

-- ============================================
-- 复制策略表
-- ============================================
CREATE TABLE IF NOT EXISTS replication_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    source_registry VARCHAR(255) NOT NULL,
    source_namespace VARCHAR(255),
    source_repository VARCHAR(255),
    source_tag_pattern VARCHAR(255),
    dest_registry VARCHAR(255) NOT NULL,
    dest_namespace VARCHAR(255),
    dest_repository VARCHAR(255),
    trigger_type VARCHAR(20) NOT NULL,
    trigger_cron VARCHAR(50),
    trigger_event VARCHAR(50),
    delete_remote BOOLEAN DEFAULT FALSE,
    override BOOLEAN DEFAULT TRUE,
    enabled BOOLEAN DEFAULT TRUE,
    last_trigger_time TIMESTAMP,
    last_success_time TIMESTAMP,
    last_failure_time TIMESTAMP,
    success_count INT DEFAULT 0,
    failure_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_replication_policies_deleted_at ON replication_policies(deleted_at);

-- ============================================
-- 复制任务表
-- ============================================
CREATE TABLE IF NOT EXISTS replication_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID,
    status VARCHAR(20) NOT NULL,
    progress INT DEFAULT 0,
    source_registry VARCHAR(255),
    dest_registry VARCHAR(255),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    total_resources INT DEFAULT 0,
    succeeded_count INT DEFAULT 0,
    failed_count INT DEFAULT 0,
    skipped_count INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_replication_tasks_policy_id ON replication_tasks(policy_id);
CREATE INDEX idx_replication_tasks_deleted_at ON replication_tasks(deleted_at);

-- ============================================
-- 复制任务详情表
-- ============================================
CREATE TABLE IF NOT EXISTS replication_task_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL,
    resource_type VARCHAR(20) NOT NULL,
    source_namespace VARCHAR(255),
    source_repository VARCHAR(255),
    source_tag VARCHAR(255),
    source_digest VARCHAR(71),
    status VARCHAR(20),
    dest_namespace VARCHAR(255),
    dest_repository VARCHAR(255),
    dest_tag VARCHAR(255),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    bytes_transferred BIGINT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_replication_task_details_task_id ON replication_task_details(task_id);
CREATE INDEX idx_replication_task_details_deleted_at ON replication_task_details(deleted_at);

-- ============================================
-- Registry端点配置表
-- ============================================
CREATE TABLE IF NOT EXISTS registry_endpoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    url VARCHAR(512) NOT NULL,
    type VARCHAR(20),
    auth_type VARCHAR(20),
    username VARCHAR(255),
    password VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,
    insecure_skip_verify BOOLEAN DEFAULT FALSE,
    timeout_seconds INT DEFAULT 30,
    is_enabled BOOLEAN DEFAULT TRUE,
    last_test_time TIMESTAMP,
    last_test_result BOOLEAN,
    last_error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_registry_endpoints_deleted_at ON registry_endpoints(deleted_at);

-- ============================================
-- 审计日志表
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP,
    action VARCHAR(50),
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    user_name VARCHAR(255),
    ip_address VARCHAR(45),
    status VARCHAR(20),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_deleted_at ON audit_logs(deleted_at);

-- ============================================
-- 外键约束
-- ============================================
ALTER TABLE namespaces ADD CONSTRAINT fk_namespace_owner
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE repositories ADD CONSTRAINT fk_repository_namespace
    FOREIGN KEY (namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE;

ALTER TABLE repositories ADD CONSTRAINT fk_repository_owner
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE manifests ADD CONSTRAINT fk_manifest_repository
    FOREIGN KEY (repository_id) REFERENCES repositories(id) ON DELETE CASCADE;

ALTER TABLE tags ADD CONSTRAINT fk_tag_repository
    FOREIGN KEY (repository_id) REFERENCES repositories(id) ON DELETE CASCADE;

ALTER TABLE tags ADD CONSTRAINT fk_tag_manifest
    FOREIGN KEY (manifest_id) REFERENCES manifests(id) ON DELETE CASCADE;

ALTER TABLE manifest_blobs ADD CONSTRAINT fk_manifest_blob_manifest
    FOREIGN KEY (manifest_id) REFERENCES manifests(id) ON DELETE CASCADE;

ALTER TABLE manifest_blobs ADD CONSTRAINT fk_manifest_blob_blob
    FOREIGN KEY (blob_id) REFERENCES blobs(id) ON DELETE CASCADE;

ALTER TABLE replication_tasks ADD CONSTRAINT fk_replication_task_policy
    FOREIGN KEY (policy_id) REFERENCES replication_policies(id) ON DELETE SET NULL;

ALTER TABLE replication_task_details ADD CONSTRAINT fk_replication_detail_task
    FOREIGN KEY (task_id) REFERENCES replication_tasks(id) ON DELETE CASCADE;

-- ============================================
-- 初始数据
-- ============================================

-- 创建默认管理员账户
-- 密码: admin123 (bcrypt哈希)
INSERT INTO users (username, password_hash, email, display_name, is_admin, is_active)
VALUES (
    'admin',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    'admin@hub-registry.local',
    '系统管理员',
    TRUE,
    TRUE
) ON CONFLICT (username) DO NOTHING;

-- 创建默认公共命名空间
INSERT INTO namespaces (name, display_name, description, is_public)
VALUES (
    'library',
    '公共镜像库',
    '公共镜像仓库，所有用户可访问',
    TRUE
) ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 更新触发器
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表创建更新触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_namespaces_updated_at BEFORE UPDATE ON namespaces
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repositories_updated_at BEFORE UPDATE ON repositories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blobs_updated_at BEFORE UPDATE ON blobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_manifests_updated_at BEFORE UPDATE ON manifests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tags_updated_at BEFORE UPDATE ON tags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_replication_policies_updated_at BEFORE UPDATE ON replication_policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_replication_tasks_updated_at BEFORE UPDATE ON replication_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_replication_task_details_updated_at BEFORE UPDATE ON replication_task_details
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_registry_endpoints_updated_at BEFORE UPDATE ON registry_endpoints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audit_logs_updated_at BEFORE UPDATE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 完成提示
-- ============================================
-- 数据库初始化完成
-- 默认管理员: admin / admin123
-- 请在生产环境中修改默认密码