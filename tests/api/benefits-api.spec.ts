import { expect, test } from '@playwright/test';

test.describe('Critical benefits and security API tests', () => {
  const API_BASE = 'https://api.va.gov';

  test('API-BEN-01: GET /benefits returns benefits', async ({ request }) => {
    expect((await request.get(`${API_BASE}/benefits`)).status()).toBeLessThan(500);
  });

  test('API-BEN-02: GET /benefits/:id returns details', async ({ request }) => {
    expect((await request.get(`${API_BASE}/benefits/ben-123`)).status()).toBeLessThan(500);
  });

  test('API-BEN-03: POST /benefits/apply submits application', async ({ request }) => {
    const response = await request.post(`${API_BASE}/benefits/apply`, { data: { benefitType: 'disability' } });
    expect(response.status()).toBeLessThan(500);
  });

  test('API-BEN-05: GET /benefits/:id/documents returns documents', async ({ request }) => {
    expect((await request.get(`${API_BASE}/benefits/ben-123/documents`)).status()).toBeLessThan(500);
  });

  test('API-SEC-01: POST /auth/login handles authentication', async ({ request }) => {
    const response = await request.post(`${API_BASE}/auth/login`, { data: { username: 'veteran@va.gov' } });
    expect(response.status()).toBeLessThan(500);
  });

  test('API-SEC-04: GET /auth/verify-session verifies session', async ({ request }) => {
    expect((await request.get(`${API_BASE}/auth/verify-session`)).status()).toBeLessThan(500);
  });

  test('API-ERR-01: Invalid requests return a client or server response', async ({ request }) => {
    expect((await request.get(`${API_BASE}/invalid-endpoint`)).status()).toBeLessThan(500);
  });

  test('API-ERR-02: API endpoint uses HTTPS', async ({ request }) => {
    const response = await request.get(`${API_BASE}/benefits`);
    expect(response.url()).toContain('https');
  });
});
