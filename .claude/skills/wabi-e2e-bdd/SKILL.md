---
name: wabi-e2e-bdd
description: >-
  How to turn the drafted Gherkin .feature files in e2e/features/ into passing
  automated tests for the Wabi clinic Flutter-canvas web app. Use when asked to
  "automate a feature", "make the <X> tests workable/green", "write step
  definitions", "continue the BDD work", or "cover the next feature". Encodes the
  read→probe→implement→run→correct→green loop, the canvas/auth gotchas, and the
  current status so anyone can continue exactly the same way.
---

# Wabi E2E — automating feature files (BDD on a Flutter canvas app)

The app (dev.wabicare.com) is a **Flutter CanvasKit** web app: there is almost no
normal DOM. Everything is driven through the accessibility tree (`flt-semantics`
nodes) exposed after "enabling accessibility". The `e2e/features/*.feature` files
were **drafted from the Flutter source** (`../wabi-flutter-dev`), so they are
often subtly wrong vs. the running app. Your job is to make them **actually pass**
against the live app, one feature at a time, verifying every assumption live.

## The loop (do this per feature)

1. **Read** `e2e/features/<feature>.feature`. Note the Background + each scenario's
   exact quoted labels/toasts.
2. **Probe live FIRST.** Write a throwaway `e2e/tests/_probe.spec.ts` that navigates
   to the screen and dumps the real semantics (labels, inputs, buttons, checkboxes,
   URLs). NEVER trust the drafted strings — the source and the live app differ.
   Delete the probe when done.
3. **Implement step definitions** in `e2e/bdd/steps/<feature>.steps.ts` (register in
   `e2e/bdd/steps/index.ts`). Reuse `common.steps.ts` where possible.
4. **Correct source-vs-live drift in the .feature** when the drafted string is
   factually wrong (add a `# NOTE:` explaining the correction). Examples already
   done: Co-Pay default is "Co-Pay Required" not "No Co-Pay"; insurance card is
   "Primary insurance card" not "Insurance Card"; save toast is "Insurance
   Information saved successfully".
5. **Run** `BDD_FEATURE=<feature> npm run test:bdd` (add `-g "<title>"` to iterate on
   one scenario). Matched scenarios run; any unimplemented step → the scenario is
   **pending (skipped)**, keeping the suite green.
6. **Iterate to green.** Fix failures. Leave genuinely-unverifiable scenarios
   **pending** (do NOT fake them — see "What stays pending").
7. **Commit** with a message stating `N green, M failing, K pending` and any
   source-vs-live corrections. Then move to the next feature.

Run everything from the `e2e/` directory (the Bash cwd resets between calls —
always `cd .../e2e` or the local Playwright/config isn't found).

## Auth (this environment is fiddly)

- Login account: `rgchaitanya6@gmail.com` / `Wabicare@123#` (Microsoft CIAM). Do
  NOT use `wabicareteam@gmail.com` (Google-federated, blocked). Password is quoted
  in `.env` (dotenv strips an unquoted trailing `#`).
- Tests use `tests/.auth/user.json` (storageState) via `--no-deps`.
- **Tokens expire fast here (clock skew — Azure thinks it's days ahead).** Refresh
  with `npm run auth:refresh`; if that returns `invalid_grant` (refresh token >24h),
  do a fresh interactive login: `npx playwright test --project=setup --headed`
  (it can fail once at the "redirect back" step — just retry; if ffmpeg is missing,
  `npx playwright install` first). **Re-login right before a run**, and prefer short
  batches — long (8+ min) runs lose auth near the end and later scenarios land on
  the Sign In page.

## The BDD runner (already built — don't rebuild)

- `bdd/parser.ts` — Gherkin parser (Background + Scenario Outline → Examples rows).
- `bdd/registry.ts` — `Given/When/Then(pattern, fn)`; pattern is a RegExp or a
  cucumber-lite string (`{string}`,`{int}`); matching is by text only.
- `bdd/world.ts` — per-scenario `World { page, context, testInfo, data }`
  (`data` carries values between steps, e.g. a stored filechooser promise).
- `tests/bdd.spec.ts` — turns each scenario into a Playwright test; if any step is
  unmatched → `test.skip` (pending); failures attach a screenshot.
- `bdd/steps/*.steps.ts` — step libraries. `common.steps.ts` has the shared
  vocabulary + a `PLACEHOLDER` map (field label → input aria-label/placeholder).

## Canvas gotchas (the whole game)

- **Read state from `flt-semantics`.** After navigation call `enableAccessibility(page)`.
  A `sees(text)` helper = poll `flt-semantics` aria-label/textContent for a substring.
- **Text inputs** are addressed by their placeholder, which Flutter mirrors into the
  input's `aria-label` — `fillByPlaceholder(page, placeholder, value, nth)`.
  ⚠️ Once an input holds a value its aria-label can change off the hint — **read the
  value back by value/position, not by the hint locator** (see `copayAmountValue`).
  Duplicate placeholders (e.g. patient vs guardian "Doe") → use `nth` (`-1` = last).
- **Dropdowns:** open the trigger button (e.g. "Select gender"); options render as
  `role="menuitem"` (Gender/Relationship) or `role="button"` (Diagnoses/chips).
  `selectDropdownOption(page, trigger, option)` handles both; retry 2–3× (flaky).
- **Overlay "More"-menu items need a REAL mouse click** at their coords —
  `dispatchEvent('click')` opens the menu but does not navigate.
- **File upload:** click the "Upload" button and catch the chooser:
  `Promise.all([page.waitForEvent('filechooser'), btn.dispatchEvent('click')])` then
  `chooser.setFiles(path)`. Success signal = the **file name appears** in the tree
  (the toast is transient). Fixtures live in `tests/fixtures/`; `ensureFixture(name)`
  creates them on demand (PNG bytes; minimal PDF for `.pdf`).
- **Canvas-painted buttons** absent from semantics (e.g. "Create Authorization",
  "End Session") are clicked by anchoring to an exposed sibling (e.g. "Cancel") and
  offsetting by mouse coords.
- **Duplicate-patient dialog:** saving a patient whose name exists raises "Possible
  Duplicate Found" → click "Create Anyway" to proceed.

## What is readable vs NOT (decides green vs pending)

- ✅ Readable in semantics: headings, card titles, chip/field labels, empty-state
  text, banners, **section-save toasts** ("<Section> saved successfully"), the
  "N / 2 completed" counter, breadcrumb text, URLs (`page.url()`), input values.
- ❌ NOT readable / not automatable: the **patient-create toast**, green completion
  **checkmarks**, chip **selection-highlight** state (canvas), validation the app
  **doesn't implement** (amount/hours have none), **stub actions** with no
  confirmation ("Record Waiver", Documents tab = "Coming Soon"), anything needing
  **another role** (only Owner creds), unreachable **preconditions** (Active status
  needs a completed Assessment), reload-persistence, and picker accept-filter
  negatives (`setFiles` bypasses the filter).

Leave those **pending** (don't implement the step → scenario stays pending). Pending
is honest and keeps the suite green; faking assertions is not allowed.

## Reachability audit before you start a feature

Source presence ≠ UI reachability. Verified dead ends / model changes:
- **assessment.feature** — CHANGED (feature #391) and REWRITTEN 2026-07 to match
  live. Assessment is NOT a patient tab; it is an appointment/**session type**
  ("Direct Service" dropdown → "Assessment"; sub-types Initial/Re-Auth/Annual
  Review). It appears in the unified Sessions list and RUNS in the **Session
  Workspace** as 5 section pills — primary "Beneficiary", "Parent interview";
  under "More": "Scoring", "Direct observation", "Report" (Scoring instruments:
  VB-MAPP Milestones/Barriers, Vineland, ABLLS); started via "Start assessment".
  The workspace scenarios are tagged `@needs-live` (drafted from source, pending
  BDD automation of the section editor). If the app changes again, re-probe and
  re-write the feature the same way.
- **documents.feature** — the Documents *tab* is a "Coming Soon" stub; real upload is
  the separate **"Files" modal** (folder icon), `FileType.any`.
- **patients-list** — the "Search patients…" input has no `onChanged` (search doesn't
  filter — a real defect); patient names are canvas-painted.
Patient top tabs (Owner): Profile / Intake Forms / Authorization / **More**; More =
Scheduling, Programming, Progress Reports, Documents, Discharge, Know Your Patient,
Care Circle, Audit Trail, Communication, Billing Lite (no Assessment).

## Commands

```
cd e2e
npm run auth:refresh                                   # refresh token (or interactive login)
BDD_FEATURE=<feature> npm run test:bdd                 # run one feature's scenarios
BDD_FEATURE=<feature> npm run test:bdd -- -g "<title>" # iterate on one scenario
npm run dashboard                                      # rebuild dashboard from last JSON
npm run test:full                                      # run EVERYTHING (bespoke+BDD) + rebuild dashboard (~20min, auth-flaky)
```

The dashboard (`e2e/dashboard/index.html`, built by `tools/build-dashboard.mjs`)
overlays real run results onto every scenario: ✅ pass / ❌ fail (error+screenshot)
/ ⏳ pending / 📝 drafted. It reads `test-results/full-run.json` (bespoke specs) and
`test-results/bdd-run.json` (BDD). `test:full` regenerates it.

## Status (update this as you go)

- ✅ **Automated & green (BDD):** `copay` (17/18), `patient-insurance` (~12),
  `navigation-and-permissions` (14).
- ✅ **Bespoke specs (not BDD):** login, patient-intake (incl. insurance card
  upload), scheduling, sessions — in `e2e/tests/*.spec.ts`.
- 🔁 **`assessment`** — rewritten to the session-type model (#391); runs in the
  Sessions workspace. Feature updated; workspace scenarios `@needs-live` (pending).
- ⬜ **Not yet automated:** authorization, documents (via Files modal), dashboard,
  settings, patients-list, billing, communication, reports, tools-tasks, kyc,
  care-circle, audit-trail, discharge, patient-status-lifecycle, session-*,
  intake-forms, patient-basic-info (bespoke-covered).

## Adding the next feature

1. `cd e2e`, refresh auth.
2. Probe the screen (throwaway `_probe.spec.ts`), delete it after.
3. Create `bdd/steps/<feature>.steps.ts`, import it in `bdd/steps/index.ts`.
4. Add any field placeholders to the `PLACEHOLDER` map in `common.steps.ts`.
5. Correct wrong strings in the `.feature` (with a `# NOTE:`).
6. `BDD_FEATURE=<feature> npm run test:bdd`; iterate to green; leave the rest pending.
7. Commit `N green / M fail / K pending`; update the Status list above.
8. Recommended next-by-yield: `authorization`, then `settings`/`dashboard`.
