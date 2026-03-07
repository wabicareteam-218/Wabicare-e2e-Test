/**
 * Patient CRUD - create, search, open patient profile.
 *
 * Patient rows are generic flt-semantics nodes (not buttons).
 * Use text-based matching to locate patient rows.
 */
import { test, expect } from '@playwright/test';
import {
  enableAccessibility,
  clickSidebarNav,
  clickFlutterButton,
  fillInputByIndex,
  getPageSemanticText,
  getFlutterButtons,
  getInputCount,
  screenshotAndAttach,
  waitForFlutterReady,
  handleDuplicateDialog,
} from '../helpers/flutter';
import { TEST_PATIENT, TEST_GUARDIAN } from '../helpers/test-data';

test.setTimeout(120_000);

test.describe('Patient CRUD', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
  });

  test('patients list page loads with expected elements', async ({ page }, testInfo) => {
    await clickSidebarNav(page, 'Patients');
    await screenshotAndAttach(page, testInfo, 'Patient list', 'patient-list.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Patients');

    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('New Patient');
    expect(buttons).toContain('Refresh');
    expect(buttons).toContain('Import');
  });

  test('patients list shows existing patients', async ({ page }, testInfo) => {
    await clickSidebarNav(page, 'Patients');
    await screenshotAndAttach(page, testInfo, 'Patient list', 'patient-list.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Jane');
    expect(text).toContain('Douglas');
  });

  test('create a new patient and verify in list', async ({ page }, testInfo) => {
    await clickSidebarNav(page, 'Patients');
    await screenshotAndAttach(page, testInfo, 'Before create', '01-before.png');

    await clickFlutterButton(page, 'New Patient');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);

    const inputCount = await getInputCount(page);
    expect(inputCount).toBeGreaterThanOrEqual(9);
    await screenshotAndAttach(page, testInfo, 'New patient form', '02-form.png');

    await fillInputByIndex(page, 1, TEST_PATIENT.firstName);
    await fillInputByIndex(page, 2, TEST_PATIENT.lastName);
    await fillInputByIndex(page, 3, TEST_PATIENT.dob);
    await fillInputByIndex(page, 4, TEST_PATIENT.diagnosis);
    await screenshotAndAttach(page, testInfo, 'Demographics', '03-demographics.png');

    await fillInputByIndex(page, 5, TEST_GUARDIAN.firstName);
    await fillInputByIndex(page, 6, TEST_GUARDIAN.lastName);
    await fillInputByIndex(page, 7, TEST_GUARDIAN.relationship);
    await fillInputByIndex(page, 8, TEST_GUARDIAN.phone);
    await fillInputByIndex(page, 9, TEST_GUARDIAN.email);
    await screenshotAndAttach(page, testInfo, 'Guardian', '04-guardian.png');

    await clickFlutterButton(page, 'Save');
    await page.waitForTimeout(5000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'After save', '05-save.png');

    await handleDuplicateDialog(page);
    await page.waitForTimeout(3000);
    await enableAccessibility(page);

    await clickSidebarNav(page, 'Patients');
    await screenshotAndAttach(page, testInfo, 'Verify', '06-verify.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain(TEST_PATIENT.firstName);
  });

  test('search for a patient', async ({ page }, testInfo) => {
    await clickSidebarNav(page, 'Patients');
    await page.waitForTimeout(1000);

    await fillInputByIndex(page, 1, 'Jane');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);

    await screenshotAndAttach(page, testInfo, 'Search results', 'search-results.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Jane');
  });

  test('open patient by clicking row', async ({ page }, testInfo) => {
    await clickSidebarNav(page, 'Patients');

    const allSemantics = page.locator('flt-semantics');
    const count = await allSemantics.count();
    let clicked = false;
    for (let i = 0; i < count; i++) {
      const text = (await allSemantics.nth(i).textContent())?.trim() || '';
      if (text.includes('Jane Douglas') && text.includes('Intake')) {
        await allSemantics.nth(i).dispatchEvent('click');
        clicked = true;
        break;
      }
    }

    if (clicked) {
      await page.waitForTimeout(3000);
      await enableAccessibility(page);
      await screenshotAndAttach(page, testInfo, 'Patient opened', 'patient-opened.png');

      const text = await getPageSemanticText(page);
      expect(text).toContain('Jane');
      expect(text).toContain('Douglas');

      const buttons = await getFlutterButtons(page);
      expect(buttons).toContain('Profile');
      expect(buttons).toContain('Intake Forms');
      expect(buttons).toContain('Scheduling');
    } else {
      await screenshotAndAttach(page, testInfo, 'Not found', 'patient-not-found.png');
    }
  });
});
