# E2E CI — running the tests when code changes

Two GitHub Actions workflows (in `.github/workflows/`):

| Workflow | When | What it does | Needs a browser / login? |
|---|---|---|---|
| **`e2e-validate.yml`** | every push / PR touching `e2e/**` | `npm ci` → `playwright test --list` (compiles all specs + step defs, enumerates every BDD scenario) → parses all `.feature` files via the dashboard builder | **No** — fast (~1–2 min), no dev-env traffic |
| **`e2e-run.yml`** | manual, nightly (06:00 UTC), or when the app deploys | mints fresh CIAM auth, runs the suite against `dev.wabicare.com`, builds the dashboard, uploads reports | **Yes** — real login + browser |

The idea: **every code change gets the cheap `validate` gate automatically** (it catches broken step definitions, TypeScript errors, and malformed Gherkin without touching the live app). The **real E2E run is gated** to manual/nightly/deploy triggers because it needs an interactive login and writes data to the shared dev environment.

## One-time setup

1. **Repo secrets** (Settings → Secrets and variables → Actions):
   - `E2E_LOGIN_EMAIL` = `rgchaitanya6@gmail.com`
   - `E2E_LOGIN_PASSWORD` = `Wabicare@123#`
   (The workflow writes `.env` with the password single-quoted so dotenv keeps the trailing `#`.)
2. That's it — the workflows install Node 22, deps, Chrome, and xvfb themselves.

## Running it

- **Manually:** Actions → **E2E run** → *Run workflow*. Choose a `suite`:
  - `ready` (default) — only the **completed/automated** features: the bespoke
    specs + the green BDD features (copay, patient-insurance,
    navigation-and-permissions). Skips the ~1100 drafted/pending scenarios.
  - `full` — everything (bespoke + all BDD; pending scenarios show as skipped).
  - `bespoke` — login, intake, scheduling, sessions only.
  - `bdd` — the BDD runner (optionally narrowed with the `feature` input).
  - `smoke` — just the landing-page checks (fast pipeline sanity).
  Optionally set `feature` to one BDD feature name to narrow `bdd`/`ready`.
- **Nightly:** runs `full` automatically at ~06:00 UTC.
- **On every app code change:** have the **app repo's** deploy pipeline fire a
  `repository_dispatch` after it publishes to dev:

  ```bash
  curl -X POST \
    -H "Authorization: Bearer $GH_PAT" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/wabicareteam-218/Wabicare-e2e-Test/dispatches \
    -d '{"event_type":"app-deployed"}'
  ```

  (`$GH_PAT` = a token with `repo` scope, stored as a secret in the app repo.)

## Reports

Each **E2E run** uploads an artifact `e2e-reports-<n>` containing:
- `dashboard/` — the interactive coverage dashboard (Feature → Scenario → steps + screenshots; ✅/❌/⏳/📝),
- `gherkin-report/` — the per-run Gherkin HTML report,
- `playwright-report/` — the standard Playwright HTML report,
- `test-results/junit.xml` — machine-readable results (also surfaced in the run summary).

Download the artifact and open `dashboard/index.html` (or `playwright-report/index.html`).

### Live dashboard on GitHub Pages

The **E2E run** also publishes to GitHub Pages, so there's a permanent URL that
auto-updates after every run — no download needed. The landing page links the
**coverage dashboard**, the **Gherkin report**, and the **Playwright report**.

**One-time setup (repo admin):** Settings → **Pages** → **Source = "GitHub
Actions"**.

> ⚠️ Behaviour change: the repo currently serves the committed Gherkin report via
> Pages' "Deploy from a branch" (root `index.html` redirect). Switching the source
> to "GitHub Actions" means Pages is updated **by the E2E run workflow instead of
> on every push to `main`** — i.e. it reflects the last *test run*, not the last
> commit. The published site still includes the Gherkin report, so nothing is lost.
> The Pages URL appears in each run's summary (the `github-pages` environment).

## Caveats (be aware)

- **Interactive CIAM login runs in CI.** It's automated (`tests/auth.setup.ts` +
  `helpers/login.ts`) and retried, but it can fail if the account gets MFA, a
  CAPTCHA, or Azure AD B2C **smart-lockout** from too-frequent logins. Runs are
  **serialized** (`concurrency: wabi-e2e-run`) so two logins never overlap; avoid
  triggering many runs back-to-back.
- **Tests hit the shared dev environment** and create data (patients, sessions).
  Keep the real run on manual/nightly/deploy — not on every push.
- **Canvas app → flaky.** CI uses `retries: 2` (already in `playwright.config.ts`).
  A red job usually means real failures + a few flakes — check the dashboard/JUnit
  artifact, don't trust the single job status alone.
- **Headed under xvfb.** The tests run `--headed` (Flutter canvas keyboard needs a
  real display); CI wraps them in `xvfb-run`.

## Local

```bash
cd e2e
npm ci
npx playwright install chrome
npm run auth:refresh                 # or: npx playwright test --project=setup --headed
BDD_FEATURE=copay npm run test:bdd   # one BDD feature
npm run test:full                    # everything + rebuild dashboard
```

See `.claude/skills/wabi-e2e-bdd/SKILL.md` for the full authoring methodology.
