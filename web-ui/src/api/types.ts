// API Types

export interface User {
  id: string;
  username: string;
  display_name: string;
  email: string;
  is_admin: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Namespace {
  id: string;
  name: string;
  display_name: string;
  description: string;
  is_public: boolean;
  owner_id: string;
  owner_name: string;
  repository_count: number;
  image_count: number;
  pull_count: number;
  created_at: string;
  updated_at: string;
}

export interface Repository {
  id: string;
  name: string;
  namespace_id: string;
  namespace: string;
  full_name: string;
  description: string;
  is_public: boolean;
  owner_id: string;
  owner_name: string;
  pull_count: number;
  image_count: number;
  created_at: string;
  updated_at: string;
  tags?: Tag[];
}

export interface CreateRepositoryRequest {
  namespace_id: string;
  name: string;
  description?: string;
  is_public?: boolean;
}

export interface UpdateRepositoryRequest {
  description?: string;
  is_public?: boolean;
}

export interface Tag {
  id: string;
  name: string;
  repository_id: string;
  manifest_id: string;
  pushed_by: string;
  pushed_at: string;
  created_at: string;
  manifest?: Manifest;
}

export interface Manifest {
  id: string;
  digest: string;
  media_type: string;
  config_digest: string;
  config_size: number;
  layers_count: number;
  total_size: number;
}

export interface SystemStats {
  total_repositories: number;
  total_namespaces: number;
  total_images: number;
  total_pull_count: number;
  storage_used: number;
}

export interface RegistryConfig {
  registry_host: string;
  registry_port: string;
  external_host: string;
  external_port: string;
  full_registry_addr: string;
}

export interface PaginationParams {
  page?: number;
  page_size?: number;
  search?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    page_size: number;
    total: number;
    total_pages: number;
  };
}

export interface APIError {
  code: string;
  message: string;
  detail?: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refresh_token: string;
  expires_in: number;
  user: User;
}

export interface CreateNamespaceRequest {
  name: string;
  display_name?: string;
  description?: string;
  is_public?: boolean;
}

export interface UpdateNamespaceRequest {
  display_name?: string;
  description?: string;
  is_public?: boolean;
}

// 镜像上传下载相关类型
export interface ImageInfo {
  namespace: string;
  repository: string;
  tags: string[];
  size: number;
  created_at: string;
}

export interface UploadResult {
  repository: string;
  tag: string;
  digest: string;
  size: number;
}

export interface UploadResponse {
  code: string;
  message: string;
  data: UploadResult;
}

// 镜像复制相关类型
export interface ReplicationPolicy {
  id: string;
  name: string;
  description: string;
  source_registry: string;
  source_namespace: string;
  source_repository: string;
  source_tag_pattern: string;
  dest_namespace: string;
  dest_repository: string;
  trigger_type: string;
  enabled: boolean;
  last_trigger_time: string;
  created_at: string;
  updated_at: string;
}

export interface ReplicationTask {
  id: string;
  policy_id: string;
  policy_name: string;
  status: string;
  started_at: string;
  ended_at: string;
  total_resources: number;
  succeeded_count: number;
  failed_count: number;
}

export interface CreateReplicationPolicyRequest {
  name: string;
  description?: string;
  source_registry: string;
  source_namespace?: string;
  source_repository?: string;
  source_tag_pattern?: string;
  dest_namespace: string;
  dest_repository?: string;
  trigger_type?: string;
  enabled?: boolean;
}

export interface UpdateReplicationPolicyRequest {
  name?: string;
  description?: string;
  source_registry?: string;
  source_namespace?: string;
  source_repository?: string;
  source_tag_pattern?: string;
  dest_namespace?: string;
  dest_repository?: string;
  trigger_type?: string;
  enabled?: boolean;
}