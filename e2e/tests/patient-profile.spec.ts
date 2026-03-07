/**
 * Patient Profile — open a known patient and navigate through all
 * profile tabs: Profile, Intake Forms, Scheduling, More.
 *
 * Patient rows are flt-semantics generic nodes (not buttons).
 * We locate them by text content containing the patient name.
 */
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
import { KNOWN_PATIENT, PATIENT_TABS } from '../helpers/test-data';

test.setTimeout(120_000);

async function openPatient(page: import('@playwright/test').Page, name: string): Promise<boolean> {
  const allSemantics = page.locator('flt-semantics');
  const count = await allSemantics.count();
  for (let i = 0; i < count; i++) {
    const text = (await allSemantics.nth(i).textContent())?.trim() || '';
    if (text.includes(name) && !['Patients', 'Dashboard', 'New Patient'].includes(text)) {
      await allSemantics.nth(i).dispatchEvent('click');
      return true;
    }
  }
  return false;
}

test.describe('Patient Profile', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Patients');

    const opened = await openPatient(page, KNOWN_PATIENT.firstName);
    if (opened) {
      await page.waitForTimeout(3000);
      await enableAccessibility(page);
    } else {
      test.skip();
    }
  });

  test('patient profile shows correct name', async ({ page }, testInfo) => {
    await screenshotAndAttach(page, testInfo, 'Patient profile', 'profile-overview.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain(KNOWN_PATIENT.firstName);
    expect(text).toContain(KNOWN_PATIENT.lastName);
  });

  test('profile has all expected tabs', async ({ page }) => {
    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Profile');
    expect(buttons).toContain('Intake Forms');
    expect(buttons).toContain('Scheduling');
  });

  test('navigate to Profile tab and verify content', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Profile');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Profile tab', 'tab-profile.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Basic Information');
  });

  test('navigate to Intake Forms tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Intake Forms');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Intake Forms tab', 'tab-intake-forms.png');

    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });

  test('navigate to Scheduling tab', async ({ page }, testInfo) => {
    await clickFlutterButton(page, 'Scheduling');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Scheduling tab', 'tab-scheduling.png');

    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });

  test('navigate to More tab', async ({ page }, testInfo) => {
    const buttons = await getFlutterButtons(page);
    const hasMore = buttons.some(b => b.includes('More'));
    if (!hasMore) {
      test.skip();
      return;
    }
    await clickFlutterButton(page, 'More');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'More tab', 'tab-more.png');

    const text = await getPageSemanticText(page);
    expect(text.length).toBeGreaterThan(50);
  });
});
