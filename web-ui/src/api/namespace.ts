import apiClient from './client';
import {
  Namespace,
  CreateNamespaceRequest,
  UpdateNamespaceRequest,
  PaginationParams,
  PaginatedResponse,
  Repository,
} from './types';

export const namespaceApi = {
  list: async (params: PaginationParams): Promise<PaginatedResponse<Namespace>> => {
    const response = await apiClient.get<PaginatedResponse<Namespace>>('/namespaces', { params });
    return response.data;
  },

  get: async (id: string): Promise<Namespace> => {
    const response = await apiClient.get<Namespace>(`/namespaces/${id}`);
    return response.data;
  },

  create: async (data: CreateNamespaceRequest): Promise<Namespace> => {
    const response = await apiClient.post<Namespace>('/namespaces', data);
    return response.data;
  },

  update: async (id: string, data: UpdateNamespaceRequest): Promise<Namespace> => {
    const response = await apiClient.put<Namespace>(`/namespaces/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/namespaces/${id}`);
  },

  getRepositories: async (id: string): Promise<Repository[]> => {
    const response = await apiClient.get<Repository[]>(`/namespaces/${id}/repos`);
    return response.data;
  },
};