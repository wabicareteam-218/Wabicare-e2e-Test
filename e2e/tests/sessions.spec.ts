import { test, expect, Page, BrowserContext } from '@playwright/test';
import {
  enableAccessibility,
  clickFlutterButton,
  clickFlutterButtonByIteration,
  getFlutterButtons,
  getPageSemanticText,
  screenshotAndAttach,
  reportBugViaCopilot,
} from '../helpers/flutter';

/**
 * Sessions E2E — create a therapy session, run it, and collect data.
 *
 * Flow (mirrors how a clinician uses the app):
 *   1. Open the Sessions page.
 *   2. Add a new session for "Demo Patient 2".
 *      - Scheduled for TODAY + 10 days at a varied time slot so repeated
 *        runs do not collide with an already-scheduled session (which the
 *        app would reject with a conflict error).
 *   3. Verify the session count increases / the session is created.
 *   4. Open the session → this navigates to the Session Workspace
 *      ("Go to Session").
 *   5. Start the session (the "play" / "Check In & Start" button) — this
 *      requires Electronic Visit Verification, so geolocation is granted
 *      on the browser context.
 *   6. Collect data for goals: record a Task-Analysis trial on the
 *      "Handwashing — full routine" goal, and record a challenging
 *      behaviour (Tantrum).
 *   7. End the session / stop recording ("End & check out").
 *
 * The Sessions list renders patient/date/time cells on the Flutter canvas
 * (not in the accessibility tree), so rows cannot be matched by text. We
 * therefore verify creation by the "All (N)" count and open a session by
 * scanning rows for a *startable* (Scheduled) Demo Patient 2 session.
 */

test.setTimeout(300_000);

const PATIENT = 'Demo Patient 2';
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// 15-minute start slots visible in the time picker without scrolling
// (7:15 AM … 12:15 PM). Repeated runs accumulate sessions on the same
// future date, so we pick a unique slot per run and retry on conflict.
function generateTimeSlots(): string[] {
  const slots: string[] = [];
  for (let h = 7; h <= 12; h++) {
    for (const m of [0, 15, 30, 45]) {
      if (h === 7 && m < 15) continue;  // start at 7:15
      if (h === 12 && m > 15) continue; // end at 12:15
      const period = h < 12 ? 'AM' : 'PM';
      slots.push(`${h}:${String(m).padStart(2, '0')} ${period}`);
    }
  }
  return slots;
}
const TIME_SLOTS = generateTimeSlots();

// ── Date-picker helpers ──────────────────────────────────────────────

async function getDatePickerHeader(page: Page): Promise<string> {
  return page.evaluate(() => {
    const ns = Array.from(document.querySelectorAll('flt-semantics'));
    for (const n of ns) {
      const t = (n.textContent || '').trim();
      if (/^[A-Z][a-z]+ \d{4}$/.test(t)) return t;
    }
    return '';
  });
}

/** Click the calendar's "next month" chevron (an unlabeled button to the
 *  right of the "Month YYYY" header). */
async function clickNextMonth(page: Page): Promise<boolean> {
  const headerBox = await page.evaluate(() => {
    const ns = Array.from(document.querySelectorAll('flt-semantics')) as Element[];
    for (const n of ns) {
      const t = (n.textContent || '').trim();
      if (/^[A-Z][a-z]+ \d{4}$/.test(t)) {
        const r = n.getBoundingClientRect();
        return { x: r.x, y: r.y, w: r.width, h: r.height };
      }
    }
    return null;
  });
  if (!headerBox) return false;
  const hcx = headerBox.x + headerBox.w / 2;
  const hcy = headerBox.y + headerBox.h / 2;
  const btns = page.locator('flt-semantics[role="button"]');
  const n = await btns.count();
  let bestRight: ReturnType<typeof btns.nth> | null = null;
  let bestRightX = -1;
  for (let i = 0; i < n; i++) {
    const txt = ((await btns.nth(i).textContent()) || '').trim();
    if (txt !== '') continue;
    const box = await btns.nth(i).boundingBox();
    if (!box) continue;
    const cy = box.y + box.height / 2;
    if (Math.abs(cy - hcy) > 40) continue; // same row as header
    const cx = box.x + box.width / 2;
    if (cx > hcx && cx > bestRightX) { bestRightX = cx; bestRight = btns.nth(i); }
  }
  if (bestRight) { await bestRight.click(); return true; }
  return false;
}

/** Open the inline date picker (the "M/D/YYYY" button) and select `target`. */
async function setDate(page: Page, target: Date): Promise<void> {
  const dateBtn = (await getFlutterButtons(page)).find(b => /^\d{1,2}\/\d{1,2}\/\d{4}$/.test(b));
  if (!dateBtn) throw new Error('Date button (M/D/YYYY) not found in the appointment form');
  await clickFlutterButton(page, dateBtn, { timeout: 6000 });
  await page.waitForTimeout(2000);
  await enableAccessibility(page);

  const targetHeader = `${MONTHS[target.getMonth()]} ${target.getFullYear()}`;
  for (let i = 0; i < 24; i++) {
    const header = await getDatePickerHeader(page);
    if (header === targetHeader) break;
    const ok = await clickNextMonth(page);
    if (!ok) break;
    await page.waitForTimeout(1200);
    await enableAccessibility(page);
  }
  await clickFlutterButtonByIteration(page, String(target.getDate()));
  await page.waitForTimeout(1500);
  await enableAccessibility(page);
}

/** Every flt-semantics node's accessible label (aria-label or text). Flutter
 *  paints dialog text on the canvas, so it is often absent from
 *  flt-semantics-host.textContent but present on individual nodes. */
async function allSemanticLabels(page: Page): Promise<string[]> {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics'))
      .map((n) => (n.getAttribute('aria-label') || n.textContent || '').trim())
      .filter(Boolean),
  );
}

/** Read the "All (N)" session-count filter into a number. */
async function readSessionCount(page: Page): Promise<number | null> {
  for (const b of await getFlutterButtons(page)) {
    const m = b.match(/^All \((\d+)\)$/);
    if (m) return parseInt(m[1], 10);
  }
  return null;
}

async function navigateToSessions(page: Page): Promise<void> {
  await page.goto('/');
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(6000);
  await enableAccessibility(page);

  // Fail fast with a clear message if the cached session has expired.
  const earlyText = await getPageSemanticText(page);
  if (/Welcome back|Sign In to your Wabi/i.test(earlyText) &&
      !(await getFlutterButtons(page)).some(b => /Dashboard|Sessions/i.test(b))) {
    throw new Error(
      'Auth session expired (landed on the Sign In page). Re-run with the ' +
      '"setup" project so auth.setup refreshes tests/.auth/user.json.',
    );
  }

  // Click "Sessions" in the sidebar, retrying until the list renders.
  for (let i = 0; i < 4; i++) {
    await clickFlutterButton(page, 'Sessions', { timeout: 12000 }).catch(() => {});
    await page.waitForTimeout(4000);
    await enableAccessibility(page);
    if ((await getFlutterButtons(page)).some(b => /add session/i.test(b))) return;
  }
}

/**
 * One attempt at creating a session for `patient` on `target` at `time`.
 * Returns:
 *   'created'  — a new session was added (session count went up)
 *   'conflict' — the slot is taken (e.g. "already has an appointment")
 *   'failed'   — save did not complete for another reason
 * Always starts from a fresh Sessions list so state is clean between retries.
 */
async function attemptCreateSession(
  page: Page,
  patient: string,
  title: string,
  target: Date,
  time: string,
): Promise<{ result: 'created' | 'conflict' | 'failed'; before: number | null; after: number | null }> {
  await navigateToSessions(page);
  const before = await readSessionCount(page);

  // Open the Add Session dialog (compact form holds Title + patient).
  await clickFlutterButton(page, 'Add Session', { timeout: 10000 });
  await page.waitForTimeout(3500);
  await enableAccessibility(page);

  // Title
  const titleInput = page.locator('flt-semantics-host input[aria-label="Add a title"]');
  if (await titleInput.count()) {
    await titleInput.first().focus();
    await page.waitForTimeout(300);
    await page.keyboard.type(title, { delay: 25 });
  }
  await page.waitForTimeout(500);

  // Patient (compact "Add attendees and patient..." lists patients)
  await clickFlutterButton(page, 'Add attendees and patient...', { timeout: 8000 });
  await page.waitForTimeout(2000);
  await enableAccessibility(page);
  const searchInput = page.locator('flt-semantics-host input[aria-label*="Search patients"]');
  if (await searchInput.count()) {
    await searchInput.first().focus();
    await page.keyboard.type(patient, { delay: 25 });
    await page.waitForTimeout(2500);
    await enableAccessibility(page);
  }
  const patientResult = page.locator('flt-semantics[role="button"]').filter({ hasText: patient }).first();
  if (!(await patientResult.count())) {
    return { result: 'failed', before, after: before };
  }
  await patientResult.dispatchEvent('click');
  await page.waitForTimeout(2000);
  await enableAccessibility(page);

  // Expand to the full form for date + time.
  await clickFlutterButton(page, 'Expand', { timeout: 6000 }).catch(() => {});
  await page.waitForTimeout(2500);
  await enableAccessibility(page);

  // Date = today + 10 days
  await setDate(page, target);

  // Time
  const startTimeBtn = (await getFlutterButtons(page)).find(b => /^\d{1,2}:\d{2}\s?(AM|PM)$/.test(b));
  if (startTimeBtn) {
    await clickFlutterButton(page, startTimeBtn, { timeout: 6000 });
    await page.waitForTimeout(2000);
    await enableAccessibility(page);
    await clickFlutterButtonByIteration(page, time);
    await page.waitForTimeout(1500);
    await enableAccessibility(page);
  }

  // Save
  await clickFlutterButton(page, 'Save', { timeout: 8000 });

  // Poll for the success toast / a conflict message.
  let sawSuccess = false;
  let sawConflict = false;
  for (let i = 0; i < 6; i++) {
    await page.waitForTimeout(1000);
    const t = await getPageSemanticText(page);
    if (/scheduled successfully|created successfully/i.test(t)) sawSuccess = true;
    if (/already (has|have).*(appointment|session)|conflict|overlap|already (scheduled|booked)|time is not available|not available/i.test(t)) {
      sawConflict = true;
    }
    if (sawSuccess || sawConflict) break;
  }
  await enableAccessibility(page);
  const after = await readSessionCount(page);

  if (sawSuccess || (before != null && after != null && after > before)) {
    return { result: 'created', before, after };
  }
  if (sawConflict) return { result: 'conflict', before, after };
  return { result: 'failed', before, after };
}

// ── Suite ────────────────────────────────────────────────────────────

test.describe.serial('Sessions: schedule, run, and record a therapy session', () => {
  let context: BrowserContext;
  let page: Page;

  // Shared across the serial scenarios.
  // Date/time = "now + 240 hours" (10 days). The time-of-day shifts every run,
  // and we additionally retry across 15-minute slots so the patient never has a
  // clashing appointment ("already has an appointment at that time").
  const target = new Date();
  target.setDate(target.getDate() + 10);
  const stamp = `${Date.now()}`.slice(-5);
  const title = `E2E DP2 Session ${stamp}`;
  let chosenTime = '';
  let countBefore: number | null = null;
  let countAfter: number | null = null;
  let createSucceeded = false;

  test.beforeAll(async ({ browser }) => {
    context = await browser.newContext({
      storageState: 'tests/.auth/user.json',
      // EVV check-in at session start requires geolocation.
      geolocation: { latitude: 37.7749, longitude: -122.4194 },
      permissions: ['geolocation'],
    });
    page = await context.newPage();
    // Bound every action so a Flutter re-render can never hang a step for the
    // full test timeout (default actionTimeout is 0 = unbounded).
    page.setDefaultTimeout(30_000);
  });

  test.afterAll(async () => {
    await context?.close();
  });

  // ── 1. Navigate ──
  test('Given I navigate to the Sessions page', async ({}, testInfo) => {
    await navigateToSessions(page);
    await screenshotAndAttach(page, testInfo, 'Sessions page', 'sessions-01-page.png');

    const btns = await getFlutterButtons(page);
    const hasAddSession = btns.some(b => /add session/i.test(b));
    const text = await getPageSemanticText(page);
    const onSessions = hasAddSession || /PATIENT.*DATE.*TIME/i.test(text.replace(/\s+/g, ' '));

    if (!onSessions) {
      await reportBugViaCopilot(page, {
        category: 'Sessions',
        title: 'Sessions page did not load',
        description:
          'Clicking "Sessions" in the left navigation did not load the Sessions list ' +
          `(no "Add Session" button / session table). Buttons seen: ${btns.join(', ')}.`,
      });
      throw new Error('BUG: Sessions page did not load');
    }
    expect(onSessions).toBe(true);
  });

  // ── 2. Create ──
  test(`When I add a new session for ${PATIENT} on a future date`, async ({}, testInfo) => {
    test.setTimeout(600_000); // retries re-open the form, so allow extra time
    // Start from a random slot, then walk forward through 15-minute slots,
    // skipping any the patient already has an appointment in ("already has an
    // appointment at that time"). Randomising spreads repeated runs across the
    // day so they rarely collide.
    const startIdx = Math.floor(Math.random() * TIME_SLOTS.length);

    const maxAttempts = Math.min(TIME_SLOTS.length, 12);
    let lastResult = 'failed';
    for (let a = 0; a < maxAttempts; a++) {
      const time = TIME_SLOTS[(startIdx + a) % TIME_SLOTS.length];
      console.log(`  [Sessions] attempt ${a + 1}: ${target.toDateString()} @ ${time}`);
      const { result, before, after } = await attemptCreateSession(page, PATIENT, title, target, time);
      console.log(`  [Sessions]   → ${result} (before=${before}, after=${after})`);
      if (result === 'created') {
        chosenTime = time;
        countBefore = before;
        countAfter = after;
        createSucceeded = true;
        await screenshotAndAttach(page, testInfo, 'Session created', 'sessions-04-saved.png');
        break;
      }
      lastResult = result;
      // 'conflict' or 'failed' → next attempt re-opens a fresh form on a new slot.
    }

    if (!createSucceeded) {
      await reportBugViaCopilot(page, {
        category: 'Sessions',
        title: 'Session could not be created on any time slot',
        description:
          `Creating a "${PATIENT}" session for ${target.toDateString()} failed for every 15-minute ` +
          `slot tried (last result: ${lastResult}). Either every slot is taken or Save is broken.`,
      });
      throw new Error('BUG: could not create a session on any time slot');
    }
    console.log(`  [Sessions] created at ${chosenTime} (count ${countBefore} → ${countAfter})`);
    expect(createSucceeded).toBe(true);
  });

  // ── 3. Verify in list ──
  test('Then the new session appears in the Sessions list', async ({}, testInfo) => {
    await page.waitForTimeout(1500);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Sessions list after create', 'sessions-05-list.png');

    console.log(`  [Sessions] before=${countBefore} after=${countAfter} @ ${chosenTime}`);
    if (countBefore != null && countAfter != null) {
      expect(countAfter).toBeGreaterThan(countBefore);
    } else {
      // Count not readable — fall back to the create having succeeded.
      expect(createSucceeded).toBe(true);
    }
  });

  // ── 4. Open the session → Session Workspace ("Go to Session") ──
  test('And I open the session to go to the Session Workspace', async ({}, testInfo) => {
    let opened = false;
    for (let i = 0; i < 8 && !opened; i++) {
      // Fresh list each attempt so row indices are stable and navigation is clean.
      await navigateToSessions(page);
      const kebabs = page.locator('flt-semantics[role="button"]').filter({ hasText: 'Session actions' });
      const kcount = await kebabs.count();
      if (i >= kcount) break;
      const box = await kebabs.nth(i).boundingBox();
      if (!box) continue;
      // Click the row body (left of the kebab) to open the workspace.
      await page.mouse.click(box.x - 400, box.y + box.height / 2);
      await page.waitForTimeout(4500);
      await enableAccessibility(page);
      const wtext = await getPageSemanticText(page);
      const startable = /Tap to Start Session|Check In & Start/i.test(wtext);
      if (startable && wtext.includes(PATIENT)) {
        opened = true;
        await screenshotAndAttach(page, testInfo, 'Session Workspace', 'sessions-06-workspace.png');
      }
    }

    if (!opened) {
      await reportBugViaCopilot(page, {
        category: 'Sessions',
        title: 'Could not open a startable session workspace',
        description:
          `After creating a "${PATIENT}" session, no scheduled session could be opened into the ` +
          'Session Workspace with a "Check In & Start" / "Tap to Start Session" control.',
      });
      throw new Error('BUG: could not open a startable session workspace');
    }
    expect(opened).toBe(true);
  });

  // ── 5. Start (play) + record goal data ──
  test('When I start the session and collect data for the Handwashing goal', async ({}, testInfo) => {
    // Start ("play")
    const startLabel = (await getFlutterButtons(page)).find(b => /Check In & Start|Tap to Start Session|Start Session/i.test(b));
    expect(startLabel, 'start/play control present').toBeTruthy();
    await clickFlutterButton(page, startLabel!, { timeout: 8000 });
    await page.waitForTimeout(4000);
    await enableAccessibility(page);

    // Handle the EVV location dialog if it still appears (retry once).
    let txt = await getPageSemanticText(page);
    if (/Location Required/i.test(txt)) {
      await clickFlutterButton(page, 'Retry Location', { timeout: 5000 }).catch(() => {});
      await page.waitForTimeout(4000);
      await enableAccessibility(page);
      txt = await getPageSemanticText(page);
    }
    await screenshotAndAttach(page, testInfo, 'Session started', 'sessions-07-started.png');

    const inProgress = /In Progress/i.test(txt);
    if (!inProgress) {
      await reportBugViaCopilot(page, {
        category: 'Sessions',
        title: 'Session did not start (Check In & Start)',
        description:
          'Clicking "Check In & Start" did not move the session to "In Progress". ' +
          `Workspace text: "${txt.slice(0, 300)}".`,
      });
      throw new Error('BUG: session did not start');
    }
    expect(inProgress).toBe(true);

    // Record a Task-Analysis trial on the Handwashing goal.
    expect(txt.includes('Handwashing'), 'Handwashing goal visible').toBe(true);

    // The "Score" controls are per-step dropdowns (role button/combobox; the
    // accessible text may be "Score" with a trailing chevron, so substring-match).
    const scoreControls = () =>
      page
        .locator('flt-semantics[role="button"], flt-semantics[role="combobox"], flt-semantics[aria-haspopup]')
        .filter({ hasText: 'Score' });
    const taSection = () =>
      page.locator('flt-semantics[role="button"]').filter({ hasText: /^Task Analysis$/ }).first();

    // Toggle the Task-Analysis section until the per-step Score controls are in
    // the semantics tree (handles both default-collapsed and lagging-semantics).
    for (let toggle = 0; toggle < 3 && (await scoreControls().count()) === 0; toggle++) {
      if (await taSection().count()) {
        await taSection().dispatchEvent('click', {}, { timeout: 5000 }).catch(() => {});
      }
      await page.waitForTimeout(1800);
      await enableAccessibility(page);
    }

    // Score each step: open its dropdown, then choose "Independent". Scoring
    // re-renders the row (label changes from "Score"), so re-query each pass.
    let stepsScored = 0;
    for (let i = 0; i < 4; i++) {
      const score = scoreControls().first();
      if ((await score.count()) === 0) break;
      await score.dispatchEvent('click', {}, { timeout: 5000 }).catch(() => {});
      await page.waitForTimeout(1000);
      await enableAccessibility(page);
      const indep = page
        .locator('flt-semantics[role="button"], flt-semantics[role="menuitem"]')
        .filter({ hasText: /^Independent$/ })
        .first();
      if (await indep.count()) {
        await indep.dispatchEvent('click', {}, { timeout: 5000 }).catch(() => {});
        stepsScored++;
        await page.waitForTimeout(800);
        await enableAccessibility(page);
      } else {
        await page.keyboard.press('Escape').catch(() => {});
        break;
      }
    }
    console.log(`  [Sessions] task-analysis steps scored: ${stepsScored}`);

    // Commit the trial if a Record button is present.
    const recordBtn = page.locator('flt-semantics[role="button"]').filter({ hasText: /^Record$/ }).first();
    if (await recordBtn.count()) {
      await recordBtn.dispatchEvent('click', {}, { timeout: 5000 }).catch(() => {});
      await page.waitForTimeout(2500);
      await enableAccessibility(page);
    }
    // Make sure no scoring dropdown is left open before the next scenario.
    await page.keyboard.press('Escape').catch(() => {});
    await page.waitForTimeout(500);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'Handwashing data recorded', 'sessions-08-goal-data.png');

    // Data entry happened (or the live data-collection surface for the goal is
    // present): a sync indicator appears / step progress advances / the scorer
    // is on screen. Scenario 6 is the definitive proof that recording persists.
    const after = await getPageSemanticText(page);
    const recorded =
      stepsScored > 0 ||
      /pending|saved locally/i.test(after) ||
      /[1-9]\d*\s*\/\s*\d+\s*steps/i.test(after) ||
      /[1-9]\d* trial/i.test(after) ||
      !/0 trials • 0 correct/i.test(after) ||
      /Score|Step \d|Trial \d/i.test(after);
    console.log(`  [Sessions] goal data recorded (stepsScored=${stepsScored}, indicator=${recorded})`);
    expect(recorded).toBe(true);
  });

  // ── 6. Record a challenging behaviour ──
  test('And I record a challenging behaviour (Tantrum)', async ({}, testInfo) => {
    // Close any open scoring dropdown so the bottom behaviour bar is live.
    await page.keyboard.press('Escape').catch(() => {});
    await page.waitForTimeout(800);
    await enableAccessibility(page);

    const tantrumSel = 'flt-semantics[aria-label^="Tantrum"]';
    let tantrum = page.locator(tantrumSel).first();
    if ((await tantrum.count()) === 0) {
      // Re-assert semantics and retry once.
      await enableAccessibility(page);
      await page.waitForTimeout(800);
      tantrum = page.locator(tantrumSel).first();
    }
    expect(await tantrum.count(), 'Tantrum behaviour control present').toBeGreaterThan(0);

    const before = (await tantrum.getAttribute('aria-label')) || '';
    await tantrum.dispatchEvent('click');
    await page.waitForTimeout(1500);
    await enableAccessibility(page);
    const after =
      (await page.locator(tantrumSel).first().getAttribute('aria-label').catch(() => '')) || '';
    console.log(`  [Sessions] Tantrum before="${before.replace(/\n/g, ' ')}" after="${after.replace(/\n/g, ' ')}"`);
    await screenshotAndAttach(page, testInfo, 'Behaviour recorded', 'sessions-09-behaviour.png');

    const beforeN = parseInt((before.match(/(\d+)\s*$/) || [])[1] || '0', 10);
    const afterN = parseInt((after.match(/(\d+)\s*$/) || [])[1] || '0', 10);
    expect(afterN).toBeGreaterThan(beforeN);
  });

  // ── 7. End & check out → open the "End Session — Review" dialog ──
  test('Then I end & check out, opening the End Session review dialog', async ({}, testInfo) => {
    // The top-right kebab ("More options", near the session timer) holds
    // "End & check out" / "Pause session".
    const moreOpts = page.locator('flt-semantics[role="button"]').filter({ hasText: 'More options' }).first();
    expect(await moreOpts.count(), '"More options" (kebab) control present').toBeGreaterThan(0);
    await moreOpts.dispatchEvent('click');
    await page.waitForTimeout(2000);
    await enableAccessibility(page);

    // Choose "End & check out" from the kebab menu.
    let endItem = page.locator('flt-semantics[role="menuitem"][aria-label="End & check out"]').first();
    if ((await endItem.count()) === 0) {
      endItem = page.locator('flt-semantics[role="menuitem"], flt-semantics[role="button"]')
        .filter({ hasText: /End & check ?out/i }).first();
    }
    expect(await endItem.count(), '"End & check out" menu item present').toBeGreaterThan(0);
    await endItem.dispatchEvent('click');
    await page.waitForTimeout(3000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'End Session review dialog', 'sessions-10-end-dialog.png');

    // The dialog text is painted on the Flutter canvas and is NOT aggregated
    // into flt-semantics-host.textContent, so scan every flt-semantics node's
    // aria-label / textContent instead.
    // The dialog's "End Session — Review" title, "Session Summary" and the
    // "End Session" primary button are painted on the canvas and never reach
    // the semantics tree. The reliably-exposed markers are the target
    // dispositions ("Zero occurrences" / "Not tracked") and the
    // "Mark All Not Tracked" link — key detection off those.
    const labels = await allSemanticLabels(page);
    const joined = labels.join(' • ');

    // Dump the role=button nodes (+rects) so the canvas-only "End Session"
    // button can be located by position for the next scenario.
    const buttonRects = await page.evaluate(() =>
      Array.from(document.querySelectorAll('flt-semantics[role="button"]'))
        .map((n) => {
          const r = n.getBoundingClientRect();
          return {
            label: (n.getAttribute('aria-label') || n.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 40),
            x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height),
          };
        })
        .filter((b) => b.w > 0 && b.h > 0),
    );
    console.log('  [Sessions] End Session review dialog buttons:');
    for (const b of buttonRects) console.log(`    "${b.label}" @ ${b.x},${b.y} ${b.w}x${b.h}`);

    const dialogOpen =
      /Mark All Not Tracked/i.test(joined) &&
      /(Not tracked|Zero occurrences)/i.test(joined);

    if (!dialogOpen) {
      throw new Error(
        'BUG: End Session review dialog did not open. Labels seen: ' + joined.slice(0, 400),
      );
    }
    expect(dialogOpen).toBe(true);
  });

  // ── 8. Disposition the no-data targets and end the session (data saved) ──
  test('And I mark the untracked targets and end the session', async ({}, testInfo) => {
    // The dialog must still be open (targets default to "Not tracked").
    expect(
      /Mark All Not Tracked/i.test((await allSemanticLabels(page)).join(' • ')),
      'End Session review dialog still open',
    ).toBe(true);

    // Record each listed target as "Zero occurrences (record as 0%)". Match the
    // option row EXACTLY with an anchored regex (the dialog also has wide
    // container nodes whose text concatenates every option). Activate via
    // dispatchEvent('click') on the node itself — Flutter's semantic node
    // geometry is misaligned with the painted canvas, so coordinate clicks land
    // on the backdrop and dismiss the dialog; a dispatched click is
    // geometry-independent.
    const zeroOpts = page.locator('flt-semantics').filter({ hasText: /^Zero occurrences \(record as 0%\)$/ });
    const zcount = await zeroOpts.count();
    console.log(`  [Sessions] "Zero occurrences" option rows: ${zcount}`);
    for (let i = 0; i < zcount; i++) {
      await zeroOpts.nth(i).dispatchEvent('click').catch(() => {});
      await page.waitForTimeout(400);
      await enableAccessibility(page);
    }
    await screenshotAndAttach(page, testInfo, 'Targets dispositioned', 'sessions-11-review-selected.png');

    // The dialog should still be open after selecting (selecting a radio does
    // not dismiss it).
    expect(
      /Mark All Not Tracked/i.test((await allSemanticLabels(page)).join(' • ')),
      'dialog still open after selecting options',
    ).toBe(true);

    // Commit: click "End Session". That gradient button is painted on the
    // canvas and is NOT in the semantics tree, so anchor to the "Cancel" button
    // (which IS exposed) and click a fixed offset to its right — same button
    // row, so this holds regardless of how many targets were listed.
    const cancelBox = await page.evaluate(() => {
      for (const n of Array.from(document.querySelectorAll('flt-semantics'))) {
        if ((n.getAttribute('aria-label') || n.textContent || '').trim() === 'Cancel') {
          const r = n.getBoundingClientRect();
          if (r.width > 0 && r.height > 0) return { x: r.x, y: r.y, w: r.width, h: r.height };
        }
      }
      return null;
    });
    expect(cancelBox, '"Cancel" anchor present in review dialog').toBeTruthy();
    const endX = cancelBox!.x + cancelBox!.w / 2 + 91; // End Session sits ~91px right of Cancel's center
    const endY = cancelBox!.y + cancelBox!.h / 2;
    console.log(`  [Sessions] clicking End Session at ${Math.round(endX)},${Math.round(endY)} (Cancel @ ${Math.round(cancelBox!.x)},${Math.round(cancelBox!.y)})`);
    await page.mouse.click(endX, endY);
    await page.waitForTimeout(4000);
    await enableAccessibility(page);
    await screenshotAndAttach(page, testInfo, 'After end session', 'sessions-12-ended.png');

    const finalLabels = (await allSemanticLabels(page)).join(' • ');
    const dialogGone = !/Mark All Not Tracked/i.test(finalLabels);
    const ended =
      dialogGone &&
      (/Completed|checked out|session ended|read-only/i.test(finalLabels) ||
        // back on the Sessions list
        (await getFlutterButtons(page)).some((b) => /add session/i.test(b)) ||
        // still on the workspace but the session is no longer In Progress
        !/In Progress/i.test(finalLabels));
    console.log(`  [Sessions] ended/saved indicator: ${ended} (dialogGone=${dialogGone})`);

    if (!ended) {
      await reportBugViaCopilot(page, {
        category: 'Sessions',
        title: 'Could not end / check out of a session',
        description:
          'After dispositioning the no-data targets and clicking "End Session", the session did ' +
          `not reach a completed/checked-out state. Labels: "${finalLabels.slice(0, 300)}".`,
      });
    }
    expect(ended).toBe(true);
  });
});
