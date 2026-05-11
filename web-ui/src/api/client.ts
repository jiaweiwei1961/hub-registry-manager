import axios from 'axios';
import { APIError } from './types';

const apiClient = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add JWT token
apiClient.interceptors.request.use(
  (config) => {
    // Read from zustand persist storage
    const authStorage = localStorage.getItem('auth-storage');
    if (authStorage) {
      try {
        const parsed = JSON.parse(authStorage);
        const token = parsed?.state?.token;
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
      } catch {
        // Ignore parse errors
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // 401 处理：只在非登录请求时才清除存储并跳转
    if (error.response?.status === 401) {
      // 检查是否是登录请求失败（不跳转，只返回错误）
      const isLoginRequest = error.config?.url?.includes('/auth/login');
      if (!isLoginRequest) {
        localStorage.removeItem('auth-storage');
        window.location.href = '/login';
      }
    }
    const apiError: APIError = error.response?.data || {
      code: 'NETWORK_ERROR',
      message: error.message || '网络请求失败',
    };
    return Promise.reject(apiError);
  }
);

export default apiClient;