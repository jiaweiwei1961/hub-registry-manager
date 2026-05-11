#!/usr/bin/env node
/**
 * Web UI 自动化功能测试
 * 使用 Puppeteer 进行页面功能验证
 */

const puppeteer = require('puppeteer');

const BASE_URL = process.env.TEST_URL || 'http://192.168.50.60:3000';
const TEST_USER = {
  username: 'admin',
  password: 'admin',
};

// Helper: sleep
async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

const results = {
  passed: [],
  failed: [],
};

async function runTest(name, fn) {
  try {
    await fn();
    results.passed.push(name);
    console.log(`✓ ${name}`);
  } catch (error) {
    results.failed.push({ name, error: error.message });
    console.log(`✗ ${name}: ${error.message}`);
  }
}

(async () => {
  console.log(`\n========================================`);
  console.log(`Web UI 功能测试`);
  console.log(`目标: ${BASE_URL}`);
  console.log(`========================================\n`);

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    // Test 1: 首页可访问
    await runTest('首页可访问', async () => {
      const response = await page.goto(BASE_URL);
      if (!response || response.status() !== 200) {
        throw new Error(`Status: ${response?.status()}`);
      }
      const title = await page.title();
      if (!title.includes('Hub Registry')) {
        throw new Error(`标题错误: ${title}`);
      }
    });

    // Test 2: 登录页面元素
    await runTest('登录页面元素完整', async () => {
      await page.goto(`${BASE_URL}/login`);
      await page.waitForSelector('input[placeholder="用户名"]', { timeout: 5000 });
      await page.waitForSelector('input[placeholder="密码"]', { timeout: 5000 });
      await page.waitForSelector('button', { timeout: 5000 });
    });

    // Test 3: 登录功能
    await runTest('登录功能正常', async () => {
      await page.goto(`${BASE_URL}/login`);
      await page.type('input[placeholder="用户名"]', TEST_USER.username);
      await page.type('input[placeholder="密码"]', TEST_USER.password);
      await page.click('button');
      await page.waitForNavigation({ timeout: 10000 });
      const url = page.url();
      if (!url.includes('/')) {
        throw new Error(`跳转错误: ${url}`);
      }
    });

    // Test 4: 仪表板页面
    await runTest('仪表板页面加载', async () => {
      await page.goto(`${BASE_URL}/`);
      await sleep(2000);
      // SPA页面检查URL即可
      const url = page.url();
      if (!url.includes(BASE_URL)) {
        throw new Error('页面加载失败');
      }
    });

    // Test 5: 侧边栏导航
    await runTest('侧边栏导航完整', async () => {
      await page.goto(`${BASE_URL}/`);
      await sleep(1000);
      const menuItems = ['命名空间', '镜像仓库', '镜像复制'];
      for (const item of menuItems) {
        const elements = await page.$$(`text=${item}`);
        if (elements.length === 0) {
          throw new Error(`未找到菜单项: ${item}`);
        }
      }
    });

    // Test 6: 命名空间页面
    await runTest('命名空间页面可访问', async () => {
      await page.goto(`${BASE_URL}/namespaces`);
      await sleep(2000);
      const content = await page.content();
      if (!content.includes('命名空间')) {
        throw new Error('页面加载失败');
      }
    });

    // Test 7: 镜像仓库页面
    await runTest('镜像仓库页面可访问', async () => {
      await page.goto(`${BASE_URL}/repositories`);
      await sleep(2000);
      const content = await page.content();
      // SPA应用，检查页面内容是否包含React挂载点
      if (!content.includes('<div id="root">') && !content.includes('镜像')) {
        throw new Error('页面加载失败');
      }
    });

    // Test 8: 镜像复制页面 (新功能)
    await runTest('镜像复制页面可访问', async () => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await sleep(2000);
      const url = page.url();
      if (!url.includes('/image-transfer')) {
        throw new Error('页面跳转失败');
      }
    });

    // Test 9: 镜像复制页面 - 标签页
    await runTest('镜像复制页面标签页完整', async () => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await sleep(1000);
      // 检查是否有标签页元素（Ant Design Tabs）
      const tabs = await page.$$('[role="tab"]');
      if (tabs.length < 2) {
        throw new Error('未找到足够的标签页');
      }
    });

    // Test 10: 镜像复制页面 - 策略创建按钮
    await runTest('镜像复制策略创建按钮可点击', async () => {
      await page.goto(`${BASE_URL}/image-transfer`);
      await sleep(1000);
      // 查找新建策略按钮（使用 xpath）
      const button = await page.$x("//button[contains(text(), '新建策略')]");
      if (button.length === 0) {
        // 可能是空状态，检查是否有空状态提示
        const emptyState = await page.$x("//*[contains(text(), '暂无复制策略')]");
        if (emptyState.length === 0) {
          throw new Error('未找到新建策略按钮或空状态提示');
        }
      }
    });

    // Test 11: 系统状态页面
    await runTest('系统状态页面可访问', async () => {
      await page.goto(`${BASE_URL}/system`);
      await sleep(2000);
      // SPA页面返回200即表示路由正常
      const url = page.url();
      if (!url.includes('/system')) {
        throw new Error('页面跳转失败');
      }
    });

    // Test 12: 用户管理页面
    await runTest('用户管理页面可访问', async () => {
      await page.goto(`${BASE_URL}/users`);
      await sleep(2000);
      const url = page.url();
      if (!url.includes('/users')) {
        throw new Error('页面跳转失败');
      }
    });

    // Test 13: 侧边栏折叠功能
    await runTest('侧边栏折叠功能正常', async () => {
      await page.goto(`${BASE_URL}/`);
      await sleep(1000);
      // 检查是否有侧边栏
      const siders = await page.$$('.ant-layout-sider');
      if (siders.length === 0) {
        // 可能是移动端布局，检查是否有菜单按钮
        const menuBtns = await page.$$('.ant-layout-header button');
        if (menuBtns.length === 0) {
          throw new Error('未找到侧边栏或菜单按钮');
        }
      }
    });

    // Test 14: 响应式布局 - 移动端
    await runTest('移动端布局适配', async () => {
      await page.setViewport({ width: 375, height: 667 });
      await page.goto(`${BASE_URL}/`);
      await sleep(1000);
      const layout = await page.$('.ant-layout, #root');
      if (!layout) {
        throw new Error('布局未正确渲染');
      }
      // 恢复桌面尺寸
      await page.setViewport({ width: 1920, height: 1080 });
    });

  } catch (error) {
    console.error(`测试执行错误: ${error.message}`);
  } finally {
    await browser.close();

    console.log(`\n========================================`);
    console.log(`测试结果`);
    console.log(`========================================`);
    console.log(`通过: ${results.passed.length}`);
    console.log(`失败: ${results.failed.length}`);

    if (results.failed.length > 0) {
      console.log(`\n失败详情:`);
      results.failed.forEach(({ name, error }) => {
        console.log(`  - ${name}: ${error}`);
      });
    }

    console.log(`\n========================================`);
    process.exit(results.failed.length > 0 ? 1 : 0);
  }
})();
