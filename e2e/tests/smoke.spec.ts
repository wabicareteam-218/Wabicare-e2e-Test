/**
 * Smoke test — fast CI gate to verify the app is reachable and login works.
 * Does NOT depend on auth setup (runs independently).
 */
import { test, expect } from '@playwright/test';
import { login } from '../helpers/login';
import { enableAccessibility, getPageSemanticText } from '../helpers/flutter';

test.setTimeout(90_000);

test.describe('Smoke', () => {
  test('landing page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/(Wabi Clinic|wabi_flutter_code)/i, { timeout: 15_000 });
  });

  test('login and verify dashboard', async ({ page }, testInfo) => {
    const email = process.env.E2E_LOGIN_EMAIL;
    const password = process.env.E2E_LOGIN_PASSWORD;
    if (!email || !password) {
      test.skip();
      return;
    }

    await page.goto('/');
    await login(page, '', email, password);
    await enableAccessibility(page);

    const hasToken = await page.evaluate(() => !!localStorage.getItem('flutter.access_token'));
    expect(hasToken).toBe(true);

    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(0);

    const screenshot = testInfo.outputPath('smoke-dashboard.png');
    await page.screenshot({ path: screenshot, fullPage: true });
    await testInfo.attach('dashboard', { path: screenshot, contentType: 'image/png' });
  });
});
