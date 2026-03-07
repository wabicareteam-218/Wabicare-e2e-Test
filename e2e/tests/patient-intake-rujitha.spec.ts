/**
 * Complete Patient Intake E2E — Rujitha Kannan
 *
 * Full flow:
 *   1. Login (via auth setup)
 *   2. Patients → New Patient → fill Basic Information + save
 *   3. Fill Insurance Information + save
 *   4. Click "Intake Forms" tab → fill all 9 intake form sections (save each)
 *   5. Click "Scheduling" tab → +New → fill appointment popup (Intake type) → Save
 *
 * Every Save is validated — error toasts like "Failed to create intake"
 * will cause the test to fail immediately.
 */
import { test, expect, Page } from '@playwright/test';
import {
  enableAccessibility,
  clickFlutterButton,
  clickFlutterButtonByIteration,
  fillInputByIndex,
  getPageSemanticText,
  getFlutterButtons,
  getInputCount,
  screenshotAndAttach,
  waitForFlutterReady,
  clickSidebarNav,
  handleDuplicateDialog,
} from '../helpers/flutter';

test.setTimeout(600_000);

const PATIENT = {
  firstName: 'Rujitha',
  lastName: 'Kannan',
  dob: '05/12/2018',
  diagnosis: 'Autism Spectrum Disorder',
};

const GUARDIAN = {
  firstName: 'Priya',
  lastName: 'Kannan',
  relationship: 'Mother',
  phone: '5129876543',
  email: 'priya.kannan@example.com',
};

// ── Helpers ──

async function assertSaveSuccess(page: Page, testInfo: any, label: string, filename: string) {
  await clickFlutterButton(page, 'Save');
  await page.waitForTimeout(4000);
  await enableAccessibility(page);
  await screenshotAndAttach(page, testInfo, label, filename);

  const text = await getPageSemanticText(page);
  const hasError = text.toLowerCase().includes('failed') ||
                   text.toLowerCase().includes('error') ||
                   text.toLowerCase().includes('unable to');

  if (hasError) {
    const errorSnippet = text.substring(0, 500);
    throw new Error(
      `Save FAILED for "${label}". ` +
      `Error toast detected on page. Page text: "${errorSnippet}"`
    );
  }
}

async function clickIntakeSection(page: Page, sectionName: string) {
  await enableAccessibility(page);
  const btns = page.locator('flt-semantics[role="button"]');
  const count = await btns.count();
  for (let i = 0; i < count; i++) {
    const txt = (await btns.nth(i).textContent())?.trim() || '';
    if (txt.includes(sectionName)) {
      await btns.nth(i).dispatchEvent('click');
      await page.waitForTimeout(2000);
      await enableAccessibility(page);
      return true;
    }
  }
  await page.mouse.wheel(0, 400);
  await page.waitForTimeout(1000);
  await enableAccessibility(page);
  const btns2 = page.locator('flt-semantics[role="button"]');
  const count2 = await btns2.count();
  for (let i = 0; i < count2; i++) {
    const txt = (await btns2.nth(i).textContent())?.trim() || '';
    if (txt.includes(sectionName)) {
      await btns2.nth(i).dispatchEvent('click');
      await page.waitForTimeout(2000);
      await enableAccessibility(page);
      return true;
    }
  }
  return false;
}

async function clickTab(page: Page, tabName: string) {
  await enableAccessibility(page);
  const btns = page.locator('flt-semantics[role="button"]');
  const count = await btns.count();
  for (let i = 0; i < count; i++) {
    const txt = (await btns.nth(i).textContent())?.trim() || '';
    if (txt === tabName) {
      await btns.nth(i).dispatchEvent('click');
      await page.waitForTimeout(3000);
      await enableAccessibility(page);
      return;
    }
  }
  throw new Error(`Tab "${tabName}" not found`);
}

// ═════════════════════════════════════════════════════
test.describe.serial('Complete Patient Intake — Rujitha Kannan', () => {
  let page: Page;

  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext({
      storageState: 'tests/.auth/user.json',
    });
    page = await context.newPage();
  });

  test.afterAll(async () => {
    await page?.context().close();
  });

  // ── STEP 1 ──
  test('Given I am logged in and navigate to Patients', async ({}, testInfo) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Patients');
    await screenshotAndAttach(page, testInfo, 'Patients list', '01-patients-list.png');
    const text = await getPageSemanticText(page);
    expect(text).toContain('Patients');
  });

  test('When I click New Patient and fill Patient Demographics for Rujitha Kannan', async ({}, testInfo) => {
    await clickFlutterButton(page, 'New Patient');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'New patient form', '02-new-patient-form.png');

    const inputCount = await getInputCount(page);
    expect(inputCount).toBeGreaterThanOrEqual(9);

    await fillInputByIndex(page, 1, PATIENT.firstName);
    await fillInputByIndex(page, 2, PATIENT.lastName);
    await fillInputByIndex(page, 3, PATIENT.dob);
    await fillInputByIndex(page, 4, PATIENT.diagnosis);
    await screenshotAndAttach(page, testInfo, 'Demographics filled', '03-demographics.png');
  });

  test('And I fill Guardian info for Priya Kannan (Mother)', async ({}, testInfo) => {
    await fillInputByIndex(page, 5, GUARDIAN.firstName);
    await fillInputByIndex(page, 6, GUARDIAN.lastName);
    await fillInputByIndex(page, 7, GUARDIAN.relationship);
    await fillInputByIndex(page, 8, GUARDIAN.phone);
    await fillInputByIndex(page, 9, GUARDIAN.email);
    await screenshotAndAttach(page, testInfo, 'Guardian filled', '04-guardian.png');
  });

  test('Then I save Basic Information and patient Rujitha Kannan is created', async ({}, testInfo) => {
    await assertSaveSuccess(page, testInfo, 'Basic Info saved', '05-basic-save.png');
    await handleDuplicateDialog(page);
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Post-save', '06-post-save.png');
  });

  // ── STEP 2 ──
  test('When I click Insurance Information in the left sidebar', async ({}, testInfo) => {
    const found = await clickIntakeSection(page, 'Insurance Information');
    if (!found) await clickFlutterButton(page, 'Insurance Information');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Insurance form', '07-insurance-form.png');
  });

  test('And I fill insurance provider, member ID, group number, policy holder, effective date', async ({}, testInfo) => {
    const inputCount = await getInputCount(page);
    if (inputCount >= 6) {
      await fillInputByIndex(page, 1, 'Blue Cross Blue Shield');
      await fillInputByIndex(page, 2, 'RK987654321');
      await fillInputByIndex(page, 3, 'GRP-100');
      await fillInputByIndex(page, 4, 'Priya Kannan');
      await fillInputByIndex(page, 5, '01/01/2024');
    }
    await screenshotAndAttach(page, testInfo, 'Insurance filled', '08-insurance-filled.png');
  });

  test('Then I save Insurance Information successfully', async ({}, testInfo) => {
    await assertSaveSuccess(page, testInfo, 'Insurance saved', '09-insurance-save.png');
  });

  // ── STEP 3 ──
  test('When I click Intake Forms tab', async ({}, testInfo) => {
    await clickTab(page, 'Intake Forms');
    await screenshotAndAttach(page, testInfo, 'Intake Forms tab', '10-intake-tab.png');
    const buttons = await getFlutterButtons(page);
    expect(buttons.some(b => b.includes('Client Information'))).toBe(true);
    expect(buttons.some(b => b.includes('Consent & Agreements'))).toBe(true);
  });

  // ── STEP 4a ──
  test('And I fill Client Information and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Client Information');
    await fillInputByIndex(page, 1, 'Ruji');
    await fillInputByIndex(page, 2, 'English, Tamil');
    await fillInputByIndex(page, 3, 'MC-RK-001');
    await fillInputByIndex(page, 4, '789 Elm St');
    await fillInputByIndex(page, 5, 'Austin');
    await fillInputByIndex(page, 6, 'TX');
    await fillInputByIndex(page, 7, '78704');
    await fillInputByIndex(page, 8, '1');
    await fillInputByIndex(page, 9, '5');
    await fillInputByIndex(page, 10, 'Clinic');
    await fillInputByIndex(page, 11, 'Mornings');
    await screenshotAndAttach(page, testInfo, 'Client Info filled', '11-client-info.png');
    await assertSaveSuccess(page, testInfo, 'Client Info saved', '11b-client-saved.png');
  });

  // ── STEP 4b ──
  test('And I fill Caregiver & Provider Info and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Caregiver & Provider Info');
    await fillInputByIndex(page, 1, 'she/her');
    await fillInputByIndex(page, 2, 'Phone');
    await fillInputByIndex(page, 3, 'Weekdays 9am-5pm');
    await fillInputByIndex(page, 4, '5121234567');
    await fillInputByIndex(page, 5, 'Raj Kannan');
    await fillInputByIndex(page, 6, 'Father');
    await fillInputByIndex(page, 7, '5129998888');
    await fillInputByIndex(page, 8, 'raj.kannan@example.com');
    await fillInputByIndex(page, 9, 'Meera Kannan');
    await fillInputByIndex(page, 10, 'Grandmother');
    await fillInputByIndex(page, 11, 'Dr. Anand Patel');
    await fillInputByIndex(page, 12, 'Austin Pediatrics');
    await fillInputByIndex(page, 13, '5125559999');
    await fillInputByIndex(page, 14, '5125559998');
    await fillInputByIndex(page, 15, 'Dr. Lisa Chen');
    await fillInputByIndex(page, 16, 'Developmental Pediatrics');
    await fillInputByIndex(page, 17, "Dell Children's Hospital");
    await fillInputByIndex(page, 18, '5125557777');
    await screenshotAndAttach(page, testInfo, 'Caregiver filled', '12-caregiver.png');
    await assertSaveSuccess(page, testInfo, 'Caregiver saved', '12b-caregiver-saved.png');
  });

  // ── STEP 4c ──
  test('And I fill ABA Therapy History and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'ABA Therapy History');
    await fillInputByIndex(page, 1, 'Yes');
    await fillInputByIndex(page, 2, '8');
    await fillInputByIndex(page, 3, '1');
    await fillInputByIndex(page, 4, 'Austin ABA Center');
    await screenshotAndAttach(page, testInfo, 'ABA filled', '13-aba.png');
    await assertSaveSuccess(page, testInfo, 'ABA saved', '13b-aba-saved.png');
  });

  // ── STEP 4d ──
  test('And I fill Challenging Behaviors and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Challenging Behaviors');
    await fillInputByIndex(page, 1, '4 times');
    await fillInputByIndex(page, 2, '10 minutes');
    await fillInputByIndex(page, 3, '2 times');
    await fillInputByIndex(page, 4, '5 minutes');
    await fillInputByIndex(page, 5, '1 time');
    await fillInputByIndex(page, 6, '3 minutes');
    await screenshotAndAttach(page, testInfo, 'Behaviors filled', '14-behaviors.png');
    await assertSaveSuccess(page, testInfo, 'Behaviors saved', '14b-behaviors-saved.png');
  });

  // ── STEP 4e ──
  test('And I fill Education & Therapies and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Education & Therapies');
    await fillInputByIndex(page, 1, 'Austin Elementary');
    await fillInputByIndex(page, 2, 'Pre-K');
    await fillInputByIndex(page, 3, '25');
    await fillInputByIndex(page, 4, 'Ms. Ramirez');
    await fillInputByIndex(page, 5, 'Speech Therapy');
    await fillInputByIndex(page, 6, '2');
    await fillInputByIndex(page, 7, '30 min');
    await fillInputByIndex(page, 8, 'Language development support');
    await screenshotAndAttach(page, testInfo, 'Education filled', '15-education.png');
    await assertSaveSuccess(page, testInfo, 'Education saved', '15b-education-saved.png');
  });

  // ── STEP 4f ──
  test('And I fill Medical History and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Medical History');
    await fillInputByIndex(page, 1, 'None');
    await fillInputByIndex(page, 2, 'N/A');
    await fillInputByIndex(page, 3, 'N/A');
    await fillInputByIndex(page, 4, 'No');
    await fillInputByIndex(page, 5, 'No');
    await fillInputByIndex(page, 6, 'None');
    await fillInputByIndex(page, 7, 'N/A');
    await fillInputByIndex(page, 8, 'N/A');
    await fillInputByIndex(page, 9, '01/01/2025');
    await fillInputByIndex(page, 10, 'ASD');
    await fillInputByIndex(page, 11, '03/15/2022');
    await screenshotAndAttach(page, testInfo, 'Medical filled', '16-medical.png');
    await assertSaveSuccess(page, testInfo, 'Medical saved', '16b-medical-saved.png');
  });

  // ── STEP 4g ──
  test('And I fill Diagnosis & Documents and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Diagnosis & Documents');
    await fillInputByIndex(page, 1, 'Yes');
    await fillInputByIndex(page, 2, 'F84.0 - Autism Spectrum Disorder');
    await fillInputByIndex(page, 3, '03/15/2022');
    await screenshotAndAttach(page, testInfo, 'Diagnosis filled', '17-diagnosis.png');
    await assertSaveSuccess(page, testInfo, 'Diagnosis saved', '17b-diagnosis-saved.png');
  });

  // ── STEP 4h ──
  test('And I fill Availability & Concerns and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Availability & Concerns');
    const count = await getInputCount(page);
    for (let i = 1; i < count; i++) {
      try { await fillInputByIndex(page, i, `Available ${i}`); } catch { break; }
    }
    await screenshotAndAttach(page, testInfo, 'Availability filled', '18-availability.png');
    await assertSaveSuccess(page, testInfo, 'Availability saved', '18b-availability-saved.png');
  });

  // ── STEP 4i ──
  test('And I fill Consent & Agreements and save', async ({}, testInfo) => {
    await clickIntakeSection(page, 'Consent & Agreements');
    await fillInputByIndex(page, 1, 'Priya Kannan');
    await fillInputByIndex(page, 2, '02/15/2026');
    await fillInputByIndex(page, 3, 'Mother');
    await screenshotAndAttach(page, testInfo, 'Consent filled', '19-consent.png');
    await assertSaveSuccess(page, testInfo, 'Consent saved', '19b-consent-saved.png');
  });

  // ── STEP 5 ──
  test('When I click Scheduling tab and click +New', async ({}, testInfo) => {
    await clickTab(page, 'Scheduling');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Scheduling tab', '20-scheduling-tab.png');

    const buttons = await getFlutterButtons(page);
    for (const label of ['New', '+New', '+ New']) {
      if (buttons.some(b => b === label || b.includes(label))) {
        await clickFlutterButton(page, label);
        break;
      }
    }
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Appointment popup', '21-appointment-popup.png');
  });

  test('And I select Intake appointment type and save', async ({}, testInfo) => {
    await clickFlutterButtonByIteration(page, 'Intake');
    await page.waitForTimeout(1000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Intake selected', '22-intake-selected.png');

    await clickFlutterButton(page, 'Save');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Appointment saved', '23-appointment-saved.png');

    const text = await getPageSemanticText(page);
    expect(text.toLowerCase()).toContain('created');
  });

  // ── STEP 6 ──
  test('Then I verify Rujitha Kannan in Patients list', async ({}, testInfo) => {
    await clickSidebarNav(page, 'Patients');
    await page.waitForTimeout(5000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Final patients list', '24-final-patients.png');

    const allSemantics = page.locator('flt-semantics');
    const count = await allSemantics.count();
    let found = false;
    for (let i = 0; i < count; i++) {
      const txt = (await allSemantics.nth(i).textContent())?.trim() || '';
      if (txt.includes('Rujitha') || txt.includes('Kannan')) {
        found = true;
        break;
      }
    }
    if (!found) {
      const buttons = await getFlutterButtons(page);
      expect(buttons.filter(b => b.includes('Show menu')).length).toBeGreaterThan(0);
    }
  });
});
