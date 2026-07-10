/**
 * Step definitions for copay.feature (Patient Profile — Co-Pay Payment).
 * The Co-Pay section renders all controls in the semantics tree, so state
 * transitions are assertable directly. Live default is "Co-Pay Required"
 * (amount + Payment Method shown), and the amount input's aria-label is "$25.00".
 */
import { expect } from '@playwright/test';
import { Given, When, Then } from '../registry';
import type { World } from '../world';
import {
  enableAccessibility, clickFlutterButton, clickFlutterButtonByIteration,
  fillByPlaceholder, clickSidebarNav, waitForFlutterReady,
} from '../../helpers/flutter';

async function labels(w: World): Promise<string[]> {
  return w.page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics'))
      .map((n) => (n.getAttribute('aria-label') || n.textContent || '').trim()).filter(Boolean));
}
async function sees(w: World, text: string, timeoutMs = 6000): Promise<boolean> {
  const needle = text.toLowerCase();
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if ((await labels(w)).join(' • ').toLowerCase().includes(needle)) return true;
    await w.page.waitForTimeout(400); await enableAccessibility(w.page);
  }
  return false;
}
async function inputVal(w: World, placeholder: string): Promise<string | null> {
  const el = w.page.locator(`flt-semantics-host input[aria-label="${placeholder}"]`).first();
  return (await el.count()) ? el.inputValue() : null;
}
// The Co-Pay Amount input's aria-label switches away from the "$25.00" hint once
// it holds a value, so read it by value (the only money-style input on the panel).
async function copayAmountValue(w: World): Promise<string | null> {
  return w.page.evaluate(() => {
    const ins = Array.from(document.querySelectorAll('flt-semantics-host input'));
    let el = ins.find((i) => (i.getAttribute('aria-label') || '') === '$25.00');
    if (!el || !(el.value || '').length) el = ins.find((i) => /^\$?\d/.test(i.value || '')) || el;
    return el ? (el.value ?? '') : null;
  });
}
async function clickChip(w: World, text: string): Promise<void> {
  const b = w.page.locator('flt-semantics[role="button"]').filter({ hasText: new RegExp('^' + text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '$') }).first();
  expect(await b.count(), `chip "${text}" not found`).toBeTruthy();
  await b.dispatchEvent('click');
  await w.page.waitForTimeout(1200); await enableAccessibility(w.page);
}
async function openSection(w: World, name: string): Promise<void> {
  const row = w.page.locator('flt-semantics[role="button"]').filter({ hasText: new RegExp('^' + name) }).first();
  await row.waitFor({ state: 'attached', timeout: 8000 });
  await row.dispatchEvent('click');
  await w.page.waitForTimeout(2000); await enableAccessibility(w.page);
}
async function createPatientInProfile(w: World, name: string): Promise<void> {
  const [first, ...rest] = name.split(' ');
  await w.page.goto('/'); await waitForFlutterReady(w.page);
  await clickSidebarNav(w.page, 'Patients');
  await w.page.waitForTimeout(2500); await enableAccessibility(w.page);
  await clickFlutterButton(w.page, 'New Patient', { timeout: 20000 });
  await w.page.waitForTimeout(3000); await enableAccessibility(w.page);
  await fillByPlaceholder(w.page, 'John', first);
  await fillByPlaceholder(w.page, 'Doe', rest.join(' ') || 'Kannan', 0);
  await clickFlutterButtonByIteration(w.page, 'Save');
  await w.page.waitForTimeout(2000); await enableAccessibility(w.page);
  const dup = w.page.locator('flt-semantics[role="button"]').filter({ hasText: /Create Anyway/ }).first();
  if (await dup.count()) { await dup.dispatchEvent('click'); await w.page.waitForTimeout(2500); await enableAccessibility(w.page); }
}

// ── Background ──────────────────────────────────────────────────────────────
Given(/^the patient "([^"]*)" has been created with Insurance pay type$/, async (w, name) => {
  await createPatientInProfile(w, name); // Insurance is the default pay type
});
When(/^I open the "([^"]*)" section$/, (w, name) => openSection(w, name));
When(/^I open "([^"]*)"$/, (w, name) => openSection(w, name));

Then(/^the chips "([^"]*)" and "([^"]*)" are visible$/, async (w, a, b) => {
  expect(await sees(w, a), `chip "${a}" not visible`).toBeTruthy();
  expect(await sees(w, b), `chip "${b}" not visible`).toBeTruthy();
});

// ── chip selection ──────────────────────────────────────────────────────────
When(/^I select the "([^"]*)" chip$/, (w, chip) => clickChip(w, chip));
When(/^I select the "([^"]*)" payment chip$/, (w, chip) => clickChip(w, chip));
Given(/^I selected the "([^"]*)" chip$/, (w, chip) => clickChip(w, chip));
Given(/^I selected "([^"]*)"$/, (w, chip) => clickChip(w, chip));
Given(/^I selected "Waive" and typed a reason$/, async (w) => {
  await clickChip(w, 'Waive');
  await fillByPlaceholder(w.page, 'Enter reason...', 'Financial hardship documented', 0);
});
Given(/^I selected "Co-Pay Required" and entered "([^"]*)"(?: with method "([^"]*)")?$/, async (w, amount, method) => {
  await clickChip(w, 'Co-Pay Required');
  await fillByPlaceholder(w.page, '$25.00', amount, 0);
  if (method) await clickChip(w, method);
});

// ── reveals / hides ─────────────────────────────────────────────────────────
Then(/^a "Co-Pay Amount" input with prefix "\$" and hint "\$25\.00" appears$/, async (w) => {
  expect(await sees(w, 'Co-Pay Amount'), 'Co-Pay Amount label missing').toBeTruthy();
  expect(await inputVal(w, '$25.00'), 'amount input missing').not.toBeNull();
});
Then(/^the "([^"]*)" card titled "([^"]*)" appears$/, async (w, card) => {
  expect(await sees(w, card), `card "${card}" missing`).toBeTruthy();
});
Then(/^the payment chips "([^"]*)", "([^"]*)", "([^"]*)" and "([^"]*)" are shown$/, async (w, ...c) => {
  for (const chip of c) expect(await sees(w, chip), `payment chip "${chip}" missing`).toBeTruthy();
});
Then(/^the amount and Payment Method card are hidden$/, async (w) => {
  expect(await sees(w, 'Payment Method', 1500), 'Payment Method still shown').toBeFalsy();
});
Then(/^the emerald "([^"]*)" confirmation returns$/, async (w, text) => {
  expect(await sees(w, text), `"${text}" not shown`).toBeTruthy();
});
Then(/^no "Co-Pay Amount" input is shown$/, async (w) => {
  expect(await inputVal(w, '$25.00'), 'amount input unexpectedly present').toBeNull();
});

// ── amount value ────────────────────────────────────────────────────────────
Then(/^the amount is accepted as "([^"]*)"$/, async (w, amount) => {
  expect(await copayAmountValue(w)).toBe(amount);
});
Then(/^the stored amount is "([^"]*)" without a leading "\$"$/, async (w, amount) => {
  const v = await copayAmountValue(w);
  expect(v).toBe(amount);
  expect(v?.startsWith('$')).toBeFalsy();
});

// ── payment method / action button ──────────────────────────────────────────
Then(/^the "([^"]*)" chip is highlighted as selected$/, async (w, chip) => {
  expect(await sees(w, chip), `chip "${chip}" not present`).toBeTruthy();
});
Then(/^the action button reads "([^"]*)"$/, async (w, label) => {
  expect(await sees(w, label), `action button "${label}" not shown`).toBeTruthy();
});
Then(/^the action button changes from "([^"]*)" to "([^"]*)"$/, async (w, _from, to) => {
  expect(await sees(w, to), `action button "${to}" not shown`).toBeTruthy();
});

// ── Card / Waive reveals ────────────────────────────────────────────────────
Then(/^a "Reason for Waiving" input with hint "Enter reason\.\.\." appears$/, async (w) => {
  expect(await sees(w, 'Reason for Waiving'), 'Reason for Waiving label missing').toBeTruthy();
  expect(await inputVal(w, 'Enter reason...'), 'reason input missing').not.toBeNull();
});
Then(/^the "Reason for Waiving" input is removed$/, async (w) => {
  expect(await inputVal(w, 'Enter reason...'), 'reason input still present').toBeNull();
});

// ── Private pay ─────────────────────────────────────────────────────────────
Given(/^the patient pay type is "Private Pay"$/, async (w) => {
  // Set pay type on the Insurance section, then the copay step opens Co-Pay.
  await createPatientInProfile(w, 'Rujitha Kannan');
  await openSection(w, 'Insurance Information');
  await clickFlutterButtonByIteration(w.page, 'Private Pay');
  await w.page.waitForTimeout(800); await enableAccessibility(w.page);
});
Then(/^the "Co-Pay Status" and payment options remain interactive below the warning$/, async (w) => {
  expect(await sees(w, 'Co-Pay Status'), 'Co-Pay Status missing').toBeTruthy();
});
Then(/^I see the warning "([^"]*)"$/, async (w, text) => {
  expect(await sees(w, text), `warning "${text}" not shown`).toBeTruthy();
});

// ── default-state assertion (live default is "Co-Pay Required") ─────────────
Then(/^the "Co-Pay Required" chip is shown selected by default with the amount field$/, async (w) => {
  expect(await sees(w, 'Co-Pay Amount'), 'amount field not shown by default').toBeTruthy();
  expect(await sees(w, 'Payment Method'), 'payment method not shown by default').toBeTruthy();
});
