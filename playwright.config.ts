import { defineConfig, devices } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'https://www.va.gov';
const IS_CI = !!process.env.CI;

/**
 * VA.gov Playwright Test Configuration
 * See https://playwright.dev/docs/test-configuration for more information.
 */
export default defineConfig({
  testDir: './tests',
  testMatch: ['**/*.spec.ts', '**/*.unit.ts'],

  /* Global configuration */
  fullyParallel: true,
  workers: 4,
  forbidOnly: IS_CI,
  retries: IS_CI ? 2 : 0,

  timeout: 60 * 1000, // 60 seconds per test
  expect: {
    timeout: 10 * 1000, // 10 seconds for expectations
  },

  /* Reporter configuration */
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'test-results/playwright-results.json' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['list'],
  ],

  /* Shared settings for all tests */
  use: {
    baseURL: BASE_URL,
    trace: IS_CI ? 'on-first-retry' : 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10 * 1000, // 10 seconds for actions
  },

  /* Browser projects for VA.gov testing */
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
    // {
    //   name: "firefox",
    //   use: {
    //     ...devices["Desktop Firefox"],
    //   },
    // },
    // {
    //   name: "webkit",
    //   use: {
    //     ...devices["Desktop Safari"],
    //   },
    // },
  ],

  /* Uncomment to test on mobile viewports */
  // {
  //   name: 'Mobile Chrome',
  //   use: { ...devices['Pixel 5'] },
  // },
  // {
  //   name: 'Mobile Safari',
  //   use: { ...devices['iPhone 12'] },
  // },

  /* Web server - not needed since we test against https://www.va.gov */
  // webServer: undefined,

  /* Snapshot directory configuration */
  snapshotPathTemplate: '{dir}/{name}.{platform}{ext}',
});
