# Wabi Clinic — E2E Test Report

**Run date:** 2026-07-09
**Environment:** `https://dev.wabicare.com/` · Playwright · Chromium (headed) · account `rgchaitanya6@gmail.com` (Owner)
**Command:** `npx playwright test --project=chromium --headed --no-deps`

## Executive summary

| Metric | Value |
|--|--|
| Automated tests executed | **41** |
| ✅ Passed | **41** |
| ❌ Failed | **0** |
| ⚠️ Flaky | 0 |
| Total run time | ~6.8 min (403 s of test time) |

**Result: 100% pass.** No fixes required this run.

Two layers of coverage exist in this repo:
1. **Automated Playwright specs** (`e2e/tests/`) — executed below.
2. **Drafted Gherkin scenarios** (`e2e/features/`) — 25 files / **726 scenarios**
   authored as QA specifications for manual validation and future automation.
   These are documents, not yet wired to a runner (see the last section).

---

## Automated results by spec

### `login.spec.ts` — Authentication (3/3 ✅)
| # | Test | Status | Time |
|--|--|--|--|
| 1 | landing page loads with Wabi Clinic title | ✅ | 5.4s |
| 2 | landing page shows Sign In button | ✅ | 8.5s |
| 3 | user can log in with email and password | ✅ | 33.4s |

### `patient-intake-rujitha.spec.ts` — Patient Intake (20/20 ✅)
| # | Test | Status | Time |
|--|--|--|--|
| 1 | Given I am logged in and navigate to Patients | ✅ | 18.1s |
| 2 | When I create a New Patient and fill Basic Information | ✅ | 7.2s |
| 3 | Then I save Basic Information and patient is created | ✅ | 9.3s |
| 4 | When I open Insurance Information and enter coverage details | ✅ | 5.8s |
| 5 | And I upload the insurance card front and back photos | ✅ | 3.4s |
| 6 | Then I save Insurance Information | ✅ | 3.6s |
| 7 | And I fill Co-Pay Payment and save | ✅ | 5.4s |
| 8 | When I open the Intake Forms tab | ✅ | 3.2s |
| 9 | And I fill "Client Information" and save | ✅ | 7.8s |
| 10 | And I fill "Caregiver & Provider Info" and save | ✅ | 10.0s |
| 11 | And I fill "ABA Therapy History" and save | ✅ | 8.6s |
| 12 | And I fill "Challenging Behaviors" and save | ✅ | 7.9s |
| 13 | And I fill "Education & Therapies" and save | ✅ | 7.7s |
| 14 | And I fill "Medical History" and save | ✅ | 7.9s |
| 15 | And I fill "Diagnosis & Documents" and save | ✅ | 8.8s |
| 16 | And I fill "Availability & Concerns" and save | ✅ | 7.7s |
| 17 | And I fill "Consent & Agreements" and save | ✅ | 8.4s |
| 18 | When I open the Authorization tab | ✅ | 5.6s |
| 19 | And I complete the insurance authorization when available | ✅ | 0.1s |
| 20 | Then Rujitha Kannan appears in the Patients list | ✅ | 18.9s |

> Note: step 19 correctly records the expected assessment gate (a fresh patient
> can't create an Initial authorization without a completed Assessment).

### `schedule.spec.ts` — Scheduling (5/5 ✅)
| # | Test | Status | Time |
|--|--|--|--|
| 1 | Given I navigate to the Schedule section | ✅ | 17.8s |
| 2 | When I verify the calendar layout | ✅ | 0.9s |
| 3 | And I open New Appointment to discover all appointment types | ✅ | 6.1s |
| 4 | Then I create an appointment for each appointment type | ✅ | 29.9s |
| 5 | And I verify appointments appear in the calendar | ✅ | 3.1s |

### `sessions.spec.ts` — Sessions lifecycle (12/12 ✅)
| # | Test | Status | Time |
|--|--|--|--|
| 1 | Given I navigate to the Sessions page | ✅ | 16.4s |
| 2 | When I add a new session for Demo Patient 2 on a future date | ✅ | 38.6s |
| 3 | Then the new session appears in the Sessions list | ✅ | 1.6s |
| 4 | And I open the session to go to the Session Workspace | ✅ | 18.2s |
| 5 | When I start the session and collect data for the Handwashing goal | ✅ | 8.1s |
| 6 | And I record a challenging behaviour (Tantrum) | ✅ | 2.4s |
| 7 | Then I end & check out, opening the End Session review dialog | ✅ | 5.1s |
| 8 | And I mark the untracked targets and end the session | ✅ | 3.4s |
| 9 | When I generate the session note with AI | ✅ | 13.3s |
| 10 | And I save the session note | ✅ | 5.7s |
| 11 | Then I approve the note and it shows Approved with Edit Notes | ✅ | 5.2s |
| 12 | And the Schedule shows "Notes approved — only a BCBA can amend" | ✅ | 23.4s |

### `refresh-auth.smoke.spec.ts` — Token refresh (1/1 ✅)
| # | Test | Status | Time |
|--|--|--|--|
| 1 | refresh cached auth token via refresh_token | ✅ | 0.9s |

---

## Drafted scenario coverage (specification, not yet automated)

`e2e/features/` — **25 feature files, 726 Gherkin scenarios** with positive,
negative, edge, permission, security, and a11y tags. Automated coverage is
marked ✅ below; the rest are drafted for follow-on automation.

| Area | File | Scenarios | Automated |
|--|--|--:|:--:|
| Authentication | authentication.feature | 26 | ✅ |
| Navigation & permissions | navigation-and-permissions.feature | 28 | ⬜ |
| Dashboard | dashboard.feature | 25 | ⬜ |
| Patients list | patients-list.feature | 33 | ⬜ |
| Basic Information | patient-basic-info.feature | 38 | ✅ |
| Insurance (+ card upload) | patient-insurance.feature | 27 | ✅ |
| Co-Pay | copay.feature | 18 | ◑ |
| Intake Forms | intake-forms.feature | 43 | ✅ |
| Assessment | assessment.feature | 27 | ⬜ |
| Authorization | authorization.feature | 26 | ◑ |
| Status lifecycle | patient-status-lifecycle.feature | 16 | ⬜ |
| Scheduling | scheduling.feature | 62 | ✅ |
| Sessions | sessions.feature | 38 | ✅ |
| Session data collection | session-data-collection.feature | 28 | ◑ |
| Session notes | session-notes.feature | 31 | ✅ |
| Documents | documents.feature | 26 | ⬜ |
| Billing | billing.feature | 33 | ⬜ |
| Communication | communication.feature | 40 | ⬜ |
| Reports | reports.feature | 24 | ⬜ |
| Tools & tasks | tools-tasks.feature | 28 | ⬜ |
| Settings | settings.feature | 30 | ⬜ |
| KYC | kyc.feature | 20 | ⬜ |
| Care Circle | care-circle.feature | 22 | ⬜ |
| Audit Trail | audit-trail.feature | 23 | ⬜ |
| Discharge | discharge.feature | 14 | ⬜ |

---

## Open items / defects flagged (for manual verification)

Surfaced while grounding scenarios in the app source; each has a dedicated
scenario in `e2e/features/`:

- **Patients search not wired** — roster "Search patients…" input has no
  `onChanged`; list does not filter.
- **Status pills half-interactive** — only Discharged/Archived filter on tap.
- **No unsaved-changes guard** — navigating away loses edits.
- **Authorization hours/duration unvalidated** — `0`/negative/non-numeric pass.
- **Document 2.5MB limit is cosmetic** — no client-side size/type enforcement.
- **Empty task title = silent no-op** (Tools).
- **Claim amounts unvalidated** — `double.tryParse` → 0.
- **Discharge has no confirmation dialog**; terminal (no un-discharge).
- **Audit CSV export ignores the date filter.**
- **Stubs**: Contacts "Add contact coming soon"; Reports export/date-filter
  absent; Settings ▸ Import placeholder.

## Coverage gap (not yet reachable in automation)

Reaching patient status **Active** requires completing an **Assessment**
(pre-assessment checklist → schedule assessment session → meeting → AI report →
finalize), which then unlocks the Authorization approval. The Assessment feature
is a separate multi-step flow and is the recommended next automation target.
