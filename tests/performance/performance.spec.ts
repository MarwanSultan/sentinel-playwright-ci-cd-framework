import { expect, test } from '@playwright/test';

test.describe('Critical performance tests', () => {
  const BASE_URL = 'https://www.va.gov';

  test('PERF-01: Homepage loads in under 6 seconds', async ({ page }) => {
    const startTime = Date.now();
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    expect(Date.now() - startTime).toBeLessThan(6000);
  });

  test('PERF-06: First Contentful Paint is measured', async ({ page }) => {
    await page.goto(BASE_URL);
    const paint = await page.evaluate(() => {
      const entry = performance.getEntriesByType('paint').find((item) => item.name === 'first-contentful-paint');
      return entry?.startTime;
    });
    expect(paint).toBeDefined();
  });
});
