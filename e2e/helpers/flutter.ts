import { Page, expect } from '@playwright/test';
import * as fs from 'fs';
import * as nodePath from 'path';

/**
 * Flutter CanvasKit interaction utilities.
 *
 * Flutter renders to a WebGL canvas and exposes a hidden
 * `flt-semantics-placeholder` element. Dispatching a click on it
 * enables the semantics tree, which surfaces `flt-semantics` elements
 * with roles and text content that Playwright can interact with.
 */

export async function enableAccessibility(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  if ((await placeholder.count()) > 0) {
    await placeholder.dispatchEvent('click');
    await page.waitForTimeout(2000);
  }
}

export async function clickFlutterButton(
  page: Page,
  label: string,
  options: { timeout?: number } = {}
): Promise<void> {
  const timeout = options.timeout ?? 10_000;
  const btn = page.locator('flt-semantics[role="button"]').filter({ hasText: label }).first();
  await btn.waitFor({ state: 'attached', timeout });
  await btn.dispatchEvent('click');
}

export async function clickFlutterButtonByIteration(
  page: Page,
  exactText: string
): Promise<boolean> {
  const btns = page.locator('flt-semantics[role="button"]');
  const count = await btns.count();
  for (let i = 0; i < count; i++) {
    const text = (await btns.nth(i).textContent())?.trim() || '';
    if (text === exactText) {
      await btns.nth(i).dispatchEvent('click');
      return true;
    }
  }
  return false;
}

export async function fillInputByIndex(
  page: Page,
  index: number,
  value: string
): Promise<void> {
  const input = page.locator('flt-semantics-host input').nth(index);
  await input.focus();
  await page.waitForTimeout(200);
  await page.keyboard.press('Control+a');
  await page.keyboard.type(value, { delay: 30 });
  await page.waitForTimeout(300);
}

export async function getInputCount(page: Page): Promise<number> {
  return page.locator('flt-semantics-host input').count();
}

export async function getPageSemanticText(page: Page): Promise<string> {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    return host?.textContent || '';
  });
}

export async function getFlutterButtons(page: Page): Promise<string[]> {
  const btns = page.locator('flt-semantics[role="button"]');
  const count = await btns.count();
  const labels: string[] = [];
  for (let i = 0; i < count; i++) {
    labels.push((await btns.nth(i).textContent())?.trim() || '');
  }
  return labels;
}

export async function navigateToSection(
  page: Page,
  sectionName: string
): Promise<void> {
  await enableAccessibility(page);
  await clickFlutterButton(page, sectionName);
  await page.waitForTimeout(3000);
  await enableAccessibility(page);
}

export async function waitForFlutterReady(page: Page, timeoutMs = 15_000): Promise<void> {
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(Math.min(timeoutMs, 5000));
  await enableAccessibility(page);
}

export async function screenshotAndAttach(
  page: Page,
  testInfo: { outputPath: (...args: string[]) => string; attach: (name: string, options: { path: string; contentType: string }) => Promise<void> },
  name: string,
  filename: string
): Promise<void> {
  const dest = testInfo.outputPath(filename);
  await page.screenshot({ path: dest, fullPage: true });
  await testInfo.attach(name, { path: dest, contentType: 'image/png' });
}

export async function clickSidebarNav(page: Page, label: string): Promise<void> {
  await enableAccessibility(page);
  const clicked = await clickFlutterButtonByIteration(page, label);
  if (!clicked) {
    await clickFlutterButton(page, label);
  }
  await page.waitForTimeout(3000);
  await enableAccessibility(page);
}

export async function expectPageContainsText(page: Page, text: string): Promise<void> {
  const pageText = await getPageSemanticText(page);
  expect(pageText).toContain(text);
}

export async function handleDuplicateDialog(page: Page): Promise<boolean> {
  const pageText = await getPageSemanticText(page);
  if (pageText.includes('Possible Duplicate')) {
    try {
      await clickFlutterButton(page, 'Create Anyway', { timeout: 5000 });
      await page.waitForTimeout(3000);
      return true;
    } catch {
      return false;
    }
  }
  return false;
}

/**
 * Opens the mesh/app-switcher menu (2nd unnamed icon button in the top bar)
 * and navigates to HRMS using keyboard Tab navigation.
 * Menu items: Clinic, Communication, Billing, Parent Portal, HRMS, LMS, Admin
 * HRMS is the 5th item, so Tab 5 times then Enter.
 */
export async function navigateToHRMS(page: Page): Promise<void> {
  await enableAccessibility(page);
  const allBtns = page.locator('flt-semantics[role="button"]');
  const count = await allBtns.count();
  const emptyIndices: number[] = [];
  for (let i = 0; i < count; i++) {
    const txt = (await allBtns.nth(i).textContent())?.trim() || '';
    if (txt === '') emptyIndices.push(i);
  }
  // 2nd empty button is the mesh/app-switcher icon
  await allBtns.nth(emptyIndices[1]).dispatchEvent('click');
  await page.waitForTimeout(3000);
  await enableAccessibility(page);

  // Tab to HRMS (5th menu item) and press Enter
  for (let t = 0; t < 5; t++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await enableAccessibility(page);
}

/**
 * Persists an open issue to gherkin-report/open-issues.json so the
 * HTML reporter can render an "Open Issues" section with hyperlinks.
 */
function recordOpenIssue(issue: {
  url: string;
  title: string;
  category: string;
  description: string;
}): void {
  const dir = nodePath.join(process.cwd(), 'gherkin-report');
  const file = nodePath.join(dir, 'open-issues.json');

  let issues: any[] = [];
  try {
    if (fs.existsSync(file)) {
      issues = JSON.parse(fs.readFileSync(file, 'utf-8'));
    }
  } catch { /* start fresh */ }

  issues.push({ ...issue, reportedAt: new Date().toISOString() });

  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(file, JSON.stringify(issues, null, 2));
}

/**
 * Reports a bug via the AI Copilot chat sidebar.
 *
 * Discovered DOM structure (Flutter CanvasKit):
 *   - Chat input is a <textarea aria="Ask me anything..."> inside flt-semantics-host
 *   - After sending "report a bug", form appears adding:
 *       input[1]    → Title field
 *       textarea[1] → Description field
 *       button "Submit" → Submit
 *   - Success response contains a GitHub issue URL
 *
 * Best-effort: returns the issue URL on success, null on failure.
 * Never throws — the calling test decides whether to fail.
 */
export async function reportBugViaCopilot(
  page: Page,
  bug: { category: string; title: string; description: string; screenshotPath?: string }
): Promise<string | null> {
  try {
    await enableAccessibility(page);

    // ── 1. Open AI Copilot ──
    await clickFlutterButton(page, 'AI Copilot', { timeout: 8000 });
    await page.waitForTimeout(5000);
    await enableAccessibility(page);

    // Verify sidebar opened — look for "AI Assistant" or "How can I help"
    let semText = await getPageSemanticText(page);
    if (!semText.includes('AI Assistant') && !semText.includes('How can I help')) {
      console.log('  [Bug Reporter] Copilot sidebar did not open, retrying click…');
      await clickFlutterButton(page, 'AI Copilot', { timeout: 5000 });
      await page.waitForTimeout(5000);
      await enableAccessibility(page);
    }

    // ── 2. Type "report a bug" in the chat textarea ──
    // The chat input is a <textarea> with aria-label="Ask me anything..."
    const chatTextarea = page.locator('flt-semantics-host textarea[aria-label="Ask me anything..."]');
    let chatCount = await chatTextarea.count();
    if (chatCount === 0) {
      // Fallback: first textarea (only one before the form loads)
      const anyTa = page.locator('flt-semantics-host textarea');
      chatCount = await anyTa.count();
      console.log(`  [Bug Reporter] No aria-labeled textarea, using first of ${chatCount}`);
      if (chatCount === 0) {
        console.log('  [Bug Reporter] No textarea found — aborting');
        return null;
      }
      await anyTa.first().focus();
    } else {
      await chatTextarea.first().focus();
    }

    await page.waitForTimeout(500);
    await page.keyboard.press('Control+a');
    await page.keyboard.type('report a bug', { delay: 50 });
    await page.waitForTimeout(500);
    await page.keyboard.press('Enter');
    console.log('  [Bug Reporter] Sent "report a bug"');

    // ── 3. Wait for the form ──
    await page.waitForTimeout(10_000);
    await enableAccessibility(page);

    semText = await getPageSemanticText(page);
    if (!semText.includes('Report a Bug') || !semText.includes('Submit')) {
      console.log(`  [Bug Reporter] Form not detected. Text: ${semText.substring(0, 400)}`);
      return null;
    }
    console.log('  [Bug Reporter] Bug report form detected');

    // ── 4. Fill Title (new <input> at index 1) ──
    const allInputs = page.locator('flt-semantics-host input');
    const inputCount = await allInputs.count();
    console.log(`  [Bug Reporter] ${inputCount} input(s) on page`);

    if (inputCount >= 2) {
      await allInputs.nth(1).focus();
      await page.waitForTimeout(300);
      await page.keyboard.press('Control+a');
      await page.keyboard.type(bug.title, { delay: 30 });
      console.log(`  [Bug Reporter] Filled Title: "${bug.title}"`);
    }

    await page.waitForTimeout(500);

    // ── 5. Fill Description ──
    // The Description field is a <textarea> with a known aria-label
    const descTa = page.locator(
      'flt-semantics-host textarea[aria-label="Describe the issue or feature..."]',
    );
    let descFilled = false;
    if ((await descTa.count()) > 0) {
      await descTa.first().focus();
      await page.waitForTimeout(300);
      await page.keyboard.press('Control+a');
      await page.keyboard.type(bug.description, { delay: 20 });
      descFilled = true;
      console.log('  [Bug Reporter] Filled Description (aria-label match)');
    } else {
      // Fallback: last textarea (index 2 of 3)
      const allTa = page.locator('flt-semantics-host textarea');
      const taCnt = await allTa.count();
      if (taCnt >= 3) {
        await allTa.nth(2).focus();
        await page.waitForTimeout(300);
        await page.keyboard.press('Control+a');
        await page.keyboard.type(bug.description, { delay: 20 });
        descFilled = true;
        console.log(`  [Bug Reporter] Filled Description (textarea[2] fallback)`);
      }
    }
    if (!descFilled) {
      console.log('  [Bug Reporter] WARNING: could not find Description textarea');
    }

    await page.waitForTimeout(500);

    // ── 6. Click Submit ──
    await enableAccessibility(page);
    await clickFlutterButton(page, 'Submit', { timeout: 10_000 });
    console.log('  [Bug Reporter] Clicked Submit');

    // ── 7. Wait for success response and capture GitHub URL ──
    // The AI responds with "Support ticket submitted successfully! GitHub issue: <url>"
    // The chat response text is rendered on the Flutter canvas but is NOT
    // always exposed via flt-semantics-host textContent. So we also search
    // every flt-semantics element individually and the full document body.
    let issueUrl: string | null = null;
    let submitted = false;

    for (let attempt = 0; attempt < 3; attempt++) {
      await page.waitForTimeout(6_000);
      await enableAccessibility(page);

      // Strategy A: semantic host textContent
      const semText = await getPageSemanticText(page);

      // Strategy B: search every flt-semantics node individually
      const urlFromNodes = await page.evaluate(() => {
        const nodes = document.querySelectorAll('flt-semantics');
        for (const n of nodes) {
          const t = n.textContent || '';
          const m = t.match(/https:\/\/github\.com\/[^\s)]+\/issues\/\d+/);
          if (m) return m[0];
        }
        return null;
      });

      // Strategy C: walk all DOM text nodes
      const urlFromDom = await page.evaluate(() => {
        const walker = document.createTreeWalker(document, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) {
          const t = walker.currentNode.textContent || '';
          const m = t.match(/https:\/\/github\.com\/[^\s)]+\/issues\/\d+/);
          if (m) return m[0];
        }
        return null;
      });

      issueUrl = urlFromNodes || urlFromDom || semText.match(/https:\/\/github\.com\/[^\s)]+\/issues\/\d+/)?.[0] || null;

      if (issueUrl) {
        console.log(`  [Bug Reporter] Poll ${attempt + 1}: captured URL → ${issueUrl}`);
        break;
      }

      // If the form closed (no "Submit" button visible), the ticket was filed
      if (!semText.includes('Submit') && !semText.includes('Report a Bug')) {
        submitted = true;
        console.log(`  [Bug Reporter] Poll ${attempt + 1}: form closed (submitted)`);
        break;
      }

      console.log(`  [Bug Reporter] Poll ${attempt + 1}: waiting…`);
    }

    if (issueUrl) {
      console.log(`  [Bug Reporter] SUCCESS → ${issueUrl}`);
      recordOpenIssue({
        url: issueUrl,
        title: bug.title,
        category: bug.category,
        description: bug.description,
      });
    } else if (submitted) {
      // Form closed → ticket was filed, but URL not capturable from DOM
      // Use the repo issues page as a fallback link
      const fallbackUrl = 'https://github.com/wabicareteam/wabi-clinic-flutter/issues';
      console.log(`  [Bug Reporter] Ticket submitted, URL not in DOM. Fallback: ${fallbackUrl}`);
      issueUrl = fallbackUrl;
      recordOpenIssue({
        url: fallbackUrl,
        title: bug.title,
        category: bug.category,
        description: `${bug.description} (exact issue URL not captured)`,
      });
    } else {
      console.log('  [Bug Reporter] Could not confirm submission');
    }

    // ── 8. Close the Copilot sidebar ──
    await page.keyboard.press('Escape');
    await page.waitForTimeout(1000);

    return issueUrl;
  } catch (err) {
    console.log(`  [Bug Reporter] Error (non-fatal): ${err}`);
    return null;
  }
}
