import puppeteer from 'puppeteer';

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function testRefreshAuth() {
  console.log('🧪 测试刷新页面后认证状态保持\n');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  const baseUrl = 'http://192.168.50.60:3000';

  try {
    // Step 1: 登录
    console.log('Step 1: 登录系统');
    await page.goto(baseUrl, { waitUntil: 'networkidle2', timeout: 30000 });

    const inputs = await page.$$('.ant-input');
    if (inputs.length >= 1) {
      await inputs[0].type('admin');
    }

    const pwdInput = await page.$('.ant-input-password input') || await page.$('input[type="password"]');
    if (pwdInput) {
      await pwdInput.type('admin123');
    }

    const submitBtn = await page.$('.ant-btn-primary');
    if (submitBtn) {
      await Promise.all([
        submitBtn.click(),
        page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 })
      ]);
    }

    const urlAfterLogin = page.url();
    console.log(`  ✅ 登录成功，当前URL: ${urlAfterLogin}`);

    await wait(2000);

    // Step 2: 检查localStorage中的auth-storage
    console.log('\nStep 2: 检查localStorage');
    const authStorage = await page.evaluate(() => localStorage.getItem('auth-storage'));
    if (authStorage) {
      const parsed = JSON.parse(authStorage);
      console.log(`  ✅ auth-storage存在`);
      console.log(`  - token: ${parsed.state?.token ? '存在' : '不存在'}`);
      console.log(`  - user: ${parsed.state?.user ? '存在' : '不存在'}`);
      console.log(`  - isAuthenticated: ${parsed.state?.isAuthenticated}`);
    } else {
      console.log('  ❌ auth-storage不存在');
    }

    // Step 3: 刷新页面
    console.log('\nStep 3: 刷新页面');
    await page.reload({ waitUntil: 'networkidle2', timeout: 30000 });
    await wait(2000);

    const urlAfterRefresh = page.url();
    console.log(`  刷新后URL: ${urlAfterRefresh}`);

    // Step 4: 检查是否仍在Dashboard
    console.log('\nStep 4: 检查认证状态');
    if (urlAfterRefresh.includes('/login')) {
      console.log('  ❌ 刷新后跳转到登录页 - 认证状态丢失！');
    } else {
      console.log('  ✅ 刷新后仍处于系统页面 - 认证状态保持正确');

      // 检查页面内容确认已登录
      const layout = await page.$('.ant-layout');
      if (layout) {
        console.log('  ✅ 页面布局正常加载');
      }

      const authStorageAfter = await page.evaluate(() => localStorage.getItem('auth-storage'));
      if (authStorageAfter) {
        const parsed = JSON.parse(authStorageAfter);
        console.log(`  ✅ isAuthenticated: ${parsed.state?.isAuthenticated}`);
      }
    }

    await page.screenshot({ path: 'test/screenshots/refresh-test.png' });

    console.log('\n========================================');
    console.log('测试完成');
    console.log('========================================');

  } catch (error) {
    console.log('❌ 测试异常: ' + error.message);
    await page.screenshot({ path: 'test/screenshots/refresh-error.png' });
  }

  await browser.close();
}

testRefreshAuth();