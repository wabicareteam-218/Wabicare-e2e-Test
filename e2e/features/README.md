# Wabi Clinic — E2E Feature Scenarios (QA coverage)

Gherkin `.feature` files describing the intended behaviour of the Wabi clinician
web app (dev.wabicare.com), authored from an experienced-QA perspective:
**positive paths, negative paths, edge/boundary cases, permission/security, and
empty/error states** — grounded in the real UI labels and validation messages in
the Flutter source (`wabi-flutter-dev`, read-only reference).

These are **specification/coverage documents** for manual validation and as the
blueprint for automation. Some already have automated Playwright specs in
`e2e/tests/` (noted below); the rest are drafted for follow-on automation.

**25 feature files · 726 scenarios** (incl. ~92 `Scenario Outline` matrices).

## Conventions

- One `Feature:` per file, kebab-cased filename by functional area.
- `Background:` for shared preconditions (role, starting screen).
- Every scenario is tagged from: `@smoke` `@positive` `@negative` `@edge`
  `@permission` `@security` `@a11y` `@data`.
- Exact on-screen labels and validation/toast text are quoted from the app.
- `Scenario Outline` + `Examples` for validation matrices and enumerations.

## Coverage map

| Area | File | Scenarios | Automated? |
|--|--|--:|--|
| Authentication & session | `authentication.feature` | 26 | ✅ `tests/login.spec.ts`, `auth.setup.ts`, `refresh-auth.smoke.spec.ts` |
| Navigation, tabs & permissions | `navigation-and-permissions.feature` | 28 | ⬜ |
| Dashboard | `dashboard.feature` | 25 | ⬜ |
| Patients list & search | `patients-list.feature` | 33 | ⬜ |
| Patient Profile — Basic Information | `patient-basic-info.feature` | 38 | ✅ `tests/patient-intake-rujitha.spec.ts` |
| Patient Profile — Insurance + card upload | `patient-insurance.feature` | 27 | ✅ (incl. card photo upload) |
| Patient Profile — Co-Pay | `copay.feature` | 18 | partial |
| Intake Forms (9 sections) | `intake-forms.feature` | 43 | ✅ |
| Assessment | `assessment.feature` | 27 | ⬜ |
| Authorization | `authorization.feature` | 26 | partial |
| Patient status lifecycle (Intake→Active) | `patient-status-lifecycle.feature` | 16 | ⬜ |
| Scheduling / calendar | `scheduling.feature` | 62 | ✅ `tests/schedule.spec.ts` |
| Sessions — run & lifecycle | `sessions.feature` | 38 | ✅ `tests/sessions.spec.ts` |
| Session data collection | `session-data-collection.feature` | 28 | ✅ (partial) |
| Session notes & reporting | `session-notes.feature` | 31 | ✅ |
| Documents & files | `documents.feature` | 26 | ⬜ |
| Billing (claims) | `billing.feature` | 33 | ⬜ |
| Communication (telehealth/contacts/phone) | `communication.feature` | 40 | ⬜ |
| Reports | `reports.feature` | 24 | ⬜ |
| Tools & tasks | `tools-tasks.feature` | 28 | ⬜ |
| Settings | `settings.feature` | 30 | ⬜ |
| Know Your Patient (KYC) | `kyc.feature` | 20 | ⬜ |
| Care Circle | `care-circle.feature` | 22 | ⬜ |
| Audit Trail | `audit-trail.feature` | 23 | ⬜ |
| Discharge | `discharge.feature` | 14 | ⬜ |

## Notable defects / gaps flagged during authoring

These were surfaced while grounding scenarios in the source and are worth manual
verification — each has a dedicated `@negative`/`@edge`/`@security` scenario:

- **Patients search not wired** — the "Search patients…" roster input has no
  `onChanged` handler in `patients_screen.dart`; the list does not filter.
- **Status pills half-interactive** — only "Discharged"/"Archived" filter on tap;
  "Intake"/"Auth Pending"/"Active" are display-only counters.
- **No unsaved-changes guard** — navigating away loses edits (only an inline
  "Unsaved changes" hint + inline "Discard"; no confirm modal anywhere).
- **Authorization hours/duration unvalidated** — New Authorization runs values
  through `tryParse` with no client validation; `0`/negative/huge/non-numeric
  pass silently.
- **Document size limit is cosmetic** — the "Maximum 2.5MB per file" note is
  display-only; the Patient Files modal uses `FileType.any` with no client-side
  size or extension enforcement (security gap; also cross-patient isolation).
- **Empty task title = silent no-op** — Tools ▸ create task with a blank title
  neither errors nor closes the dialog.
- **Claim amounts unvalidated** — `double.tryParse` falls back to 0, so `abc`→0;
  negatives/huge pass through; units `int.tryParse` (`1.5`→1).
- **Discharge has no confirmation** — no required-field validation and no confirm
  dialog; submits immediately and is terminal (no un-discharge flow).
- **Audit CSV export ignores the date filter** (respects the others).
- **Stubbed/coming-soon** — Contacts "Add contact coming soon"; Reports has no
  date-range/patient filter or export (Generate just opens the AI Assistant);
  Settings ▸ Import is a placeholder; guardian "Request from parent" is a stub.
- **Empty names default silently** — blank first/last on patient create default
  to "New"/"Patient" rather than erroring.

## Notable behaviours (state machines / gates worth knowing)

- **Patient status**: `intake → authorization_pending → active` (insurance) or
  `intake → active` (private_pay, on assessment complete); authorization
  `approved → active`. An **Initial authorization requires a completed
  Assessment**; the auth workflow has two steps ("Submit to Insurance",
  "Complete"). Notes-approved appointments are read-only except for a BCBA
  ("Notes approved — only a BCBA can amend.").
- **EVV** check-in is non-blocking (session starts even if geolocation denied,
  showing a "Location Required" dialog). Note approval is disabled until the
  session is Completed; amending an approved note needs a ≥20-char reason.
