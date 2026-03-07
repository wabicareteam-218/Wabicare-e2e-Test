import { test, expect } from '@playwright/test';
import {
  enableAccessibility,
  clickSidebarNav,
  clickFlutterButton,
  getPageSemanticText,
  getFlutterButtons,
  screenshotAndAttach,
  waitForFlutterReady,
} from '../helpers/flutter';
import { DASHBOARD } from '../helpers/locators';

test.setTimeout(90_000);

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
  });

  test('dashboard loads with metric cards', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Dashboard', 'dashboard.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Dashboard');
    expect(text).toContain('Active Patients');
    expect(text).toContain("Today's Sessions");
    expect(text).toContain('Pending Intakes');
    expect(text).toContain('Hours This Week');
  });

  test('dashboard has Refresh and View Calendar buttons', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Refresh');
    expect(buttons).toContain('View Calendar');
  });

  test('dashboard shows schedule and alerts sections', async ({ page }) => {
    const text = await getPageSemanticText(page);
    expect(text).toContain("Today's Schedule");
    expect(text).toContain('Staff Utilization');
    expect(text).toContain('Authorization Alerts');
  });

  test('sidebar shows all navigation items', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    for (const item of ['Dashboard', 'Patients', 'Sessions', 'Schedule', 'Reports', 'Tools', 'Settings']) {
      expect(buttons).toContain(item);
    }
  });

  test('View Calendar button works', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'View Calendar');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Calendar', 'calendar.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(100);
  });
});
