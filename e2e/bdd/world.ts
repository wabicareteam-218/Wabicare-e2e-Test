/**
 * The World shared across a scenario's steps: the Playwright page/context plus
 * a scratch bag for values steps pass to each other (e.g. a created patient
 * name, a chosen time slot, the last-read semantic text).
 */
import type { Page, BrowserContext, TestInfo } from '@playwright/test';

export interface World {
  page: Page;
  context: BrowserContext;
  testInfo: TestInfo;
  data: Record<string, any>;
}

export function makeWorld(page: Page, context: BrowserContext, testInfo: TestInfo): World {
  return { page, context, testInfo, data: {} };
}
