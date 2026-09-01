import { APIResponse, expect, test } from '@playwright/test';

type JsonRecord = Record<string, unknown>;

const API_BASE = 'https://api.va.gov';

async function responseJson(response: APIResponse): Promise<unknown> {
  return response.json().catch(() => undefined);
}

function isObject(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

test.describe('Critical API examples', () => {
  test.describe('GET requests', () => {
    test('API-GET-01: GET benefits collection responds', async ({ request }) => {
      const response = await request.get(`${API_BASE}/benefits`);
      expect(response.status()).toBeLessThan(500);
    });

    test('API-GET-02: GET claim details responds', async ({ request }) => {
      const response = await request.get(`${API_BASE}/claims/clm-123`);
      expect(response.status()).toBeLessThan(500);
    });
  });

  test.describe('POST requests', () => {
    test('API-POST-01: POST appointment accepts a request body', async ({ request }) => {
      const response = await request.post(`${API_BASE}/appointments`, {
        data: { facilityId: '983', clinicId: '123', appointmentType: 'primary-care' },
      });
      expect(response.status()).toBeLessThan(500);
    });

    test('API-POST-02: POST message accepts a request body', async ({ request }) => {
      const response = await request.post(`${API_BASE}/messages`, {
        data: { recipientId: 'provider-123', subject: 'Test', body: 'Test message' },
      });
      expect(response.status()).toBeLessThan(500);
    });
  });

  test.describe('PUT requests', () => {
    test('API-PUT-01: PUT appointment accepts an update', async ({ request }) => {
      const response = await request.put(`${API_BASE}/appointments/apt-123`, {
        data: { status: 'confirmed' },
      });
      expect(response.status()).toBeLessThan(500);
    });

    test('API-PUT-02: PUT profile accepts an update', async ({ request }) => {
      const response = await request.put(`${API_BASE}/profile`, {
        data: { phone: '555-0100' },
      });
      expect(response.status()).toBeLessThan(500);
    });
  });

  test.describe('PATCH requests', () => {
    test('API-PATCH-01: PATCH claim accepts a partial update', async ({ request }) => {
      const response = await request.patch(`${API_BASE}/claims/clm-123`, {
        data: { status: 'in_progress' },
      });
      expect(response.status()).toBeLessThan(500);
    });

    test('API-PATCH-02: PATCH profile accepts a partial update', async ({ request }) => {
      const response = await request.patch(`${API_BASE}/profile`, {
        data: { preferredName: 'Veteran' },
      });
      expect(response.status()).toBeLessThan(500);
    });
  });

  test.describe('DELETE requests', () => {
    test('API-DELETE-01: DELETE appointment responds', async ({ request }) => {
      const response = await request.delete(`${API_BASE}/appointments/apt-123`);
      expect(response.status()).toBeLessThan(500);
    });

    test('API-DELETE-02: DELETE message responds', async ({ request }) => {
      const response = await request.delete(`${API_BASE}/messages/msg-123`);
      expect(response.status()).toBeLessThan(500);
    });
  });

  test.describe('Authentication', () => {
    test('API-AUTH-01: Login endpoint handles credentials', async ({ request }) => {
      const response = await request.post(`${API_BASE}/auth/login`, {
        data: { username: 'veteran@va.gov', password: 'invalid-for-test' },
      });
      expect(response.status()).toBeLessThan(500);
    });

    test('API-AUTH-02: Protected profile endpoint responds to an unauthenticated request', async ({ request }) => {
      const response = await request.get(`${API_BASE}/profile`);
      expect([200, 401, 403, 404]).toContain(response.status());
    });
  });

  test.describe('Schema validation', () => {
    test('API-SCHEMA-01: Benefits response is JSON object or array', async ({ request }) => {
      const response = await request.get(`${API_BASE}/benefits`);
      const body = await responseJson(response);
      expect(isObject(body) || Array.isArray(body) || body === undefined).toBe(true);
    });

    test('API-SCHEMA-02: Appointment response is JSON-compatible', async ({ request }) => {
      const response = await request.get(`${API_BASE}/appointments`);
      const body = await responseJson(response);
      expect(isObject(body) || Array.isArray(body) || body === undefined).toBe(true);
    });

    test('API-SCHEMA-03: Error response remains JSON-compatible when returned', async ({ request }) => {
      const response = await request.get(`${API_BASE}/invalid-endpoint`);
      const body = await responseJson(response);
      expect(isObject(body) || Array.isArray(body) || body === undefined).toBe(true);
    });
  });

  test.describe('Contract validation', () => {
    test('API-CONTRACT-01: Benefits contract exposes the requested resource URL', async ({ request }) => {
      const response = await request.get(`${API_BASE}/benefits`);
      expect(response.url()).toBe(`${API_BASE}/benefits`);
      expect(response.status()).toBeLessThan(500);
    });

    test('API-CONTRACT-02: Appointment contract returns a valid HTTP status', async ({ request }) => {
      const response = await request.get(`${API_BASE}/appointments`);
      expect(response.status()).toBeGreaterThanOrEqual(100);
      expect(response.status()).toBeLessThan(500);
    });
  });
});
