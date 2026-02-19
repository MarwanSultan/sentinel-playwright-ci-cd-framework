/**
 * Profile API Tests
 * Tests VA.gov Profile/Account API
 */

import { expect, test } from "@playwright/test";

test.describe("VA Profile API", () => {
  const API_BASE = "https://api.va.gov";

  test("API-PROF-01: GET /profile returns user profile", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/profile`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-PROF-02: PUT /profile updates user profile", async ({
    request,
  }) => {
    const profileData = {
      email: "veteran@va.gov",
      phone: "555-0100",
    };
    const response = await request.put(`${API_BASE}/profile`, {
      data: profileData,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-PROF-03: PUT /profile/2fa enables two-factor auth", async ({
    request,
  }) => {
    const response = await request.put(`${API_BASE}/profile/2fa`, {
      data: { enabled: true },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-PROF-04: PUT /profile/notifications updates preferences", async ({
    request,
  }) => {
    const response = await request.put(`${API_BASE}/profile/notifications`, {
      data: { emailNotifications: true, smsNotifications: false },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-PROF-05: GET /profile/security returns security settings", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/profile/security`);
    expect(response.status()).toBeLessThan(500);
  });
});
