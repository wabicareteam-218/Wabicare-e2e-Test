import { defineConfig, devices } from '@playwright/test';

require('dotenv').config();

const baseURL = process.env.BASE_URL || 'https://dev.wabicare.com/';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 1,
  timeout: 120_000,
  expect: { timeout: 10_000 },
  reporter: [
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
    ['list'],
    ['./reporters/gherkin-html-reporter.ts', { outputDir: 'gherkin-report' }],
    ...(process.env.CI
      ? [['junit', { outputFile: 'test-results/junit.xml' }] as any]
      : []),
  ],
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on',
    extraHTTPHeaders: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      Pragma: 'no-cache',
    },
  },
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        launchOptions: { args: ['--disable-web-security'] },
      },
    },
    {
      name: 'chromium',
      dependencies: ['setup'],
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        storageState: 'tests/.auth/user.json',
        launchOptions: { args: ['--disable-web-security'] },
      },
    },
    {
      name: 'smoke',
      testMatch: /smoke\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        launchOptions: { args: ['--disable-web-security'] },
      },
    },
  ],
});
