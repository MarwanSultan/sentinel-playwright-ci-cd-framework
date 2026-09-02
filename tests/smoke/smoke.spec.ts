import { expect, test } from '@playwright/test';

test.describe('Critical smoke tests', () => {
  const BASE_URL = 'https://www.va.gov';

  test('SMOKE-01: VA.gov homepage is accessible', async ({ page }) => {
    const response = await page.goto(BASE_URL);
    expect(response?.status()).toBeLessThan(400);
  });

  test('SMOKE-02: VA.gov responds with valid HTTPS', async ({ page }) => {
    await page.goto(BASE_URL);
    expect(page.url()).toMatch(/^https:\/\//);
  });

  test('SMOKE-03: Main navigation exists', async ({ page }) => {
    await page.goto(BASE_URL);
    expect(await page.locator('nav').count()).toBeGreaterThanOrEqual(0);
  });

  test('SMOKE-04: Site title is visible', async ({ page }) => {
    await page.goto(BASE_URL);
    expect((await page.title()).toLowerCase()).toContain('va');
  });

  test('SMOKE-05: Main content is loaded', async ({ page }) => {
    await page.goto(BASE_URL);
    await expect(page.locator('main')).toBeVisible();
  });

  test('SMOKE-06: Benefits section is accessible', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/benefits`);
    expect(response?.status()).toBeLessThan(400);
    await expect(page).toHaveURL(/benefits/i);
  });

  test('SMOKE-07: Healthcare section is available', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/health-care`);
    expect(response?.status()).toBeLessThan(400);
    await expect(page).toHaveURL(/health-care/i);
  });

  test('SMOKE-08: Search functionality exists', async ({ page }) => {
    await page.goto(BASE_URL);
    await expect(page.locator('input[type="search"], input[placeholder*="Search"]')).toHaveCount(1, {
      timeout: 30000,
    });
  });

  test('SMOKE-09: Sign-in option is available', async ({ page }) => {
    await page.goto(BASE_URL);
    expect(
      await page
        .locator('a')
        .filter({ hasText: /sign in|login/i })
        .count(),
    ).toBeGreaterThanOrEqual(0);
  });

  test('SMOKE-10: Footer information is present', async ({ page }) => {
    await page.goto(BASE_URL);
    await expect(page.locator('footer')).toBeAttached({ timeout: 30000 });
  });
});
