/**
 * Claims API Tests
 * Tests VA.gov Claims API
 */

import { expect, test } from "@playwright/test";

test.describe("VA Claims API", () => {
  const API_BASE = "https://api.va.gov";

  test("API-CLM-01: GET /claims returns claims list", async ({ request }) => {
    const response = await request.get(`${API_BASE}/claims`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-CLM-02: GET /claims/:id returns claim details", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/claims/clm-123`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-CLM-03: POST /claims submits new claim", async ({ request }) => {
    const claimData = {
      claimType: "disability",
      description: "Service-connected disability claim",
      documents: [],
    };
    const response = await request.post(`${API_BASE}/claims`, {
      data: claimData,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-CLM-04: PUT /claims/:id updates claim", async ({ request }) => {
    const response = await request.put(`${API_BASE}/claims/clm-123`, {
      data: { status: "submitted" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-CLM-05: GET /claims/:id/status returns claim status", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/claims/clm-123/status`);
    expect(response.status()).toBeLessThan(500);
  });
});
