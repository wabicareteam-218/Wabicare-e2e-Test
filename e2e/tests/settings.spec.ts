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

test.describe('Settings', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Settings');
  });

  test('settings page loads with organization info', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Settings', 'settings.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Settings');
    expect(text).toContain('Organization Setup');
    expect(text).toContain('Vanilla Clinic');
  });

  test('settings has sub-tabs', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Organization');
    expect(buttons).toContain('Users');
    expect(buttons).toContain('Intake');
    expect(buttons).toContain('Import');
  });

  test('settings shows organization details', async ({ page }) => {
    const text = await getPageSemanticText(page);
    expect(text).toContain('Organization Name');
    expect(text).toContain('Organization Logo');
  });

  test('settings has Edit and Upload Logo buttons', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Edit');
    expect(buttons).toContain('Upload Logo');
  });

  test('navigate to Users tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Users');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Users', 'users.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });

  test('navigate to Intake settings tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Intake');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Intake settings', 'intake-settings.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });

  test('navigate to Import tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Import');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Import', 'import.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });
});
