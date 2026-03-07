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

test.describe('Schedule', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Schedule');
  });

  test('schedule page loads with calendar', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Schedule', 'schedule.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Scheduling');
    expect(text).toContain('Team Members');
    expect(text).toContain('Appointment Types');
  });

  test('schedule has view toggle buttons', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Today');
    expect(buttons).toContain('Calendar View');
    expect(buttons).toContain('Table View');
    expect(buttons).toContain('Day');
    expect(buttons).toContain('Week');
    expect(buttons).toContain('Month');
  });

  test('schedule has New appointment button', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('New');
  });

  test('schedule shows appointment types', async ({ page }) => {
    const text = await getPageSemanticText(page);
    expect(text).toContain('Intake');
    expect(text).toContain('Assessment');
    expect(text).toContain('Session');
    expect(text).toContain('Miscellaneous');
  });

  test('switch to Day view', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Day');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Day view', 'day-view.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(100);
  });

  test('switch to Month view', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Month');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Month view', 'month-view.png');
    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(100);
  });
});
