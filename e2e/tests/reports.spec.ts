import { test, expect } from '@playwright/test';
import {
  clickSidebarNav,
  clickFlutterButton,
  fillInputByIndex,
  getPageSemanticText,
  getFlutterButtons,
  screenshotAndAttach,
  waitForFlutterReady,
  enableAccessibility,
} from '../helpers/flutter';

test.setTimeout(90_000);

test.describe('Reports', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Reports');
  });

  test('reports page loads with caseload summary', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Reports', 'reports.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Reports');
    expect(text).toContain('Caseload Summary');
    expect(text).toContain('BCBA Name');
  });

  test('reports has export and generate buttons', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Refresh');
    expect(buttons).toContain('Export Excel');
    expect(buttons).toContain('Export DOC');
    expect(buttons).toContain('Generate');
  });

  test('reports shows BCBA data', async ({ page }) => {
    const text = await getPageSemanticText(page);
    expect(text).toContain('Total');
    expect(text).toContain('Active');
    expect(text).toContain('Authorized');
    expect(text).toContain('Utilization');
  });

  test('filter input is available', async ({ page }, testInfo) => {
    await fillInputByIndex(page, 1, 'test filter');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Filter', 'filter.png');
  });
});
