import axios from 'axios';
import apiClient from './client';
import { Tag, SystemStats, Repository, CreateRepositoryRequest, UpdateRepositoryRequest, ReplicationPolicy, ReplicationTask, CreateReplicationPolicyRequest, UpdateReplicationPolicyRequest, RegistryConfig } from './types';

export const repositoryApi = {
  getTags: async (id: string): Promise<Tag[]> => {
    const response = await apiClient.get<Tag[]>(`/repos/${id}/tags`);
    return response.data;
  },

  // 获取仓库列表（从web-api）
  listRepositories: async (params?: { namespace_id?: string; search?: string; page?: number; page_size?: number }): Promise<{ data: Repository[]; pagination: { total: number; page: number; page_size: number; total_pages: number } }> => {
    const response = await apiClient.get('/repositories', { params });
    return response.data;
  },

  // 获取单个仓库详情
  getRepository: async (id: string): Promise<Repository> => {
    const response = await apiClient.get(`/repositories/${id}`);
    return response.data;
  },

  // 创建仓库
  createRepository: async (data: CreateRepositoryRequest): Promise<Repository> => {
    const response = await apiClient.post('/repositories', data);
    return response.data;
  },

  // 更新仓库
  updateRepository: async (id: string, data: UpdateRepositoryRequest): Promise<Repository> => {
    const response = await apiClient.put(`/repositories/${id}`, data);
    return response.data;
  },

  // 删除仓库
  deleteRepository: async (id: string): Promise<void> => {
    await apiClient.delete(`/repositories/${id}`);
  },

  // 删除标签
  deleteTag: async (repoId: string, tagId: string): Promise<void> => {
    await apiClient.delete(`/repos/${repoId}/tags/${tagId}`);
  },
};

export const systemApi = {
  getStats: async (): Promise<SystemStats> => {
    const response = await apiClient.get<SystemStats>('/system/stats');
    return response.data;
  },

  getRegistryConfig: async (): Promise<RegistryConfig> => {
    const response = await apiClient.get<RegistryConfig>('/system/config');
    return response.data;
  },
};

export const replicationApi = {
  // 获取复制策略列表
  listPolicies: async (): Promise<{ data: ReplicationPolicy[] }> => {
    const response = await apiClient.get('/replication/policies');
    return response.data;
  },

  // 创建复制策略
  createPolicy: async (data: CreateReplicationPolicyRequest): Promise<ReplicationPolicy> => {
    const response = await apiClient.post('/replication/policies', data);
    return response.data;
  },

  // 获取策略详情
  getPolicy: async (id: string): Promise<ReplicationPolicy> => {
    const response = await apiClient.get(`/replication/policies/${id}`);
    return response.data;
  },

  // 更新策略
  updatePolicy: async (id: string, data: UpdateReplicationPolicyRequest): Promise<ReplicationPolicy> => {
    const response = await apiClient.put(`/replication/policies/${id}`, data);
    return response.data;
  },

  // 删除策略
  deletePolicy: async (id: string): Promise<void> => {
    await apiClient.delete(`/replication/policies/${id}`);
  },

  // 执行策略
  executePolicy: async (id: string): Promise<{ message: string; task_id: string; status: string }> => {
    const response = await apiClient.post(`/replication/policies/${id}/execute`);
    return response.data;
  },

  // 获取任务列表
  listTasks: async (): Promise<{ data: ReplicationTask[] }> => {
    const response = await apiClient.get('/replication/tasks');
    return response.data;
  },

  // 获取单个任务状态
  getTask: async (id: string): Promise<{ data: ReplicationTask }> => {
    const response = await apiClient.get(`/replication/tasks/${id}`);
    return response.data;
  },
};

// Docker Registry API (v2) - 直接调用 /v2 端点，不走 /api/v1
const registryClient = axios.create({
  baseURL: '',
  timeout: 30000,
});

export const registryApi = {
  catalog: async (n?: number): Promise<{ repositories: string[] }> => {
    const params = n ? { n } : {};
    const response = await registryClient.get<{ repositories: string[] }>('/v2/_catalog', { params });
    return response.data;
  },
};