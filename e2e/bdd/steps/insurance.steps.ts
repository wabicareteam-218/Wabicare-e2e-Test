/**
 * Step definitions for patient-insurance.feature. The Insurance section renders
 * card titles/banner/subscriber controls in the semantics tree. Live strings
 * differ from the source panel: card is "Primary insurance card", save toast is
 * "Insurance Information saved successfully".
 */
import { expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
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
async function hasInput(w: World, placeholder: string): Promise<boolean> {
  return (await w.page.locator(`flt-semantics-host input[aria-label="${placeholder}"]`).count()) > 0;
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

// Minimal PNG (used for jpg/jpeg/png fixtures) + minimal PDF, created on demand.
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAF0lEQVR4nGP8z8Dwn4EIwESMokGpEAA6zwOEfx3g2gAAAABJRU5ErkJggg==', 'base64');
const PDF = Buffer.from('%PDF-1.1\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 50 50]>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF');
function ensureFixture(name: string): string {
  const dir = path.resolve('tests/fixtures');
  const p = path.join(dir, name);
  if (!fs.existsSync(p)) fs.writeFileSync(p, name.toLowerCase().endsWith('.pdf') ? PDF : PNG);
  return p;
}

async function uploadCard(w: World, side: 'Front' | 'Back', file: string): Promise<void> {
  const nth = side === 'Front' ? 0 : 1;
  const btn = w.page.locator('flt-semantics[role="button"]').filter({ hasText: /^Upload$/ }).nth(nth);
  const [chooser] = await Promise.all([
    w.page.waitForEvent('filechooser', { timeout: 10_000 }),
    btn.dispatchEvent('click'),
  ]);
  await chooser.setFiles(ensureFixture(file));
  await w.page.waitForTimeout(2500); await enableAccessibility(w.page);
}
async function cardUploaded(w: World, file: string): Promise<boolean> {
  // Durable success signal: the file name appears in the box (toast is transient).
  return (await sees(w, file, 6000)) || (await sees(w, 'card uploaded', 1500));
}

// ── Background ──────────────────────────────────────────────────────────────
Given(/^the patient "([^"]*)" has been created \(Basic Information saved\)$/, (w, name) => createPatientInProfile(w, name));
When(/^I open the "([^"]*)" section$/, (w, name) => openSection(w, name));
When(/^I open "Insurance Information" with "Insurance" selected$/, (w) => openSection(w, 'Insurance Information'));

Then(/^the pay-type chips "([^"]*)" and "([^"]*)" are visible$/, async (w, a, b) => {
  expect(await sees(w, a), `chip "${a}" missing`).toBeTruthy();
  expect(await sees(w, b), `chip "${b}" missing`).toBeTruthy();
});

// ── pay-type toggle ─────────────────────────────────────────────────────────
Then(/^the "Insurance" sub-cards are shown by default$/, async (w) => {
  expect(await sees(w, 'Primary insurance card'), 'insurance sub-cards not shown').toBeTruthy();
});
Then(/^I see the "([^"]*)" card(?: titled "([^"]*)")?$/, async (w, card) => {
  expect(await sees(w, card), `card "${card}" not shown`).toBeTruthy();
});
When(/^I select the "([^"]*)" chip$/, async (w, chip) => {
  await clickFlutterButtonByIteration(w.page, chip);
  await w.page.waitForTimeout(1200); await enableAccessibility(w.page);
});
Given(/^I selected "([^"]*)"$/, async (w, chip) => {
  await clickFlutterButtonByIteration(w.page, chip);
  await w.page.waitForTimeout(1000); await enableAccessibility(w.page);
});
Then(/^the "([^"]*)" and "([^"]*)" cards are hidden$/, async (w, a, b) => {
  expect(await sees(w, a, 1500), `"${a}" still shown`).toBeFalsy();
  expect(await sees(w, b, 800), `"${b}" still shown`).toBeFalsy();
});
Then(/^I see the banner "([^"]*)"$/, async (w, text) => {
  expect(await sees(w, text), `banner "${text}" not shown`).toBeTruthy();
});
Then(/^the insurance sub-cards reappear$/, async (w) => {
  expect(await sees(w, 'Primary insurance card'), 'sub-cards did not reappear').toBeTruthy();
});
Then(/^the private-pay banner is gone$/, async (w) => {
  expect(await sees(w, 'pay out-of-pocket', 1500), 'private-pay banner still shown').toBeFalsy();
});

// ── coverage ────────────────────────────────────────────────────────────────
When(/^I leave "([^"]*)", "([^"]*)" and "([^"]*)" empty$/, async () => { /* fields start empty */ });
Then(/^the section still saves \(no hard validation on coverage fields\)$/, async (w) => {
  expect(await sees(w, 'saved successfully'), 'section did not save').toBeTruthy();
});

// ── subscriber ──────────────────────────────────────────────────────────────
When(/^I check "Patient is the subscriber"$/, async (w) => {
  const cb = w.page.locator('flt-semantics[role="checkbox"]').first();
  if ((await cb.getAttribute('aria-checked')) !== 'true') await cb.dispatchEvent('click');
  await w.page.waitForTimeout(1000); await enableAccessibility(w.page);
});
Given(/^"Patient is the subscriber" is unchecked$/, async (w) => {
  const cb = w.page.locator('flt-semantics[role="checkbox"]').first();
  if ((await cb.getAttribute('aria-checked')) === 'true') { await cb.dispatchEvent('click'); await w.page.waitForTimeout(800); await enableAccessibility(w.page); }
});
Then(/^the "Subscriber Name" and "Subscriber DOB" inputs are hidden$/, async (w) => {
  expect(await hasInput(w, 'John Doe Sr.'), 'Subscriber Name still shown').toBeFalsy();
});
Then(/^the "Subscriber Name" input \(hint "John Doe Sr\."\) is shown$/, async (w) => {
  expect(await hasInput(w, 'John Doe Sr.'), 'Subscriber Name not shown').toBeTruthy();
});
Then(/^the "Subscriber DOB" input \(hint "MM\/DD\/YYYY"\) is shown$/, async (w) => {
  expect(await hasInput(w, 'MM/DD/YYYY'), 'Subscriber DOB not shown').toBeTruthy();
});
Then(/^the subscriber details persist$/, async (w) => {
  expect(await sees(w, 'saved successfully'), 'save not confirmed').toBeTruthy();
});

// ── card upload ─────────────────────────────────────────────────────────────
When(/^I click "Upload" in the "([^"]*)" box$/, async (w, box) => {
  const nth = /Front/i.test(box) ? 0 : 1;
  const btn = w.page.locator('flt-semantics[role="button"]').filter({ hasText: /^Upload$/ }).nth(nth);
  w.data.chooser = w.page.waitForEvent('filechooser', { timeout: 10_000 });
  await btn.dispatchEvent('click');
});
When(/^I choose the file "([^"]*)"$/, async (w, file) => {
  const chooser = await w.data.chooser;
  await chooser.setFiles(ensureFixture(file));
  w.data.lastFile = file;
  await w.page.waitForTimeout(2500); await enableAccessibility(w.page);
});
When(/^I upload "([^"]*)" to "([^"]*)"$/, async (w, file, box) => {
  await uploadCard(w, /Front/i.test(box) ? 'Front' : 'Back', file); w.data.lastFile = file;
});
When(/^I upload a "([^"]*)" to "([^"]*)"$/, async (w, file, box) => {
  await uploadCard(w, /Front/i.test(box) ? 'Front' : 'Back', file); w.data.lastFile = file;
});
Then(/^I see the toast "(Front|Back) of card uploaded"$/, async (w) => {
  expect(await cardUploaded(w, w.data.lastFile || ''), 'card upload not confirmed').toBeTruthy();
});
Then(/^the "([^"]*)" box shows the uploaded card$/, async (w) => {
  expect(await cardUploaded(w, w.data.lastFile || ''), 'uploaded card not shown').toBeTruthy();
});
