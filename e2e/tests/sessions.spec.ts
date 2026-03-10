/**
 * Sessions E2E — Create a session and verify on the Schedule calendar.
 *
 * Flow:
 *   1. Navigate to Sessions
 *   2. Click Add Session → fill popup (title, patient, type, duration, CPT)
 *   3. Save and assert no error toast
 *   4. Navigate to Schedule → verify session title on the calendar date
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
} from '../helpers/flutter';

test.setTimeout(300_000);

const SESSION_TITLE = `Therapy Session ${new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`;

function getTodayFormatted(): string {
  return new Date().toLocaleDateString('en-US', {
    month: 'numeric',
    day: 'numeric',
    year: 'numeric',
  });
}

async function assertSaveSuccess(page: Page, testInfo: any, label: string, filename: string) {
  await clickFlutterButton(page, 'Save');
  await page.waitForTimeout(5000);
  await enableAccessibility(page);
  await screenshotAndAttach(page, testInfo, label, filename);

  const text = await getPageSemanticText(page);
  const lower = text.toLowerCase();
  const hasError = lower.includes('failed') ||
                   (lower.includes('error') && !lower.includes('error-free'));

  if (hasError) {
    const errorSnippet = text.substring(0, 500);
    throw new Error(
      `Save FAILED for "${label}". ` +
      `Error toast detected on page. Page text: "${errorSnippet}"`
    );
  }
}

// ═════════════════════════════════════════════════════
test.describe.serial('Create and Verify Session', () => {
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

  // ── Step 1: Navigate to Sessions ──
  test('When I click Sessions in the left navigation', async ({}, testInfo) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await clickSidebarNav(page, 'Sessions');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Sessions page', 'sess-01-page.png');

    const buttons = await getFlutterButtons(page);
    expect(buttons).toContain('Add Session');
  });

  // ── Step 2: Open Add Session popup ──
  test('When I click Add Session', async ({}, testInfo) => {
    await clickFlutterButton(page, 'Add Session');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Add Session popup', 'sess-02-popup.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Select a patient');
    expect(text).toContain('Session Duration');
  });

  // ── Step 3: Fill session title ──
  test('When I enter a session title', async ({}, testInfo) => {
    await fillInputByIndex(page, 0, SESSION_TITLE);
    await page.waitForTimeout(500);
    await screenshotAndAttach(page, testInfo, 'Title filled', 'sess-03-title.png');
  });

  // ── Step 4: Select a patient ──
  test('When I click Select a patient and choose a patient', async ({}, testInfo) => {
    await clickFlutterButton(page, 'Select a patient');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Patient picker open', 'sess-04a-patient-picker.png');

    const text = await getPageSemanticText(page);
    console.log('=== Patient picker text ===');
    console.log(text.substring(0, 500));

    const inputCount = await getInputCount(page);
    console.log(`Input count after patient picker: ${inputCount}`);

    // The patient picker likely shows a searchable list — type to search
    // or click the first available patient
    const allSemantics = page.locator('flt-semantics');
    const count = await allSemantics.count();
    let patientFound = false;

    for (let i = 0; i < count; i++) {
      const el = allSemantics.nth(i);
      const txt = (await el.textContent())?.trim() || '';
      const role = await el.getAttribute('role');
      // Look for patient name patterns (First Last, or names with ages/diagnosis)
      if (role === 'button' && (txt.includes('Kannan') || txt.includes('Douglas') || txt.includes('TestPt'))) {
        console.log(`Found patient: "${txt}"`);
        await el.dispatchEvent('click');
        patientFound = true;
        break;
      }
    }

    if (!patientFound) {
      // Try clicking the first list item that looks like a patient
      for (let i = 0; i < count; i++) {
        const el = allSemantics.nth(i);
        const txt = (await el.textContent())?.trim() || '';
        const role = await el.getAttribute('role');
        if (role === 'button' && txt.length > 3 && !['Save', 'Discard', 'Scheduling Assistant', 'Expand',
          'Invite required attendees', 'Select a patient', 'All day', 'Recurring', 'Intake', 'Assessment',
          'Session', 'Misc', 'More options', 'Dismiss', 'Show menu'].includes(txt) &&
          !txt.includes('AM') && !txt.includes('PM') && !txt.includes('/2026') &&
          !txt.includes('97') && !txt.includes('h') && !txt.includes('Vanilla') &&
          !txt.includes('Dashboard') && !txt.includes('Patients') && !txt.includes('Sessions') &&
          !txt.includes('Schedule') && !txt.includes('Reports') && !txt.includes('Tools') &&
          !txt.includes('Settings') && !txt.includes('Clinic') && !txt.includes('Copilot') &&
          !txt.includes('Add Session') && !txt.includes('Add a room')) {
          console.log(`Selecting first available item: "${txt.substring(0, 60)}"`);
          await el.dispatchEvent('click');
          patientFound = true;
          break;
        }
      }
    }

    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Patient selected', 'sess-04b-patient-selected.png');
  });

  // ── Step 5: Select session type and duration ──
  test('When I select Session type and 1h duration', async ({}, testInfo) => {
    await clickFlutterButtonByIteration(page, 'Session');
    await page.waitForTimeout(500);
    await clickFlutterButtonByIteration(page, '1h');
    await page.waitForTimeout(500);
    await screenshotAndAttach(page, testInfo, 'Type and duration set', 'sess-05-type-duration.png');
  });

  // ── Step 6: Select CPT code ──
  test('When I select CPT code 97153', async ({}, testInfo) => {
    const btns = page.locator('flt-semantics[role="button"]');
    const count = await btns.count();
    for (let i = 0; i < count; i++) {
      const txt = (await btns.nth(i).textContent())?.trim() || '';
      if (txt.includes('97153')) {
        await btns.nth(i).dispatchEvent('click');
        break;
      }
    }
    await page.waitForTimeout(500);
    await screenshotAndAttach(page, testInfo, 'CPT 97153 selected', 'sess-06-cpt.png');
  });

  // ── Step 7: Save ──
  test('When I click Save and session is created', async ({}, testInfo) => {
    await assertSaveSuccess(page, testInfo, 'Session saved', 'sess-07-saved.png');
  });

  // ── Step 8: Navigate to Schedule ──
  test('When I navigate to Schedule', async ({}, testInfo) => {
    await clickSidebarNav(page, 'Schedule');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Schedule page', 'sess-08-schedule.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Schedule');
  });

  // ── Step 9: Verify session on calendar ──
  test('Then I verify the session on the calendar for today', async ({}, testInfo) => {
    await enableAccessibility(page);

    // The schedule defaults to today's date. Check if our session title appears.
    // Try Day view first for better visibility
    const buttons = await getFlutterButtons(page);
    if (buttons.includes('Day')) {
      await clickFlutterButtonByIteration(page, 'Day');
      await page.waitForTimeout(2000);
      await enableAccessibility(page);
    }

    await screenshotAndAttach(page, testInfo, 'Calendar day view', 'sess-09a-day-view.png');

    const text = await getPageSemanticText(page);
    console.log('=== Schedule page text (first 1000 chars) ===');
    console.log(text.substring(0, 1000));

    // Check for the session title on the calendar
    const titleKeyword = 'Therapy Session';
    const hasSession = text.includes(titleKeyword) || text.includes(SESSION_TITLE);

    if (!hasSession) {
      // Try Week view
      if (buttons.includes('Week')) {
        await clickFlutterButtonByIteration(page, 'Week');
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
      }
      await screenshotAndAttach(page, testInfo, 'Calendar week view', 'sess-09b-week-view.png');

      const weekText = await getPageSemanticText(page);
      console.log('=== Schedule WEEK text (first 1000 chars) ===');
      console.log(weekText.substring(0, 1000));

      const hasSessionWeek = weekText.includes(titleKeyword) || weekText.includes(SESSION_TITLE);

      if (!hasSessionWeek) {
        // Even if title not found in semantic text, the schedule loaded
        // Take a final screenshot and check for any appointment indicators
        await screenshotAndAttach(page, testInfo, 'Calendar final check', 'sess-09c-final.png');
        const allSemantics = page.locator('flt-semantics');
        const count = await allSemantics.count();
        let sessionFound = false;
        for (let i = 0; i < count; i++) {
          const txt = (await allSemantics.nth(i).textContent())?.trim() || '';
          if (txt.includes('Therapy') || txt.includes(SESSION_TITLE)) {
            sessionFound = true;
            console.log(`Found session element: "${txt}"`);
            break;
          }
        }
        expect(sessionFound).toBe(true);
      }
    } else {
      console.log(`Session "${SESSION_TITLE}" found on calendar.`);
      expect(hasSession).toBe(true);
    }
  });
});
