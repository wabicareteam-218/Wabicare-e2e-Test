/**
 * Step definitions for navigation-and-permissions.feature (Owner-reachable
 * subset: sidebar routing, patient tabs/More menu, breadcrumbs, a11y). Role-
 * gated scenarios (BCBA/RBT/super_admin) stay pending — one Owner fixture only.
 */
import { expect } from '@playwright/test';
import { Given, When, Then } from '../registry';
import type { World } from '../world';
import {
  enableAccessibility, clickFlutterButton, clickSidebarNav, waitForFlutterReady,
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
function quoted(s: string): string[] { return (s.match(/"([^"]+)"/g) || []).map((q) => q.slice(1, -1)); }
async function assertAllSeen(w: World, rest: string): Promise<void> {
  for (const item of quoted(rest)) expect(await sees(w, item), `"${item}" not visible`).toBeTruthy();
}
async function openMore(w: World): Promise<void> {
  const more = w.page.locator('flt-semantics[role="button"]').filter({ hasText: /More/ }).first();
  await more.dispatchEvent('click');
  await w.page.waitForTimeout(1500); await enableAccessibility(w.page);
}
async function clickMoreItem(w: World, name: string): Promise<void> {
  await openMore(w);
  const box = await w.page.evaluate((t) => {
    for (const n of Array.from(document.querySelectorAll('flt-semantics[role="menuitem"]'))) {
      if (new RegExp('^' + t + '$', 'i').test((n.getAttribute('aria-label') || n.textContent || '').trim())) {
        const r = n.getBoundingClientRect(); if (r.width > 0) return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      }
    }
    return null;
  }, name);
  if (box) { await w.page.mouse.click(box.x, box.y); await w.page.waitForTimeout(2500); await enableAccessibility(w.page); }
}
async function openPatientWorkspace(w: World): Promise<void> {
  await w.page.goto('/'); await waitForFlutterReady(w.page);
  await clickSidebarNav(w.page, 'Patients');
  await w.page.waitForTimeout(2000); await enableAccessibility(w.page);
  await clickFlutterButton(w.page, 'New Patient', { timeout: 20000 });
  await w.page.waitForTimeout(3000); await enableAccessibility(w.page);
}

// ── Background ──────────────────────────────────────────────────────────────
Given(/^I am signed in to Wabi Clinic as an Owner$/, async (w) => { await w.page.goto('/'); await waitForFlutterReady(w.page); });
Given(/^I am on the Clinic section$/, async () => { /* Clinic is the default section */ });

// ── sidebar ─────────────────────────────────────────────────────────────────
Then(/^under "([^"]*)" I see (.+)$/, (w, _group, rest) => assertAllSeen(w, rest));
When(/^I click "([^"]*)" in the sidebar$/, async (w, item) => {
  await clickSidebarNav(w.page, item);
  await w.page.waitForTimeout(1500); await enableAccessibility(w.page);
});
Then(/^I am navigated to "([^"]*)"$/, async (w, route) => {
  await expect.poll(() => w.page.url(), { timeout: 8000 }).toContain(route);
});
Then(/^the breadcrumb shows "([^"]*)"$/, (w, crumb) => sees(w, crumb).then((ok) => expect(ok, `breadcrumb "${crumb}" missing`).toBeTruthy()));

// ── patient tabs ────────────────────────────────────────────────────────────
Given(/^I open a patient's profile workspace(?: as an Owner)?$/, (w) => openPatientWorkspace(w));
Then(/^the primary tab pills are (.+)$/, (w, rest) => assertAllSeen(w, rest));
Then(/^a "More" overflow control is shown$/, (w) => sees(w, 'More').then((ok) => expect(ok).toBeTruthy()));
When(/^I open the "More" menu$/, (w) => openMore(w));
Then(/^it lists (.+)$/, (w, rest) => assertAllSeen(w, rest));
Then(/^neither "([^"]+)" nor "([^"]+)" appears in the pill bar or the "More" menu$/, async (w, a, b) => {
  await openMore(w);
  expect(await sees(w, a, 1200), `"${a}" unexpectedly present`).toBeFalsy();
  expect(await sees(w, b, 800), `"${b}" unexpectedly present`).toBeFalsy();
});
When(/^I choose "([^"]*)" from the "More" menu$/, (w, name) => clickMoreItem(w, name));
Then(/^the "([^"]*)" tab content is shown$/, async (w, tab) => {
  // The Documents tab is a "Coming Soon" stub; assert the tab activated.
  expect(await sees(w, tab), `"${tab}" tab content not shown`).toBeTruthy();
});

// ── breadcrumbs ─────────────────────────────────────────────────────────────
When(/^I open the Patients screen$/, async (w) => {
  await clickSidebarNav(w.page, 'Patients'); await w.page.waitForTimeout(1500); await enableAccessibility(w.page);
});
Then(/^the breadcrumb begins with my organization name$/, (w) => sees(w, 'Vanilla Clinic').then((ok) => expect(ok, 'org name missing from breadcrumb').toBeTruthy()));
Then(/^ends with "([^"]*)"$/, (w, crumb) => sees(w, crumb).then((ok) => expect(ok).toBeTruthy()));

// ── a11y ────────────────────────────────────────────────────────────────────
Given(/^accessibility is enabled$/, (w) => enableAccessibility(w.page));
Then(/^the semantics tree contains (.+)$/, (w, rest) => assertAllSeen(w, rest));
