#!/usr/bin/env python3
"""
Test image replication progress display on Repository Detail page.
"""
import sys
import os
import time

# Add skill directory to path
sys.path.insert(0, '/Users/jiaweiwei/.claude/skills/webapp-testing')

from playwright.sync_api import sync_playwright

def test_replication_progress():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        print("1. Navigate to login page...")
        page.goto('http://192.168.50.60:3000')
        page.wait_for_load_state('networkidle')

        # Login
        print("2. Login with admin credentials...")
        page.fill('input[type="text"]', 'admin')
        page.fill('input[type="password"]', 'admin123')
        page.click('button[type="submit"]')

        # Wait for login to complete
        page.wait_for_load_state('networkidle')
        time.sleep(2)

        # Check if we're logged in by checking for navigation menu
        nav = page.locator('nav, .ant-menu, .ant-layout-sider')
        if nav.count() > 0:
            print("   Login successful!")
        else:
            print("   Checking for login status...")
            # Take screenshot to debug
            page.screenshot(path='/tmp/login_debug.png')
            print("   Saved debug screenshot to /tmp/login_debug.png")

        # Navigate to repositories
        print("3. Navigate to repositories page...")
        # Find repositories menu item
        repo_menu = page.locator('text=镜像仓库, text=仓库, :text-is("Repositories")')
        if repo_menu.count() > 0:
            repo_menu.first.click()
        else:
            # Try navigation link
            page.click('a[href*="/repositories"]')

        page.wait_for_load_state('networkidle')
        time.sleep(1)

        # Find a repository and click to view details
        print("4. Find and click on a repository name link...")
        # Debug: take screenshot
        page.screenshot(path='/tmp/repos_page.png')
        print("   Saved repos page screenshot")

        # Click on the repository name link (blue link)
        repo_name_link = page.locator('table tbody tr td a').first
        if repo_name_link.count() > 0:
            print(f"   Found repository name link: {repo_name_link.text_content()}")
            repo_name_link.click()
        else:
            # Alternative: use the navigation with href
            repo_links = page.locator('a[href*="/repositories/"]').all()
            if len(repo_links) > 0:
                print(f"   Found {len(repo_links)} repository links")
                repo_links[0].click()
            else:
                print("   No repository links found")
                return

        page.wait_for_load_state('networkidle')
        time.sleep(2)

        # Debug: take screenshot of detail page
        page.screenshot(path='/tmp/detail_page.png')
        print("   Saved detail page screenshot")

        print("5. Looking for '复制镜像' button on detail page...")
        # Find the replicate button - it's a Button with text "复制镜像"
        all_buttons = page.locator('button').all()
        print(f"   Found {len(all_buttons)} buttons on page")

        replicate_btn = None
        for btn in all_buttons:
            text = btn.text_content()
            print(f"   Button: '{text}'")
            if '复制' in text:
                replicate_btn = btn
                break

        if replicate_btn:
            print(f"   Clicking replicate button: '{replicate_btn.text_content()}'")
            replicate_btn.click()
            time.sleep(1)
        else:
            print("   No replicate button found on detail page")
            return

        # Check if modal appeared
        print("6. Check for replication modal...")
        modal = page.locator('.ant-modal-content')
        if modal.count() > 0:
            print("   Modal appeared!")

            # Enter source image
            print("7. Enter source image address...")
            source_input = page.locator('input[placeholder*="源镜像"]').first
            if source_input.count() > 0:
                source_input.fill('registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1')
            else:
                # Try alternative selector
                page.locator('.ant-modal input').first.fill('registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1')

            time.sleep(0.5)

            # Click submit button
            print("8. Click submit button...")
            submit_btn = page.locator('.ant-modal button:has-text("开始复制")')
            if submit_btn.count() > 0:
                submit_btn.click()
            else:
                page.click('.ant-modal button:has-text("确定")')

            print("9. Wait for progress bar...")
            time.sleep(2)

            # Check for progress bar
            progress = page.locator('.ant-progress')
            if progress.count() > 0:
                print("   Progress bar found!")

                # Get task ID from modal
                task_id_elem = page.locator('text=任务ID')
                if task_id_elem.count() > 0:
                    print(f"   Task ID element: {task_id_elem.text_content()}")

                # Wait for progress updates (max 60 seconds)
                print("10. Polling for task status updates...")
                for i in range(20):
                    time.sleep(3)

                    # Check progress percentage
                    progress_text = page.locator('.ant-progress-text')
                    if progress_text.count() > 0:
                        pct = progress_text.text_content()
                        print(f"   Progress: {pct}")

                    # Check if modal still visible - if closed, task completed
                    modal_content = page.locator('.ant-modal-content')
                    modal_count = modal_content.count()
                    print(f"   Modal visible: {modal_count}")

                    if modal_count == 0:
                        print("   ✓ Modal closed - replication completed!")
                        # Check for success message on page
                        success_msg = page.locator('.ant-message-success')
                        if success_msg.count() > 0:
                            print(f"   Success message: {success_msg.text_content()}")
                        break

                    # Get all text content from modal to find status
                    modal_text = modal_content.text_content()
                    print(f"   Modal text preview: {modal_text[:100]}...")

                    # Check for success/failure keywords in modal
                    if '成功' in modal_text:
                        print("   ✓ Replication SUCCESS!")
                        break
                    elif '失败' in modal_text:
                        print("   ✗ Replication FAILED!")
                        break

                    # Also check if modal closed (means success)
                    modal_check = page.locator('.ant-modal-content')
                    if modal_check.count() == 0:
                        print("   Modal closed - task likely completed!")
                        break
            else:
                print("   No progress bar found - checking for task creation...")
                task_id = page.locator('text*="任务ID"')
                if task_id.count() > 0:
                    print(f"   Task created: {task_id.text_content()}")
                else:
                    print("   Task might be processing without visible progress...")
        else:
            print("   Modal not found!")

        # Take screenshot for verification
        print("11. Taking screenshot...")
        page.screenshot(path='/tmp/replication_test_result.png', full_page=True)

        # Close browser
        browser.close()

        print("\nTest completed. Check screenshot at /tmp/replication_test_result.png")

if __name__ == '__main__':
    test_replication_progress()