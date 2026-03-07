import { test, expect } from '@playwright/test';
import {
  clickSidebarNav,
  clickFlutterButton,
  getPageSemanticText,
  getFlutterButtons,
  screenshotAndAttach,
  waitForFlutterReady,
  enableAccessibility,
} from '../helpers/flutter';

test.setTimeout(90_000);

test.describe('Tools', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Tools');
  });

  test('tools page loads with task management', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Tools', 'tools.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Tools');
    expect(text).toContain('Vanilla Test');
  });

  test('tools has task filter tabs', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    const filterLabels = buttons.filter(b => /^(All|To Do|Done|In Progress)/.test(b));
    expect(filterLabels.length).toBeGreaterThanOrEqual(4);
  });

  test('tools has Tasks, Notes, Documents tabs', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Tasks');
    expect(buttons).toContain('Notes');
    expect(buttons).toContain('Documents');
  });

  test('tools has New Task button', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('New Task');
  });

  test('switch to Notes tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Notes');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Notes', 'notes.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });

  test('switch to Documents tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Documents');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Documents', 'documents.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });
});
