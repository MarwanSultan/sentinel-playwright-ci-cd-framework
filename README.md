# VA.gov Playwright Test Suite

Automated Playwright tests for VA.gov — UI, API, performance and smoke tests.

**Contents**
- Project overview
- Prerequisites
- Install
- Running tests
- Test organization
- Reports
- Contributing

## Project overview
This repository contains Playwright tests used to validate VA.gov functionality, including UI flows, API checks, and performance benchmarks. Tests are organized under the `tests/` folder and configured via `playwright.config.ts`.

## Prerequisites
- Node.js 18+ and npm
- Git
- (Optional) Playwright browsers installed via Playwright CLI

## Install
1. Install dependencies:

```bash
npm install
```

2. (Optional) Install Playwright browsers if not already present:

```bash
npx playwright install --with-deps
```

## Running tests
- Run the full test suite:

```bash
npx playwright test
```

- Run a specific test file:

```bash
npx playwright test tests/performance/performance.spec.ts
```

- Run tests headed (visible browser):

```bash
npx playwright test --headed
```

- Show HTML report after a run (report saved to `playwright-report`):

```bash
npx playwright show-report
# or open the generated file: playwright-report/index.html
```

## Test organization
- `tests/` — main Playwright test files (UI, performance, smoke, api, etc.)
- `specs/` — supplemental specs and guides
- `scripts/` — helper scripts for CI and local runs (e.g., `test.sh`, `build.sh`)
- `playwright.config.ts` — Playwright configuration
- `playwright-report/` — generated HTML test reports
- `test-results/` — saved test outputs (JSON, junit.xml)

## Performance tests
Performance tests are located under `tests/performance/` (for example `performance.spec.ts`). They measure page load times and core web vitals. Some endpoints may require public accessible routes (non-authenticated) to yield reliable measurements.

## CI / Scripts
Check `scripts/` for CI helpers. This repo includes `test.sh` which can be used by CI to run tests and collect reports. Adapt the scripts to your CI environment as needed.

## Contributing
- Open an issue for bugs or feature requests.
- Create a branch per change and open a PR with a clear description.

## License
Repository license: add your license here.
