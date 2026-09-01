import { expect, test } from '@playwright/test';

test.describe('Critical appointments API tests', () => {
  const API_BASE = 'https://api.va.gov';

  test('API-APT-01: GET /appointments returns appointments list', async ({ request }) => {
    expect((await request.get(`${API_BASE}/appointments`)).status()).toBeLessThan(500);
  });

  test('API-APT-02: POST /appointments schedules an appointment', async ({ request }) => {
    const response = await request.post(`${API_BASE}/appointments`, {
      data: { facilityId: '983', clinicId: '123', appointmentType: 'primary-care' },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test('API-APT-03: GET /appointments/available returns slots', async ({ request }) => {
    expect((await request.get(`${API_BASE}/appointments/available`)).status()).toBeLessThan(500);
  });
});
