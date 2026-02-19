import { test as base } from "@playwright/test";
import { VAGovPage } from "./pages/va-gov.page";

/**
 * VA.gov Test Fixtures
 * Provides pre-configured page and page objects for VA.gov testing
 */

/**
 * Extended test fixture with VA.gov-specific setup
 * - Automatically navigates to https://www.va.gov before each test
 * - Provides page object models for common operations
 * - Configures default timeouts
 */
export const test = base.extend<{
  vaGovPage: VAGovPage;
}>({
  /**
   * Fixture: vaGovPage
   * Provides a page object already navigated to VA.gov
   */
  vaGovPage: async ({ page }, use) => {
    // Setup: Navigate to VA.gov before each test
    await page.goto("https://www.va.gov", { waitUntil: "domcontentloaded" });

    // Set default timeouts
    page.setDefaultTimeout(30 * 1000); // 30 seconds
    page.setDefaultNavigationTimeout(30 * 1000); // 30 seconds

    // Create page object instance
    const vaGovPage = new VAGovPage(page);

    // Make the fixture available to the test
    await use(vaGovPage);

    // Teardown: No cleanup needed for this fixture
  },
});

// Export expect for use in tests
export { expect } from "@playwright/test";
