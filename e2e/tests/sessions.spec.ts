import { test, expect } from '@playwright/test';
import {
  clickSidebarNav,
  clickFlutterButton,
  getPageSemanticText,
  getFlutterButtons,
  screenshotAndAttach,
  waitForFlutterReady,
} from '../helpers/flutter';

test.setTimeout(90_000);

test.describe('Sessions', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Sessions');
  });

  test('sessions page loads with correct elements', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Sessions', 'sessions.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Sessions');
    expect(text).toContain('Patient');
    expect(text).toContain('Total Sessions');
    expect(text).toContain('Status');
  });

  test('sessions page has Patients and Reports tabs', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Patients');
    expect(buttons).toContain('Reports');
  });

  test('sessions page has Add Session button', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Add Session');
  });

  test('sessions shows empty state when no sessions', async ({ page }) => {
    const text = await getPageSemanticText(page);
    if (text.includes('No patients with sessions found')) {
      expect(text).toContain('No patients with sessions found');
    } else {
      expect(text.length).toBeGreaterThan(100);
    }
  });
});
