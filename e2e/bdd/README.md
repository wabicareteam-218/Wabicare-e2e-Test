# BDD runner — automating the `e2e/features/*.feature` files

A dependency-free runner that executes the drafted Gherkin feature files against
the live Flutter-canvas app. Matched steps run; any unimplemented step marks the
scenario **pending** (skipped), so the suite stays green while coverage grows.

## Quick start

```bash
cd e2e
npm run auth:refresh                                    # or: npx playwright test --project=setup --headed
BDD_FEATURE=copay npm run test:bdd                      # run one feature
BDD_FEATURE=copay npm run test:bdd -- -g "Waive"        # one scenario
npm run dashboard                                       # rebuild the coverage dashboard
```

## Layout

| File | Role |
|---|---|
| `parser.ts` | Gherkin → Feature/Background/Scenarios (Outlines expanded) |
| `registry.ts` | `Given/When/Then(pattern, fn)` step registry |
| `world.ts` | per-scenario `{ page, context, testInfo, data }` |
| `steps/common.steps.ts` | shared vocabulary + `PLACEHOLDER` field map |
| `steps/<feature>.steps.ts` | one file per feature; register it in `steps/index.ts` |
| `../tests/bdd.spec.ts` | the runner (scenario → Playwright test) |
| `../tools/build-dashboard.mjs` | builds `../dashboard/index.html` from run JSON |

## How to add a feature — and the full methodology

**Read the `wabi-e2e-bdd` skill** (`.claude/skills/wabi-e2e-bdd/SKILL.md`). It has
the read→probe→implement→run→correct→green loop, every canvas/auth gotcha, what is
readable vs must-stay-pending, the reachability audit, and the current status.

Golden rules: **probe the live app before trusting any drafted string** (the
features were drafted from source and drift from the running app), and **never fake
an assertion** — if the app paints it on canvas, doesn't implement it, or needs a
role/precondition we can't reach, leave the scenario pending.

## Status

- Green: `copay` (17/18), `patient-insurance` (~12), `navigation-and-permissions` (14).
- Blocked: `assessment` (tab intentionally unexposed).
- The rest are drafted and pending — see the skill's Status section.
