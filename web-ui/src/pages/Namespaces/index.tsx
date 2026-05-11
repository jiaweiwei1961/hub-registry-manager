import React, { useState, useEffect } from 'react';
import {
  Table,
  Button,
  Input,
  Space,
  Modal,
  Form,
  message,
  Popconfirm,
  Tag,
  Card,
  Switch,
} from 'antd';
import { PlusOutlined, SearchOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { namespaceApi } from '../../api/namespace';
import { Namespace, CreateNamespaceRequest, UpdateNamespaceRequest, APIError } from '../../api/types';
import { formatTime } from '../../utils/format';
import { useAuthStore } from '../../store/authStore';
import styles from './Namespaces.module.css';

const Namespaces: React.FC = () => {
  const navigate = useNavigate();
  const currentUser = useAuthStore((state) => state.user);
  const isAdmin = currentUser?.is_admin || false;

  const [data, setData] = useState<Namespace[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ page: 1, page_size: 10, total: 0, total_pages: 0 });
  const [search, setSearch] = useState('');
  const [modalVisible, setModalVisible] = useState(false);
  const [editingNamespace, setEditingNamespace] = useState<Namespace | null>(null);
  const [form] = Form.useForm();

  const fetchData = async (page = 1, pageSize = 10, searchTerm = '') => {
    setLoading(true);
    try {
      const result = await namespaceApi.list({ page, page_size: pageSize, search: searchTerm });
      setData(result.data);
      setPagination(result.pagination);
    } catch {
      message.error('获取数据失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleSearch = () => {
    fetchData(1, pagination.page_size, search);
  };

  const handleTableChange = (page: number, pageSize: number) => {
    fetchData(page, pageSize, search);
  };

  const handleCreate = () => {
    setEditingNamespace(null);
    form.resetFields();
    form.setFieldsValue({ is_public: true }); // 默认公开
    setModalVisible(true);
  };

  const handleEdit = (record: Namespace) => {
    // 权限检查：只有所有者和管理员可以编辑
    if (!isAdmin && record.owner_id !== currentUser?.id) {
      message.warning('您没有权限编辑此命名空间');
      return;
    }
    setEditingNamespace(record);
    form.setFieldsValue({
      name: record.name,
      description: record.description,
      is_public: record.is_public,
    });
    setModalVisible(true);
  };

  const handleDelete = async (id: string) => {
    try {
      await namespaceApi.delete(id);
      message.success('删除成功');
      fetchData(pagination.page, pagination.page_size, search);
    } catch (error) {
      const apiError = error as APIError;
      message.error(apiError.message || '删除失败');
    }
  };

  // 检查是否有删除权限
  const canDelete = (record: Namespace): boolean => {
    return isAdmin || record.owner_id === currentUser?.id;
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      // Switch unchecked 时值可能是 undefined 或 false，都应该表示私有
      const isPublic = values.is_public === true;
      if (editingNamespace) {
        const updateData: UpdateNamespaceRequest = {
          display_name: values.display_name,
          description: values.description,
          is_public: isPublic,
        };
        await namespaceApi.update(editingNamespace.id, updateData);
        message.success('更新成功');
      } else {
        const createData: CreateNamespaceRequest = {
          name: values.name,
          display_name: values.display_name,
          description: values.description,
          is_public: isPublic,
        };
        await namespaceApi.create(createData);
        message.success('创建成功');
      }
      setModalVisible(false);
      fetchData(pagination.page, pagination.page_size, search);
    } catch (error) {
      if (error instanceof Error) {
        return;
      }
      const apiError = error as APIError;
      message.error(apiError.message || '操作失败');
    }
  };

  const columns = [
    {
      title: '名称',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Namespace) => (
        <a onClick={() => navigate(`/namespaces/${record.id}`)}>
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
      title: '仓库数',
      dataIndex: 'repository_count',
      key: 'repository_count',
    },
    {
      title: '镜像数量',
      dataIndex: 'image_count',
      key: 'image_count',
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
    {
      title: '操作',
      key: 'action',
      render: (_: unknown, record: Namespace) => {
        const hasPermission = canDelete(record);
        // 非所有者和管理员不显示操作按钮
        if (!hasPermission) {
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
              title="确定要删除此命名空间吗?"
              description="删除后无法恢复"
              onConfirm={() => handleDelete(record.id)}
              okText="确定"
              cancelText="取消"
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
              placeholder="搜索命名空间"
              prefix={<SearchOutlined />}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onPressEnter={handleSearch}
              style={{ width: 200 }}
            />
            <Button type="primary" onClick={handleSearch}>
              搜索
            </Button>
          </Space>
          <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>
            创建命名空间
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          pagination={{
            current: pagination.page,
            pageSize: pagination.page_size,
            total: pagination.total,
            onChange: handleTableChange,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条`,
          }}
        />
      </Card>

      <Modal
        title={editingNamespace ? '编辑命名空间' : '创建命名空间'}
        open={modalVisible}
        onOk={handleModalOk}
        onCancel={() => setModalVisible(false)}
        okText="确定"
        cancelText="取消"
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="name"
            label="名称"
            extra="只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾"
            rules={[
              { required: true, message: '请输入名称' },
              {
                pattern: /^[a-z0-9]+([._-][a-z0-9]+)*$/,
                message: '名称只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾',
              },
              { min: 2, max: 255, message: '名称长度必须在2-255个字符之间' },
            ]}
          >
            <Input disabled={!!editingNamespace} placeholder="命名空间名称" />
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

export default Namespaces;