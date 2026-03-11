import { Page, expect } from '@playwright/test';

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
  const path = testInfo.outputPath(filename);
  await page.screenshot({ path, fullPage: true });
  await testInfo.attach(name, { path, contentType: 'image/png' });
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
 * Reports a bug via the AI Copilot chat sidebar.
 * Opens AI Copilot, types a bug description in the chat input, and sends it.
 * Best-effort: does not fail the calling test if the report itself doesn't go through.
 */
export async function reportBugViaCopilot(
  page: Page,
  bug: { category: string; title: string; description: string; screenshotPath?: string }
): Promise<void> {
  try {
    await enableAccessibility(page);
    await clickFlutterButton(page, 'AI Copilot', { timeout: 5000 });
    await page.waitForTimeout(4000);
    await enableAccessibility(page);

    const message = `[Bug Report] Category: ${bug.category} | Title: ${bug.title} | Description: ${bug.description}`;

    const chatInput = page.locator('flt-semantics-host input').last();
    await chatInput.focus();
    await page.keyboard.press('Control+a');
    await page.keyboard.type(message, { delay: 20 });
    await page.waitForTimeout(500);

    // Send via Enter
    await page.keyboard.press('Enter');
    await page.waitForTimeout(5000);
    await enableAccessibility(page);

    console.log(`  [Bug Reporter] Submitted: ${bug.title}`);
  } catch (err) {
    console.log(`  [Bug Reporter] Failed to submit bug report (non-fatal): ${err}`);
  }
}
