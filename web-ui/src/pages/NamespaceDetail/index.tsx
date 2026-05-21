import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, Descriptions, Tag, Button, Space, Table, message, Spin, Typography, Modal, Form, Input, Switch, Popconfirm } from 'antd';
import { ArrowLeftOutlined, PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { namespaceApi } from '../../api/namespace';
import { repositoryApi } from '../../api/repository';
import { Namespace, Repository } from '../../api/types';
import { formatTime } from '../../utils/format';
import { useAuthStore } from '../../store/authStore';
import styles from './NamespaceDetail.module.css';

const { Text, Title } = Typography;

const NamespaceDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const isAdmin = user?.is_admin || false;
  const [namespace, setNamespace] = useState<Namespace | null>(null);
  const [repositories, setRepositories] = useState<Repository[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingRepos, setLoadingRepos] = useState(false);
  const [createModalVisible, setCreateModalVisible] = useState(false);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [editingRepo, setEditingRepo] = useState<Repository | null>(null);
  const [createForm] = Form.useForm();
  const [editForm] = Form.useForm();
  const [searchText, setSearchText] = useState('');
  const [repoPagination, setRepoPagination] = useState({
    current: 1,
    pageSize: 5,
    total: 0,
  });

  // 判断是否有管理权限（是所有者或管理员）
  const canManage = () => {
    if (!namespace || !user) return false;
    if (isAdmin) return true;
    return namespace.owner_id === user.id;
  };

  useEffect(() => {
    if (!id) return;
    loadNamespace();
    loadRepositories(1, 5, '');
  }, [id]);

  const loadNamespace = async () => {
    setLoading(true);
    try {
      const data = await namespaceApi.get(id!);
      setNamespace(data);
    } catch {
      message.error('获取命名空间详情失败');
      navigate('/namespaces');
    } finally {
      setLoading(false);
    }
  };

  const loadRepositories = async (page = 1, pageSize = 5, search = '') => {
    setLoadingRepos(true);
    try {
      const result = await repositoryApi.listRepositories({
        namespace_id: id!,
        page,
        page_size: pageSize,
        search: search || undefined,
      });
      setRepositories(result.data);
      setRepoPagination({
        current: result.pagination.page,
        pageSize: result.pagination.page_size,
        total: result.pagination.total,
      });
    } catch {
      message.error('获取仓库列表失败');
    } finally {
      setLoadingRepos(false);
    }
  };

  const handleSearch = (value: string) => {
    setSearchText(value);
    loadRepositories(1, repoPagination.pageSize, value);
  };

  const handleRepoClick = (repoId: string) => {
    navigate(`/repositories/${repoId}`);
  };

  const handleCreateRepo = () => {
    createForm.resetFields();
    createForm.setFieldsValue({ is_public: true });
    setCreateModalVisible(true);
  };

  const handleCreateSubmit = async () => {
    try {
      const values = await createForm.validateFields();
      // Switch unchecked 时值可能是 undefined 或 false，都应该表示私有
      const isPublic = values.is_public === true;
      await repositoryApi.createRepository({
        namespace_id: id!,
        name: values.name,
        description: values.description,
        is_public: isPublic,
      });
      message.success('仓库创建成功');
      setCreateModalVisible(false);
      loadRepositories(repoPagination.current, repoPagination.pageSize, searchText);
      loadNamespace();
    } catch {
      message.error('创建仓库失败');
    }
  };

  const handleRepoTableChange = (pag: { current?: number; pageSize?: number }) => {
    loadRepositories(pag.current || 1, pag.pageSize || 5, searchText);
  };

  const handleEditRepo = (repo: Repository) => {
    setEditingRepo(repo);
    editForm.setFieldsValue({
      name: repo.name,
      description: repo.description,
      is_public: repo.is_public,
    });
    setEditModalVisible(true);
  };

  const handleEditSubmit = async () => {
    try {
      const values = await editForm.validateFields();
      // Switch unchecked 时值可能是 undefined 或 false，都应该表示私有
      const isPublic = values.is_public === true;
      await repositoryApi.updateRepository(editingRepo!.id, {
        description: values.description,
        is_public: isPublic,
      });
      message.success('仓库更新成功');
      setEditModalVisible(false);
      loadRepositories(repoPagination.current, repoPagination.pageSize, searchText);
      loadNamespace();
    } catch {
      message.error('更新仓库失败');
    }
  };

  const handleDeleteRepo = async (repoId: string) => {
    try {
      await repositoryApi.deleteRepository(repoId);
      message.success('仓库删除成功');
      // 如果当前页只有一条数据且不是第一页，跳转到前一页
      const shouldGoToPrevPage = repositories.length === 1 && repoPagination.current > 1;
      const newPage = shouldGoToPrevPage ? repoPagination.current - 1 : repoPagination.current;
      loadRepositories(newPage, repoPagination.pageSize, searchText);
      loadNamespace();
    } catch {
      message.error('删除仓库失败');
    }
  };

  if (loading) {
    return (
      <div style={{ padding: 24, textAlign: 'center' }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!namespace) {
    return null;
  }

  const repoColumns = [
    {
      title: '仓库名',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Repository) => (
        <a onClick={() => handleRepoClick(record.id)}>
          {name}
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
      title: '公开',
      dataIndex: 'is_public',
      key: 'is_public',
      render: (isPublic: boolean) => (
        <Tag color={isPublic ? 'green' : 'orange'}>
          {isPublic ? '公开' : '私有'}
        </Tag>
      ),
    },
    {
      title: '镜像数',
      dataIndex: 'image_count',
      key: 'image_count',
      render: (count: number) => count || 0,
    },
    {
      title: '下载次数',
      dataIndex: 'pull_count',
      key: 'pull_count',
      render: (count: number) => count || 0,
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: formatTime,
    },
    ...(canManage() ? [{
      title: '操作',
      key: 'action',
      width: 150,
      render: (_: unknown, record: Repository) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditRepo(record)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定删除此仓库?"
            description="删除后无法恢复，所有镜像版本将一并删除"
            onConfirm={() => handleDeleteRepo(record.id)}
          >
            <Button type="link" danger icon={<DeleteOutlined />}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    }] : []),
  ];

  return (
    <div className={styles.container}>
      {/* 顶部导航 */}
      <div className={styles.header}>
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate(-1)}>
          返回
        </Button>
        <Title level={4} style={{ margin: 0 }}>
          {namespace.name}
        </Title>
      </div>

      {/* 命名空间基本信息 */}
      <Card className={styles.infoCard}>
        <Descriptions column={4}>
          <Descriptions.Item label="命名空间名称">
            {namespace.name}
          </Descriptions.Item>
          <Descriptions.Item label="所有者">{namespace.owner_name || '-'}</Descriptions.Item>
          <Descriptions.Item label="公开">
            <Tag color={namespace.is_public ? 'green' : 'orange'}>
              {namespace.is_public ? '公开' : '私有'}
            </Tag>
          </Descriptions.Item>
          <Descriptions.Item label="仓库数">{namespace.repository_count || 0}</Descriptions.Item>
          <Descriptions.Item label="镜像数量">{namespace.image_count || 0}</Descriptions.Item>
          <Descriptions.Item label="下载次数">{namespace.pull_count || 0}</Descriptions.Item>
          <Descriptions.Item label="创建时间">{formatTime(namespace.created_at)}</Descriptions.Item>
          <Descriptions.Item label="更新时间">{formatTime(namespace.updated_at)}</Descriptions.Item>
        </Descriptions>
        <div style={{ marginTop: 16 }}>
          <Text strong>描述：</Text>
          <Text>{namespace.description || '-'}</Text>
        </div>
      </Card>

      {/* 仓库列表 */}
      <Card title="仓库列表" extra={
        <Space>
          <Input.Search
            placeholder="搜索仓库"
            allowClear
            onSearch={handleSearch}
            style={{ width: 200 }}
          />
          {canManage() && (
            <Button type="primary" icon={<PlusOutlined />} onClick={handleCreateRepo}>
              创建仓库
            </Button>
          )}
          <Button onClick={() => loadRepositories(repoPagination.current, repoPagination.pageSize, searchText)}>刷新</Button>
        </Space>
      }>
        {loadingRepos ? (
          <Spin style={{ display: 'block', textAlign: 'center', padding: 40 }} />
        ) : repositories.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40 }}>
            <Text type="secondary">{searchText ? '未找到匹配的仓库' : '该命名空间下暂无仓库'}</Text>
          </div>
        ) : (
          <Table
            dataSource={repositories}
            columns={repoColumns}
            rowKey="id"
            loading={loadingRepos}
            pagination={{
              current: repoPagination.current,
              pageSize: repoPagination.pageSize,
              total: repoPagination.total,
              onChange: (page, pageSize) => handleRepoTableChange({ current: page, pageSize }),
              showSizeChanger: true,
              pageSizeOptions: ['5', '10', '20'],
              showTotal: (total) => `共 ${total} 条`,
            }}
            size="middle"
          />
        )}
      </Card>

      {/* 创建仓库Modal */}
      <Modal
        title="创建仓库"
        open={createModalVisible}
        onOk={handleCreateSubmit}
        onCancel={() => setCreateModalVisible(false)}
        okText="确定"
        cancelText="取消"
      >
        <Form form={createForm} layout="vertical">
          <Form.Item
            name="name"
            label="仓库名"
            extra="只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾"
            rules={[
              { required: true, message: '请输入仓库名' },
              {
                pattern: /^[a-z0-9]+([._-][a-z0-9]+)*$/,
                message: '仓库名只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾',
              },
              { min: 2, max: 255, message: '仓库名长度必须在2-255个字符之间' },
            ]}
          >
            <Input placeholder="仓库名称" />
          </Form.Item>
          <Form.Item name="description" label="描述">
            <Input.TextArea placeholder="描述信息" rows={3} />
          </Form.Item>
          <Form.Item name="is_public" label="公开访问" valuePropName="checked">
            <Switch checkedChildren="公开" unCheckedChildren="私有" />
          </Form.Item>
        </Form>
      </Modal>

      {/* 编辑仓库Modal */}
      <Modal
        title="编辑仓库"
        open={editModalVisible}
        onOk={handleEditSubmit}
        onCancel={() => setEditModalVisible(false)}
        okText="确定"
        cancelText="取消"
      >
        <Form form={editForm} layout="vertical">
          <Form.Item name="name" label="仓库名">
            <Input disabled placeholder="仓库名称" />
          </Form.Item>
          <Form.Item name="description" label="描述">
            <Input.TextArea placeholder="描述信息" rows={3} />
          </Form.Item>
          <Form.Item name="is_public" label="公开访问" valuePropName="checked">
            <Switch checkedChildren="公开" unCheckedChildren="私有" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default NamespaceDetail;