import { Page, expect } from "@playwright/test";

/**
 * VA.gov Page Object Model
 * Provides reusable methods and locators for testing VA.gov
 */

export class VAGovPage {
  readonly page: Page;
  readonly baseURL = "https://www.va.gov";

  // Locators defined as getters
  get header() {
    return this.page.locator("header");
  }

  get mainNav() {
    return this.page.locator("nav");
  }

  get mainContent() {
    return this.page.locator("main");
  }

  get searchInput() {
    return this.page.getByPlaceholder(/search/i);
  }

  get footer() {
    return this.page.locator("footer");
  }

  constructor(page: Page) {
    this.page = page;
  }

  /**
   * Navigate to VA.gov homepage
   */
  async goto(path?: string) {
    await this.page.goto("https://www.va.gov");
    if (path) {
      await this.page.goto(`${this.baseURL}${path}`);
    }
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Navigate to VA.gov homepage
   */
  async goToHome() {
    await this.goto();
  }

  /**
   * Navigate to Benefits page
   */
  async goToBenefits() {
    await this.goto("/benefits");
  }

  /**
   * Navigate to Health Care page
   */
  async goToHealthCare() {
    await this.goto("/health-care");
  }

  /**
   * Navigate to Disability page
   */
  async goToDisability() {
    await this.goto("/disability");
  }

  /**
   * Navigate to Records page
   */
  async goToRecords() {
    await this.goto("/records");
  }

  /**
   * Perform a search on VA.gov
   */
  async search(query: string) {
    await this.searchInput.fill(query);
    await this.page.keyboard.press("Enter");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Click on a main navigation link
   */
  async clickNavLink(label: string | RegExp) {
    await this.page.getByRole("link", { name: label }).first().click();
  }

  /**
   * Verify page is accessible
   */
  async verifyPageIsAccessible() {
    await expect(this.mainContent).toBeVisible({ timeout: 30000 });
  }

  /**
   * Wait for page to be fully loaded
   */
  async waitForPageLoad() {
    await this.page.waitForLoadState("domcontentloaded");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Get page title
   */
  async getPageTitle(): Promise<string> {
    return this.page.title();
  }

  /**
   * Verify HTTPS connection
   */
  isSecure(): boolean {
    return this.page.url().startsWith("https://");
  }

  /**
   * Scroll to element
   */
  async scrollToElement(selector: string) {
    const element = this.page.locator(selector);
    await element.scrollIntoViewIfNeeded();
  }

  /**
   * Get text content of element
   */
  async getElementText(selector: string): Promise<string | null> {
    return this.page.locator(selector).textContent();
  }

  /**
   * Check if element is visible
   */
  async isElementVisible(selector: string): Promise<boolean> {
    return this.page
      .locator(selector)
      .isVisible()
      .catch(() => false);
  }
}

/**
 * Benefits Page Object Model
 */
export class BenefitsPage extends VAGovPage {
  async applyForBenefit(benefitType: string) {
    // Navigate to benefits
    await this.goToBenefits();

    // Find and click the benefit link
    const benefitLink = this.page.getByRole("link", {
      name: new RegExp(benefitType, "i"),
    });

    await benefitLink.click();
  }
}

/**
 * Health Care Page Object Model
 */
export class HealthCarePage extends VAGovPage {
  async scheduleAppointment() {
    await this.goToHealthCare();

    // Look for appointment scheduling link
    const appointmentLink = this.page.getByRole("link", {
      name: /schedule|appointment/i,
    });

    if (await appointmentLink.isVisible().catch(() => false)) {
      await appointmentLink.click();
    }
  }

  async viewMedicalRecords() {
    await this.goToRecords();
    await this.verifyPageIsAccessible();
  }
}

/**
 * Claims Page Object Model
 */
export class ClaimsPage extends VAGovPage {
  async checkClaimsStatus() {
    await this.goToDisability();
    await this.verifyPageIsAccessible();
  }

  async viewClaimDetails(claimId: string) {
    // This would typically require login and claim access
    // For now, just navigate to claims page
    await this.goToDisability();

    // Wait for page to load
    await this.waitForPageLoad();
  }
}

/**
 * Accessibility Checker
 */
export class AccessibilityChecker {
  constructor(private page: Page) {}

  /**
   * Check for basic accessibility requirements
   */
  async checkBasicAccessibility(): Promise<{
    hasH1: boolean;
    hasAltText: boolean;
    hasAriaLabels: boolean;
  }> {
    const h1Count = await this.page.locator("h1").count();
    const imagesWithoutAlt = await this.page.locator("img:not([alt])").count();
    const elementsWithAriaLabel = await this.page
      .locator("[aria-label]")
      .count();

    return {
      hasH1: h1Count > 0,
      hasAltText: imagesWithoutAlt === 0,
      hasAriaLabels: elementsWithAriaLabel > 0,
    };
  }

  /**
   * Check for common accessibility issues
   */
  async getAccessibilityIssues(): Promise<string[]> {
    const issues: string[] = [];

    // Check for empty buttons
    const emptyButtons = await this.page
      .locator("button:not(:has(*, :contains(text())))")
      .count();
    if (emptyButtons > 0) {
      issues.push(`Found ${emptyButtons} buttons without visible text`);
    }

    // Check for images without alt text
    const imagesWithoutAlt = await this.page.locator("img:not([alt])").count();
    if (imagesWithoutAlt > 0) {
      issues.push(`Found ${imagesWithoutAlt} images without alt text`);
    }

    return issues;
  }
}

/**
 * Performance Checker
 */
export class PerformanceChecker {
  constructor(private page: Page) {}

  /**
   * Get page load time
   */
  async getLoadTime(): Promise<number> {
    const navigationTiming = await this.page.evaluate(() => {
      const timing = performance.getEntriesByType("navigation")[0] as any;
      return timing?.loadEventEnd - timing?.fetchStart || 0;
    });

    return navigationTiming;
  }

  /**
   * Get time to first paint
   */
  async getFirstPaintTime(): Promise<number> {
    const paintTiming = await this.page.evaluate(() => {
      const entries = performance.getEntriesByType("paint");
      const firstPaint = entries.find((entry) => entry.name === "first-paint");
      return firstPaint?.startTime || 0;
    });

    return paintTiming;
  }

  /**
   * Get Largest Contentful Paint
   */
  async getLCP(): Promise<number> {
    const lcp = await this.page
      .evaluate(() => {
        return new Promise<number>((resolve) => {
          const observer = new PerformanceObserver((list) => {
            const entries = list.getEntries();
            const lastEntry = entries.at(-1);
            resolve(lastEntry?.startTime || 0);
          });
          observer.observe({ entryTypes: ["largest-contentful-paint"] });

          // Timeout after 5 seconds
          setTimeout(() => resolve(0), 5000);
        });
      })
      .catch(() => 0);

    return lcp;
  }
}
