/**
 * BDD runner — turns every e2e/features/*.feature scenario into a Playwright
 * test. Steps are matched against the registry (bdd/steps/*). A scenario whose
 * every step is implemented RUNS; a scenario with any unimplemented step is
 * marked pending (skipped) so the suite stays green while coverage grows.
 *
 * Filter while developing:  BDD_FEATURE=patient-basic-info npm run test:bdd
 */
import { test } from '@playwright/test';
import * as path from 'path';
import { parseAllFeatures } from '../bdd/parser';
import { matchStep } from '../bdd/registry';
import { makeWorld } from '../bdd/world';
import '../bdd/steps/index';

const FEATURES_DIR = path.join(__dirname, '..', 'features');
const only = process.env.BDD_FEATURE;
const features = parseAllFeatures(FEATURES_DIR).filter((f) => !only || f.name === only);

test.describe.configure({ mode: 'default' });

for (const feature of features) {
  test.describe(`Feature: ${feature.title || feature.name}`, () => {
    for (const scenario of feature.scenarios) {
      const steps = [...feature.background, ...scenario.steps];
      const unmatched = steps.filter((s) => !matchStep(s.text));
      const pending = unmatched.length > 0;

      test(scenario.name, async ({ browser }, testInfo) => {
        test.skip(pending, `pending — ${unmatched.length} step(s) not implemented: ${unmatched.slice(0, 2).map((s) => `"${s.text}"`).join(', ')}`);

        const context = await browser.newContext({
          storageState: 'tests/.auth/user.json',
          geolocation: { latitude: 37.7749, longitude: -122.4194 },
          permissions: ['geolocation'],
        });
        const page = await context.newPage();
        page.setDefaultTimeout(30_000);
        const world = makeWorld(page, context, testInfo);

        try {
          for (const step of steps) {
            const m = matchStep(step.text)!;
            await test.step(`${step.keyword} ${step.text}`, async () => {
              await m.fn(world, ...m.args);
            });
          }
        } catch (err) {
          try {
            const shot = testInfo.outputPath('failure.png');
            await page.screenshot({ path: shot, fullPage: true });
            await testInfo.attach('failure', { path: shot, contentType: 'image/png' });
          } catch { /* ignore */ }
          throw err;
        } finally {
          await context.close();
        }
      });
    }
  });
}
