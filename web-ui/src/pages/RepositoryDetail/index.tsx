import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, Descriptions, Tag, Button, Space, Table, message, Spin, Modal, Input, Typography, Popconfirm, Alert, Progress, Tooltip, Upload } from 'antd';
import { ArrowLeftOutlined, DownloadOutlined, DeleteOutlined, CopyOutlined, SyncOutlined, UploadOutlined, CloudUploadOutlined, ContainerOutlined, CheckCircleOutlined, CloseCircleOutlined, LoadingOutlined, EditOutlined, SaveOutlined } from '@ant-design/icons';
import { repositoryApi } from '../../api/repository';
import { Repository, Tag as TagType } from '../../api/types';
import { formatTime } from '../../utils/format';
import { useAuthStore } from '../../store/authStore';
import axios from 'axios';
import styles from './RepositoryDetail.module.css';

const { Text, Title } = Typography;
const { TextArea } = Input;

// 生成随机5位标签（数字+字母）
const generateRandomTag = (): string => {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 5; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

const RepositoryDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const isAdmin = user?.is_admin || false;
  const [repo, setRepo] = useState<Repository | null>(null);
  const [loading, setLoading] = useState(true);
  const [tags, setTags] = useState<TagType[]>([]);
  const [loadingTags, setLoadingTags] = useState(false);

  // 判断是否有管理权限（是所有者或管理员）
  const canManage = () => {
    if (!repo || !user) return false;
    if (isAdmin) return true;
    return repo.owner_id === user.id;
  };

  // Docker-compose 编辑器状态
  const [composeYaml, setComposeYaml] = useState('');
  const [editingCompose, setEditingCompose] = useState(false);
  const [tempComposeYaml, setTempComposeYaml] = useState('');

  // 简介编辑状态
  const [description, setDescription] = useState('');
  const [editingDescription, setEditingDescription] = useState(false);
  const [savingDescription, setSavingDescription] = useState(false);

  // 镜像复制状态
  const [replicateModalVisible, setReplicateModalVisible] = useState(false);
  const [sourceImage, setSourceImage] = useState('');
  const [replicating, setReplicating] = useState(false);
  const [replicateProgress, setReplicateProgress] = useState(0);
  const [replicateTaskId, setReplicateTaskId] = useState<string | null>(null);
  const [replicateTaskStatus, setReplicateTaskStatus] = useState<string>('');
  const [replicateTaskError, setReplicateTaskError] = useState<string>('');
  const pollIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // 上传镜像状态
  const [uploadModalVisible, setUploadModalVisible] = useState(false);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadTag, setUploadTag] = useState('');
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  // 获取registry地址：使用浏览器实际访问的完整地址
  const getRegistryAddr = (): string => {
    return window.location.host;
  };

  // 加载仓库详情
  useEffect(() => {
    if (!id) return;
    loadRepository();
    loadTags();
  }, [id]);

  const loadRepository = async () => {
    setLoading(true);
    try {
      const data = await repositoryApi.getRepository(id!);
      setRepo(data);
      setDescription(data.description || '');
    } catch {
      message.error('获取仓库详情失败');
      navigate('/repositories');
    } finally {
      setLoading(false);
    }
  };

  const loadTags = async () => {
    setLoadingTags(true);
    try {
      const data = await repositoryApi.getTags(id!);
      // 按推送时间降序排序（最新的在前）
      const sortedTags = [...data].sort((a, b) => {
        const timeA = a.pushed_at || a.created_at || '';
        const timeB = b.pushed_at || b.created_at || '';
        return timeB.localeCompare(timeA);
      });
      setTags(sortedTags);
    } catch {
      message.error('获取镜像版本失败');
    } finally {
      setLoadingTags(false);
    }
  };

  // 保存简介
  const handleSaveDescription = async () => {
    if (!repo) return;
    setSavingDescription(true);
    try {
      await repositoryApi.updateRepository(repo.id, { description });
      message.success('简介已保存');
      setEditingDescription(false);
      // 更新 repo 状态
      setRepo({ ...repo, description });
    } catch {
      message.error('保存简介失败');
    } finally {
      setSavingDescription(false);
    }
  };

  // 当仓库信息加载完成后更新compose
  useEffect(() => {
    if (repo) {
      const registryAddr = getRegistryAddr();
      const defaultCompose = `version: '3.8'
services:
  ${repo.name}:
    image: ${registryAddr}/${repo.full_name}:latest
    container_name: ${repo.name}-container
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./data:/app/data
`;
      setComposeYaml(defaultCompose);
    }
  }, [repo]);

  // 复制docker pull命令
  const copyPullCommand = (tagName: string) => {
    const command = `docker pull ${getRegistryAddr()}/${repo?.full_name}:${tagName}`;
    navigator.clipboard.writeText(command);
    message.success('命令已复制到剪贴板');
  };

  // 下载镜像（使用 fetch API + blob 方式）
  const handleDownloadImage = async (tagName: string) => {
    const parts = repo?.full_name.split('/') || ['library', 'app'];
    const namespace = parts[0] || 'library';
    const repository = parts[1] || repo?.name || 'app';

    // 获取认证 token
    const token = localStorage.getItem('auth-storage')
      ? JSON.parse(localStorage.getItem('auth-storage') || '{}').state?.token
      : '';

    if (!token) {
      message.error('请先登录');
      return;
    }

    const downloadUrl = `/api/v1/images/export?namespace=${encodeURIComponent(namespace)}&repository=${encodeURIComponent(repository)}&tag=${encodeURIComponent(tagName)}`;

    message.loading({ content: '正在准备下载...', key: 'download', duration: 0 });

    try {
      const response = await fetch(downloadUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`下载失败: ${response.status}`);
      }

      // 获取文件名
      const disposition = response.headers.get('Content-Disposition');
      let filename = `${namespace}-${repository}-${tagName}.tar.gz`;
      if (disposition) {
        const match = disposition.match(/filename="?([^"]+)"?/);
        if (match) {
          filename = match[1];
        }
      }

      // 获取总大小（用于进度显示）
      const contentLength = response.headers.get('Content-Length');
      const totalSize = contentLength ? parseInt(contentLength, 10) : 0;

      // 创建可读流
      const reader = response.body?.getReader();
      if (!reader) {
        throw new Error('无法读取响应数据');
      }

      const chunks: BlobPart[] = [];
      let receivedSize = 0;

      // 读取数据块
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        receivedSize += value.length;

        // 更新进度（如果有总大小）
        if (totalSize > 0) {
          const percent = Math.round((receivedSize / totalSize) * 100);
          message.loading({
            content: `正在下载 ${percent}% (${(receivedSize / 1024 / 1024).toFixed(1)} MB / ${(totalSize / 1024 / 1024).toFixed(1)} MB)`,
            key: 'download',
            duration: 0
          });
        } else {
          message.loading({
            content: `正在下载 ${(receivedSize / 1024 / 1024).toFixed(1)} MB...`,
            key: 'download',
            duration: 0
          });
        }
      }

      // 合并数据块为 blob
      const blob = new Blob(chunks, { type: 'application/gzip' });
      const url = window.URL.createObjectURL(blob);

      // 创建下载链接
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();

      // 清理
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      message.success({ content: `下载完成: ${filename}`, key: 'download' });
    } catch (err) {
      console.error('下载失败:', err);
      message.error({ content: `下载失败: ${err instanceof Error ? err.message : '未知错误'}`, key: 'download' });
    }
  };

  // 删除Tag
  const handleDeleteTag = async (tagId: string, tagName: string) => {
    try {
      await repositoryApi.deleteTag(id!, tagId);
      message.success(`版本 ${tagName} 已删除`);
      loadTags();
    } catch {
      message.error('删除失败');
    }
  };

  // 打开镜像复制Modal
  const handleOpenReplicate = () => {
    setSourceImage('');
    setReplicateProgress(0);
    setReplicateTaskId(null);
    setReplicateTaskStatus('');
    setReplicateTaskError('');
    setReplicateModalVisible(true);
  };

  // 获取认证Token
  const getAuthToken = () => {
    return localStorage.getItem('auth-storage')
      ? `Bearer ${JSON.parse(localStorage.getItem('auth-storage') || '{}').state?.token}`
      : '';
  };

  // 轮询任务状态
  const pollTaskStatus = async (taskId: string) => {
    try {
      const response = await axios.get(`/api/v1/replication/tasks/${taskId}`, {
        headers: { 'Authorization': getAuthToken() }
      });

      const task = response.data?.data;
      if (!task) return;

      setReplicateTaskStatus(task.status);

      // 使用 API 返回的实际进度，如果没有则使用默认值
      const apiProgress = task.progress || 0;
      setReplicateProgress(apiProgress);

      // 根据状态更新UI
      switch (task.status) {
        case 'pending':
          // 进度保持 API 返回值（通常是10%）
          break;
        case 'running':
          // 进度保持 API 返回值（20%-90%）
          break;
        case 'success':
          setReplicateProgress(100);
          setReplicating(false);
          message.success('镜像复制成功！');
          loadTags(); // 刷新标签列表
          // 停止轮询，3秒后关闭Modal
          if (pollIntervalRef.current) {
            clearInterval(pollIntervalRef.current);
            pollIntervalRef.current = null;
          }
          setTimeout(() => setReplicateModalVisible(false), 2000);
          break;
        case 'failed':
          setReplicateProgress(100);
          setReplicating(false);
          setReplicateTaskError(task.error_message || '复制失败');
          message.error(`镜像复制失败: ${task.error_message || '未知错误'}`);
          // 停止轮询
          if (pollIntervalRef.current) {
            clearInterval(pollIntervalRef.current);
            pollIntervalRef.current = null;
          }
          break;
        case 'stopped':
          setReplicateProgress(0);
          setReplicating(false);
          message.warning('复制任务已停止');
          if (pollIntervalRef.current) {
            clearInterval(pollIntervalRef.current);
            pollIntervalRef.current = null;
          }
          break;
      }
    } catch (err) {
      console.error('轮询任务状态失败:', err);
    }
  };

  // 开始轮询
  const startPolling = (taskId: string) => {
    // 立即查询一次
    pollTaskStatus(taskId);

    // 每1秒轮询一次（更频繁以实时显示进度）
    pollIntervalRef.current = setInterval(() => {
      pollTaskStatus(taskId);
    }, 1000);
  };

  // 清理轮询
  useEffect(() => {
    return () => {
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
      }
    };
  }, []);

  // 执行镜像复制
  const handleReplicate = async () => {
    if (!sourceImage) {
      message.error('请输入源镜像地址');
      return;
    }

    // 解析源镜像地址
    // 格式: registry.example.com/namespace/image:tag 或 registry.example.com/image:tag
    const parts = repo?.full_name.split('/') || [];
    const destNamespace = parts[0] || 'library';
    const destRepo = parts[1] || repo?.name || 'app';

    // 解析标签
    let destTag = 'latest';
    if (sourceImage.includes(':')) {
      const tagParts = sourceImage.split(':');
      if (tagParts.length > 1 && !tagParts[tagParts.length - 1].includes('/')) {
        destTag = tagParts[tagParts.length - 1];
      }
    }

    setReplicating(true);
    setReplicateProgress(5);
    setReplicateTaskError('');
    setReplicateTaskStatus('pending');

    try {
      // 调用复制API
      const response = await axios.post('/api/v1/images/replicate', {
        source_image: sourceImage,
        dest_namespace: destNamespace,
        dest_repository: destRepo,
        dest_tag: destTag,
      }, {
        headers: { 'Authorization': getAuthToken() }
      });

      const taskId = response.data?.data?.task_id;
      if (taskId) {
        setReplicateTaskId(taskId);
        setReplicateProgress(10);
        message.info('复制任务已创建，正在执行...');
        // 开始轮询任务状态
        startPolling(taskId);
      } else {
        throw new Error('未获取到任务ID');
      }
    } catch (err: unknown) {
      setReplicating(false);
      setReplicateProgress(0);
      if (typeof err === 'object' && err !== null && 'response' in err) {
        const errorResp = err as { response?: { data?: { message?: string } } };
        setReplicateTaskError(errorResp.response?.data?.message || '复制失败');
        message.error(errorResp.response?.data?.message || '复制失败');
      } else if (err instanceof Error) {
        setReplicateTaskError(err.message);
        message.error(err.message);
      } else {
        setReplicateTaskError('复制失败');
        message.error('复制失败');
      }
    }
  };

  // 上传镜像
  const uploadProps = {
    name: 'file',
    accept: '.tar,.tar.gz,.tgz',
    multiple: false,
    showUploadList: false,
    beforeUpload: (file: File) => {
      setUploadFile(file);
      return false;
    },
  };

  const handleUpload = async () => {
    if (!uploadFile || !uploadTag) {
      message.error('请选择文件并输入标签');
      return;
    }

    // 验证tag名称
    if (!/^[a-zA-Z0-9_.-]+$/.test(uploadTag)) {
      message.error('标签名称只能包含字母、数字、下划线、点、连字符');
      return;
    }

    setUploading(true);
    setUploadProgress(0);

    const parts = repo?.full_name.split('/') || [];
    const namespace = parts[0] || 'library';
    const repository = parts[1] || repo?.name || 'app';

    const formData = new FormData();
    formData.append('file', uploadFile);
    formData.append('namespace', namespace);
    formData.append('repository', repository);
    formData.append('tag', uploadTag);

    try {
      await axios.post('/api/v1/images/upload', formData, {
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
      message.success('镜像上传成功');
      setUploadModalVisible(false);
      loadTags();
    } catch (err: unknown) {
      if (typeof err === 'object' && err !== null && 'response' in err) {
        const errorResp = err as { response?: { data?: { message?: string } } };
        message.error(errorResp.response?.data?.message || '上传失败');
      } else {
        message.error('上传失败');
      }
    } finally {
      setUploading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ padding: 24, textAlign: 'center' }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!repo) {
    return null;
  }

  // 镜像版本表格列
  const tagColumns = [
    {
      title: '标签',
      dataIndex: 'name',
      key: 'name',
      width: 100,
      render: (name: string) => <Tag color="blue">{name}</Tag>,
    },
    {
      title: '大小',
      key: 'size',
      width: 100,
      render: (_: unknown, record: TagType) => {
        const size = record.manifest?.total_size || 0;
        if (size === 0) return '-';
        // 格式化大小显示
        if (size >= 1024 * 1024 * 1024) {
          return `${(size / 1024 / 1024 / 1024).toFixed(2)} GB`;
        } else if (size >= 1024 * 1024) {
          return `${(size / 1024 / 1024).toFixed(2)} MB`;
        } else if (size >= 1024) {
          return `${(size / 1024).toFixed(2)} KB`;
        }
        return `${size} B`;
      },
    },
    {
      title: '推送时间',
      key: 'pushed_time',
      width: 150,
      render: (_: unknown, record: TagType) => formatTime(record.pushed_at || record.created_at),
    },
    {
      title: '推送者',
      dataIndex: 'pushed_by',
      key: 'pushed_by',
      width: 100,
      render: (by: string) => by || '-',
    },
    {
      title: '操作',
      key: 'action',
      width: canManage() ? 180 : 100,
      render: (_: unknown, record: TagType) => (
        <Space size="small">
          <Tooltip title="复制pull命令">
            <Button
              type="link"
              size="small"
              icon={<CopyOutlined />}
              onClick={() => copyPullCommand(record.name)}
            />
          </Tooltip>
          <Tooltip title="下载镜像">
            <Button
              type="link"
              size="small"
              icon={<DownloadOutlined />}
              onClick={() => handleDownloadImage(record.name)}
            />
          </Tooltip>
          {canManage() && (
            <Popconfirm
              title="确定删除此版本?"
              onConfirm={() => handleDeleteTag(record.id, record.name)}
            >
              <Tooltip title="删除版本">
                <Button type="link" size="small" danger icon={<DeleteOutlined />} />
              </Tooltip>
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  return (
    <div className={styles.container}>
      {/* 顶部导航 */}
      <div className={styles.header}>
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate(-1)}>
          返回
        </Button>
        <Title level={4} style={{ margin: 0 }}>
          <ContainerOutlined style={{ marginRight: 8 }} />
          {repo.full_name}
        </Title>
        <Space>
          {canManage() && (
            <Button icon={<SyncOutlined />} onClick={handleOpenReplicate}>
              复制镜像
            </Button>
          )}
          {canManage() && (
            <Button icon={<UploadOutlined />} onClick={() => {
              setUploadTag(generateRandomTag());
              setUploadModalVisible(true);
            }}>
              上传镜像
            </Button>
          )}
        </Space>
      </div>

      {/* 仓库基本信息 */}
      <Card className={styles.infoCard}>
        <Descriptions column={4}>
          <Descriptions.Item label="命名空间">
            <Tag color="blue">{repo.namespace || 'library'}</Tag>
          </Descriptions.Item>
          <Descriptions.Item label="仓库名">{repo.name}</Descriptions.Item>
          <Descriptions.Item label="所有者">{repo.owner_name || '-'}</Descriptions.Item>
          <Descriptions.Item label="公开">
            <Tag color={repo.is_public ? 'green' : 'orange'}>
              {repo.is_public ? '公开' : '私有'}
            </Tag>
          </Descriptions.Item>
          <Descriptions.Item label="镜像数">{repo.image_count || 0}</Descriptions.Item>
          <Descriptions.Item label="下载次数">{repo.pull_count || 0}</Descriptions.Item>
          <Descriptions.Item label="创建时间">{formatTime(repo.created_at)}</Descriptions.Item>
          <Descriptions.Item label="更新时间">{formatTime(repo.updated_at)}</Descriptions.Item>
        </Descriptions>
      </Card>

      {/* 下部两列布局 */}
      <div className={styles.bottomSection}>
        {/* 左侧：简介 + Docker-compose编辑器 */}
        <div className={styles.leftSection}>
          {/* 简介卡片 */}
          <Card
            className={styles.descriptionCard}
            title="仓库简介"
            extra={
              canManage() ? (
                <Space>
                  {editingDescription ? (
                    <>
                      <Button
                        icon={<SaveOutlined />}
                        type="primary"
                        loading={savingDescription}
                        onClick={handleSaveDescription}
                      >
                        保存
                      </Button>
                      <Button onClick={() => { setEditingDescription(false); setDescription(repo?.description || ''); }}>
                        取消
                      </Button>
                    </>
                  ) : (
                    <Button icon={<EditOutlined />} onClick={() => setEditingDescription(true)}>
                      编辑
                    </Button>
                  )}
                </Space>
              ) : null
            }
          >
            {editingDescription ? (
              <TextArea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                style={{ height: 100, resize: 'none' }}
                placeholder="请输入仓库简介..."
                autoFocus
              />
            ) : (
              <div className={styles.descriptionContent}>
                {description ? (
                  <Text>{description}</Text>
                ) : (
                  <Text type="secondary">暂无简介</Text>
                )}
              </div>
            )}
          </Card>

          {/* Docker-compose编辑器 */}
          <Card
            className={styles.composeCard}
            title="Docker Compose 配置"
            extra={
              editingCompose ? (
                <Space>
                  <Button
                    icon={<SaveOutlined />}
                    type="primary"
                    onClick={() => {
                      setComposeYaml(tempComposeYaml);
                      setEditingCompose(false);
                      message.success('配置已保存');
                    }}
                  >
                    保存
                  </Button>
                  <Button onClick={() => { setEditingCompose(false); setTempComposeYaml(composeYaml); }}>
                    取消
                  </Button>
                </Space>
              ) : (
                <Space>
                  {canManage() && (
                    <Button icon={<EditOutlined />} onClick={() => { setEditingCompose(true); setTempComposeYaml(composeYaml); }}>
                      编辑
                    </Button>
                  )}
                  <Button icon={<CopyOutlined />} onClick={() => {
                    navigator.clipboard.writeText(composeYaml);
                    message.success('已复制到剪贴板');
                  }}>
                    复制
                  </Button>
                  <Button icon={<DownloadOutlined />} onClick={() => {
                    const blob = new Blob([composeYaml], { type: 'text/yaml' });
                    const url = window.URL.createObjectURL(blob);
                    const link = document.createElement('a');
                    link.href = url;
                    link.download = `docker-compose-${repo?.name || 'app'}.yml`;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    window.URL.revokeObjectURL(url);
                    message.success('docker-compose.yml 已下载');
                  }}>
                    下载
                  </Button>
                </Space>
              )
            }
          >
            {editingCompose ? (
              <TextArea
                value={tempComposeYaml}
                onChange={(e) => setTempComposeYaml(e.target.value)}
                className={styles.composeTextArea}
                style={{ fontFamily: 'monospace', fontSize: 13 }}
                placeholder="docker-compose.yml 配置..."
                autoFocus
              />
            ) : (
              <div className={styles.composeContent}>
                {composeYaml ? (
                  <pre style={{ fontFamily: 'monospace', fontSize: 13, margin: 0, whiteSpace: 'pre-wrap' }}>{composeYaml}</pre>
                ) : (
                  <Text type="secondary">暂无配置，点击编辑按钮添加</Text>
                )}
              </div>
            )}
          </Card>
        </div>

        {/* 右侧：镜像版本列表 */}
        <Card
          className={styles.tagsCard}
          title="镜像版本列表"
          extra={
            <Button icon={<SyncOutlined />} onClick={loadTags}>
              刷新
            </Button>
          }
        >
          {loadingTags ? (
            <Spin style={{ display: 'block', textAlign: 'center', padding: 40 }} />
          ) : tags.length === 0 ? (
            <Alert
              message="暂无镜像版本"
              description="点击上方'上传镜像'按钮添加新版本"
              type="info"
              showIcon
            />
          ) : (
            <Table
              dataSource={tags}
              columns={tagColumns}
              rowKey="id"
              pagination={false}
              size="small"
            />
          )}
        </Card>
      </div>

      {/* 镜像复制Modal */}
      <Modal
        title={<Space><SyncOutlined />从其他Registry复制镜像</Space>}
        open={replicateModalVisible}
        onCancel={() => {
          if (!replicating) {
            setReplicateModalVisible(false);
          } else {
            message.warning('复制任务正在执行，请等待完成');
          }
        }}
        footer={null}
        width={500}
        maskClosable={!replicating}
        closable={!replicating}
      >
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Alert
            message="输入源镜像地址，将复制到当前仓库"
            type="info"
            showIcon
          />
          <div>
            <Text>源镜像地址:</Text>
            <Input
              style={{ marginTop: 8 }}
              placeholder="例如: docker.io/library/nginx:latest 或 registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1"
              value={sourceImage}
              onChange={(e) => setSourceImage(e.target.value)}
              disabled={replicating}
            />
          </div>
          <div>
            <Text>目标仓库:</Text>
            <Input
              style={{ marginTop: 8 }}
              value={`${getRegistryAddr()}/${repo.full_name}`}
              disabled
            />
          </div>

          {/* 进度显示 */}
          {replicating && (
            <Card size="small" style={{ background: '#F8FAFC' }}>
              <Space direction="vertical" style={{ width: '100%' }}>
                <Space>
                  <LoadingOutlined spin />
                  <Text>正在复制镜像...</Text>
                  {replicateTaskId && (
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      任务ID: {replicateTaskId.slice(0, 8)}
                    </Text>
                  )}
                </Space>
                <Progress
                  percent={replicateProgress}
                  status="active"
                  strokeColor={{ from: '#108ee9', to: '#87d068' }}
                />
                <Space>
                  <Text type="secondary">状态: </Text>
                  <Tag color={
                    replicateTaskStatus === 'pending' ? 'default' :
                    replicateTaskStatus === 'running' ? 'processing' :
                    replicateTaskStatus === 'success' ? 'success' :
                    replicateTaskStatus === 'failed' ? 'error' : 'default'
                  }>
                    {replicateTaskStatus === 'pending' ? '等待中' :
                     replicateTaskStatus === 'running' ? '执行中' :
                     replicateTaskStatus === 'success' ? '成功' :
                     replicateTaskStatus === 'failed' ? '失败' :
                     replicateTaskStatus || '创建任务'}
                  </Tag>
                </Space>
              </Space>
            </Card>
          )}

          {/* 成功提示 */}
          {replicateTaskStatus === 'success' && (
            <Alert
              message="镜像复制成功"
              description={`镜像已成功复制到 ${getRegistryAddr()}/${repo.full_name}`}
              type="success"
              showIcon
              icon={<CheckCircleOutlined />}
            />
          )}

          {/* 错误提示 */}
          {replicateTaskError && (
            <Alert
              message="复制失败"
              description={replicateTaskError}
              type="error"
              showIcon
              icon={<CloseCircleOutlined />}
            />
          )}

          {/* 开始按钮 */}
          {!replicating && replicateTaskStatus !== 'success' && (
            <Button type="primary" icon={<SyncOutlined />} block onClick={handleReplicate}>
              开始复制
            </Button>
          )}

          {/* 成功后关闭按钮 */}
          {replicateTaskStatus === 'success' && (
            <Button block onClick={() => setReplicateModalVisible(false)}>
              关闭
            </Button>
          )}
        </Space>
      </Modal>

      {/* 上传镜像Modal */}
      <Modal
        title={<Space><CloudUploadOutlined />上传镜像</Space>}
        open={uploadModalVisible}
        onCancel={() => !uploading && setUploadModalVisible(false)}
        footer={null}
        width={500}
        maskClosable={!uploading}
        closable={!uploading}
      >
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Upload.Dragger {...uploadProps} disabled={uploading}>
            <p className="ant-upload-drag-icon">
              <UploadOutlined />
            </p>
            <p className="ant-upload-text">点击或拖拽镜像文件</p>
            <p className="ant-upload-hint">支持 .tar 和 .tar.gz 格式</p>
          </Upload.Dragger>

          {uploadFile && (
            <Card size="small" style={{ background: '#F8FAFC' }}>
              <Text>文件: {uploadFile.name} ({(uploadFile.size / 1024 / 1024).toFixed(2)} MB)</Text>
            </Card>
          )}

          <div>
            <Text>标签名称:</Text>
            <Input
              style={{ marginTop: 8 }}
              placeholder="例如: latest 或 v1.0.0"
              value={uploadTag}
              onChange={(e) => {
                const value = e.target.value;
                // 验证tag名称：不能包含 : / 空格等特殊字符
                if (value && !/^[a-zA-Z0-9_.-]+$/.test(value)) {
                  message.warning('标签名称只能包含字母、数字、下划线、点、连字符');
                  return;
                }
                setUploadTag(value);
              }}
              disabled={uploading}
            />
            <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
              只能包含字母、数字、下划线、点、连字符，不能包含冒号(:)或斜杠(/)
            </Text>
          </div>

          {uploading && (
            <Progress
              percent={uploadProgress}
              status="active"
              strokeColor={{ from: '#108ee9', to: '#87d068' }}
            />
          )}

          {uploadFile && uploadTag && !uploading && (
            <Button type="primary" icon={<CloudUploadOutlined />} block onClick={handleUpload}>
              开始上传
            </Button>
          )}
        </Space>
      </Modal>
    </div>
  );
};

export default RepositoryDetail;