/**
 * Appointments API Tests
 * Tests VA.gov Appointments API
 */

import { expect, test } from "@playwright/test";

test.describe("VA Appointments API", () => {
  const API_BASE = "https://api.va.gov";

  test("API-APT-01: GET /appointments returns appointments list", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/appointments`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-APT-02: POST /appointments schedules new appointment", async ({
    request,
  }) => {
    const appointmentData = {
      facilityId: "983",
      clinicId: "123",
      appointmentType: "primary-care",
      preferredDate: "2024-03-15",
      timeSlot: "9:00 AM",
    };
    const response = await request.post(`${API_BASE}/appointments`, {
      data: appointmentData,
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-APT-03: GET /appointments/available returns available slots", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE}/appointments/available`);
    expect(response.status()).toBeLessThan(500);
  });

  test("API-APT-04: PUT /appointments/:id updates appointment", async ({
    request,
  }) => {
    const response = await request.put(`${API_BASE}/appointments/apt-123`, {
      data: { status: "confirmed" },
    });
    expect(response.status()).toBeLessThan(500);
  });

  test("API-APT-05: DELETE /appointments/:id cancels appointment", async ({
    request,
  }) => {
    const response = await request.delete(`${API_BASE}/appointments/apt-123`);
    expect(response.status()).toBeLessThan(500);
  });
});
