# WabiCare E2E Test Suite

End-to-end test automation for the WabiCare Clinic Flutter web application using [Playwright](https://playwright.dev/).

## Project Structure

```
e2e/
├── helpers/
│   ├── flutter.ts          # Flutter CanvasKit interaction utilities (a11y, clicks, fills)
│   ├── locators.ts         # Centralized locator map for all app pages and forms
│   ├── login.ts            # Multi-step CIAM login flow with CORS proxy
│   └── test-data.ts        # Shared test data (patient, guardian, constants)
├── reporters/
│   └── gherkin-html-reporter.ts  # Custom HTML reporter with Gherkin-style output
├── tests/
│   ├── auth.setup.ts              # Global auth setup (login once, cache state)
│   ├── patient-intake-rujitha.spec.ts  # Full E2E: create patient → 9 intake forms → schedule
│   ├── login.spec.ts              # Login flow tests
│   ├── smoke.spec.ts              # Quick CI smoke tests
│   ├── dashboard.spec.ts          # Dashboard navigation tests
│   ├── patient-crud.spec.ts       # Patient create/search/open tests
│   ├── patient-profile.spec.ts    # Patient profile tab navigation
│   ├── sessions.spec.ts           # Sessions page tests
│   ├── schedule.spec.ts           # Schedule/calendar tests
│   ├── reports.spec.ts            # Reports page tests
│   ├── tools.spec.ts              # Tools (tasks/notes/docs) tests
│   └── settings.spec.ts           # Settings page tests
├── gherkin-report/                # Generated HTML report with screenshots
├── playwright.config.ts           # Playwright configuration
└── package.json
```

## Setup

```bash
cd e2e
npm install
npx playwright install
cp .env.example .env   # Fill in your credentials
```

## Running Tests

```bash
# Run the full E2E patient intake flow
npx playwright test tests/patient-intake-rujitha.spec.ts --project=chromium --headed

# Run all tests
npx playwright test --project=chromium

# Run smoke tests only
npx playwright test --project=smoke

# Run with visible browser
npx playwright test --project=chromium --headed
```

## Reports

After running tests, three reports are generated:

1. **Gherkin HTML Report** — `gherkin-report/index.html`
   Colorful report with Gherkin keywords, pass/fail badges, screenshots, and error details.

2. **Playwright HTML Report** — `playwright-report/index.html`
   Standard Playwright report with trace viewer.

3. **JUnit XML** (CI only) — `test-results/junit.xml`

## Key Design Decisions

- **Flutter CanvasKit**: The app renders to WebGL canvas. All element interaction uses Flutter's semantic tree (`flt-semantics` elements) enabled via `flt-semantics-placeholder`.
- **CIAM Login**: Multi-step Azure AD B2C auth with `page.route()` proxy to handle CORS with `--disable-web-security`.
- **Auth Caching**: `auth.setup.ts` logs in once and saves `storageState` so dependent tests skip login.
- **Save Validation**: Every save action checks for error toasts ("Failed", "error") and fails the test immediately.
- **Serial Tests**: The main intake flow uses `test.describe.serial` with a shared browser page for efficiency.

## Test Coverage (69 tests)

| Area | Tests | File |
|------|-------|------|
| Patient Intake E2E (Rujitha Kannan) | 20 | `patient-intake-rujitha.spec.ts` |
| Dashboard | 5 | `dashboard.spec.ts` |
| Patient CRUD | 5 | `patient-crud.spec.ts` |
| Patient Profile | 6 | `patient-profile.spec.ts` |
| Sessions | 4 | `sessions.spec.ts` |
| Schedule | 6 | `schedule.spec.ts` |
| Reports | 4 | `reports.spec.ts` |
| Tools | 6 | `tools.spec.ts` |
| Settings | 7 | `settings.spec.ts` |
| Login | 3 | `login.spec.ts` |
| Smoke | 2 | `smoke.spec.ts` |
| Auth Setup | 1 | `auth.setup.ts` |
