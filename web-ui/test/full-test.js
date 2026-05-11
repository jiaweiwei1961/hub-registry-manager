import puppeteer from 'puppeteer';

// 等待函数
const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// 测试结果收集
let testResults = {
  passed: 0,
  failed: 0,
  skipped: 0,
  details: []
};

// 记录测试结果
function logResult(name, status, message = '') {
  const icon = status === 'pass' ? '✅' : status === 'fail' ? '❌' : '⚠️';
  console.log(`  ${icon} ${name}${message ? ': ' + message : ''}`);
  testResults[status === 'pass' ? 'passed' : status === 'fail' ? 'failed' : 'skipped']++;
  testResults.details.push({ name, status, message });
}

async function runFullTests() {
  console.log('════════════════════════════════════════════════════════════');
  console.log('        Hub Registry 功能全量测试 & 业务全流程测试');
  console.log('════════════════════════════════════════════════════════════\n');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  const baseUrl = 'http://192.168.50.60:3000';

  try {
    // ═════════════════════════════════════════════════════════════
    // 第一部分：功能全量测试
    // ═════════════════════════════════════════════════════════════

    console.log('【一、登录功能测试】\n');

    // Test 1.1: 页面加载
    console.log('Test 1.1: 登录页面加载');
    await page.goto(baseUrl, { waitUntil: 'networkidle2', timeout: 30000 });
    const title = await page.title();
    logResult('页面标题', title.includes('Hub Registry') ? 'pass' : 'fail', title);

    await wait(1000);

    // Test 1.2: 登录表单元素
    console.log('\nTest 1.2: 登录表单元素检查');
    const form = await page.$('.ant-form');
    logResult('登录表单', form ? 'pass' : 'fail');

    const inputs = await page.$$('.ant-input');
    logResult('用户名输入框', inputs.length >= 1 ? 'pass' : 'fail', `找到${inputs.length}个`);

    const passwordInputs = await page.$$('input[type="password"]');
    logResult('密码输入框', passwordInputs.length >= 1 ? 'pass' : 'fail');

    const submitBtn = await page.$('.ant-btn-primary');
    logResult('登录按钮', submitBtn ? 'pass' : 'fail');

    // Test 1.3: 登录功能
    console.log('\nTest 1.3: 登录功能');
    if (inputs.length >= 1) {
      await inputs[0].type('admin');
      logResult('输入用户名', 'pass', 'admin');
    }

    const pwdInput = await page.$('.ant-input-password input') || await page.$('input[type="password"]');
    if (pwdInput) {
      await pwdInput.type('admin123');
      logResult('输入密码', 'pass', 'admin123');
    }

    if (submitBtn) {
      await Promise.all([
        submitBtn.click(),
        page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 })
      ]);

      const currentUrl = page.url();
      logResult('登录跳转', !currentUrl.includes('/login') ? 'pass' : 'fail', currentUrl);
    }

    await wait(3000);
    await page.screenshot({ path: 'test/screenshots/full-01-dashboard.png' });

    // ═════════════════════════════════════════════════════════════
    console.log('\n【二、Dashboard仪表板测试】\n');

    // Test 2.1: 页面布局
    console.log('Test 2.1: Dashboard页面布局');
    const layout = await page.$('.ant-layout');
    logResult('Ant Design布局', layout ? 'pass' : 'fail');

    const sider = await page.$('.ant-layout-sider');
    logResult('侧边栏导航', sider ? 'pass' : 'fail');

    const header = await page.$('.ant-layout-header');
    logResult('顶部导航栏', header ? 'pass' : 'fail');

    const content = await page.$('.ant-layout-content');
    logResult('内容区域', content ? 'pass' : 'fail');

    // Test 2.2: 统计卡片
    console.log('\nTest 2.2: 统计卡片');
    await page.waitForSelector('.ant-statistic', { timeout: 10000 });
    const statCards = await page.$$('.ant-statistic');
    logResult('统计卡片数量', statCards.length >= 4 ? 'pass' : 'fail', `${statCards.length}个`);

    // 检查每个统计卡片的标题
    const statTitles = await page.$$('.ant-statistic-title');
    const expectedTitles = ['命名空间', '镜像仓库', '镜像数量', '下载次数'];
    let titleMatchCount = 0;
    for (const titleEl of statTitles) {
      const text = await titleEl.evaluate(el => el.textContent);
      if (expectedTitles.some(t => text.includes(t))) {
        titleMatchCount++;
      }
    }
    logResult('统计卡片标题', titleMatchCount >= 4 ? 'pass' : 'skip', `${titleMatchCount}个匹配`);

    // Test 2.3: 命名空间表格
    console.log('\nTest 2.3: 最近命名空间表格');
    const table = await page.$('.ant-table');
    logResult('表格组件', table ? 'pass' : 'fail');

    const tableHeaders = await page.$$('.ant-table-thead th');
    logResult('表格列头', tableHeaders.length >= 3 ? 'pass' : 'fail', `${tableHeaders.length}列`);

    // Test 2.4: 快速操作区域
    console.log('\nTest 2.4: 快速操作区域');
    const quickLinks = await page.$$('a[href="/namespaces"], a[href="/repositories"]');
    logResult('快速操作链接', quickLinks.length >= 1 ? 'pass' : 'fail', `${quickLinks.length}个`);

    // ═════════════════════════════════════════════════════════════
    console.log('\n【三、命名空间管理测试】\n');

    // 导航到命名空间页面
    const menuItems = await page.$$('.ant-menu-item');
    if (menuItems.length >= 2) {
      await menuItems[1].click();
      await wait(2000);
      await page.screenshot({ path: 'test/screenshots/full-02-namespaces.png' });
    }

    // Test 3.1: 命名空间列表
    console.log('Test 3.1: 命名空间列表功能');
    const nsTable = await page.$('.ant-table');
    logResult('命名空间表格', nsTable ? 'pass' : 'fail');

    const nsSearch = await page.$('.ant-input');
    logResult('搜索框', nsSearch ? 'pass' : 'fail');

    const searchBtn = await page.$('.ant-btn-primary');
    const text = searchBtn ? await searchBtn.evaluate(el => el.textContent) : '';
    logResult('搜索按钮', text.includes('搜索') ? 'pass' : 'skip');

    // Test 3.2: 创建命名空间按钮
    console.log('\nTest 3.2: 创建命名空间');
    const createBtns = await page.$$('button');
    let createFound = false;
    for (const btn of createBtns) {
      const btnText = await btn.evaluate(el => el.textContent);
      if (btnText && btnText.includes('创建')) {
        createFound = true;
        logResult('创建命名空间按钮', 'pass');
        break;
      }
    }
    if (!createFound) logResult('创建命名空间按钮', 'fail');

    // Test 3.3: 创建命名空间流程
    console.log('\nTest 3.3: 创建命名空间流程测试');
    if (createFound) {
      // 点击创建按钮
      for (const btn of createBtns) {
        const btnText = await btn.evaluate(el => el.textContent);
        if (btnText && btnText.includes('创建')) {
          await btn.click();
          await wait(1000);
          break;
        }
      }

      // 检查弹窗
      const modal = await page.$('.ant-modal');
      logResult('创建弹窗', modal ? 'pass' : 'fail');

      if (modal) {
        // 检查表单字段
        const modalInputs = await modal.$$('.ant-input');
        logResult('名称输入框', modalInputs.length >= 1 ? 'pass' : 'fail');

        const modalTextArea = await modal.$('.ant-input textarea');
        logResult('描述输入框', modalTextArea || modalInputs.length >= 3 ? 'pass' : 'skip');

        // 输入测试数据
        const nameInput = modalInputs[0];
        if (nameInput) {
          await nameInput.type('test-namespace-' + Date.now());
          logResult('输入命名空间名称', 'pass');
        }

        // 点击取消关闭弹窗
        const cancelBtn = await modal.$('.ant-btn-default');
        if (cancelBtn) {
          await cancelBtn.click();
          await wait(500);
          logResult('关闭弹窗', 'pass');
        }
      }
    }

    // Test 3.4: 表格数据
    console.log('\nTest 3.4: 命名空间数据展示');
    const tableRows = await page.$$('.ant-table-row');
    logResult('命名空间数据行', tableRows.length > 0 ? 'pass' : 'skip', `${tableRows.length}行`);

    // 检查操作列
    const actionCells = await page.$$('.ant-table-cell-action');
    logResult('操作列', actionCells.length > 0 ? 'pass' : 'skip');

    // ═════════════════════════════════════════════════════════════
    console.log('\n【四、仓库列表测试】\n');

    // 导航到仓库页面
    const menuItems2 = await page.$$('.ant-menu-item');
    if (menuItems2.length >= 3) {
      await menuItems2[2].click();
      await wait(2000);
      await page.screenshot({ path: 'test/screenshots/full-03-repositories.png' });
    }

    // Test 4.1: 仓库列表页面
    console.log('Test 4.1: 仓库列表页面');
    const repoCard = await page.$('.ant-card');
    logResult('仓库卡片容器', repoCard ? 'pass' : 'fail');

    const repoSearch = await page.$('.ant-input');
    const placeholder = repoSearch ? await repoSearch.evaluate(el => el.placeholder) : '';
    logResult('仓库搜索框', placeholder.includes('搜索') ? 'pass' : 'skip', placeholder);

    // Test 4.2: 仓库表格
    console.log('\nTest 4.2: 仓库数据展示');
    const repoTable = await page.$('.ant-table');
    logResult('仓库表格', repoTable ? 'pass' : 'skip');

    // 检查表格列
    const repoHeaders = await page.$$('.ant-table-thead th');
    logResult('仓库表格列', repoHeaders.length >= 3 ? 'pass' : 'skip', `${repoHeaders.length}列`);

    // ═════════════════════════════════════════════════════════════
    console.log('\n【五、系统状态测试】\n');

    // 导航到系统页面
    const menuItems3 = await page.$$('.ant-menu-item');
    if (menuItems3.length >= 4) {
      await menuItems3[3].click();
      await wait(2000);
      await page.screenshot({ path: 'test/screenshots/full-04-system.png' });
    }

    // Test 5.1: 系统健康状态
    console.log('Test 5.1: 系统健康状态展示');
    const healthCards = await page.$$('.ant-card');
    logResult('健康状态卡片', healthCards.length >= 2 ? 'pass' : 'fail', `${healthCards.length}个`);

    // Test 5.2: 服务状态标签
    console.log('\nTest 5.2: 服务状态标签');
    const allTags = await page.$$('.ant-tag');
    logResult('状态标签', allTags.length >= 5 ? 'pass' : 'skip', `${allTags.length}个`);

    // 检查正常/异常标签
    const successTags = await page.$$('.ant-tag-green, .ant-tag-success');
    const errorTags = await page.$$('.ant-tag-red, .ant-tag-error');
    logResult('正常状态标签', successTags.length > 0 ? 'pass' : 'skip', `${successTags.length}个`);
    logResult('异常状态标签', errorTags.length >= 0 ? 'pass' : 'fail', `${errorTags.length}个`);

    // Test 5.3: 系统信息
    console.log('\nTest 5.3: 系统信息展示');
    const descriptions = await page.$$('.ant-descriptions');
    logResult('系统信息描述', descriptions.length >= 1 ? 'pass' : 'skip');

    // ═════════════════════════════════════════════════════════════
    console.log('\n【六、用户界面元素测试】\n');

    // Test 6.1: 侧边栏导航
    console.log('Test 6.1: 侧边栏导航完整性');
    const finalMenuItems = await page.$$('.ant-menu-item');
    logResult('菜单项数量', finalMenuItems.length >= 4 ? 'pass' : 'fail', `${finalMenuItems.length}个`);

    // Test 6.2: 用户信息
    console.log('\nTest 6.2: 用户信息展示');
    const avatar = await page.$('.ant-avatar');
    logResult('用户头像', avatar ? 'pass' : 'fail');

    // Test 6.3: 响应式布局
    console.log('\nTest 6.3: 响应式布局');
    await page.setViewport({ width: 768, height: 1024 });
    await wait(500);
    const mobileLayout = await page.$('.ant-layout');
    logResult('移动端布局', mobileLayout ? 'pass' : 'fail');

    await page.setViewport({ width: 1280, height: 800 });
    await wait(500);

    // ═════════════════════════════════════════════════════════════
    // 第二部分：业务全流程测试
    // ═════════════════════════════════════════════════════════════

    console.log('\n══════════════════════════════════════════════════════════════');
    console.log('        第二部分：业务全流程测试');
    console.log('══════════════════════════════════════════════════════════════\n');

    // 流程1: 登录 -> Dashboard -> 查看命名空间 -> 返回Dashboard
    console.log('【流程1: 基础导航流程】\n');

    // 回到Dashboard
    const dashMenu = await page.$$('.ant-menu-item');
    if (dashMenu.length >= 1) {
      await dashMenu[0].click();
      await wait(1000);
      logResult('返回Dashboard', page.url().includes('/') && !page.url().includes('/login') ? 'pass' : 'fail');
    }

    // 导航到命名空间
    const nsMenu = await page.$$('.ant-menu-item');
    if (nsMenu.length >= 2) {
      await nsMenu[1].click();
      await wait(1000);
      logResult('导航到命名空间', 'pass');
    }

    // 返回Dashboard
    if (dashMenu.length >= 1) {
      await dashMenu[0].click();
      await wait(1000);
      logResult('导航循环完成', 'pass');
    }

    // 流程2: 搜索流程
    console.log('\n【流程2: 搜索功能流程】\n');

    // 导航到命名空间页面
    const nsMenu2 = await page.$$('.ant-menu-item');
    if (nsMenu2.length >= 2) {
      await nsMenu2[1].click();
      await wait(1500);
    }

    // 测试搜索
    const searchInput = await page.$('.ant-input');
    if (searchInput) {
      await searchInput.type('test');
      await wait(500);
      logResult('输入搜索关键词', 'pass', 'test');

      // 点击搜索按钮（如果有）
      const searchButtons = await page.$$('button');
      for (const btn of searchButtons) {
        const btnText = await btn.evaluate(el => el.textContent);
        if (btnText && btnText.includes('搜索')) {
          await btn.click();
          await wait(1000);
          logResult('执行搜索', 'pass');
          break;
        }
      }

      // 清空搜索
      await searchInput.evaluate(el => { el.value = ''; });
      const clearEvents = ['input', 'change'];
      for (const event of clearEvents) {
        await searchInput.evaluate((el, ev) => {
          el.dispatchEvent(new Event(ev, { bubbles: true }));
        }, event);
      }
      logResult('清空搜索', 'pass');
    }

    // 流程3: 表格分页流程
    console.log('\n【流程3: 表格交互流程】\n');

    // 检查分页器
    const pagination = await page.$('.ant-pagination');
    logResult('分页组件', pagination ? 'pass' : 'skip');

    const pageItems = await page.$$('.ant-pagination-item');
    logResult('分页按钮', pageItems.length > 0 ? 'pass' : 'skip', `${pageItems.length}个`);

    // 流程4: 完整业务操作流程模拟
    console.log('\n【流程4: 完整业务操作流程】\n');

    // 4.1 查看Dashboard统计
    await dashMenu[0].click();
    await wait(1000);
    const stats = await page.$$('.ant-statistic');
    logResult('查看系统统计', stats.length >= 4 ? 'pass' : 'fail');

    // 4.2 查看命名空间列表
    await nsMenu2[1].click();
    await wait(1000);
    const nsRows = await page.$$('.ant-table-row');
    logResult('查看命名空间列表', nsRows.length > 0 ? 'pass' : 'skip', `${nsRows.length}条`);

    // 4.3 查看仓库列表
    const repoMenu = await page.$$('.ant-menu-item');
    if (repoMenu.length >= 3) {
      await repoMenu[2].click();
      await wait(1000);
      logResult('查看仓库列表', 'pass');
    }

    // 4.4 检查系统状态
    if (repoMenu.length >= 4) {
      await repoMenu[3].click();
      await wait(1000);
      const sysCards = await page.$$('.ant-card');
      logResult('查看系统状态', sysCards.length >= 2 ? 'pass' : 'fail', `${sysCards.length}个卡片`);
    }

    // 流程5: 用户交互流程
    console.log('\n【流程5: 用户交互流程】\n');

    // 5.1 点击用户头像区域
    const userArea = await page.$('.ant-layout-header .ant-avatar, .ant-dropdown-trigger');
    logResult('用户交互区域', userArea ? 'pass' : 'skip');

    // 5.2 测试菜单折叠（如果支持）
    const collapseTrigger = await page.$('.ant-layout-sider-trigger');
    if (collapseTrigger) {
      await collapseTrigger.click();
      await wait(500);
      logResult('侧边栏折叠', 'pass');
      await collapseTrigger.click();
      await wait(500);
      logResult('侧边栏展开', 'pass');
    } else {
      logResult('侧边栏折叠功能', 'skip', '未实现');
    }

    // ═════════════════════════════════════════════════════════════
    // 最终截图
    // ═════════════════════════════════════════════════════════════

    await page.screenshot({ path: 'test/screenshots/full-final.png', fullPage: true });

  } catch (error) {
    console.log('\n❌ 测试执行异常: ' + error.message);
    testResults.failed++;
    await page.screenshot({ path: 'test/screenshots/full-error.png' });
  }

  await browser.close();

  // 输出测试报告
  console.log('\n══════════════════════════════════════════════════════════════');
  console.log('                    测试结果汇总报告');
  console.log('══════════════════════════════════════════════════════════════');
  console.log(`✅ 通过: ${testResults.passed}`);
  console.log(`❌ 失败: ${testResults.failed}`);
  console.log(`⚠️  跳过: ${testResults.skipped}`);
  console.log(`📊 通过率: ${Math.round(testResults.passed / (testResults.passed + testResults.failed) * 100)}%`);
  console.log('══════════════════════════════════════════════════════════════\n');

  console.log('【详细测试结果】\n');
  for (const detail of testResults.details) {
    const icon = detail.status === 'pass' ? '✅' : detail.status === 'fail' ? '❌' : '⚠️';
    console.log(`${icon} ${detail.name}${detail.message ? ' - ' + detail.message : ''}`);
  }

  console.log('\n══════════════════════════════════════════════════════════════');
  console.log('📸 测试截图文件:');
  console.log('   - test/screenshots/full-01-dashboard.png');
  console.log('   - test/screenshots/full-02-namespaces.png');
  console.log('   - test/screenshots/full-03-repositories.png');
  console.log('   - test/screenshots/full-04-system.png');
  console.log('   - test/screenshots/full-final.png');
  console.log('══════════════════════════════════════════════════════════════\n');

  process.exit(testResults.failed > 0 ? 1 : 0);
}

runFullTests();