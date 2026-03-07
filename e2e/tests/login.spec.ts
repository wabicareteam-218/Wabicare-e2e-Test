/**
 * Login flow tests — verify the CIAM auth flow works end-to-end.
 * This file does NOT depend on auth.setup (it performs its own login).
 */
import { test, expect } from '@playwright/test';
import { login } from '../helpers/login';
import { enableAccessibility, getPageSemanticText, screenshotAndAttach } from '../helpers/flutter';

test.use({ storageState: { cookies: [], origins: [] } });
test.setTimeout(90_000);

test.describe('Login', () => {
  test('landing page loads with Wabi Clinic title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/(Wabi Clinic|wabi_flutter_code)/i, { timeout: 15_000 });
  });

  test('landing page shows Sign In button', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);

    const text = await getPageSemanticText(page);
    expect(text).toContain('Sign In');
  });

  test('user can log in with email and password', async ({ page }, testInfo) => {
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

    await screenshotAndAttach(page, testInfo, 'Post-login dashboard', 'login-dashboard.png');

    const title = await page.title();
    expect(title).toBeTruthy();

    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(0);
  });
});
