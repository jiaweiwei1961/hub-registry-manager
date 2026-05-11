import React, { useState, useEffect } from 'react';
import { Card, Tabs, Upload, Progress, Select, Input, Button, message, Space, Divider, Typography, Alert, Table, Modal, Form, Switch, Popconfirm, Tag, Badge, Spin } from 'antd';
import { InboxOutlined, CloudUploadOutlined, CheckCircleOutlined, ContainerOutlined, SyncOutlined, PlusOutlined, EditOutlined, DeleteOutlined, PlayCircleOutlined, HistoryOutlined } from '@ant-design/icons';
import type { UploadProps } from 'antd';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { namespaceApi } from '../../api/namespace';
import { replicationApi } from '../../api/repository';
import { ReplicationPolicy, ReplicationTask, Namespace } from '../../api/types';
import styles from './ImageTransfer.module.css';

const { Dragger } = Upload;
const { Text, Title } = Typography;

const ImageTransfer: React.FC = () => {
  const navigate = useNavigate();

  // 上传状态
  const [namespaces, setNamespaces] = useState<Namespace[]>([]);
  const [selectedNamespace, setSelectedNamespace] = useState<string>('');
  const [repositoryName, setRepositoryName] = useState<string>('');
  const [tagName, setTagName] = useState<string>('latest');
  const [uploadProgress, setUploadProgress] = useState<number>(0);
  const [uploading, setUploading] = useState<boolean>(false);
  const [uploadResult, setUploadResult] = useState<any>(null);

  // 复制策略状态
  const [policies, setPolicies] = useState<ReplicationPolicy[]>([]);
  const [tasks, setTasks] = useState<ReplicationTask[]>([]);
  const [loadingPolicies, setLoadingPolicies] = useState(false);
  const [loadingTasks, setLoadingTasks] = useState(false);
  const [policyModalVisible, setPolicyModalVisible] = useState(false);
  const [editingPolicy, setEditingPolicy] = useState<ReplicationPolicy | null>(null);
  const [policyForm] = Form.useForm();

  // 加载命名空间列表
  useEffect(() => {
    loadNamespaces();
    loadPolicies();
    loadTasks();
  }, []);

  const loadNamespaces = async () => {
    try {
      const result = await namespaceApi.list({ page: 1, page_size: 100 });
      setNamespaces(result.data || []);
      if (result.data && result.data.length > 0) {
        setSelectedNamespace(result.data[0].id);
      }
    } catch {
      message.error('加载命名空间列表失败');
    }
  };

  const loadPolicies = async () => {
    setLoadingPolicies(true);
    try {
      const result = await replicationApi.listPolicies();
      setPolicies(result.data || []);
    } catch {
      message.error('加载复制策略失败');
    } finally {
      setLoadingPolicies(false);
    }
  };

  const loadTasks = async () => {
    setLoadingTasks(true);
    try {
      const result = await replicationApi.listTasks();
      setTasks(result.data || []);
    } catch {
      message.error('加载复制任务失败');
    } finally {
      setLoadingTasks(false);
    }
  };

  // 上传配置
  const uploadProps: UploadProps = {
    name: 'file',
    accept: '.tar,.tar.gz,.tgz',
    multiple: false,
    showUploadList: false,
    customRequest: async (options) => {
      const { file, onSuccess, onError } = options;

      if (!selectedNamespace) {
        message.error('请先选择命名空间');
        onError?.(new Error('请先选择命名空间'));
        return;
      }

      if (!repositoryName) {
        message.error('请输入仓库名称');
        onError?.(new Error('请输入仓库名称'));
        return;
      }

      // 验证仓库名格式
      if (!/^[a-z0-9]+([._-][a-z0-9]+)*$/.test(repositoryName)) {
        message.error('仓库名只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾');
        onError?.(new Error('仓库名格式错误'));
        return;
      }

      // 验证标签格式
      if (!/^[a-zA-Z0-9_.-]+$/.test(tagName)) {
        message.error('标签只能包含字母、数字、下划线、点、连字符');
        onError?.(new Error('标签格式错误'));
        return;
      }

      setUploading(true);
      setUploadProgress(0);
      setUploadResult(null);

      // 获取选中的命名空间名称
      const selectedNs = namespaces.find(ns => ns.id === selectedNamespace);
      const nsName = selectedNs?.name || 'library';

      const formData = new FormData();
      formData.append('file', file as File);
      formData.append('namespace', nsName);
      formData.append('repository', repositoryName);
      formData.append('tag', tagName);

      try {
        const response = await axios.post('/api/v1/images/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': localStorage.getItem('auth-storage')
              ? `Bearer ${JSON.parse(localStorage.getItem('auth-storage') || '{}').state?.token}`
              : '',
          },
          onUploadProgress: (progressEvent) => {
            const percent = Math.round((progressEvent.loaded * 100) / (progressEvent.total || 1));
            setUploadProgress(percent);
          },
        });

        setUploadProgress(100);
        setUploadResult(response.data);
        message.success('镜像上传成功');
        onSuccess?.(response.data);
      } catch (error: unknown) {
        if (typeof error === 'object' && error !== null && 'response' in error) {
          const err = error as { response?: { data?: { message?: string } } };
          message.error(err.response?.data?.message || '上传失败');
        } else {
          message.error('上传失败');
        }
        onError?.(error as Error);
      }

      setUploading(false);
    },
  };

  // 创建/编辑策略
  const handleCreatePolicy = () => {
    setEditingPolicy(null);
    policyForm.resetFields();
    policyForm.setFieldsValue({ enabled: true, trigger_type: 'manual' });
    setPolicyModalVisible(true);
  };

  const handleEditPolicy = (policy: ReplicationPolicy) => {
    setEditingPolicy(policy);
    policyForm.setFieldsValue({
      name: policy.name,
      description: policy.description,
      source_registry: policy.source_registry,
      source_namespace: policy.source_namespace,
      source_repository: policy.source_repository,
      source_tag_pattern: policy.source_tag_pattern,
      dest_namespace: policy.dest_namespace,
      dest_repository: policy.dest_repository,
      trigger_type: policy.trigger_type,
      enabled: policy.enabled,
    });
    setPolicyModalVisible(true);
  };

  const handlePolicySubmit = async () => {
    try {
      const values = await policyForm.validateFields();
      if (editingPolicy) {
        await replicationApi.updatePolicy(editingPolicy.id, values);
        message.success('策略更新成功');
      } else {
        await replicationApi.createPolicy(values);
        message.success('策略创建成功');
      }
      setPolicyModalVisible(false);
      loadPolicies();
    } catch (error) {
      if (error instanceof Error) return;
      message.error('操作失败');
    }
  };

  const handleDeletePolicy = async (id: string) => {
    try {
      await replicationApi.deletePolicy(id);
      message.success('策略删除成功');
      loadPolicies();
    } catch {
      message.error('删除失败');
    }
  };

  const handleExecutePolicy = async (id: string) => {
    try {
      const result = await replicationApi.executePolicy(id);
      message.success(`复制任务已创建: ${result.task_id}`);
      loadTasks();
      loadPolicies();
    } catch {
      message.error('执行失败');
    }
  };

  // 策略表格列定义
  const policyColumns = [
    {
      title: '策略名称',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => <Tag color="blue">{name}</Tag>,
    },
    {
      title: '源Registry',
      dataIndex: 'source_registry',
      key: 'source_registry',
      render: (registry: string) => <Text code>{registry}</Text>,
    },
    {
      title: '源命名空间',
      dataIndex: 'source_namespace',
      key: 'source_namespace',
      render: (ns: string) => ns || '*',
    },
    {
      title: '目标命名空间',
      dataIndex: 'dest_namespace',
      key: 'dest_namespace',
      render: (ns: string) => <Tag color="green">{ns}</Tag>,
    },
    {
      title: '触发方式',
      dataIndex: 'trigger_type',
      key: 'trigger_type',
      render: (type: string) => {
        const colorMap: Record<string, string> = { manual: 'orange', scheduled: 'blue', event: 'purple' };
        return <Tag color={colorMap[type] || 'default'}>{type || 'manual'}</Tag>;
      },
    },
    {
      title: '状态',
      dataIndex: 'enabled',
      key: 'enabled',
      render: (enabled: boolean) => (
        <Badge status={enabled ? 'success' : 'default'} text={enabled ? '启用' : '禁用'} />
      ),
    },
    {
      title: '最后执行',
      dataIndex: 'last_trigger_time',
      key: 'last_trigger_time',
      render: (time: string) => time || '-',
    },
    {
      title: '操作',
      key: 'action',
      width: 200,
      render: (_: unknown, record: ReplicationPolicy) => (
        <Space>
          <Button
            type="link"
            icon={<PlayCircleOutlined />}
            onClick={() => handleExecutePolicy(record.id)}
            disabled={!record.enabled}
          >
            执行
          </Button>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditPolicy(record)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定删除此策略?"
            onConfirm={() => handleDeletePolicy(record.id)}
          >
            <Button type="link" danger icon={<DeleteOutlined />}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // 任务表格列定义
  const taskColumns = [
    {
      title: '任务ID',
      dataIndex: 'id',
      key: 'id',
      render: (id: string) => <Text code style={{ fontSize: 12 }}>{id.slice(0, 8)}</Text>,
    },
    {
      title: '策略',
      dataIndex: 'policy_name',
      key: 'policy_name',
      render: (name: string) => name || '-',
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const statusConfig: Record<string, { color: string; text: string }> = {
          pending: { color: 'default', text: '等待中' },
          running: { color: 'processing', text: '执行中' },
          success: { color: 'success', text: '成功' },
          failed: { color: 'error', text: '失败' },
          stopped: { color: 'warning', text: '已停止' },
        };
        const config = statusConfig[status] || { color: 'default', text: status };
        return <Badge status={config.color as any} text={config.text} />;
      },
    },
    {
      title: '开始时间',
      dataIndex: 'started_at',
      key: 'started_at',
      render: (time: string) => time || '-',
    },
    {
      title: '结束时间',
      dataIndex: 'ended_at',
      key: 'ended_at',
      render: (time: string) => time || '-',
    },
    {
      title: '成功/失败',
      key: 'counts',
      render: (_: unknown, record: ReplicationTask) => (
        <Space>
          <Tag color="green">{record.succeeded_count}</Tag>
          <Tag color="red">{record.failed_count}</Tag>
        </Space>
      ),
    },
  ];

  return (
    <div className={styles.container}>
      <Title level={3} style={{ marginBottom: 24 }}>
        <SyncOutlined /> 镜像传输
      </Title>

      <Tabs
        defaultActiveKey="upload"
        items={[
          {
            key: 'upload',
            label: <Space><CloudUploadOutlined />镜像上传</Space>,
            children: (
              <Card className={styles.card}>
                <Space direction="vertical" style={{ width: '100%' }} size="large">
                  <Alert
                    message="镜像下载功能已移至镜像仓库页面"
                    description={
                      <Space>
                        <span>如需下载镜像，请前往</span>
                        <Button type="link" icon={<ContainerOutlined />} onClick={() => navigate('/repositories')}>
                          镜像仓库
                        </Button>
                        <span>页面，点击"版本管理"或"下载"按钮。</span>
                      </Space>
                    }
                    type="info"
                    showIcon
                  />

                  <Divider />

                  {/* 配置输入 */}
                  <Space style={{ width: '100%' }} size="middle">
                    <div style={{ width: 200 }}>
                      <Text>命名空间</Text>
                      <Select
                        style={{ width: '100%', marginTop: 8 }}
                        placeholder="选择命名空间"
                        value={selectedNamespace}
                        onChange={setSelectedNamespace}
                        options={namespaces.map(ns => ({ label: ns.name, value: ns.id }))}
                      />
                    </div>
                    <div style={{ width: 200 }}>
                      <Text>仓库名称</Text>
                      <Input
                        style={{ marginTop: 8 }}
                        placeholder="例如: my-image"
                        value={repositoryName}
                        onChange={(e) => {
                          const value = e.target.value;
                          if (value && !/^[a-z0-9]+([._-][a-z0-9]+)*$/.test(value)) {
                            message.warning('仓库名只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾');
                            return;
                          }
                          setRepositoryName(value);
                        }}
                      />
                      <Text type="secondary" style={{ fontSize: 11 }}>小写字母、数字、下划线、点、连字符</Text>
                    </div>
                    <div style={{ width: 120 }}>
                      <Text>标签</Text>
                      <Input
                        style={{ marginTop: 8 }}
                        placeholder="例如: latest"
                        value={tagName}
                        onChange={(e) => {
                          const value = e.target.value;
                          if (value && !/^[a-zA-Z0-9_.-]+$/.test(value)) {
                            message.warning('标签只能包含字母、数字、下划线、点、连字符');
                            return;
                          }
                          setTagName(value);
                        }}
                      />
                      <Text type="secondary" style={{ fontSize: 11 }}>字母、数字、下划线、点、连字符</Text>
                    </div>
                  </Space>

                  <Divider />

                  {/* 拖拽上传区域 */}
                  <Dragger {...uploadProps} disabled={uploading}>
                    <p className="ant-upload-drag-icon">
                      <InboxOutlined />
                    </p>
                    <p className="ant-upload-text">点击或拖拽tar文件到此区域上传</p>
                    <p className="ant-upload-hint">
                      支持 .tar 和 .tar.gz 格式的Docker镜像文件
                    </p>
                  </Dragger>

                  {/* 上传进度 */}
                  {uploading && (
                    <Progress
                      percent={uploadProgress}
                      status="active"
                      strokeColor={{ from: '#108ee9', to: '#87d068' }}
                    />
                  )}

                  {/* 上传结果 */}
                  {uploadResult && (
                    <Card size="small" style={{ background: '#f6ffed' }}>
                      <Space>
                        <CheckCircleOutlined style={{ color: '#52c41a' }} />
                        <Text>上传成功: {uploadResult.data?.repository}:{uploadResult.data?.tag}</Text>
                        <Text type="secondary">(大小: {(uploadResult.data?.size / 1024 / 1024).toFixed(2)} MB)</Text>
                      </Space>
                    </Card>
                  )}
                </Space>
              </Card>
            ),
          },
          {
            key: 'replication',
            label: <Space><SyncOutlined />镜像复制</Space>,
            children: (
              <Space direction="vertical" style={{ width: '100%' }} size="large">
                {/* 复制策略 */}
                <Card
                  title={<Space><SyncOutlined />复制策略</Space>}
                  extra={
                    <Button type="primary" icon={<PlusOutlined />} onClick={handleCreatePolicy}>
                      新建策略
                    </Button>
                  }
                >
                  {loadingPolicies ? (
                    <Spin style={{ display: 'block', textAlign: 'center', padding: 40 }} />
                  ) : policies.length === 0 ? (
                    <Alert
                      message="暂无复制策略"
                      description="点击上方按钮创建新的复制策略，可以从其他Registry同步镜像到本地"
                      type="info"
                      showIcon
                    />
                  ) : (
                    <Table
                      columns={policyColumns}
                      dataSource={policies}
                      rowKey="id"
                      pagination={false}
                      size="small"
                    />
                  )}
                </Card>

                {/* 执行历史 */}
                <Card title={<Space><HistoryOutlined />执行历史</Space>}>
                  {loadingTasks ? (
                    <Spin style={{ display: 'block', textAlign: 'center', padding: 40 }} />
                  ) : tasks.length === 0 ? (
                    <Alert
                      message="暂无执行记录"
                      description="执行复制策略后，任务记录将显示在这里"
                      type="info"
                      showIcon
                    />
                  ) : (
                    <Table
                      columns={taskColumns}
                      dataSource={tasks}
                      rowKey="id"
                      pagination={false}
                      size="small"
                    />
                  )}
                </Card>
              </Space>
            ),
          },
        ]}
      />

      {/* 创建/编辑策略Modal */}
      <Modal
        title={editingPolicy ? '编辑复制策略' : '新建复制策略'}
        open={policyModalVisible}
        onOk={handlePolicySubmit}
        onCancel={() => setPolicyModalVisible(false)}
        okText="确定"
        cancelText="取消"
        width={600}
      >
        <Form form={policyForm} layout="vertical">
          <Form.Item
            name="name"
            label="策略名称"
            rules={[{ required: true, message: '请输入策略名称' }]}
          >
            <Input placeholder="例如: sync-from-hub" />
          </Form.Item>
          <Form.Item name="description" label="描述">
            <Input.TextArea placeholder="策略描述" rows={2} />
          </Form.Item>
          <Form.Item
            name="source_registry"
            label="源Registry地址"
            rules={[{ required: true, message: '请输入源Registry地址' }]}
          >
            <Input placeholder="例如: https://registry.hub.docker.com" />
          </Form.Item>
          <Form.Item
            name="source_namespace"
            label="源命名空间"
            extra="只能包含小写字母、数字、下划线、点、连字符，留空表示所有"
          >
            <Input placeholder="例如: library，留空表示所有" />
          </Form.Item>
          <Form.Item
            name="source_repository"
            label="源仓库"
            extra="只能包含小写字母、数字、下划线、点、连字符，留空表示所有"
          >
            <Input placeholder="例如: nginx，留空表示所有" />
          </Form.Item>
          <Form.Item
            name="source_tag_pattern"
            label="标签过滤"
            extra="只能包含字母、数字、下划线、点、连字符、星号(*)"
          >
            <Input placeholder="例如: v* 或 latest，留空表示所有" />
          </Form.Item>
          <Divider />
          <Form.Item
            name="dest_namespace"
            label="目标命名空间"
            rules={[{ required: true, message: '请输入目标命名空间' }]}
          >
            <Select
              placeholder="选择目标命名空间"
              options={namespaces.map(ns => ({ label: ns.name, value: ns.name }))}
            />
          </Form.Item>
          <Form.Item
            name="dest_repository"
            label="目标仓库"
            extra="只能包含小写字母、数字、下划线、点、连字符，留空则使用源仓库同名"
          >
            <Input placeholder="留空则使用源仓库同名" />
          </Form.Item>
          <Form.Item name="trigger_type" label="触发方式">
            <Select
              options={[
                { label: '手动触发', value: 'manual' },
                { label: '定时触发', value: 'scheduled' },
                { label: '事件触发', value: 'event' },
              ]}
            />
          </Form.Item>
          <Form.Item name="enabled" label="启用策略" valuePropName="checked">
            <Switch checkedChildren="启用" unCheckedChildren="禁用" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default ImageTransfer;