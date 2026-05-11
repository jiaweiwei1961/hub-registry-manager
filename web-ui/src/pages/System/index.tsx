import React, { useEffect, useState } from 'react';
import { Card, Descriptions, Tag, Spin, Row, Col, message } from 'antd';
import { CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import axios from 'axios';
import apiClient from '../../api/client';
import { systemApi } from '../../api/repository';
import styles from './System.module.css';

interface ServiceHealth {
  name: string;
  status: 'healthy' | 'unhealthy';
}

interface SystemInfo {
  version: string;
  environment: string;
  api_version: string;
  update_time: string;
}

const System: React.FC = () => {
  const [services, setServices] = useState<ServiceHealth[]>([]);
  const systemInfo: SystemInfo = {
    version: 'v1.0.0',
    environment: 'Docker',
    api_version: 'V2',
    update_time: '2026-04-27',
  };
  const [stats, setStats] = useState<{
    total_repositories: number;
    total_namespaces: number;
    total_images: number;
    total_pull_count: number;
  } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkHealth = async () => {
      const results: ServiceHealth[] = [];

      try {
        const gatewayRes = await axios.get('/health', { timeout: 5000 });
        results.push({
          name: 'Gateway',
          status: gatewayRes.status === 200 ? 'healthy' : 'unhealthy',
        });
      } catch {
        results.push({ name: 'Gateway', status: 'unhealthy' });
      }

      try {
        const webApiRes = await apiClient.get('/health/web-api', { timeout: 5000 });
        results.push({
          name: 'Web API',
          status: webApiRes.status === 200 ? 'healthy' : 'unhealthy',
        });
      } catch {
        results.push({ name: 'Web API', status: 'unhealthy' });
      }

      try {
        const registryRes = await apiClient.get('/health/registry', { timeout: 5000 });
        results.push({
          name: 'Registry Core',
          status: registryRes.status === 200 ? 'healthy' : 'unhealthy',
        });
      } catch {
        results.push({ name: 'Registry Core', status: 'unhealthy' });
      }

      try {
        const minioRes = await apiClient.get('/health/minio', { timeout: 5000 });
        results.push({
          name: 'MinIO',
          status: minioRes.status === 200 ? 'healthy' : 'unhealthy',
        });
      } catch {
        results.push({ name: 'MinIO', status: 'unhealthy' });
      }

      try {
        const statsData = await systemApi.getStats();
        setStats(statsData);
        results.push({
          name: 'PostgreSQL',
          status: 'healthy',
        });
        results.push({
          name: 'Redis',
          status: 'healthy',
        });
      } catch {
        results.push({ name: 'PostgreSQL', status: 'unhealthy' });
        results.push({ name: 'Redis', status: 'unhealthy' });
        message.error('无法获取系统统计信息');
      }

      setServices(results);
      setLoading(false);
    };

    checkHealth();
  }, []);

  if (loading) {
    return (
      <div style={{ padding: 24, textAlign: 'center' }}>
        <Spin size="large" />
      </div>
    );
  }

  const healthyCount = services.filter(s => s.status === 'healthy').length;
  const unhealthyCount = services.filter(s => s.status === 'unhealthy').length;

  return (
    <div className={styles.container}>
      {/* 系统健康状态 */}
      <Card title="系统健康状态" extra={
        <Tag color={unhealthyCount === 0 ? 'green' : 'orange'}>
          {healthyCount}/{services.length} 正常
        </Tag>
      }>
          <Row gutter={[16, 16]}>
            {services.map((service) => (
              <Col xs={24} sm={12} md={8} key={service.name}>
                <Card size="small">
                  <Descriptions column={1} labelStyle={{ width: 80, minWidth: 80 }}>
                    <Descriptions.Item label="服务名称">
                      <Tag color="blue">{service.name}</Tag>
                    </Descriptions.Item>
                    <Descriptions.Item label="状态">
                      {service.status === 'healthy' ? (
                        <Tag color="green" icon={<CheckCircleOutlined />}>
                          正常
                        </Tag>
                      ) : (
                        <Tag color="red" icon={<CloseCircleOutlined />}>
                          异常
                        </Tag>
                      )}
                    </Descriptions.Item>
                  </Descriptions>
                </Card>
              </Col>
            ))}
          </Row>
        </Card>

      {stats && (
        <Card title="系统统计" style={{ marginTop: 16 }}>
          <Row gutter={[16, 16]}>
            <Col xs={12} sm={6}>
              <Descriptions column={1}>
                <Descriptions.Item label="命名空间">{stats.total_namespaces}</Descriptions.Item>
              </Descriptions>
            </Col>
            <Col xs={12} sm={6}>
              <Descriptions column={1}>
                <Descriptions.Item label="仓库数">{stats.total_repositories}</Descriptions.Item>
              </Descriptions>
            </Col>
            <Col xs={12} sm={6}>
              <Descriptions column={1}>
                <Descriptions.Item label="镜像数">{stats.total_images}</Descriptions.Item>
              </Descriptions>
            </Col>
            <Col xs={12} sm={6}>
              <Descriptions column={1}>
                <Descriptions.Item label="下载次数">{stats.total_pull_count}</Descriptions.Item>
              </Descriptions>
            </Col>
          </Row>
        </Card>
      )}

      <Card title="系统信息" style={{ marginTop: 16 }}>
        <Descriptions column={2}>
          <Descriptions.Item label="版本">{systemInfo.version}</Descriptions.Item>
          <Descriptions.Item label="运行环境">{systemInfo.environment}</Descriptions.Item>
          <Descriptions.Item label="API版本">{systemInfo.api_version}</Descriptions.Item>
          <Descriptions.Item label="更新时间">{systemInfo.update_time}</Descriptions.Item>
        </Descriptions>
      </Card>
    </div>
  );
};

export default System;