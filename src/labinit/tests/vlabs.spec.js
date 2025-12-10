const { test, expect } = require('@playwright/test');

test('vlabs start button flow', async ({ page }) => {
  const user = process.env.SITE_USER;
  const pass = process.env.SITE_PASSWORD;

  await page.goto('https://vlabs.stackroute.in/', { waitUntil: 'domcontentloaded' });

  // Login if credentials provided
  if (user && pass) {
    // Fill username field
    await page.locator('#sl_userName').fill(user);
    
    // Fill password field (try common password selectors)
    const passwordSelectors = ['#sl_password', 'input[name="sl_password"]', 'input[type="password"]'];
    for (const sel of passwordSelectors) {
      const loc = page.locator(sel);
      if (await loc.count() > 0) {
        await loc.first().fill(pass);
        break;
      }
    }
    
    // Click login button
    await page.locator('#user_sign_in_button').click();
    
    // Wait for login to complete and next page to load
    await page.waitForTimeout(2000);
    // Check for cleanup message and wait if present
    for (let i = 0; i < 10; i++) {
      const cleanupMsg = page.locator('h3.progress-text:has-text("Cleanup - InProgress")');
      if (await cleanupMsg.count() === 0) {
        break;
      }
      await page.waitForTimeout(60000); // Wait 1 minute
    }
    // Click View Lab button
    await page.locator('div.btn.btn-default.btn-xs.roundedButton:has-text("View Lab")').click();
    
    // Wait for modal to appear
    await page.waitForTimeout(1000);
    
    // Close the modal dialog
    await page.locator('button[type="button"][data-dismiss="modal"]:has-text("Close")').click();
    
    // Wait for modal to close and page to settle
    await page.waitForTimeout(1000);
  }

  // Wait for Start button and click it
  const btn = page.locator('#leftActionBtn');
  await btn.waitFor({ state: 'visible', timeout: 15000 });
  await btn.click();

  // Wait for deploymentStatus span to appear and validate its text (5 minute timeout)
  const statusSpan = page.locator('#deploymentStatus');
  await statusSpan.waitFor({ state: 'visible', timeout: 300000 });
  await expect(statusSpan).toHaveText('Start - Complete', { timeout: 300000 });
});