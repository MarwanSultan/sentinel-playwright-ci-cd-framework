# VA.gov Test Automation - Quick Start Guide

## 5-Minute Setup

### Prerequisites

- Node.js 18+ ([download](https://nodejs.org/))
- npm 8+ (comes with Node.js)
- Git
- Docker & Docker Compose (optional, for containerized testing)

### Installation

**Step 1: Clone and install**

```bash
git clone https://github.com/your-org/va-gov-test-automation.git
cd va-gov-test-automation
npm ci
npx playwright install
```

**Step 2: Create environment file**

```bash
cat > .env.local <<EOF
NODE_ENV=development
BASE_URL=http://localhost:3000
DATABASE_URL=postgresql://testuser:testpass@localhost:5432/test_db
REDIS_URL=redis://localhost:6379
LOG_LEVEL=debug
EOF
```

**Step 3: Start services**

```bash
# Option A: Using Docker Compose
docker-compose up -d postgres redis

# Option B: Use existing database (if available)
# Configure DATABASE_URL in .env.local
```

**Step 4: Run tests**

```bash
# Run unit tests
npm run test:unit

# Run E2E tests
npm run test:e2e

# Run all tests
npm run test
```

---

## Common Tasks

### Run Only Specific Tests

```bash
# Unit tests only
npm run test:unit

# E2E tests only (all suites)
npm run test:e2e

# Specific E2E test file
npx playwright test tests/e2e/benefits-application.spec.ts

# Single test within file
npm run test:e2e -- --grep "Submit valid application"

# API tests only
npm run test:api

# Smoke tests only
npm run test:smoke
```

### Run Tests in Different Modes

```bash
# Headed mode (see browser)
npm run test:e2e:headed

# Debug mode (pause on errors)
npm run test:e2e:debug

# Watch mode (re-run on file changes)
npm run test:unit:watch

# With coverage report
npm run test:unit:coverage
```

### View Test Reports

```bash
# Generate and view HTML report
npm run test:e2e
open playwright-report/index.html

# View coverage report
open coverage/index.html

# Check test results
open test-results/index.html
```

### Build Application

```bash
# Build for development
npm run build

# Build for production
npm run build:prod

# Build with source maps (for debugging)
npm run build:dev
```

### Local Deployment Testing

```bash
# Build and run locally
npm run build
npm start

# Test deployment script
bash scripts/deploy.sh staging

# Test rollback script
bash scripts/rollback.sh staging
```

---

## Docker Quick Commands

### Using Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Run tests in container
docker-compose run --rm test-automation npm run test

# Stop all services
docker-compose down

# Clean up (remove volumes)
docker-compose down -v
```

### Using Docker Directly

```bash
# Build image
docker build -t va-test-automation:latest .

# Run tests
docker run --rm \
  -e BASE_URL=http://localhost:3000 \
  va-test-automation:latest \
  npm run test:unit

# Interactive shell
docker run -it --rm va-test-automation:latest bash
```

---

## GitHub Actions CI/CD

### First-Time Setup

1. **Add GitHub secrets**:

   ```
   Settings → Secrets and variables → Actions → New repository secret
   ```

   Add: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `SLACK_WEBHOOK_URL`

2. **Create S3 buckets**:

   ```bash
   aws s3 mb s3://va-test-staging --region us-east-1
   aws s3 mb s3://va-test-production --region us-east-1
   ```

3. **Configure CloudFront**:
   - Create distribution pointing to S3 bucket
   - Note the domain name

4. **Update pipeline**:
   - Edit `.github/workflows/ci-cd.yml`
   - Update bucket names and CloudFront domains

### Triggering Deployments

```bash
# Deploy to staging
git push origin develop

# Deploy to production
git push origin main
```

### Monitoring Deployments

1. Go to **Actions** tab in GitHub
2. Click on your workflow run
3. View real-time logs
4. Check deployment status badges

---

## Troubleshooting

### Issue: Tests timeout

**Solution:**

```bash
# Increase timeout
npm run test:e2e -- --timeout=120000

# Check if server is running
curl http://localhost:3000/health

# View detailed logs
DEBUG=* npm run test:e2e
```

### Issue: "Browser was not launched"

**Solution:**

```bash
# Reinstall Playwright browsers
npx playwright install --with-deps

# Check Playwright version
npx playwright --version

# Install system dependencies
npx playwright install-deps
```

### Issue: Port 3000 already in use

**Solution:**

```bash
# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
PORT=3001 npm start
```

### Issue: Database connection failed

**Solution:**

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Wait for database to be ready
sleep 5

# Verify connection
psql $DATABASE_URL -c "SELECT 1"
```

### Issue: S3 permission denied

**Solution:**

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check S3 bucket permissions
aws s3 ls

# Verify bucket exists
aws s3 ls s3://va-test-staging/
```

---

## File Structure

```
va-gov-test-automation/
├── .github/
│   └── workflows/
│       └── ci-cd.yml                 # GitHub Actions pipeline
├── scripts/
│   ├── build.sh                      # Build script
│   ├── test.sh                       # Test orchestration
│   ├── deploy.sh                     # Deployment script
│   └── rollback.sh                   # Rollback script
├── src/
│   ├── index.ts                      # Application entry point
│   ├── config.ts                     # Configuration
│   └── utils/                        # Utilities
├── tests/
│   ├── e2e/                          # End-to-end tests
│   │   ├── benefits-application.spec.ts
│   │   ├── appointment-scheduling.spec.ts
│   │   ├── claims-status.spec.ts
│   │   ├── profile-management.spec.ts
│   │   └── secure-messaging.spec.ts
│   ├── unit/                         # Unit tests
│   ├── api/                          # API integration tests
│   ├── smoke/                        # Smoke tests
│   └── performance/                  # Performance tests
├── config/
│   ├── nginx.conf                    # Nginx configuration
│   ├── prometheus.yml                # Prometheus config
│   └── mockserver/                   # Mock API setup
├── Dockerfile                        # Container definition
├── docker-compose.yml                # Multi-container setup
├── package.json                      # Dependencies and scripts
├── tsconfig.json                     # TypeScript config
├── playwright.config.ts              # Playwright configuration
├── jest.config.js                    # Jest configuration
├── CI_CD_PIPELINE.md                # This document
├── VA_GOV_TEST_PLAN.md              # Test plan
└── README.md                         # Project readme
```

---

## Key Configuration Files

### playwright.config.ts

Configures Playwright test runner:

- Timeout settings
- Browser selection (Chromium, Firefox, WebKit)
- Reporter configuration
- Retry logic
- Parallel execution

### jest.config.js

Configures Jest test runner for unit and API tests:

- Test environment (node, jsdom)
- Setup files
- Coverage thresholds
- Module resolution

### tsconfig.json

TypeScript compiler configuration:

- Target and module output
- Strict type checking
- Decorator support
- Path aliases

---

## Useful Resources

### Documentation

- [Full CI/CD Pipeline Documentation](./CI_CD_PIPELINE.md)
- [Test Plan](./VA_GOV_TEST_PLAN.md)
- [Playwright Documentation](https://playwright.dev)
- [GitHub Actions Documentation](https://docs.github.com/actions)

### Tools & Technologies

- [Playwright Test](https://playwright.dev/docs/intro)
- [Jest](https://jestjs.io/)
- [GitHub Actions](https://github.com/features/actions)
- [Docker](https://docs.docker.com/)

### Learning Resources

- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Testing Best Practices](https://pytest.org/en/latest/goodpractices.html)
- [CI/CD Best Practices](https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery)

---

## Getting Help

### Support Channels

1. Check [Troubleshooting](#troubleshooting) section
2. Review logs in `test-results/` or `.github/workflows/`
3. Ask in team Slack channel: `#qa-automation`
4. Open GitHub issue with logs and error details
5. Contact QA Team: qa-team@example.com

---

## Next Steps

After setup, explore:

1. **Run the test plan**: `npm run test`
2. **Deploy to staging**: `git push origin develop`
3. **Review Playwright reports**: `open playwright-report/index.html`
4. **Check GitHub Actions**: Go to Actions tab
5. **Set up Slack notifications**: Add webhook URL to secrets
6. **Enable auto-deployment**: Push to main branch
7. **Monitor production**: Check health checks and logs

---

## Common Commands Cheat Sheet

```bash
# Testing
npm test                          # All tests
npm run test:unit               # Unit tests only
npm run test:e2e                # E2E tests only
npm run test:api                # API tests only
npm run test:e2e:headed        # E2E with visible browser

# Building
npm run build                    # Development build
npm run build:prod              # Production build
npm run prebuild-script         # Make scripts executable

# Docker
docker-compose up -d            # Start services
docker-compose logs -f          # View logs
docker-compose down             # Stop services

# Deployment
bash scripts/deploy.sh staging   # Deploy to staging
bash scripts/rollback.sh staging # Rollback staging

# Code Quality
npm run lint                     # Check for issues
npm run lint:fix                # Auto-fix issues
npm run format                   # Format code
npm run type-check              # TypeScript check

# Utilities
npm run clean                    # Delete build artifacts
npm run docker:build            # Build Docker image
npm run docker:test             # Run tests in Docker
```

---

**Happy Testing!**

For detailed information, see [CI_CD_PIPELINE.md](./CI_CD_PIPELINE.md)
