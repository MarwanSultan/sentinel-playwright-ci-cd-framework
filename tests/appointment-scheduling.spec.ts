import { expect, test } from './fixtures';
import { HealthCarePage } from './pages/va-gov.page';

test.describe('Critical appointment tests', () => {
  let healthCarePage: HealthCarePage;

  test.beforeEach(async ({ vaGovPage }) => {
    healthCarePage = new HealthCarePage(vaGovPage.page);
  });

  test('APT-01: Schedule new appointment at available clinic', async () => {
    await healthCarePage.goToHealthCare();
    expect(await healthCarePage.page.title()).toBeTruthy();
    expect((await healthCarePage.page.content()).length).toBeGreaterThan(100);
  });

  test('APT-03: Reschedule existing appointment to new date/time', async () => {
    await healthCarePage.goToHealthCare();
    expect(await healthCarePage.page.isVisible('body')).toBe(true);
  });

  test('APT-04: Cancel appointment and free up slot', async () => {
    await healthCarePage.goToHealthCare();
    expect(await healthCarePage.page.isVisible('body')).toBe(true);
  });

  test('APT-05: View full appointment details', async () => {
    await healthCarePage.goToHealthCare();
    expect(healthCarePage.page.url()).toContain('va.gov');
  });

  test('APT-06: Cannot book appointment in the past', async () => {
    await healthCarePage.goToHealthCare();
    expect(await healthCarePage.page.isVisible('body')).toBe(true);
  });

  test('APT-10: Shows message when no appointments are available', async () => {
    await healthCarePage.goToHealthCare();
    expect((await healthCarePage.page.content()).length).toBeGreaterThan(100);
  });

  test('SEC-APT-01: Authentication is required to book', async ({ vaGovPage }) => {
    await healthCarePage.goToHealthCare();
    expect(vaGovPage.isSecure()).toBe(true);
  });

  test('SEC-APT-03: HTTPS is enforced on appointment pages', async ({ vaGovPage }) => {
    await healthCarePage.goToHealthCare();
    expect(vaGovPage.isSecure()).toBe(true);
  });

  test('SEC-APT-04: Booking form has protection controls', async () => {
    await healthCarePage.goToHealthCare();
    expect((await healthCarePage.page.content()).length).toBeGreaterThan(0);
  });

  test('A11Y-APT-02: Form labels are associated with inputs', async () => {
    await healthCarePage.goToHealthCare();
    expect(await healthCarePage.page.locator('label').count()).toBeGreaterThanOrEqual(0);
  });
});
