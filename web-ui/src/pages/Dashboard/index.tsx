import React, { useEffect, useState } from 'react';
import { Card, Row, Col, Table, Tag, Spin, message, Typography, Statistic, Button } from 'antd';
import { useNavigate } from 'react-router-dom';
import {
  ContainerOutlined,
  AppstoreOutlined,
  CloudOutlined,
  DownloadOutlined,
  ArrowRightOutlined,
  DatabaseOutlined,
} from '@ant-design/icons';
import { systemApi } from '../../api/repository';
import { namespaceApi } from '../../api/namespace';
import { SystemStats, Namespace } from '../../api/types';
import { formatTime } from '../../utils/format';
import styles from './Dashboard.module.css';

const { Title, Text } = Typography;

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [namespaces, setNamespaces] = useState<Namespace[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const statsData = await systemApi.getStats();
        setStats(statsData);
      } catch {
        console.error('获取系统统计失败');
      }

      try {
        const nsData = await namespaceApi.list({ page: 1, page_size: 5 });
        setNamespaces(nsData.data);
      } catch {
        message.error('获取命名空间列表失败');
      }

      setLoading(false);
    };
    fetchData();
  }, []);

  // Registry 地址：使用浏览器实际访问的完整地址
  const registryAddr = window.location.host;

  if (loading) {
    return (
      <div className={styles.loading}>
        <Spin size="large" />
      </div>
    );
  }

  const nsColumns = [
    {
      title: '名称',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Namespace) => (
        <a onClick={() => navigate(`/namespaces/${record.id}`)} className={styles.namespaceLink}>
          <Tag color="blue">{name}</Tag>
        </a>
      ),
    },
    {
      title: '所有者',
      dataIndex: 'owner_name',
      key: 'owner_name',
      render: (owner: string) => owner || '-',
    },
    {
      title: '仓库数',
      dataIndex: 'repository_count',
      key: 'repository_count',
      align: 'center' as const,
    },
    {
      title: '镜像数量',
      dataIndex: 'image_count',
      key: 'image_count',
      align: 'center' as const,
    },
    {
      title: '下载次数',
      dataIndex: 'pull_count',
      key: 'pull_count',
      align: 'center' as const,
      render: (count: number) => count || 0,
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: formatTime,
    },
  ];

  return (
    <div className={styles.dashboard}>
      {/* Stats Row */}
      <Row gutter={[24, 24]} className={styles.statsRow}>
        <Col xs={24} sm={12} lg={6}>
          <Card className={styles.statCard} onClick={() => navigate('/namespaces')} hoverable>
            <Statistic
              title="命名空间"
              value={stats?.total_namespaces || namespaces.length || 0}
              prefix={<AppstoreOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className={styles.statCard} onClick={() => navigate('/repositories')} hoverable>
            <Statistic
              title="镜像仓库"
              value={stats?.total_repositories || 0}
              prefix={<ContainerOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className={styles.statCard} onClick={() => navigate('/repositories')} hoverable>
            <Statistic
              title="镜像数量"
              value={stats?.total_images || 0}
              prefix={<CloudOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className={styles.statCard} onClick={() => navigate('/repositories')} hoverable>
            <Statistic
              title="下载次数"
              value={stats?.total_pull_count || 0}
              prefix={<DownloadOutlined />}
            />
          </Card>
        </Col>
      </Row>

      {/* Main Content */}
      <Row gutter={[24, 24]} className={styles.mainContent}>
        <Col xs={24}>
          <Card
            title={
              <div className={styles.cardTitle}>
                <DatabaseOutlined />
                <span>最近命名空间</span>
              </div>
            }
            className={styles.tableCard}
            extra={
              <Button type="link" onClick={() => navigate('/namespaces')} className={styles.viewAllLink}>
                查看全部 <ArrowRightOutlined />
              </Button>
            }
          >
            <Table
              columns={nsColumns}
              dataSource={namespaces}
              rowKey="id"
              pagination={false}
              size="small"
            />
          </Card>
        </Col>

        <Col xs={24}>
          <Card
            title="快速开始"
            className={styles.guideCard}
          >
            <div className={styles.guideSection}>
              <Title level={5}>Registry 地址</Title>
              <Text copyable className={styles.registryAddr}>{registryAddr}</Text>
            </div>

            <div className={styles.guideSection}>
              <Title level={5}>1. 登录 Registry</Title>
              <pre className={styles.codeBlock}>
                <code>docker login {registryAddr}</code>
              </pre>
            </div>

            <div className={styles.guideSection}>
              <Title level={5}>2. 推送镜像</Title>
              <pre className={styles.codeBlock}>
                <code>docker push {registryAddr}/&lt;namespace&gt;/&lt;repo&gt;:&lt;tag&gt;</code>
              </pre>
            </div>

            <div className={styles.guideSection}>
              <Title level={5}>3. 拉取镜像</Title>
              <pre className={styles.codeBlock}>
                <code>docker pull {registryAddr}/&lt;namespace&gt;/&lt;repo&gt;:&lt;tag&gt;</code>
              </pre>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;
