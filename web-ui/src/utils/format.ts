/**
 * 格式化时间显示
 * @param timeStr - 时间字符串或Date对象
 * @returns 格式化后的时间字符串，如 "2026-04-23 22:19"
 */
export const formatTime = (timeStr: string | Date | null | undefined): string => {
  if (!timeStr) return '-';

  // 检查是否是Go时间零值（0001-01-01开头）
  if (typeof timeStr === 'string' && (timeStr.startsWith('0001-') || timeStr.startsWith('1-'))) {
    return '-';
  }

  try {
    const date = typeof timeStr === 'string' ? new Date(timeStr) : timeStr;

    // 检查日期是否有效
    if (date.getFullYear() < 2000) return '-';

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}`;
  } catch {
    return typeof timeStr === 'string' ? timeStr : '-';
  }
};

/**
 * 格式化日期显示（不含时间）
 * @param timeStr - 时间字符串或Date对象
 * @returns 格式化后的日期字符串，如 "2026-04-23"
 */
export const formatDate = (timeStr: string | Date | null | undefined): string => {
  if (!timeStr) return '-';

  if (typeof timeStr === 'string' && (timeStr.startsWith('0001-') || timeStr.startsWith('1-'))) {
    return '-';
  }

  try {
    const date = typeof timeStr === 'string' ? new Date(timeStr) : timeStr;

    if (date.getFullYear() < 2000) return '-';

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  } catch {
    return typeof timeStr === 'string' ? timeStr : '-';
  }
};