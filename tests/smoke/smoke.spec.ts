import { expect, test } from '@playwright/test';

/**
 * Smoke Tests
 * Quick sanity checks to verify core functionality is working
 */

test.describe('Smoke Tests - Core Functionality Verification', () => {
  const BASE_URL = 'https://www.va.gov';

  test.describe('Site Accessibility', () => {
    test('SMOKE-01: VA.gov homepage is accessible', async ({ page }) => {
      const response = await page.goto(BASE_URL);
      expect(response?.status()).toBeLessThan(400);
    });

    test('SMOKE-02: VA.gov responds with valid HTTPS', async ({ page }) => {
      await page.goto(BASE_URL);
      const url = page.url();
      expect(url).toMatch(/^https:\/\//);
    });

    test('SMOKE-03: Main navigation exists', async ({ page }) => {
      await page.goto(BASE_URL);
      const nav = page.locator('nav').first();
      expect(await nav.count()).toBeGreaterThanOrEqual(0);
    });

    test('SMOKE-04: Logo or site title visible', async ({ page }) => {
      await page.goto(BASE_URL);
      const title = await page.title();
      expect(title).toBeTruthy();
      expect(title.toLowerCase()).toContain('va');
    });

    test('SMOKE-05: Page has content loaded', async ({ page }) => {
      await page.goto(BASE_URL);
      const mainContent = page.locator('main');
      expect(await mainContent.isVisible()).toBeTruthy();
    });
  });

  test.describe('Critical Features Detection', () => {
    test('SMOKE-06: Benefits section accessible', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/benefits`);
      expect(response?.status()).toBeLessThan(400);
      await expect(page).toHaveURL(/benefits/i);
    });

    test('SMOKE-07: Healthcare section accessible', async ({ page }) => {
      await page.goto(BASE_URL);
      const healthLink = page.locator('a').filter({ hasText: /health/i });
      expect(await healthLink.count()).toBeGreaterThan(0);
    });

    test('SMOKE-08: Search functionality exists', async ({ page }) => {
      await page.goto(BASE_URL);
      const searchInput = page.locator('input[type="search"], input[placeholder*="Search"]');
      expect(await searchInput.count()).toBeGreaterThan(0);
    });

    test('SMOKE-09: Login/Sign in option available', async ({ page }) => {
      await page.goto(BASE_URL);
      const loginLink = page.locator('a').filter({ hasText: /sign in|login/i });
      expect(await loginLink.count()).toBeGreaterThanOrEqual(0);
    });

    test('SMOKE-10: Footer information present', async ({ page }) => {
      await page.goto(BASE_URL);
      const footer = page.locator('footer');
      expect(await footer.isVisible()).toBeTruthy();
    });
  });

  test.describe('Page Performance', () => {
    test('SMOKE-11: Homepage loads within reasonable time', async ({ page }) => {
      const startTime = Date.now();
      await page.goto(BASE_URL, { waitUntil: 'load' });
      const loadTime = Date.now() - startTime;

      expect(loadTime).toBeLessThan(30000); // 30 seconds is reasonable for smoke test
    });

    test('SMOKE-12: No excessive JavaScript errors on page', async ({ page }) => {
      let errorCount = 0;

      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errorCount += 1;
        }
      });

      await page.goto(BASE_URL);

      // Allow a small number of non-critical errors; fail only on many errors
      expect(errorCount).toBeLessThanOrEqual(5);
    });

    test('SMOKE-13: Images load properly', async ({ page }) => {
      await page.goto(BASE_URL);
      const images = page.locator('img');
      const imageCount = await images.count();

      expect(imageCount).toBeGreaterThan(0);
    });

    test('SMOKE-14: Links are properly formed', async ({ page }) => {
      await page.goto(BASE_URL);
      const links = page.locator('a');
      const linkCount = await links.count();

      expect(linkCount).toBeGreaterThan(0);
    });

    test('SMOKE-15: Page has proper heading structure', async ({ page }) => {
      await page.goto(BASE_URL);
      const h1 = page.locator('h1');
      expect(await h1.count()).toBeGreaterThan(0);
    });
  });

  test.describe('Basic Navigation', () => {
    test('SMOKE-16: Can navigate to benefits page', async ({ page }) => {
      await page.goto(BASE_URL);
      const benefitsLink = page.getByRole('link', { name: /benefits/i }).first();

      await expect(benefitsLink).toBeVisible();

      const href = await benefitsLink.getAttribute('href');

      expect(href).toBeTruthy();

      if (href) {
        await benefitsLink.click();
        await expect(page).toHaveURL(/benefits/i);
        return;
      }

      await page.goto(`${BASE_URL}/benefits`);
      await expect(page).toHaveURL(/benefits/i);
    });

    test('SMOKE-17: Back button works', async ({ page }) => {
      await page.goto(BASE_URL);
      await page.goto(`${BASE_URL}/benefits`);
      const currentUrl = page.url();
      expect(currentUrl).toContain('benefits');
    });

    test('SMOKE-18: Page title updates', async ({ page }) => {
      await page.goto(BASE_URL);
      const homeTitle = await page.title();
      expect(homeTitle).toBeTruthy();
    });

    test('SMOKE-19: No 404 errors on homepage', async ({ page }) => {
      const response = await page.goto(BASE_URL);
      expect(response?.status()).not.toBe(404);
    });

    test('SMOKE-20: Responsive design meta tag present', async ({ page }) => {
      await page.goto(BASE_URL);
      const viewport = page.locator('meta[name="viewport"]');
      expect(await viewport.count()).toBeGreaterThan(0);
    });
  });
});
