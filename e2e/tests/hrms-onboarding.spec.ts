/**
 * HRMS Onboarding E2E — Navigate to HRMS → Onboarding module,
 * verify filter tabs and New Onboarding button, click New Onboarding,
 * assert a form is shown. If a bug is detected (e.g. 404 error),
 * automatically report it via AI Copilot and fail the test.
 *
 * Flow:
 *   1. Click mesh/app-switcher icon → navigate to HRMS
 *   2. Click Onboarding module
 *   3. Verify All / In Progress / Completed / Overdue tabs
 *   4. Click New Onboarding → expect a form
 *   5. If no form (error/404), report bug via AI Copilot and fail
 */
import { test, expect, Page } from '@playwright/test';
import {
  enableAccessibility,
  clickFlutterButton,
  getPageSemanticText,
  getFlutterButtons,
  getInputCount,
  screenshotAndAttach,
  waitForFlutterReady,
  navigateToHRMS,
  reportBugViaCopilot,
} from '../helpers/flutter';

test.setTimeout(300_000);

test.describe.serial('HRMS Onboarding', () => {
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

  // ── Step 1: Navigate to HRMS ──
  test('Given I navigate to HRMS via the app-switcher menu', async ({}, testInfo) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await navigateToHRMS(page);
    await screenshotAndAttach(page, testInfo, 'HRMS Dashboard', 'hrms-01-dashboard.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('HRMS');

    const buttons = await getFlutterButtons(page);
    expect(buttons.some(b => b.includes('Onboarding'))).toBe(true);
  });

  // ── Step 2: Click Onboarding module ──
  test('When I click the Onboarding module', async ({}, testInfo) => {
    await clickFlutterButton(page, 'Onboarding');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Onboarding page', 'hrms-02-onboarding.png');

    const text = await getPageSemanticText(page);
    expect(text).toContain('Onboarding');
  });

  // ── Step 3: Verify filter tabs ──
  test('Then I see All, In Progress, Completed, Overdue filter tabs', async ({}, testInfo) => {
    const buttons = await getFlutterButtons(page);

    expect(buttons).toContain('All');
    expect(buttons).toContain('In Progress');
    expect(buttons).toContain('Completed');
    expect(buttons).toContain('Overdue');

    await screenshotAndAttach(page, testInfo, 'Filter tabs verified', 'hrms-03-tabs.png');
  });

  // ── Step 4: Verify New Onboarding button exists ──
  test('And I see the New Onboarding button', async ({}, testInfo) => {
    const buttons = await getFlutterButtons(page);
    const hasNewOnboarding = buttons.some(b => b.includes('New Onboarding'));
    expect(hasNewOnboarding).toBe(true);

    await screenshotAndAttach(page, testInfo, 'New Onboarding button', 'hrms-04-new-btn.png');
  });

  // ── Step 5: Click New Onboarding and verify form ──
  test('When I click New Onboarding then I should see a form', async ({}, testInfo) => {
    await clickFlutterButton(page, 'New Onboarding');
    await page.waitForTimeout(4000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'After New Onboarding click', 'hrms-05-new-onboarding.png');

    const text = await getPageSemanticText(page);
    const buttons = await getFlutterButtons(page);
    const inputCount = await getInputCount(page);

    // Detect bugs: 404 error, "Failed to Load", or no form fields
    const hasError = text.includes('Failed to Load') ||
                     text.includes('404') ||
                     text.includes('Not Found') ||
                     text.includes('Something went wrong');

    const hasForm = inputCount > 2 || buttons.some(b => b === 'Save' || b === 'Submit' || b === 'Create');

    if (hasError || !hasForm) {
      // Take error screenshot
      await screenshotAndAttach(page, testInfo, 'BUG - No form shown', 'hrms-05-BUG.png');
      const screenshotPath = testInfo.outputPath('hrms-05-BUG.png');

      // Auto-report bug via AI Copilot
      const errorDetail = hasError
        ? text.substring(0, 300)
        : 'New Onboarding clicked but no form appeared. Expected input fields and a Save/Submit button.';

      await reportBugViaCopilot(page, {
        category: 'HRMS - Onboarding',
        title: 'New Onboarding form fails to load',
        description: `Clicking "New Onboarding" on the HRMS Onboarding page does not show a form. ` +
          `Instead: ${errorDetail}. ` +
          `Expected: A new onboarding form with employee fields and a Save button.`,
        screenshotPath,
      });

      await screenshotAndAttach(page, testInfo, 'Bug reported via Copilot', 'hrms-06-bug-reported.png');

      // Fail the test with a clear message
      throw new Error(
        `BUG DETECTED: New Onboarding form did not load. ` +
        `Page shows: "${text.substring(0, 200)}". ` +
        `Expected a form with input fields. Bug was auto-reported via AI Copilot.`
      );
    }

    // If we get here, the form loaded correctly
    expect(hasForm).toBe(true);
  });
});
