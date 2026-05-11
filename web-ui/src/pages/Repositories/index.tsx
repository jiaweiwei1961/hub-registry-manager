import React, { useState, useEffect } from 'react';
import { Table, Input, Space, Card, Tag, message, Spin, Button, Modal, Popconfirm, Form, Select, Switch } from 'antd';
import { SearchOutlined, DeleteOutlined, PlusOutlined, EditOutlined } from '@ant-design/icons';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { repositoryApi } from '../../api/repository';
import { namespaceApi } from '../../api/namespace';
import { Repository, Namespace } from '../../api/types';
import { formatTime } from '../../utils/format';
import { useAuthStore } from '../../store/authStore';
import styles from './Repositories.module.css';

const Repositories: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuthStore();
  const isAdmin = user?.is_admin || false;
  const [data, setData] = useState<Repository[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
    total: 0,
  });

  // 创建/编辑仓库相关状态
  const [createModalVisible, setCreateModalVisible] = useState(false);
  const [editingRepo, setEditingRepo] = useState<Repository | null>(null);
  const [namespaces, setNamespaces] = useState<Namespace[]>([]);
  const [createForm] = Form.useForm();

  // 筛选状态 - 从 URL 参数初始化
  const [namespaceFilter, setNamespaceFilter] = useState<string | undefined>(() => {
    const nsIdFromUrl = searchParams.get('namespace_id');
    return nsIdFromUrl || undefined;
  });

  const fetchData = async (page = 1, pageSize = 10) => {
    setLoading(true);
    try {
      const result = await repositoryApi.listRepositories({
        page,
        page_size: pageSize,
        search: search || undefined,
        namespace_id: namespaceFilter,
      });
      setData(result.data);
      setPagination({
        current: result.pagination.page,
        pageSize: result.pagination.page_size,
        total: result.pagination.total,
      });
    } catch {
      message.error('获取仓库列表失败');
    } finally {
      setLoading(false);
    }
  };

  const fetchNamespaces = async () => {
    try {
      const result = await namespaceApi.list({ page: 1, page_size: 100 });
      setNamespaces(result.data);
    } catch {
      message.error('获取命名空间列表失败');
    }
  };

  useEffect(() => {
    fetchData();
    fetchNamespaces();
  }, []);

  useEffect(() => {
    fetchData(1, pagination.pageSize);
  }, [namespaceFilter]);

  const handleTableChange = (pag: { current?: number; pageSize?: number }) => {
    fetchData(pag.current || 1, pag.pageSize || 20);
  };

  const handleSearch = () => {
    fetchData(1, pagination.pageSize);
  };

  // 打开创建Modal
  const handleCreate = () => {
    setEditingRepo(null);
    createForm.resetFields();
    createForm.setFieldsValue({ is_public: true });
    setCreateModalVisible(true);
  };

  // 打开编辑Modal
  const handleEdit = (repo: Repository) => {
    setEditingRepo(repo);
    createForm.setFieldsValue({
      namespace_id: repo.namespace_id,
      name: repo.name,
      description: repo.description,
      is_public: repo.is_public,
    });
    setCreateModalVisible(true);
  };

  // 创建/编辑仓库提交
  const handleCreateSubmit = async () => {
    try {
      const values = await createForm.validateFields();
      // Switch unchecked 时值可能是 undefined 或 false，都应该表示私有
      const isPublic = values.is_public === true;
      if (editingRepo) {
        await repositoryApi.updateRepository(editingRepo.id, {
          description: values.description,
          is_public: isPublic,
        });
        message.success('仓库更新成功');
      } else {
        await repositoryApi.createRepository({
          namespace_id: values.namespace_id,
          name: values.name,
          description: values.description,
          is_public: isPublic,
        });
        message.success('仓库创建成功');
      }
      setCreateModalVisible(false);
      fetchData(pagination.current, pagination.pageSize);
    } catch (error) {
      if (error instanceof Error) {
        return;
      }
      message.error('操作失败');
    }
  };

  // 删除仓库
  const handleDeleteRepo = async (id: string) => {
    try {
      await repositoryApi.deleteRepository(id);
      message.success('仓库删除成功');
      fetchData(pagination.current, pagination.pageSize);
    } catch (error: unknown) {
      if (typeof error === 'object' && error !== null && 'response' in error) {
        const errorResp = error as { response?: { data?: { message?: string } } };
        message.error(errorResp.response?.data?.message || '删除失败');
      } else {
        message.error('删除失败');
      }
    }
  };

  // 判断是否有管理权限（是所有者或管理员）
  const canManage = (record: Repository): boolean => {
    if (!user) return false;
    if (isAdmin) return true;
    return record.owner_id === user.id;
  };

  const columns = [
    {
      title: '仓库名',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Repository) => (
        <a onClick={() => navigate(`/repositories/${record.id}`)} style={{ fontWeight: 500, color: '#1890ff' }}>
          {name}
        </a>
      ),
    },
    {
      title: '命名空间',
      dataIndex: 'namespace',
      key: 'namespace',
      render: (namespace: string) => <Tag color="blue">{namespace || 'library'}</Tag>,
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
      width: 100,
      render: (count: number) => <Tag color="green">{count}</Tag>,
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: formatTime,
    },
    {
      title: '操作',
      key: 'action',
      width: 150,
      render: (_: unknown, record: Repository) => {
        // 非所有者和管理员不显示操作按钮
        if (!canManage(record)) {
          return null;
        }
        return (
          <Space>
            <Button
              type="link"
              icon={<EditOutlined />}
              onClick={() => handleEdit(record)}
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
        );
      },
    },
  ];

  return (
    <div className={styles.container}>
      <Card>
        <div className={styles.toolbar}>
          <Space>
            <Input
              placeholder="搜索仓库"
              prefix={<SearchOutlined />}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onPressEnter={handleSearch}
              style={{ width: 200 }}
            />
            <Select
              placeholder="全部命名空间"
              value={namespaceFilter}
              onChange={(value) => setNamespaceFilter(value || undefined)}
              allowClear
              style={{ width: 200 }}
              options={namespaces.map(ns => ({ label: ns.name, value: ns.id }))}
            />
            <Button type="primary" onClick={handleSearch}>
              搜索
            </Button>
          </Space>
          <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>
            创建仓库
          </Button>
        </div>

        {loading ? (
          <div className={styles.loading}>
            <Spin size="large" />
          </div>
        ) : (
          <Table
            columns={columns}
            dataSource={data}
            rowKey="id"
            pagination={{
              current: pagination.current,
              pageSize: pagination.pageSize,
              total: pagination.total,
              showSizeChanger: true,
            }}
            onChange={handleTableChange}
          />
        )}
      </Card>

      {/* 创建/编辑仓库Modal */}
      <Modal
        title={editingRepo ? '编辑仓库' : '创建仓库'}
        open={createModalVisible}
        onOk={handleCreateSubmit}
        onCancel={() => setCreateModalVisible(false)}
        okText="确定"
        cancelText="取消"
        width={600}
      >
        <Form form={createForm} layout="vertical">
          <Form.Item
            name="namespace_id"
            label="命名空间"
            rules={[{ required: true, message: '请选择命名空间' }]}
          >
            <Select
              placeholder="选择命名空间"
              disabled={!!editingRepo}
              options={namespaces.map(ns => ({ label: ns.name, value: ns.id }))}
            />
          </Form.Item>
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
            <Input disabled={!!editingRepo} placeholder="仓库名称" />
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

export default Repositories;