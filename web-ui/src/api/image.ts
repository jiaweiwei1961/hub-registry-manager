import apiClient from './client';
import { ImageInfo } from './types';

export const imageApi = {
  // 获取镜像列表
  list: async (): Promise<{ data: ImageInfo[] }> => {
    const response = await apiClient.get<{ data: ImageInfo[] }>('/images/list');
    return response.data;
  },

  // 导出/下载镜像
  export: async (namespace: string, repository: string, tag: string): Promise<Blob> => {
    const response = await apiClient.get('/images/export', {
      params: { namespace, repository, tag },
      responseType: 'blob',
    });
    return response.data;
  },
};