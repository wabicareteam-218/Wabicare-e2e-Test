import { Page } from '@playwright/test';

/**
 * Login via the Microsoft CIAM (Azure AD B2C) external auth flow.
 *
 * Flow:
 *   1. Flutter landing page → Tab + Enter → redirects to ciamlogin.com
 *   2. CIAM email page → fill email → Next
 *   3. CIAM password page → fill password → Sign in
 *   4. "Stay signed in?" → Yes
 *   5. Redirect back to Flutter app with auth code
 *   6. Flutter exchanges code for token
 *   7. Dashboard loads
 *
 * Note: --disable-web-security is required in the Playwright config for
 * keyboard events to reach the Flutter canvas. However, that flag strips
 * the Origin header from cross-origin requests, causing Azure AD's SPA
 * token endpoint to reject the request (AADSTS9002327). We work around
 * this by intercepting the token request and re-adding the Origin header.
 */
export async function login(
  page: Page,
  _baseURL: string,
  email: string,
  password: string
): Promise<void> {
  // --disable-web-security strips the Origin header, causing Azure AD's
  // SPA token endpoint to reject with AADSTS9002327. Proxy the request
  // through Node.js fetch where we can set the Origin header freely.
  await page.route('**/oauth2/v2.0/token', async (route) => {
    const request = route.request();
    const postData = request.postData() || '';
    const url = request.url();

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Origin': 'https://dev.wabicare.com',
        },
        body: postData,
      });
      const body = await res.text();
      await route.fulfill({
        status: res.status,
        contentType: res.headers.get('content-type') || 'application/json',
        body,
      });
    } catch (err) {
      console.log('  → Token proxy error:', err);
      await route.abort();
    }
  });

  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(4000);

  console.log('  → [Login] Step 1: Click Sign In on Flutter landing page (Tab+Enter)…');
  await page.keyboard.press('Tab');
  await page.waitForTimeout(500);
  await page.keyboard.press('Enter');

  console.log('  → [Login] Step 2: Waiting for CIAM auth page…');
  await page.waitForURL(/ciamlogin\.com/, { timeout: 20000 });
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(1000);

  console.log('  → [Login] Step 3: Filling email address…');
  const emailField = page.getByPlaceholder('Email address');
  await emailField.waitFor({ state: 'visible', timeout: 10000 });
  await emailField.fill(email);

  console.log('  → [Login] Step 4: Clicking Next…');
  await page.getByRole('button', { name: 'Next' }).click();

  console.log('  → [Login] Step 5: Filling password…');
  const passwordField = page.getByPlaceholder('Password');
  await passwordField.waitFor({ state: 'visible', timeout: 10000 });
  await passwordField.fill(password);

  console.log('  → [Login] Step 6: Clicking Sign in…');
  await page.getByRole('button', { name: 'Sign in' }).click();

  console.log('  → [Login] Step 7: Handling "Stay signed in?" prompt…');
  try {
    const yesBtn = page.getByRole('button', { name: 'Yes' });
    await yesBtn.waitFor({ state: 'visible', timeout: 10000 });
    await yesBtn.click({ force: true });
  } catch {
    console.log('  → "Stay signed in?" prompt not shown, continuing…');
  }

  console.log('  → [Login] Step 8: Waiting for redirect back to app…');
  await page.waitForURL(/dev\.wabicare\.com/, { timeout: 30000 });
  await page.waitForLoadState('domcontentloaded');

  // Wait for Flutter to exchange the auth code for a token and load the dashboard
  console.log('  → [Login] Step 9: Waiting for Flutter to process auth code…');
  await page.waitForTimeout(12000);

  // Remove the route intercept
  await page.unroute('**/oauth2/v2.0/token');

  console.log('  → [Login] Complete!');
}
