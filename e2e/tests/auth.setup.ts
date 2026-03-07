import { test as setup } from '@playwright/test';
import { login } from '../helpers/login';
import { enableAccessibility } from '../helpers/flutter';

const AUTH_FILE = 'tests/.auth/user.json';

setup('authenticate', async ({ page }) => {
  const email = process.env.E2E_LOGIN_EMAIL;
  const password = process.env.E2E_LOGIN_PASSWORD;
  if (!email || !password) {
    throw new Error('E2E_LOGIN_EMAIL and E2E_LOGIN_PASSWORD must be set');
  }

  await page.goto('/');
  await login(page, '', email, password);
  await enableAccessibility(page);

  const hasToken = await page.evaluate(() => !!localStorage.getItem('flutter.access_token'));
  if (!hasToken) {
    throw new Error('Login failed — no access token in localStorage');
  }

  await page.context().storageState({ path: AUTH_FILE });
});
