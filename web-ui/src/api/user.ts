import apiClient from './client';
import { User } from './types';

export interface CreateUserRequest {
  username: string;
  password: string;
  display_name?: string;
  email?: string;
  is_admin?: boolean;
}

export interface UpdateUserRequest {
  display_name?: string;
  email?: string;
  is_admin?: boolean;
  is_active?: boolean;
  password?: string;
}

export interface UserListResponse {
  data: User[];
  pagination: {
    page: number;
    page_size: number;
    total: number;
    total_pages: number;
  };
}

export const userApi = {
  list: async (params?: { page?: number; page_size?: number; search?: string }): Promise<UserListResponse> => {
    const response = await apiClient.get<UserListResponse>('/users', { params });
    return response.data;
  },

  get: async (id: string): Promise<User> => {
    const response = await apiClient.get<User>(`/users/${id}`);
    return response.data;
  },

  create: async (data: CreateUserRequest): Promise<User> => {
    const response = await apiClient.post<User>('/users', data);
    return response.data;
  },

  update: async (id: string, data: UpdateUserRequest): Promise<User> => {
    const response = await apiClient.put<User>(`/users/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/users/${id}`);
  },
};