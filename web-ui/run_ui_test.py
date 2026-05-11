#!/usr/bin/env python3
"""
Hub Registry UI 自动化测试 - 完整流程
使用 Playwright 进行端到端测试
"""

import subprocess
import sys
import os

# 配置
BASE_URL = "http://192.168.50.60:3000"
API_URL = "http://192.168.50.60:8080"
TEST_IMAGE = "registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1"
SCREENSHOT_DIR = os.path.expanduser("~/workspace/hub-registry/test_screenshots")

def ensure_dir():
    """确保截图目录存在"""
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_test():
    """运行 Playwright 测试"""

    test_script = '''
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
    const BASE_URL = "http://192.168.50.60:3000";
    const API_URL = "http://192.168.50.60:8080";
    const TEST_IMAGE = "registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1";
    const SCREENSHOT_DIR = "''' + SCREENSHOT_DIR + '''";

    console.log("=".repeat(70));
    console.log("Hub Registry UI 自动化测试");
    console.log("测试镜像: " + TEST_IMAGE);
    console.log("=".repeat(70));
    console.log();

    // 启动浏览器（有界面模式）
    console.log("[启动] 正在打开浏览器...");
    const browser = await chromium.launch({
        headless: false,
        slowMo: 50
    });

    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    const page = await context.newPage();

    try {
        // ========== 1. 登录测试 ==========
        console.log("\\n[1/8] 测试登录功能...");
        await page.goto(BASE_URL + '/login');
        await page.waitForSelector('input[placeholder="用户名"]', { timeout: 10000 });
        console.log("  ✓ 登录页面加载成功");

        await page.fill('input[placeholder="用户名"]', 'admin');
        await page.fill('input[placeholder="密码"]', 'admin');
        await page.click('button');
        await page.waitForURL(BASE_URL + '/', { timeout: 10000 });
        console.log("  ✓ 登录成功，已跳转到首页");

        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '01_login_success.png') });

        // ========== 2. 仪表板测试 ==========
        console.log("\\n[2/8] 测试仪表板页面...");
        await page.waitForSelector('.ant-layout', { timeout: 10000 });
        const dashboardContent = await page.content();
        if (dashboardContent.includes('仪表板') || dashboardContent.includes('Dashboard')) {
            console.log("  ✓ 仪表板加载成功");
        }
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '02_dashboard.png') });

        // ========== 3. 命名空间页面测试 ==========
        console.log("\\n[3/8] 测试命名空间页面...");
        await page.click('text=命名空间');
        await page.waitForURL(/.*\\/namespaces/, { timeout: 10000 });
        await page.waitForLoadState('networkidle');
        const nsContent = await page.content();
        if (nsContent.includes('命名空间')) {
            console.log("  ✓ 命名空间页面加载成功");
        }
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '03_namespaces.png') });

        // ========== 4. 镜像仓库页面测试 ==========
        console.log("\\n[4/8] 测试镜像仓库页面...");
        await page.click('text=镜像仓库');
        await page.waitForURL(/.*\\/repositories/, { timeout: 10000 });
        await page.waitForLoadState('networkidle');
        const repoContent = await page.content();
        if (repoContent.includes('镜像仓库')) {
            console.log("  ✓ 镜像仓库页面加载成功");
        }
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '04_repositories.png') });

        // ========== 5. 镜像复制页面测试 ==========
        console.log("\\n[5/8] 测试镜像复制页面...");
        await page.click('text=镜像复制');
        await page.waitForURL(/.*\\/image-transfer/, { timeout: 10000 });
        await page.waitForLoadState('networkidle');

        const transferContent = await page.content();
        const hasUpload = transferContent.includes('镜像上传');
        const hasReplicate = transferContent.includes('镜像复制');

        if (hasUpload && hasReplicate) {
            console.log("  ✓ 镜像复制页面加载成功");
            console.log("  ✓ 发现镜像上传标签页");
            console.log("  ✓ 发现镜像复制标签页");
        } else {
            console.log("  ⚠ 页面内容检查: 上传=" + hasUpload + ", 复制=" + hasReplicate);
        }
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '05_image_transfer.png'), fullPage: true });

        // ========== 6. 切换到镜像复制标签 ==========
        console.log("\\n[6/8] 切换到镜像复制标签...");
        const tabs = await page.locator('.ant-tabs-tab').all();
        let foundReplicateTab = false;
        for (const tab of tabs) {
            const text = await tab.innerText();
            if (text.includes('镜像复制')) {
                await tab.click();
                foundReplicateTab = true;
                break;
            }
        }

        if (foundReplicateTab) {
            console.log("  ✓ 已切换到镜像复制标签");
        } else {
            console.log("  ⚠ 未找到镜像复制标签，可能已经在该标签");
        }

        await page.waitForTimeout(1000);
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '06_replication_tab.png'), fullPage: true });

        // ========== 7. 检查复制策略区域 ==========
        console.log("\\n[7/8] 检查复制策略区域...");
        const policyContent = await page.content();
        const hasPolicySection = policyContent.includes('复制策略');
        const hasHistorySection = policyContent.includes('执行历史');
        const hasEmptyState = policyContent.includes('暂无复制策略');
        const hasCreateBtn = policyContent.includes('新建策略');

        if (hasPolicySection) {
            console.log("  ✓ 发现复制策略区域");
        }
        if (hasHistorySection) {
            console.log("  ✓ 发现执行历史区域");
        }
        if (hasEmptyState) {
            console.log("  ℹ 当前暂无复制策略（空状态）");
        }
        if (hasCreateBtn) {
            console.log("  ✓ 发现新建策略按钮");
        }

        // ========== 8. 系统状态页面测试 ==========
        console.log("\\n[8/8] 测试系统状态页面...");
        await page.click('text=系统状态');
        await page.waitForURL(/.*\\/system/, { timeout: 10000 });
        await page.waitForLoadState('networkidle');
        const systemContent = await page.content();
        if (systemContent.includes('系统状态')) {
            console.log("  ✓ 系统状态页面加载成功");
        }
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '07_system_status.png') });

        // 最终总结
        console.log("\\n" + "=".repeat(70));
        console.log("测试完成！");
        console.log("=".repeat(70));
        console.log("\\n截图文件保存在: " + SCREENSHOT_DIR);
        console.log("文件列表:");
        const files = fs.readdirSync(SCREENSHOT_DIR).filter(f => f.endsWith('.png'));
        files.forEach(f => console.log("  - " + f));

        console.log("\\n浏览器将保持打开 10 秒供您查看...");
        console.log("访问地址: " + BASE_URL);
        await page.waitForTimeout(10000);

    } catch (error) {
        console.error("\\n测试出错: " + error.message);
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'error_screenshot.png'), fullPage: true });
        console.log("错误截图已保存: error_screenshot.png");
    } finally {
        await browser.close();
        console.log("\\n浏览器已关闭");
    }
})();
'''

    # 写入临时文件
    with open('/tmp/playwright_full_test.js', 'w') as f:
        f.write(test_script)

    # 运行测试
    print("=" * 70)
    print("启动 Playwright UI 自动化测试")
    print("=" * 70)
    print(f"\n截图将保存到: {SCREENSHOT_DIR}\n")

    result = subprocess.run(
        ['node', '/tmp/playwright_full_test.js'],
        cwd=SCREENSHOT_DIR
    )

    return result.returncode == 0


def main():
    ensure_dir()
    try:
        success = run_test()
        return 0 if success else 1
    except KeyboardInterrupt:
        print("\n\n测试被用户中断")
        return 1
    except Exception as e:
        print(f"\n\n测试出错: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
