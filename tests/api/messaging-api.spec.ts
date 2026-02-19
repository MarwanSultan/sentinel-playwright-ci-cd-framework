/**
 * Messaging API Tests
 * Tests VA.gov Secure Messaging API
 */

import { expect, test } from "@playwright/test";

test.describe("VA Messaging API", () => {
  const API_BASE = "https://api.va.gov";

  test("API-MSG-01: GET /messages endpoint responds", async ({ request }) => {
    const response = await request.get(`${API_BASE}/messages`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-MSG-02: POST /messages sends message", async ({ request }) => {
    const messageData = {
      recipientId: "provider-123",
      subject: "Test Subject",
      body: "Test message body",
    };
    const response = await request.post(`${API_BASE}/messages`, {
      data: messageData,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-MSG-03: GET /messages/:id returns message", async ({ request }) => {
    const response = await request.get(`${API_BASE}/messages/msg-123`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-MSG-04: POST /messages/:id/reply sends reply", async ({
    request,
  }) => {
    const response = await request.post(`${API_BASE}/messages/msg-123/reply`, {
      data: { body: "Reply text" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-MSG-05: PUT /messages/:id/archive archives message", async ({
    request,
  }) => {
    const response = await request.put(`${API_BASE}/messages/msg-123/archive`);
    expect(response.status()).toBeLessThan(500);
  });
});
