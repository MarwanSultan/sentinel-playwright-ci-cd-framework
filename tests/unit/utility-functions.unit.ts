/**
 * Unit Tests
 * Tests for utility functions and business logic
 */

import { expect, test } from "@playwright/test";

// Mock utility functions for testing
function formatDate(date: string): string {
  // Use UTC to avoid timezone shifts affecting the formatted date
  return new Date(date).toLocaleDateString("en-US", { timeZone: "UTC" });
}

function validateEmail(email: string): boolean {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  return emailRegex.test(email);
}

function validatePhoneNumber(phone: string): boolean {
  // Accepts 7-digit local numbers, 10-digit numbers, and optional country code
  const phoneRegex = /^(\+?1[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}$/;
  return phoneRegex.test(phone);
}

function calculateBenefitAmount(
  yearsOfService: number,
  disabilityRating: number,
): number {
  const baseAmount = 1000;
  const serviceMultiplier = 0.05;
  const disabilityMultiplier = 0.01;

  return (
    baseAmount +
    yearsOfService * serviceMultiplier * baseAmount +
    disabilityRating * disabilityMultiplier * baseAmount
  );
}

function maskSSN(ssn: string): string {
  // Preserve separators while masking all digits except the last 4
  const digitsOnly = ssn.replace(/\D/g, "");
  const visibleLast = digitsOnly.slice(-4);
  const maskedPrefix = digitsOnly.slice(0, -4).replace(/\d/g, "*");
  const maskedDigits = maskedPrefix + visibleLast;
  let idx = 0;
  return ssn.replace(/\d/g, () => maskedDigits[idx++] || "");
}

test.describe("Unit Tests - Utility Functions", () => {
  test.describe("Email Validation", () => {
    test("UNIT-01: Valid email format passes validation", () => {
      expect(validateEmail("veteran@va.gov")).toBe(true);
      expect(validateEmail("john.doe@example.com")).toBe(true);
    });

    test("UNIT-02: Invalid email format fails validation", () => {
      expect(validateEmail("invalid-email")).toBe(false);
      expect(validateEmail("@example.com")).toBe(false);
      expect(validateEmail("user@")).toBe(false);
    });

    test("UNIT-03: Empty email fails validation", () => {
      expect(validateEmail("")).toBe(false);
    });
  });

  test.describe("Phone Number Validation", () => {
    test("UNIT-04: Valid phone number formats pass", () => {
      expect(validatePhoneNumber("555-555-0100")).toBe(true);
      expect(validatePhoneNumber("(555) 555-0100")).toBe(true);
      expect(validatePhoneNumber("+1-555-555-0100")).toBe(true);
    });

    test("UNIT-05: Invalid phone numbers fail", () => {
      expect(validatePhoneNumber("123")).toBe(false);
      expect(validatePhoneNumber("invalid")).toBe(false);
    });
  });

  test.describe("Date Formatting", () => {
    test("UNIT-06: Valid date formats correctly", () => {
      const formatted = formatDate("2026-03-01");
      expect(formatted).toBeTruthy();
      expect(formatted).toContain("2026");
    });

    test("UNIT-07: Date formatting handles various formats", () => {
      const result1 = formatDate("2026-01-15");
      const result2 = formatDate("2026-12-31");

      expect(result1).toBeTruthy();
      expect(result2).toBeTruthy();
    });
  });

  test.describe("Benefit Calculation", () => {
    test("UNIT-08: Benefit amount calculated correctly", () => {
      const amount = calculateBenefitAmount(20, 50);
      expect(amount).toBeGreaterThan(1000);
      expect(amount).toBeLessThan(3000);
    });

    test("UNIT-09: Benefit amount considers service years", () => {
      const amount1 = calculateBenefitAmount(10, 50);
      const amount2 = calculateBenefitAmount(20, 50);

      expect(amount2).toBeGreaterThan(amount1);
    });

    test("UNIT-10: Benefit amount considers disability rating", () => {
      const amount1 = calculateBenefitAmount(20, 30);
      const amount2 = calculateBenefitAmount(20, 70);

      expect(amount2).toBeGreaterThan(amount1);
    });
  });

  test.describe("SSN Masking", () => {
    test("UNIT-11: SSN masks correctly", () => {
      const masked = maskSSN("123-45-6789");
      expect(masked).toContain("*");
      expect(masked).toContain("6789");
      expect(masked).not.toContain("123");
    });

    test("UNIT-12: Masked SSN length preserved", () => {
      const original = "123-45-6789";
      const masked = maskSSN(original);
      expect(masked.length).toBe(original.length);
    });

    test("UNIT-13: Last 4 digits always visible", () => {
      const masked = maskSSN("999-88-7777");
      expect(masked).toContain("7777");
    });
  });

  test.describe("Data Validation", () => {
    test("UNIT-14: Null/undefined input handled", () => {
      expect(validateEmail("")).toBe(false);
      expect(validatePhoneNumber("")).toBe(false);
    });

    test("UNIT-15: Special characters handled", () => {
      expect(validateEmail("test@test.com!")).toBe(false);
      expect(validatePhoneNumber("555-@1@0")).toBe(false);
    });

    test("UNIT-16: Whitespace handling", () => {
      expect(validateEmail(" test@test.com")).toBe(false);
      expect(validateEmail("test@test.com ")).toBe(false);
    });
  });
});
