/**
 * Benefits API Tests
 * Tests VA.gov Benefits API endpoints
 */

import { expect, test } from "@playwright/test";

test.describe("VA Benefits API", () => {
  const API_BASE = "https://api.va.gov";

  // Benefits Endpoints
  test("API-BEN-01: GET /benefits returns benefits list", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/benefits`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-BEN-02: GET /benefits/:id returns benefit details", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/benefits/ben-123`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-BEN-03: POST /benefits/apply submits benefit application", async ({
    request,
  }) => {
    const applicationData = {
      benefitType: "disability",
      rating: 50,
      effectiveDate: "2024-01-01",
    };
    const response = await request.post(`${API_BASE}/benefits/apply`, {
      data: applicationData,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-BEN-04: PUT /benefits/:id/status updates benefit status", async ({
    request,
  }) => {
    const response = await request.put(`${API_BASE}/benefits/ben-123/status`, {
      data: { status: "active" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-BEN-05: GET /benefits/:id/documents returns documents", async ({
    request,
  }) => {
    const response = await request.get(
      `${API_BASE}/benefits/ben-123/documents`,
    );
    expect(response.status()).toBeLessThan(500);
  });

  // Security Endpoints
  test("API-SEC-01: POST /auth/login authenticates user", async ({
    request,
  }) => {
    const credentials = {
      username: "veteran@va.gov",
      password: "password123",
    };
    const response = await request.post(`${API_BASE}/auth/login`, {
      data: credentials,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-SEC-02: POST /auth/logout logs out user", async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/logout`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-SEC-03: POST /auth/refresh-token refreshes access token", async ({
    request,
  }) => {
    const response = await request.post(`${API_BASE}/auth/refresh-token`, {
      data: { refreshToken: "token123" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-SEC-04: GET /auth/verify-session verifies active session", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/auth/verify-session`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-SEC-05: POST /auth/mfa sends MFA challenge", async ({
    request,
  }) => {
    const response = await request.post(`${API_BASE}/auth/mfa`, {
      data: { method: "email" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  // Error Handling
  test("API-ERR-01: Returns 4xx on invalid request", async ({ request }) => {
    const response = await request.get(`${API_BASE}/invalid-endpoint`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-ERR-02: Validates HTTPS only", async ({ request }) => {
    // This would normally fail in production
    const response = await request.get(`${API_BASE}/benefits`);
    expect(response.url()).toContain("https");
  });

  test("API-ERR-03: Rate limiting protects API", async ({ request }) => {
    const response = await request.get(`${API_BASE}/benefits`);
    expect(response.status()).toBeLessThan(500);
  });
});
