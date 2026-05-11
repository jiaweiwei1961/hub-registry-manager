import React, { useState, useEffect } from 'react';
import {
  Table,
  Card,
  Space,
  Select,
  Input,
  DatePicker,
  Tag,
  message,
  Button,
  Tooltip,
  Modal,
  Descriptions,
  Typography,
} from 'antd';
import {
  SearchOutlined,
  ReloadOutlined,
  EyeOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ClearOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { auditLogApi, AuditLog } from '../../api/audit';
import { formatTime } from '../../utils/format';
import styles from './AuditLogs.module.css';

const { RangePicker } = DatePicker;
const { Text } = Typography;

const AuditLogs: React.FC = () => {
  const [data, setData] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({
    page: 1,
    page_size: 10,
    total: 0,
    total_pages: 0,
  });

  // 筛选条件
  const [username, setUsername] = useState('');
  const [action, setAction] = useState<string | undefined>(undefined);
  const [resourceType, setResourceType] = useState<string | undefined>(undefined);
  const [resourceName, setResourceName] = useState('');
  const [success, setSuccess] = useState<string | undefined>(undefined);
  const [dateRange, setDateRange] = useState<[string | null, string | null]>([null, null]);

  // 选项列表
  const [actions, setActions] = useState<{ value: string; label: string }[]>([]);
  const [resourceTypes, setResourceTypes] = useState<{ value: string; label: string }[]>([]);

  // 详情弹窗状态
  const [detailModalVisible, setDetailModalVisible] = useState(false);
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);

  // 加载操作类型和资源类型选项
  useEffect(() => {
    loadOptions();
  }, []);

  // 加载审计日志
  useEffect(() => {
    fetchData();
  }, [pagination.page, pagination.page_size]);

  const loadOptions = async () => {
    try {
      const [actionList, resourceTypeList] = await Promise.all([
        auditLogApi.getActions(),
        auditLogApi.getResourceTypes(),
      ]);
      setActions(actionList);
      setResourceTypes(resourceTypeList);
    } catch {
      message.error('加载筛选选项失败');
    }
  };

  const fetchData = async (
    page = pagination.page,
    pageSize = pagination.page_size,
    overrideFilter?: Partial<{
      username: string;
      action: string;
      resource_type: string;
      resource_name: string;
      success: string;
      start_time: string | null;
      end_time: string | null;
    }>
  ) => {
    setLoading(true);
    try {
      const filter = {
        page,
        page_size: pageSize,
        username: (overrideFilter?.username ?? username) || undefined,
        action: (overrideFilter?.action ?? action) || undefined,
        resource_type: (overrideFilter?.resource_type ?? resourceType) || undefined,
        resource_name: (overrideFilter?.resource_name ?? resourceName) || undefined,
        success: (overrideFilter?.success ?? success) || undefined,
        start_time: (overrideFilter?.start_time ?? dateRange[0]) || undefined,
        end_time: (overrideFilter?.end_time ?? dateRange[1]) || undefined,
      };

      const result = await auditLogApi.list(filter);
      setData(result.data);
      setPagination(result.pagination);
    } catch {
      message.error('获取审计日志失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    fetchData(1, pagination.page_size);
  };

  const handleReset = () => {
    setUsername('');
    setAction(undefined);
    setResourceType(undefined);
    setResourceName('');
    setSuccess(undefined);
    setDateRange([null, null]);
    fetchData(1, pagination.page_size, {
      username: '',
      action: '',
      resource_type: '',
      resource_name: '',
      success: '',
      start_time: null,
      end_time: null,
    });
  };

  const handleTableChange = (page: number, pageSize: number) => {
    fetchData(page, pageSize);
  };

  // 操作类型标签颜色映射
  const getActionColor = (action: string) => {
    const colorMap: Record<string, string> = {
      login: 'blue',
      logout: 'orange',
      create: 'green',
      update: 'cyan',
      delete: 'red',
      download: 'purple',
      upload: 'gold',
      pull: 'lime',
      push: 'magenta',
      replicate: 'volcano',
      view: 'geekblue',
      change_status: 'processing',
    };
    return colorMap[action] || 'default';
  };

  // 资源类型标签颜色映射
  const getResourceTypeColor = (type: string) => {
    const colorMap: Record<string, string> = {
      namespace: 'blue',
      repository: 'green',
      tag: 'cyan',
      user: 'purple',
      system: 'orange',
      replication: 'magenta',
      image: 'gold',
    };
    return colorMap[type] || 'default';
  };

  // 操作类型标签
  const getActionLabel = (action: string) => {
    const actionItem = actions.find((a) => a.value === action);
    return actionItem?.label || action;
  };

  // 资源类型标签
  const getResourceTypeLabel = (type: string) => {
    const typeItem = resourceTypes.find((t) => t.value === type);
    return typeItem?.label || type;
  };

  const columns = [
    {
      title: '时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 120,
      render: (time: string) => formatTime(time),
    },
    {
      title: '用户',
      dataIndex: 'username',
      key: 'username',
      width: 70,
      render: (username: string) => username || '-',
    },
    {
      title: '操作',
      dataIndex: 'action',
      key: 'action',
      width: 80,
      render: (action: string) => (
        <Tag color={getActionColor(action)}>{getActionLabel(action)}</Tag>
      ),
    },
    {
      title: '资源类型',
      dataIndex: 'resource_type',
      key: 'resource_type',
      width: 100,
      render: (type: string) => (
        <Tag color={getResourceTypeColor(type)}>{getResourceTypeLabel(type)}</Tag>
      ),
    },
    {
      title: '资源名称',
      dataIndex: 'resource_name',
      key: 'resource_name',
      width: 120,
      ellipsis: true,
      render: (name: string) => name || '-',
    },
    {
      title: '详情',
      dataIndex: 'detail',
      key: 'detail',
      width: 180,
      ellipsis: true,
      render: (detail: string) => detail || '-',
    },
    {
      title: 'IP地址',
      dataIndex: 'ip_address',
      key: 'ip_address',
      width: 130,
      render: (ip: string) => ip || '-',
    },
    {
      title: '状态',
      dataIndex: 'success',
      key: 'success',
      width: 80,
      align: 'center' as const,
      render: (success: boolean) =>
        success ? (
          <Tooltip title="成功">
            <CheckCircleOutlined style={{ color: '#52c41a' }} />
          </Tooltip>
        ) : (
          <Tooltip title="失败">
            <CloseCircleOutlined style={{ color: '#ff4d4f' }} />
          </Tooltip>
        ),
    },
    {
      title: '操作',
      key: 'action',
      width: 80,
      align: 'center' as const,
      render: (_: unknown, record: AuditLog) => (
        <Tooltip title="查看详情">
          <Button
            type="link"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleViewDetail(record)}
          />
        </Tooltip>
      ),
    },
  ];

  const handleViewDetail = (record: AuditLog) => {
    setSelectedLog(record);
    setDetailModalVisible(true);
  };

  const handleCloseDetail = () => {
    setDetailModalVisible(false);
    setSelectedLog(null);
  };

  return (
    <div className={styles.container}>
      <Card>
        <div className={styles.toolbar}>
          <Space wrap>
            <Input
              placeholder="用户名"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              prefix={<SearchOutlined />}
              allowClear
              style={{ width: 120 }}
            />
            <Select
              placeholder="操作类型"
              value={action}
              onChange={setAction}
              options={actions}
              allowClear
              style={{ width: 120 }}
            />
            <Select
              placeholder="资源类型"
              value={resourceType}
              onChange={setResourceType}
              options={resourceTypes}
              allowClear
              style={{ width: 120 }}
            />
            <Input
              placeholder="资源名称"
              value={resourceName}
              onChange={(e) => setResourceName(e.target.value)}
              allowClear
              style={{ width: 150 }}
            />
            <Select
              placeholder="执行结果"
              value={success}
              onChange={setSuccess}
              options={[
                { value: 'true', label: '成功' },
                { value: 'false', label: '失败' },
              ]}
              allowClear
              style={{ width: 100 }}
            />
            <RangePicker
              showTime
              value={
                dateRange[0] && dateRange[1]
                  ? [dayjs(dateRange[0]), dayjs(dateRange[1])]
                  : null
              }
              onChange={(dates) => {
                if (dates) {
                  setDateRange([
                    dates[0]?.toISOString() || null,
                    dates[1]?.toISOString() || null,
                  ]);
                } else {
                  setDateRange([null, null]);
                }
              }}
              style={{ width: 280 }}
            />
            <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>
              搜索
            </Button>
            <Button icon={<ClearOutlined />} onClick={handleReset}>
              重置
            </Button>
            <Tooltip title="刷新">
              <Button icon={<ReloadOutlined />} onClick={() => fetchData()} />
            </Tooltip>
          </Space>
        </div>

        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{
            current: pagination.page,
            pageSize: pagination.page_size,
            total: pagination.total,
            onChange: handleTableChange,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条`,
            pageSizeOptions: ['10', '20', '50', '100'],
          }}
        />
      </Card>

      <Modal
        title="审计日志详情"
        open={detailModalVisible}
        onCancel={handleCloseDetail}
        footer={null}
        width={700}
      >
        {selectedLog && (
          <Descriptions column={1} bordered>
            <Descriptions.Item label="日志ID">{selectedLog.id}</Descriptions.Item>
            <Descriptions.Item label="操作时间">{formatTime(selectedLog.created_at)}</Descriptions.Item>
            <Descriptions.Item label="操作用户">{selectedLog.username || '-'}</Descriptions.Item>
            <Descriptions.Item label="用户ID">{selectedLog.user_id || '-'}</Descriptions.Item>
            <Descriptions.Item label="操作类型">
              <Tag color={getActionColor(selectedLog.action)}>{getActionLabel(selectedLog.action)}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="资源类型">
              <Tag color={getResourceTypeColor(selectedLog.resource_type)}>{getResourceTypeLabel(selectedLog.resource_type)}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="资源名称">{selectedLog.resource_name || '-'}</Descriptions.Item>
            <Descriptions.Item label="资源ID">{selectedLog.resource_id || '-'}</Descriptions.Item>
            <Descriptions.Item label="IP地址">{selectedLog.ip_address || '-'}</Descriptions.Item>
            <Descriptions.Item label="执行状态">
              {selectedLog.success ? (
                <Tag color="green">成功</Tag>
              ) : (
                <Tag color="red">失败</Tag>
              )}
            </Descriptions.Item>
            {selectedLog.error_message && selectedLog.error_message.trim().length > 0 ? (
              <Descriptions.Item label="错误信息">
                <Text type="danger">{selectedLog.error_message}</Text>
              </Descriptions.Item>
            ) : null}
            <Descriptions.Item label="操作详情">{selectedLog.detail || '-'}</Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
};

export default AuditLogs;