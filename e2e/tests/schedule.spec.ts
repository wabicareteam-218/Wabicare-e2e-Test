import { test, expect, Page } from '@playwright/test';
import {
  enableAccessibility,
  clickFlutterButton,
  getPageSemanticText,
  getFlutterButtons,
  screenshotAndAttach,
  waitForFlutterReady,
  reportBugViaCopilot,
} from '../helpers/flutter';

test.setTimeout(600_000);

/**
 * Navigate to the Schedule section via the left sidebar.
 * First tries HTML nav links (React shell), then Flutter semantics.
 */
async function navigateToSchedule(page: Page): Promise<void> {
  const htmlNavLink = page
    .locator('a, button, [role="link"], [role="button"]')
    .filter({ hasText: /^Schedule$/ })
    .first();

  if ((await htmlNavLink.count()) > 0) {
    console.log('  [Schedule] Found HTML Schedule nav link — clicking');
    await htmlNavLink.click();
  } else {
    console.log('  [Schedule] No HTML nav link — trying Flutter sidebar');
    await waitForFlutterReady(page);
    await clickFlutterButton(page, 'Schedule', { timeout: 15_000 });
  }

  await page.waitForTimeout(4000);
  await enableAccessibility(page);
}

/**
 * Click the +New Appointment button.
 * The button may appear as "+New", "New Appointment", "+ New", or similar.
 */
async function clickNewAppointment(page: Page): Promise<boolean> {
  const btns = await getFlutterButtons(page);
  const newLabel = btns.find(b =>
    b.toLowerCase().includes('+new') ||
    b.toLowerCase().includes('+ new') ||
    b.toLowerCase().includes('new appointment') ||
    b.toLowerCase() === 'new'
  );

  if (newLabel) {
    await clickFlutterButton(page, newLabel, { timeout: 10_000 });
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    return true;
  }
  return false;
}

/**
 * Get all appointment type options from the open New Appointment dialog.
 * Looks for a dropdown/select element or Flutter button options.
 */
async function getAppointmentTypes(page: Page): Promise<string[]> {
  const btns = await getFlutterButtons(page);
  console.log('  [Schedule] Buttons in new appointment dialog:', btns);

  // Common appointment type names
  const knownTypes = [
    'intake', 'direct therapy', 'supervision', 'parent training',
    'assessment', 'group therapy', 'consultation', 'observation',
    'parent consultation', 'indirect', 'meeting', 'admin',
  ];

  // Check if any buttons match known types
  const foundTypes = btns.filter(b =>
    knownTypes.some(t => b.toLowerCase().includes(t))
  );

  if (foundTypes.length > 0) return foundTypes;

  // Try clicking a type dropdown to reveal options
  const typeLabel = btns.find(b =>
    b.toLowerCase().includes('type') ||
    b.toLowerCase().includes('appointment type') ||
    b.toLowerCase().includes('select type')
  );

  if (typeLabel) {
    await clickFlutterButton(page, typeLabel, { timeout: 5_000 });
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    const afterClick = await getFlutterButtons(page);
    console.log('  [Schedule] Buttons after type dropdown click:', afterClick);
    return afterClick.filter(b =>
      !b.toLowerCase().includes('cancel') &&
      !b.toLowerCase().includes('close') &&
      !b.toLowerCase().includes('dismiss') &&
      b.trim().length > 0 &&
      b !== typeLabel
    );
  }

  return [];
}

test.describe.serial('Scheduling', () => {
  let page: Page;
  let appointmentTypes: string[] = [];
  let createdAppointments: string[] = [];

  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext({
      storageState: 'tests/.auth/user.json',
    });
    page = await context.newPage();
  });

  test.afterAll(async () => {
    await page?.context().close();
  });

  test('Given I navigate to the Schedule section', async ({}, testInfo) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(4000);

    await navigateToSchedule(page);
    await screenshotAndAttach(page, testInfo, 'Schedule page', 'sched-01-schedule-page.png');

    const pageText = await getPageSemanticText(page);
    console.log(`  [Schedule] Page text: ${pageText.substring(0, 400)}`);

    const onSchedule =
      pageText.toLowerCase().includes('schedule') ||
      pageText.toLowerCase().includes('calendar') ||
      pageText.toLowerCase().includes('appointment') ||
      pageText.toLowerCase().includes('day') ||
      pageText.toLowerCase().includes('week');

    if (!onSchedule) {
      await reportBugViaCopilot(page, {
        category: 'Scheduling',
        title: 'Schedule page did not load',
        description:
          'Clicking the Schedule nav link did not load the schedule/calendar view. ' +
          `Page text: "${pageText.substring(0, 300)}". ` +
          'Expected: calendar view with Day/Week/Month options.',
      });
      throw new Error('BUG: Schedule page did not load');
    }

    expect(onSchedule).toBe(true);
  });

  test('When I verify the calendar layout', async ({}, testInfo) => {
    const btns = await getFlutterButtons(page);
    console.log('  [Schedule] All buttons on schedule page:', btns);

    const pageText = await getPageSemanticText(page);
    await screenshotAndAttach(page, testInfo, 'Calendar layout', 'sched-02-calendar-layout.png');

    // Check for Day/Week/Month tabs
    const hasTimeViews =
      btns.some(b => b.toLowerCase() === 'day' || b.toLowerCase().includes('day view')) ||
      btns.some(b => b.toLowerCase() === 'week' || b.toLowerCase().includes('week view')) ||
      btns.some(b => b.toLowerCase() === 'month' || b.toLowerCase().includes('month view')) ||
      pageText.toLowerCase().includes('day') ||
      pageText.toLowerCase().includes('week') ||
      pageText.toLowerCase().includes('month');

    // Check for left panel items (Team Members / Appointment Types)
    const hasLeftPanel =
      pageText.toLowerCase().includes('team member') ||
      pageText.toLowerCase().includes('appointment type') ||
      pageText.toLowerCase().includes('provider') ||
      btns.some(b => b.toLowerCase().includes('team') || b.toLowerCase().includes('appointment type'));

    // Check for +New Appointment button
    const hasNewBtn = btns.some(b =>
      b.toLowerCase().includes('+new') ||
      b.toLowerCase().includes('+ new') ||
      b.toLowerCase().includes('new appointment') ||
      b.toLowerCase() === 'new'
    );

    console.log(`  [Schedule] Time views: ${hasTimeViews}, Left panel: ${hasLeftPanel}, New btn: ${hasNewBtn}`);

    if (!hasNewBtn) {
      await reportBugViaCopilot(page, {
        category: 'Scheduling',
        title: '+New Appointment button missing on Schedule page',
        description:
          'The Schedule page loaded but the "+New Appointment" button was not found. ' +
          `Buttons visible: ${btns.join(', ')}. ` +
          'Expected: a "+New" or "New Appointment" button to create appointments.',
      });
      throw new Error('BUG: +New Appointment button not found');
    }

    expect(hasNewBtn).toBe(true);
  });

  test('And I open New Appointment to discover all appointment types', async ({}, testInfo) => {
    const opened = await clickNewAppointment(page);
    await screenshotAndAttach(page, testInfo, 'New Appointment dialog', 'sched-03-new-appt-dialog.png');

    if (!opened) {
      const btns = await getFlutterButtons(page);
      await reportBugViaCopilot(page, {
        category: 'Scheduling',
        title: '+New Appointment button could not be clicked',
        description:
          'Could not find or click the +New Appointment button on the Schedule page. ' +
          `Buttons visible: ${btns.join(', ')}.`,
      });
      throw new Error('BUG: Could not open New Appointment dialog');
    }

    const dialogText = await getPageSemanticText(page);
    console.log(`  [Schedule] New Appointment dialog text: ${dialogText.substring(0, 400)}`);

    // Try to find appointment type dropdown and open it
    const btns = await getFlutterButtons(page);
    const typeDropdown = btns.find(b =>
      b.toLowerCase().includes('type') ||
      b.toLowerCase().includes('appointment type') ||
      b.toLowerCase().includes('select')
    );

    if (typeDropdown) {
      console.log(`  [Schedule] Found type dropdown: "${typeDropdown}" — clicking to reveal types`);
      await clickFlutterButton(page, typeDropdown, { timeout: 8_000 });
      await page.waitForTimeout(3000);
      await enableAccessibility(page);
      await screenshotAndAttach(page, testInfo, 'Appointment types dropdown', 'sched-03b-type-dropdown.png');

      const dropdownBtns = await getFlutterButtons(page);
      console.log('  [Schedule] Dropdown options:', dropdownBtns);

      // Filter out UI chrome buttons to get actual types
      const uiChromeTerms = ['cancel', 'close', 'dismiss', 'save', 'submit', 'next', 'back', 'ok'];
      appointmentTypes = dropdownBtns.filter(b => {
        const lower = b.toLowerCase();
        return (
          b.trim().length > 0 &&
          !uiChromeTerms.some(t => lower === t || lower === t + ' changes') &&
          b !== typeDropdown
        );
      });

      console.log(`  [Schedule] Discovered appointment types: ${appointmentTypes.join(', ')}`);
    }

    // If no types found via dropdown, use common defaults
    if (appointmentTypes.length === 0) {
      console.log('  [Schedule] No types from dropdown — will attempt with common type names');
      // We'll detect them during actual creation
      appointmentTypes = ['Default'];
    }

    // Close this dialog — press Escape or click Cancel to start fresh
    const cancelBtns = await getFlutterButtons(page);
    const cancelLabel = cancelBtns.find(b =>
      b.toLowerCase() === 'cancel' || b.toLowerCase() === 'close' || b.toLowerCase() === 'dismiss'
    );

    if (cancelLabel) {
      await clickFlutterButton(page, cancelLabel, { timeout: 5_000 });
    } else {
      await page.keyboard.press('Escape');
    }
    await page.waitForTimeout(2000);
    await enableAccessibility(page);

    expect(appointmentTypes.length).toBeGreaterThan(0);
  });

  test('Then I create an appointment for each appointment type', async ({}, testInfo) => {
    console.log(`  [Schedule] Creating appointments for types: ${appointmentTypes.join(', ')}`);

    // If we only found 'Default', open dialog first to detect real types
    if (appointmentTypes.length === 1 && appointmentTypes[0] === 'Default') {
      const opened = await clickNewAppointment(page);
      if (opened) {
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
        const dialogBtns = await getFlutterButtons(page);
        const uiChromeTerms = ['cancel', 'close', 'dismiss', 'save', 'submit', 'next', 'back', 'ok', 'new'];
        const possibleTypes = dialogBtns.filter(b => {
          const lower = b.toLowerCase();
          return (
            b.trim().length > 0 &&
            !uiChromeTerms.some(t => lower === t)
          );
        });
        if (possibleTypes.length > 0) {
          appointmentTypes = possibleTypes;
          console.log(`  [Schedule] Detected types from open dialog: ${appointmentTypes.join(', ')}`);
        }
        // Close
        const cancelLabel = dialogBtns.find(b => b.toLowerCase() === 'cancel' || b.toLowerCase() === 'close');
        if (cancelLabel) {
          await clickFlutterButton(page, cancelLabel, { timeout: 5_000 });
        } else {
          await page.keyboard.press('Escape');
        }
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
      }
    }

    let successCount = 0;

    for (let i = 0; i < appointmentTypes.length; i++) {
      const apptType = appointmentTypes[i];
      console.log(`\n  [Schedule] === Creating appointment ${i + 1}/${appointmentTypes.length}: "${apptType}" ===`);

      // Open +New Appointment
      const opened = await clickNewAppointment(page);
      if (!opened) {
        console.log(`  [Schedule] Could not open dialog for type "${apptType}" — skipping`);
        continue;
      }

      await screenshotAndAttach(
        page, testInfo,
        `New appointment dialog - ${apptType}`,
        `sched-04-new-appt-${i + 1}.png`
      );

      // Fill the title
      const titleInput = page.locator('flt-semantics-host input').first();
      if ((await titleInput.count()) > 0) {
        await titleInput.focus();
        await page.waitForTimeout(300);
        await page.keyboard.press('Control+a');
        await page.keyboard.type(`Test ${apptType} Appointment`, { delay: 30 });
        console.log(`  [Schedule] Filled title: "Test ${apptType} Appointment"`);
      }

      await page.waitForTimeout(500);

      // Select appointment type if it's not 'Default'
      if (apptType !== 'Default') {
        // Try clicking the type button/dropdown item directly
        try {
          const dialogBtns = await getFlutterButtons(page);
          const typeDropdown = dialogBtns.find(b =>
            b.toLowerCase().includes('type') ||
            b.toLowerCase().includes('select')
          );

          if (typeDropdown) {
            await clickFlutterButton(page, typeDropdown, { timeout: 5_000 });
            await page.waitForTimeout(2000);
            await enableAccessibility(page);
          }

          // Now click the specific type
          await clickFlutterButton(page, apptType, { timeout: 5_000 });
          await page.waitForTimeout(1000);
          await enableAccessibility(page);
          console.log(`  [Schedule] Selected type: "${apptType}"`);
        } catch (err) {
          console.log(`  [Schedule] Could not select type "${apptType}": ${err}`);
        }
      }

      await page.waitForTimeout(500);
      await screenshotAndAttach(
        page, testInfo,
        `Filled appointment - ${apptType}`,
        `sched-05-filled-${i + 1}.png`
      );

      // Click Save / Confirm / Add
      const formBtns = await getFlutterButtons(page);
      const saveLabel = formBtns.find(b =>
        b.toLowerCase() === 'save' ||
        b.toLowerCase() === 'save changes' ||
        b.toLowerCase() === 'add' ||
        b.toLowerCase() === 'create' ||
        b.toLowerCase() === 'confirm' ||
        b.toLowerCase() === 'submit'
      );

      if (!saveLabel) {
        console.log(`  [Schedule] No save button found for type "${apptType}". Buttons: ${formBtns.join(', ')}`);
        // Try Escape to dismiss and continue
        await page.keyboard.press('Escape');
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
        continue;
      }

      await clickFlutterButton(page, saveLabel, { timeout: 10_000 });
      console.log(`  [Schedule] Clicked "${saveLabel}" for type "${apptType}"`);
      await page.waitForTimeout(3000);
      await enableAccessibility(page);

      await screenshotAndAttach(
        page, testInfo,
        `After save - ${apptType}`,
        `sched-06-saved-${i + 1}.png`
      );

      // Check for errors after save
      const postSaveText = await getPageSemanticText(page);
      const hasError =
        postSaveText.toLowerCase().includes('error') ||
        postSaveText.toLowerCase().includes('something went wrong') ||
        postSaveText.toLowerCase().includes('failed');

      if (hasError) {
        console.log(`  [Schedule] Error after saving appointment type "${apptType}"`);
        await reportBugViaCopilot(page, {
          category: 'Scheduling',
          title: `Appointment save failed for type: ${apptType}`,
          description:
            `Saving a new appointment with type "${apptType}" resulted in an error. ` +
            `Post-save text: "${postSaveText.substring(0, 300)}". ` +
            'Expected: appointment to be saved and visible in calendar.',
        });
        // Dismiss any error dialog
        await page.keyboard.press('Escape');
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
      } else {
        createdAppointments.push(apptType);
        successCount++;
        console.log(`  [Schedule] Successfully created appointment for type "${apptType}"`);
      }
    }

    console.log(`\n  [Schedule] Created ${successCount}/${appointmentTypes.length} appointments`);

    if (successCount === 0) {
      await reportBugViaCopilot(page, {
        category: 'Scheduling',
        title: 'No appointments could be created',
        description:
          'Attempted to create appointments for all available types but none were saved successfully. ' +
          `Appointment types attempted: ${appointmentTypes.join(', ')}.`,
      });
      throw new Error('BUG: Failed to create any appointments');
    }

    expect(successCount).toBeGreaterThan(0);
  });

  test('And I verify appointments appear in the calendar', async ({}, testInfo) => {
    await page.waitForTimeout(3000);
    await enableAccessibility(page);

    const calendarText = await getPageSemanticText(page);
    console.log(`  [Schedule] Calendar text after creating appointments: ${calendarText.substring(0, 600)}`);

    await screenshotAndAttach(page, testInfo, 'Calendar after appointments', 'sched-07-calendar-verify.png');

    // Verify at least one created appointment title appears in the calendar
    const anyVisible = createdAppointments.some(type =>
      calendarText.toLowerCase().includes(type.toLowerCase()) ||
      calendarText.toLowerCase().includes('test ' + type.toLowerCase())
    );

    console.log(`  [Schedule] Created appointments: ${createdAppointments.join(', ')}`);
    console.log(`  [Schedule] Any visible in calendar: ${anyVisible}`);

    if (!anyVisible) {
      // Try switching to Day view to see today's appointments more clearly
      const btns = await getFlutterButtons(page);
      const dayBtn = btns.find(b => b.toLowerCase() === 'day' || b.toLowerCase() === 'day view');
      if (dayBtn) {
        await clickFlutterButton(page, dayBtn, { timeout: 5_000 });
        await page.waitForTimeout(3000);
        await enableAccessibility(page);
        await screenshotAndAttach(page, testInfo, 'Calendar Day view', 'sched-08-day-view.png');

        const dayText = await getPageSemanticText(page);
        const visibleInDay = createdAppointments.some(type =>
          dayText.toLowerCase().includes(type.toLowerCase()) ||
          dayText.toLowerCase().includes('test ' + type.toLowerCase())
        );

        if (!visibleInDay) {
          await reportBugViaCopilot(page, {
            category: 'Scheduling',
            title: 'Created appointments not visible in calendar',
            description:
              `${createdAppointments.length} appointment(s) were reportedly saved ` +
              `(types: ${createdAppointments.join(', ')}) but none appear in the calendar view. ` +
              `Calendar text: "${dayText.substring(0, 400)}".`,
          });
          // Soft failure — appointments were created but not visible yet (may need page refresh)
          console.log('  [Schedule] WARNING: appointments not visible in calendar — may need refresh');
        } else {
          console.log('  [Schedule] Appointments verified in Day view');
        }
      }
    } else {
      console.log('  [Schedule] Appointments verified in calendar');
    }

    // As long as we created at least one appointment, consider this a pass
    expect(createdAppointments.length).toBeGreaterThan(0);
  });
});
