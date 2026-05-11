import { test, expect, Page } from '@playwright/test';

const BASE_URL = process.env.TEST_URL || 'http://localhost:3000';
const TEST_USER = {
  username: 'admin',
  password: 'admin',
};

// Helper: Login before tests
async function login(page: Page) {
  await page.goto(`${BASE_URL}/login`);
  await page.fill('input[placeholder="用户名"]', TEST_USER.username);
  await page.fill('input[placeholder="密码"]', TEST_USER.password);
  await page.click('button:has-text("登录")');
  await page.waitForURL(`${BASE_URL}/`);
}

test.describe('页面功能测试', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  // ========== 登录页面测试 ==========
  test.describe('登录页面', () => {
    test('应正确显示登录表单', async ({ page }) => {
      await page.goto(`${BASE_URL}/login`);
      await expect(page.locator('input[placeholder="用户名"]')).toBeVisible();
      await expect(page.locator('input[placeholder="密码"]')).toBeVisible();
      await expect(page.locator('button:has-text("登录")')).toBeVisible();
    });

    test('登录成功后应跳转到首页', async ({ page }) => {
      await page.goto(`${BASE_URL}/login`);
      await page.fill('input[placeholder="用户名"]', TEST_USER.username);
      await page.fill('input[placeholder="密码"]', TEST_USER.password);
      await page.click('button:has-text("登录")');
      await page.waitForURL(`${BASE_URL}/`);
      await expect(page.url()).toBe(`${BASE_URL}/`);
    });
  });

  // ========== 仪表板页面测试 ==========
  test.describe('仪表板页面', () => {
    test('应显示仪表板基本结构', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);
      await expect(page.locator('text=仪表板')).toBeVisible();
      await expect(page.locator('.ant-layout-sider')).toBeVisible();
      await expect(page.locator('.ant-layout-header')).toBeVisible();
    });

    test('应显示统计卡片', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);
      // 检查是否有统计卡片
      const cards = await page.locator('.ant-card').count();
      expect(cards).toBeGreaterThan(0);
    });
  });

  // ========== 命名空间页面测试 ==========
  test.describe('命名空间页面', () => {
    test('应正确加载命名空间列表', async ({ page }) => {
      await page.goto(`${BASE_URL}/namespaces`);
      await expect(page.locator('text=命名空间')).toBeVisible();
      await expect(page.locator('table, .ant-list')).toBeVisible();
    });

    test('应能打开创建命名空间对话框', async ({ page }) => {
      await page.goto(`${BASE_URL}/namespaces`);
      await page.click('button:has-text("新建")');
      await expect(page.locator('.ant-modal:has-text("创建命名空间")')).toBeVisible();
    });
  });

  // ========== 镜像仓库页面测试 ==========
  test.describe('镜像仓库页面', () => {
    test('应正确加载镜像仓库列表', async ({ page }) => {
      await page.goto(`${BASE_URL}/repositories`);
      await expect(page.locator('text=镜像仓库')).toBeVisible();
      await expect(page.locator('table, .ant-list')).toBeVisible();
    });

    test('应能搜索镜像仓库', async ({ page }) => {
      await page.goto(`${BASE_URL}/repositories`);
      const searchInput = page.locator('input[placeholder*="搜索"]');
      if (await searchInput.isVisible()) {
        await searchInput.fill('nginx');
        await page.waitForTimeout(500);
        // 验证搜索后页面仍在
        await expect(page.locator('text=镜像仓库')).toBeVisible();
      }
    });
  });

  // ========== 镜像复制页面测试 ==========
  test.describe('镜像复制页面', () => {
    test('应正确加载镜像复制页面', async ({ page }) => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await expect(page.locator('text=镜像传输')).toBeVisible();
      // 检查是否有两个标签页
      await expect(page.locator('text=镜像上传')).toBeVisible();
      await expect(page.locator('text=镜像复制')).toBeVisible();
    });

    test('应能切换到镜像复制标签', async ({ page }) => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await page.click('text=镜像复制');
      await expect(page.locator('text=复制策略')).toBeVisible();
      await expect(page.locator('text=执行历史')).toBeVisible();
    });

    test('应能打开创建复制策略对话框', async ({ page }) => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await page.click('text=镜像复制');
      await page.click('button:has-text("新建策略")');
      await expect(page.locator('.ant-modal:has-text("新建复制策略")')).toBeVisible();

      // 验证表单字段
      await expect(page.locator('input[placeholder*="策略名称"]')).toBeVisible();
      await expect(page.locator('input[placeholder*="源Registry"]')).toBeVisible();
    });
  });

  // ========== 系统状态页面测试 ==========
  test.describe('系统状态页面', () => {
    test('应正确加载系统状态页面', async ({ page }) => {
      await page.goto(`${BASE_URL}/system`);
      await expect(page.locator('text=系统状态')).toBeVisible();
      // 检查服务状态卡片
      await expect(page.locator('.ant-card')).toBeVisible();
    });
  });

  // ========== 用户管理页面测试 ==========
  test.describe('用户管理页面', () => {
    test('应正确加载用户管理页面', async ({ page }) => {
      await page.goto(`${BASE_URL}/users`);
      await expect(page.locator('text=用户管理')).toBeVisible();
      await expect(page.locator('table, .ant-list')).toBeVisible();
    });
  });

  // ========== 导航菜单测试 ==========
  test.describe('导航菜单', () => {
    test('应能通过菜单导航到各页面', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);

      // 测试命名空间导航
      await page.click('text=命名空间');
      await expect(page).toHaveURL(/.*\/namespaces/);

      // 测试镜像仓库导航
      await page.click('text=镜像仓库');
      await expect(page).toHaveURL(/.*\/repositories/);

      // 测试镜像复制导航
      await page.click('text=镜像复制');
      await expect(page).toHaveURL(/.*\/image-transfer/);

      // 测试系统状态导航
      await page.click('text=系统状态');
      await expect(page).toHaveURL(/.*\/system/);

      // 测试用户管理导航
      await page.click('text=用户管理');
      await expect(page).toHaveURL(/.*\/users/);
    });

    test('应能折叠/展开侧边栏', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);
      const sider = page.locator('.ant-layout-sider');
      const initialWidth = await sider.evaluate(el => el.offsetWidth);

      // 点击折叠按钮
      await page.click('.ant-btn:has(.anticon-menu-fold), .ant-btn:has(.anticon-menu-unfold)');
      await page.waitForTimeout(300);

      const newWidth = await sider.evaluate(el => el.offsetWidth);
      expect(newWidth).not.toBe(initialWidth);
    });
  });

  // ========== 响应式测试 ==========
  test.describe('响应式布局', () => {
    test('应在不同屏幕尺寸下正常显示', async ({ page }) => {
      // 桌面尺寸
      await page.setViewportSize({ width: 1920, height: 1080 });
      await page.goto(`${BASE_URL}/`);
      await expect(page.locator('.ant-layout-sider')).toBeVisible();

      // 平板尺寸
      await page.setViewportSize({ width: 768, height: 1024 });
      await page.goto(`${BASE_URL}/`);
      await expect(page.locator('.ant-layout')).toBeVisible();

      // 手机尺寸
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto(`${BASE_URL}/`);
      await expect(page.locator('.ant-layout')).toBeVisible();
    });
  });

  // ========== API 集成测试 ==========
  test.describe('API 集成', () => {
    test('应正确加载 API 数据', async ({ page }) => {
      await page.goto(`${BASE_URL}/namespaces`);

      // 等待 API 请求完成
      await page.waitForResponse(response =>
        response.url().includes('/api/v1/namespaces') && response.status() === 200
      );

      // 验证页面已加载数据
      await expect(page.locator('.ant-spin-container, table')).toBeVisible();
    });
  });
});
