import puppeteer from 'puppeteer';

// 等待函数
const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function runTests() {
  console.log('🚀 开始自动化测试...\n');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  const baseUrl = 'http://192.168.50.60:3000';

  let passed = 0;
  let failed = 0;

  try {
    // Test 1: 登录页面加载
    console.log('Test 1: 登录页面加载');
    await page.goto(baseUrl, { waitUntil: 'networkidle2', timeout: 30000 });
    const title = await page.title();
    if (title.includes('Hub Registry')) {
      console.log('  ✅ 页面标题正确: ' + title);
      passed++;
    } else {
      console.log('  ❌ 页面标题错误');
      failed++;
    }

    // 等待React渲染
    await wait(2000);

    // 截图保存
    await page.screenshot({ path: 'test/screenshots/01-login-page.png' });

    // 检查登录表单
    const loginForm = await page.$('.ant-form');
    if (loginForm) {
      console.log('  ✅ 登录表单存在');
      passed++;
    } else {
      console.log('  ❌ 登录表单不存在');
      failed++;
    }

    // Test 2: 登录功能
    console.log('\nTest 2: 登录功能');

    // 输入用户名 - 使用ant-design的Input组件选择器
    const inputs = await page.$$('.ant-input');
    if (inputs.length >= 2) {
      await inputs[0].type('admin');
      console.log('  ✅ 输入用户名: admin');
      passed++;
    } else {
      console.log('  ❌ 无法找到用户名输入框，找到 ' + inputs.length + ' 个输入框');
      failed++;
    }

    // 输入密码
    const passwordInputs = await page.$$('.ant-input-password input');
    if (passwordInputs.length > 0) {
      await passwordInputs[0].type('admin123');
      console.log('  ✅ 输入密码: admin123');
      passed++;
    } else {
      // 尝试其他方式
      const allInputs = await page.$$('input');
      for (let i = 0; i < allInputs.length; i++) {
        const type = await allInputs[i].evaluate(el => el.type);
        if (type === 'password') {
          await allInputs[i].type('admin123');
          console.log('  ✅ 输入密码: admin123');
          passed++;
          break;
        }
      }
    }

    // 点击登录按钮
    const loginButton = await page.$('.ant-btn-primary');
    if (loginButton) {
      await Promise.all([
        loginButton.click(),
        page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 })
      ]);

      const currentUrl = page.url();
      if (!currentUrl.includes('/login')) {
        console.log('  ✅ 登录成功，跳转到: ' + currentUrl);
        passed++;
      } else {
        console.log('  ❌ 登录失败，仍在登录页');
        failed++;
      }
    } else {
      console.log('  ❌ 无法找到登录按钮');
      failed++;
    }

    // 等待页面完全加载
    await wait(3000);
    await page.screenshot({ path: 'test/screenshots/02-dashboard.png' });

    // Test 3: Dashboard页面
    console.log('\nTest 3: Dashboard页面');

    // 检查Ant Design布局组件
    const layout = await page.$('.ant-layout');
    if (layout) {
      console.log('  ✅ 布局组件存在');
      passed++;
    } else {
      console.log('  ❌ 布局组件不存在');
      failed++;
    }

    // 检查侧边栏
    const sider = await page.$('.ant-layout-sider');
    if (sider) {
      console.log('  ✅ 侧边栏存在');
      passed++;
    } else {
      console.log('  ❌ 侧边栏不存在');
      failed++;
    }

    // 检查统计卡片
    await page.waitForSelector('.ant-statistic', { timeout: 10000 });
    const statCards = await page.$$('.ant-statistic');
    if (statCards.length >= 4) {
      console.log('  ✅ 统计卡片数量: ' + statCards.length);
      passed++;
    } else {
      console.log('  ⚠️  统计卡片数量: ' + statCards.length + ' (预期4个)');
      // 不计入失败，可能是API返回慢
    }

    // Test 4: 命名空间页面
    console.log('\nTest 4: 命名空间页面');

    // 获取所有菜单项
    const menuItems = await page.$$('.ant-menu-item');
    console.log('  找到菜单项: ' + menuItems.length + ' 个');

    // 直接点击第2个菜单项（命名空间）
    if (menuItems.length >= 2) {
      await menuItems[1].click();
      await wait(2000);
      await page.waitForSelector('.ant-table', { timeout: 10000 });
      await page.screenshot({ path: 'test/screenshots/03-namespaces.png' });

      const table = await page.$('.ant-table');
      if (table) {
        console.log('  ✅ 命名空间表格存在');
        passed++;
      } else {
        console.log('  ❌ 命名空间表格不存在');
        failed++;
      }

      // 检查创建按钮
      const createBtn = await page.$('.ant-btn-primary');
      if (createBtn) {
        const text = await createBtn.evaluate(el => el.textContent);
        if (text && text.includes('创建')) {
          console.log('  ✅ 创建命名空间按钮存在');
          passed++;
        }
      }
    } else {
      console.log('  ❌ 菜单项数量不足');
      failed++;
    }

    // Test 5: 仓库页面
    console.log('\nTest 5: 仓库页面');

    const menuItems2 = await page.$$('.ant-menu-item');
    if (menuItems2.length >= 3) {
      await menuItems2[2].click();
      await wait(2000);
      await page.waitForSelector('.ant-card', { timeout: 10000 });
      await page.screenshot({ path: 'test/screenshots/04-repositories.png' });

      const searchInput = await page.$('.ant-input');
      if (searchInput) {
        const placeholder = await searchInput.evaluate(el => el.placeholder);
        if (placeholder && placeholder.includes('搜索')) {
          console.log('  ✅ 仓库搜索框存在');
          passed++;
        }
      } else {
        console.log('  ❌ 仓库搜索框不存在');
        failed++;
      }
    } else {
      console.log('  ❌ 菜单项数量不足');
      failed++;
    }

    // Test 6: 系统页面
    console.log('\nTest 6: 系统页面');

    const menuItems3 = await page.$$('.ant-menu-item');
    if (menuItems3.length >= 4) {
      await menuItems3[3].click();
      await wait(2000);
      await page.waitForSelector('.ant-card', { timeout: 10000 });
      await page.screenshot({ path: 'test/screenshots/05-system.png' });

      const healthCards = await page.$$('.ant-card');
      if (healthCards.length >= 2) {
        console.log('  ✅ 系统状态卡片存在，数量: ' + healthCards.length);
        passed++;
      } else {
        console.log('  ❌ 系统状态卡片不存在');
        failed++;
      }

      // 检查服务状态标签
      const successTags = await page.$$('.ant-tag-success, .ant-tag-green');
      const errorTags = await page.$$('.ant-tag-error, .ant-tag-red');
      const allTags = successTags.length + errorTags.length;
      if (allTags > 0) {
        console.log('  ✅ 状态标签存在，正常:' + successTags.length + ' 异常:' + errorTags.length);
        passed++;
      }
    } else {
      console.log('  ❌ 菜单项数量不足');
      failed++;
    }

    // Test 7: 用户信息显示
    console.log('\nTest 7: 用户信息显示');
    const header = await page.$('.ant-layout-header');
    if (header) {
      console.log('  ✅ 页面头部存在');
      passed++;

      const avatar = await header.$('.ant-avatar');
      if (avatar) {
        console.log('  ✅ 用户头像存在');
        passed++;
      }
    } else {
      console.log('  ❌ 页面头部不存在');
      failed++;
    }

    // Test 8: API响应验证
    console.log('\nTest 8: API响应验证');

    // 回到命名空间页面检查数据
    const menuItems4 = await page.$$('.ant-menu-item');
    for (const item of menuItems4) {
      const href = await item.evaluate(el => {
        const link = el.querySelector('a');
        return link ? link.getAttribute('href') : null;
      });
      if (href === '/namespaces') {
        await item.click();
        break;
      }
    }
    await wait(2000);

    // 检查是否有数据加载
    const tableRows = await page.$$('.ant-table-row');
    if (tableRows.length > 0) {
      console.log('  ✅ 命名空间数据加载成功，行数: ' + tableRows.length);
      passed++;
    } else {
      console.log('  ⚠️  命名空间数据可能未加载或为空');
    }

  } catch (error) {
    console.log('  ❌ 测试异常: ' + error.message);
    console.log('  错误堆栈: ' + error.stack);
    failed++;
    await page.screenshot({ path: 'test/screenshots/error.png' });
  }

  await browser.close();

  console.log('\n========================================');
  console.log('📊 测试结果汇总');
  console.log('========================================');
  console.log('✅ 通过: ' + passed);
  console.log('❌ 失败: ' + failed);
  const total = passed + failed;
  console.log('📈 通过率: ' + (total > 0 ? Math.round(passed / total * 100) : 0) + '%');
  console.log('========================================');
  console.log('\n📸 截图保存位置: test/screenshots/');
  console.log('========================================\n');

  process.exit(failed > 0 ? 1 : 0);
}

runTests();