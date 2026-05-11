import client from './client';

export interface AuditLog {
  id: string;
  user_id: string | null;
  username: string;
  action: string;
  resource_type: string;
  resource_id: string;
  resource_name: string;
  detail: string;
  ip_address: string;
  success: boolean;
  error_message: string;
  created_at: string;
}

export interface AuditLogFilter {
  page?: number;
  page_size?: number;
  user_id?: string;
  username?: string;
  action?: string;
  resource_type?: string;
  resource_name?: string;
  start_time?: string;
  end_time?: string;
  success?: string;
}

export interface AuditAction {
  value: string;
  label: string;
}

export interface AuditResourceType {
  value: string;
  label: string;
}

export interface Pagination {
  page: number;
  page_size: number;
  total: number;
  total_pages: number;
}

export const auditLogApi = {
  // 获取审计日志列表
  list: async (filter: AuditLogFilter = {}) => {
    const params = new URLSearchParams();
    if (filter.page) params.append('page', String(filter.page));
    if (filter.page_size) params.append('page_size', String(filter.page_size));
    if (filter.user_id) params.append('user_id', filter.user_id);
    if (filter.username) params.append('username', filter.username);
    if (filter.action) params.append('action', filter.action);
    if (filter.resource_type) params.append('resource_type', filter.resource_type);
    if (filter.resource_name) params.append('resource_name', filter.resource_name);
    if (filter.start_time) params.append('start_time', filter.start_time);
    if (filter.end_time) params.append('end_time', filter.end_time);
    if (filter.success) params.append('success', filter.success);

    const response = await client.get<{ data: AuditLog[]; pagination: Pagination }>(
      `/audit-logs?${params.toString()}`
    );
    return response.data;
  },

  // 获取审计日志详情
  get: async (id: string) => {
    const response = await client.get<AuditLog>(`/audit-logs/${id}`);
    return response.data;
  },

  // 获取操作类型列表
  getActions: async () => {
    const response = await client.get<{ data: AuditAction[] }>('/audit-logs/actions');
    return response.data.data;
  },

  // 获取资源类型列表
  getResourceTypes: async () => {
    const response = await client.get<{ data: AuditResourceType[] }>('/audit-logs/resource-types');
    return response.data.data;
  },
};
