# VA.gov Test Automation - CI/CD Pipeline Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Pipeline Components](#pipeline-components)
4. [Setup & Configuration](#setup--configuration)
5. [Usage Guide](#usage-guide)
6. [Deployment Process](#deployment-process)
7. [Rollback Procedures](#rollback-procedures)
8. [Monitoring & Notifications](#monitoring--notifications)
9. [Troubleshooting](#troubleshooting)
10. [Environment Variables](#environment-variables)
11. [Best Practices](#best-practices)

---

## Overview

The VA.gov Test Automation CI/CD pipeline is an enterprise-grade, fully automated system designed to:

- **Validate code quality** on every commit
- **Execute comprehensive test suites** (unit, E2E, API, performance)
- **Generate detailed test reports** with trend analysis
- **Deploy automatically** to staging and production environments
- **Rollback deployments** if tests fail or issues arise
- **Monitor application health** post-deployment
- **Notify stakeholders** of pipeline status via Slack and email
- **Maintain audit trails** for compliance and traceability

### Key Features

- **Fully Automated**: Triggered on push, pull request, and schedule
- **Multi-Stage Pipeline**: Build → Test → Deploy → Verify
- **Parallel Execution**: Run independent tests concurrently
- **Container-Based**: Docker/Docker Compose for consistency
- **CloudFront Integration**: CDN cache invalidation post-deploy
- **Automatic Rollback**: Emergency rollback on deployment failure
- **Comprehensive Monitoring**: Health checks and notifications
- **Production-Ready**: Enterprise security and compliance

---

## Architecture

### Pipeline Flow Diagram

```
┌─────────────────┐
│  Git Push/PR    │
└────────┬────────┘
         │
    ┌────▼─────┐
    │Dashboard │
    └────┬─────┘
         │
    ┌────▼────────────────────────┐
    │ Code Quality & Dependency    │
    │ Checks (ESLint, TypeScript)  │
    └────┬────────────────────────┘
         │
    ┌────▼────────────────────────┐
    │ Build Artifacts             │
    │ (npm run build)             │
    └────┬────────────────────────┘
         │
    ┌────┴──────────┬──────────────┬───────────────┬────────────────┐
    │               │              │               │                │
┌───▼──────┐  ┌───▼──────┐  ┌───▼──────┐  ┌───▼──────┐  ┌───▼──────┐
│ Unit     │  │Functional│  │   API    │  │Performance│  │Security  │
│ Tests    │  │   E2E    │  │  Tests   │  │   Tests   │  │  Scan    │
└───┬──────┘  └───┬──────┘  └───┬──────┘  └───┬──────┘  └───┬──────┘
    │             │              │            │              │
    └─────────────┴──────────────┴────────────┴──────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │ Test Report Consolidation           │
    │ & Notifications (Slack, Email)      │
    └──────────────────┬──────────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │  Deploy to Staging               │
    │  (S3 + CloudFront)               │
    └──────────────────┬──────────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │  Smoke Tests on Staging             │
    └──────────────────┬──────────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │  Deploy to Production               │
    │  (S3 + CloudFront)                  │
    │  [APPROVAL REQUIRED ON PR]          │
    └──────────────────┬──────────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │  Health Checks & Smoke Tests        │
    │  on Production                      │
    └──────────────────┬──────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │ SUCCESS                   │ FAILURE
         │                           │
    ┌────▼─────────┐           ┌────▼──────────┐
    │ Deploy OK    │           │ Initiate      │
    │ Send Success │           │ Automatic     │
    │ Notification │           │ Rollback      │
    └──────────────┘           └───────────────┘
```

---

## Pipeline Components

### 1. **Quality Checks Job**

- **Purpose**: Validate code quality before build
- **Tasks**:
  - ESLint static analysis
  - TypeScript compilation check
  - npm audit for dependency vulnerabilities
  - Code comments and PR feedback
- **Duration**: ~2-3 minutes
- **Failure Action**: Blocks pipeline

### 2. **Build Job**

- **Purpose**: Compile and create deployable artifacts
- **Tasks**:
  - Install dependencies
  - Run build script
  - Create Docker images
  - Push to container registry
- **Duration**: ~5-7 minutes
- **Artifacts**: `dist/`, Docker images
- **Failure Action**: Blocks all downstream jobs

### 3. **Unit Tests Job**

- **Purpose**: Validate individual components
- **Framework**: Jest
- **Coverage**: 80%+ required
- **Duration**: ~3-5 minutes
- **Reports**: HTML coverage, JUnit XML

### 4. **Functional Tests Job (E2E)**

- **Purpose**: Test user workflows end-to-end
- **Framework**: Playwright
- **Test Suites** (parallel execution):
  - Benefits Application
  - Appointment Scheduling
  - Claims Status
  - Profile Management
  - Secure Messaging
- **Duration**: ~15-20 minutes (parallel)
- **Reports**: Playwright HTML report, trace files
- **Video Capture**: On failure only (saves storage)

### 5. **API Tests Job**

- **Purpose**: Integration testing with backend APIs
- **Database**: PostgreSQL service container
- **Approach**: Jest-based API testing
- **Coverage**: All critical endpoints
- **Duration**: ~5-8 minutes

### 6. **Security Scanning Job**

- **Purpose**: Identify security vulnerabilities
- **Tools**:
  - Trivy (vulnerability scanning)
  - OWASP Dependency-Check
  - npm audit
- **Reports**: SARIF format for GitHub integration
- **Duration**: ~3-5 minutes

### 7. **Performance Tests Job**

- **Purpose**: Load and stress testing
- **Tools**: k6
- **Scenarios**: Concurrent user simulation (50-500 users)
- **Metrics**: Response times, throughput, error rates
- **Duration**: ~10-15 minutes
- **Trigger**: Only on main branch pushes

### 8. **Deploy to Staging**

- **Purpose**: Validate deployment process in safe environment
- **Method**: S3 + CloudFront
- **Steps**:
  1. Backup current version
  2. Upload artifacts to S3
  3. Invalidate CloudFront cache
  4. Run smoke tests
  5. Verify health
- **Duration**: ~5-10 minutes
- **Trigger**: On develop branch or main branch
- **Failure Action**: Automatic rollback

### 9. **Deploy to Production**

- **Purpose**: Release tested version to live environment
- **Prerequisites**: All tests passed + manual approval
- **Method**: S3 + CloudFront
- **Steps**: Same as staging
- **Duration**: ~5-10 minutes
- **Trigger**: Main branch push (after staging success)
- **Failure Action**: Automatic rollback with notification

### 10. **Health Check & Monitoring**

- **Purpose**: Verify deployment health
- **Checks**:
  - HTTP health endpoint (200 OK)
  - Response time thresholds
  - Error rate monitoring
  - Smoke tests
- **Duration**: ~5 minutes
- **Retries**: 30 attempts with 2s intervals

### 11. **Notifications**

- **Channels**:
  - Slack webhook (real-time)
  - Email (on failure)
  - GitHub issues (on critical failure)
  - GitHub deployment status (via API)
- **Info**: Build status, duration, artifacts links, action items

---

## Setup & Configuration

### Prerequisites

1. **GitHub Repository** with admin access
2. **AWS Account** with:
   - S3 buckets for staging/production
   - CloudFront distributions
   - IAM user with appropriate permissions
3. **Slack Workspace** (for notifications)
4. **Docker/Docker Compose** (for local testing)
5. **Node.js 18+** and **npm 8+**

### Step 1: Repository Setup

```bash
# Clone the repository
git clone https://github.com/your-org/va-gov-test-automation.git
cd va-gov-test-automation

# Create necessary branches
git branch develop
git push origin develop
```

### Step 2: GitHub Secrets Configuration

Add these secrets to GitHub repository settings:

```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<your_access_key>
AWS_SECRET_ACCESS_KEY=<your_secret_key>
EMAIL_USERNAME=ci-notifications@example.com
EMAIL_PASSWORD=<app_password>
```

**To set secrets:**

1. Go to Repository → Settings → Secrets and Variables → Actions
2. Click "New repository secret"
3. Add each secret with the exact names above

### Step 3: S3 Buckets Setup

```bash
# Create staging bucket
aws s3 mb s3://va-test-staging --region us-east-1

# Create production bucket
aws s3 mb s3://va-test-production --region us-east-1

# Enable versioning for rollback capability
aws s3api put-bucket-versioning \
  --bucket va-test-staging \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket va-test-production \
  --versioning-configuration Status=Enabled

# Set bucket policies for public read (if applicable)
# Set lifecycle policies for backup retention
```

### Step 4: CloudFront Distributions Setup

```bash
# Create CloudFront distribution pointing to S3 bucket
# Configure cache settings:
# - TTL: 86400 seconds (1 day)
# - Compress: enabled
# - HTTPS redirect: enabled
```

### Step 5: IAM Permissions Setup

Create IAM policy for CI/CD user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::va-test-staging/*",
        "arn:aws:s3:::va-test-staging",
        "arn:aws:s3:::va-test-production/*",
        "arn:aws:s3:::va-test-production"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:ListDistributions",
        "cloudfront:GetDistribution",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 6: Local Environment Setup

```bash
# Install dependencies
npm ci

# Install Playwright browsers
npx playwright install

# Create .env file for local testing
cat > .env.local <<EOF
ENVIRONMENT=development
BASE_URL=http://localhost:3000
DATABASE_URL=postgresql://testuser:testpass@localhost:5432/test_db
REDIS_URL=redis://localhost:6379
LOG_LEVEL=debug
EOF

# Start Docker Compose for local development
docker-compose up -d postgres redis

# Run tests locally
npm run test:unit
npm run test:e2e
```

---

## Usage Guide

### Running the Pipeline Manually

**Option 1: Push to trigger branch**

```bash
# Will trigger pipeline automatically
git push origin feature/my-feature
```

**Option 2: Rerun failed job in GitHub UI**

1. Go to Actions tab
2. Select failed workflow
3. Click "Re-run jobs"

**Option 3: Trigger via GitHub CLI**

```bash
# Trigger workflow via CLI
gh workflow run ci-cd.yml -f environment=staging
```

### Running Tests Locally

```bash
# Run all tests
npm run test

# Run specific test suite
npm run test:unit
npm run test:e2e
npm run test:api
npm run test:smoke

# Run with coverage
npm run test:unit -- --coverage

# Run in watch mode (development)
npm run test:watch
```

### Building Application

```bash
# Build for production
npm run build

# Or use the build script directly
bash scripts/build.sh production

# Build for different environments
bash scripts/build.sh development
bash scripts/build.sh staging
bash scripts/build.sh production
```

### Running with Docker

```bash
# Build Docker image
docker build -t va-test-automation:latest .

# Run tests in container
docker run --rm \
  -e BASE_URL=http://localhost:3000 \
  va-test-automation:latest npm run test:e2e

# Use Docker Compose
docker-compose up test-automation

# Run tests in parallel
docker-compose run --rm playwright-runner
```

---

## Deployment Process

### Automatic Deployment to Staging

**Trigger**: Push to `develop` branch

```bash
git checkout develop
git merge --no-ff feature/my-feature
git push origin develop
# Pipeline automatically deploys to staging
```

**What happens:**

1. Code quality checks
2. Build artifacts
3. All tests executed
4. Deploy to S3 staging bucket
5. CloudFront cache invalidation
6. Smoke tests on staging
7. Health verification
8. Slack notification

**Expected time**: ~30-45 minutes

### Automatic Deployment to Production

**Trigger**: Push to `main` branch

```bash
git checkout main
git merge --no-ff develop
git push origin main
# Pipeline automatically deploys to production
```

**Prerequisites for production deployment:**

- All tests in main branch passed
- Security scan passed
- No critical vulnerabilities
- Approval from CODEOWNERS (if configured)

**What happens:**

1. Code quality checks
2. Build artifacts
3. All tests executed
4. Security scanning
5. Deploy to S3 production bucket
6. CloudFront cache invalidation
7. Smoke tests on production
8. Health verification
9. Deployment notifications to all channels

**Expected time**: ~40-60 minutes

### Manual Deployment (Emergency)

```bash
# Deploy specific version to staging
bash scripts/deploy.sh staging

# Deploy specific version to production
bash scripts/deploy.sh production

# With environment variables
DEPLOYMENT_ID=123 \
AWS_REGION=us-east-1 \
bash scripts/deploy.sh production
```

---

## Rollback Procedures

### Automatic Rollback

Triggered automatically when:

- Deployment verification fails
- Health checks fail
- Smoke tests fail in production
- Error rate exceeds threshold

```bash
# Automatic rollback happens in pipeline
# No manual action required
```

### Manual Rollback

```bash
# Interactive rollback (requires confirmation for production)
bash scripts/rollback.sh production

# Interactive rollback for staging
bash scripts/rollback.sh staging

# With environment variables
GITHUB_TOKEN=<token> \
SLACK_WEBHOOK_URL=<url> \
bash scripts/rollback.sh production
```

**Rollback steps:**

1. Confirm environment (double-check for production)
2. List available backups
3. Select latest backup
4. Restore from backup to S3
5. Invalidate CloudFront cache
6. Verify health
7. Send notifications to Slack/email
8. Create GitHub issue if rollback failed

**Expected time**: ~10-15 minutes

### Rollback Recovery

If rollback itself fails:

1. **Check logs**:

   ```bash
   cat rollback-<environment>-*.log
   ```

2. **Verify current state**:

   ```bash
   curl https://va-test.example.com/health
   ```

3. **Contact AWS support** or DBA for manual S3 intervention

4. **Review backup strategy** and improve for future

---

## Monitoring & Notifications

### Slack Notifications

Messages posted to configured Slack channel:

```
Build #123 - SUCCESS
Branch: main
Commit: a1b2c3d
View Details: [button link to GitHub Actions]
```

**Statuses**:

- All jobs passed
- Warnings (tests passed with warnings)
- Failed (test failures or build errors)

### Email Notifications

Sent to `qa-team@example.com` on:

- Build failures
- Deployment failures
- Critical security vulnerabilities

### GitHub Integration

- **Deployment status updates** in PR/commit
- **Check runs** with detailed test results
- **Issues created** for critical failures
- **Pull request comments** with test summary

### Monitoring Dashboard (Optional)

Set up monitoring with:

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **CloudWatch**: AWS-native monitoring

```bash
# Start monitoring stack
docker-compose --profile monitoring up -d prometheus grafana

# Access Grafana at http://localhost:3001
# Default credentials: admin / admin
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. Pipeline Fails on Build

**Symptom**: "npm ci failed" or "npm run build failed"

**Solutions**:

```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm ci

# Check Node version
node --version  # Should be 18.x

# View full build logs in GitHub Actions UI
```

#### 2. Playwright Tests Timeout

**Symptom**: "Timeout: Browser was not launched" or "Waiting for element"

**Solutions**:

```bash
# Reinstall Playwright browsers
npx playwright install --with-deps

# Run with longer timeout
npm run test:e2e -- --timeout=60000

# Enable debug mode
DEBUG=pw:api npm run test:e2e

# Check server logs
npm start &
curl http://localhost:3000/health
```

#### 3. Deployment S3 Upload Fails

**Symptom**: "Access Denied" or "NoSuchBucket"

**Solutions**:

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check S3 bucket exists
aws s3 ls s3://va-test-staging

# Check IAM permissions
aws s3api head-bucket --bucket va-test-staging

# Manual upload test
aws s3 sync dist/ s3://va-test-staging/ --region us-east-1
```

#### 4. CloudFront Cache Issues

**Symptom**: Old content served after deploy

**Solutions**:

```bash
# Manual invalidation
aws cloudfront create-invalidation \
  --distribution-id <ID> \
  --paths "/*"

# Check distribution ID
aws cloudfront list-distributions | grep -i "va-test"

# Monitor invalidation status
aws cloudfront list-invalidations --distribution-id <ID>
```

#### 5. Rollback Fails

**Symptom**: "No backup found" or "Rollback verification failed"

**Solutions**:

```bash
# Check available backups
aws s3 ls s3://va-test-production/backups/production/ --recursive

# Manual restore from specific backup
aws s3 sync \
  s3://va-test-production/backups/production/backup-20240218_150000/ \
  s3://va-test-production/ \
  --delete

# Verify restore
curl https://va-test.example.com/health
```

### Debug Mode

Enable detailed logging:

```bash
# GitHub Actions debug
ACTIONS_STEP_DEBUG=true

# Script debug
bash -x scripts/deploy.sh production

# Application debug
DEBUG=* npm start

# k6 load test debug
k6 run --vus=1 --duration=10s tests/performance/k6-load-tests.js
```

### Viewing Logs

```bash
# GitHub Actions logs
# Go to: Actions → Workflow → Job → Step → View Logs

# Local logs
tail -f logs/build-<date>.log
tail -f logs/test-<date>.log
tail -f logs/deployment-<environment>-<date>.log

# Docker logs
docker logs va-test-automation
docker-compose logs -f test-automation
```

---

## Environment Variables

### GitHub Actions Secrets

These must be set in GitHub repository settings:

| Variable                | Description                      | Example                       |
| ----------------------- | -------------------------------- | ----------------------------- |
| `AWS_REGION`            | AWS region for S3 and CloudFront | `us-east-1`                   |
| `AWS_ACCESS_KEY_ID`     | AWS IAM access key               | `AKI...`                      |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key               | `wJal...`                     |
| `SLACK_WEBHOOK_URL`     | Slack incoming webhook           | `https://hooks.slack.com/...` |
| `EMAIL_USERNAME`        | Email for notifications          | `ci@example.com`              |
| `EMAIL_PASSWORD`        | Email password/app token         | `xxxx xxxx xxxx xxxx`         |

### Runtime Environment Variables

Used during pipeline execution:

| Variable           | Default                  | Description                |
| ------------------ | ------------------------ | -------------------------- |
| `NODE_ENV`         | `test`                   | Environment mode           |
| `ENVIRONMENT`      | `staging`                | Deployment environment     |
| `BASE_URL`         | `http://localhost:3000`  | Application base URL       |
| `DATABASE_URL`     | `postgres://...`         | Database connection string |
| `REDIS_URL`        | `redis://localhost:6379` | Redis connection string    |
| `PARALLEL_WORKERS` | `4`                      | Parallel test workers      |
| `LOG_LEVEL`        | `info`                   | Logging level              |
| `TIMEOUT`          | `60000`                  | Test timeout (ms)          |
| `RETRY_DELAY`      | `10`                     | Retry delay (seconds)      |

### Docker Environment Variables

Set in `.env` file or docker-compose:

```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://testuser:testpass@postgres:5432/test_db
REDIS_URL=redis://redis:6379
LOG_LEVEL=info
```

---

## Best Practices

### 1. Branch Strategy

```
main (production-ready, protected)
  ↑
develop (staging environment)
  ↑
feature/* (feature branches)
```

**Rules:**

- `main` requires PR approval and passing tests
- `develop` auto-deploys to staging
- Feature branches blocked until tests pass
- Delete feature branches after merge

### 2. Commit Messages

Use conventional commits for clear history:

```
feat: Add new test for claims status
fix: Resolve E2E timeout issue
test: Improve appointment scheduling tests
ci: Update Docker image version
docs: Update deployment documentation
```

### 3. Test Best Practices

```javascript
// DO: Descriptive test names
test('User can schedule appointment with valid clinic and date', async () => {});

// DON'T: Vague test names
test('Test scheduling', async () => {});

// DO: Proper assertions
expect(appointmentStatus).toBe('confirmed');

// DON'T: Weak assertions
expect(result).toBeTruthy();

// DO: Use Page Object Model
const loginPage = new LoginPage(page);
await loginPage.login(credentials);

// DON'T: Direct element interaction everywhere
await page.fill('input[type="email"]', 'user@example.com');
```

### 4. Performance Optimization

- Use **parallel test execution** (jobs and workers)
- **Cache dependencies** in Docker and npm
- **Limit artifact size** (videos only on failure)
- **Archive old reports** (30-day retention)
- **Use fast base images** (alpine Linux)

### 5. Security Best Practices

- **Never commit secrets** to repository
- **Use GitHub secrets** for sensitive data
- **Rotate access keys** quarterly
- **Use IAM roles** instead of static credentials
- **Enable branch protection** on main
- **Review deployment logs** regularly
- **Keep dependencies updated** (weekly npm audit)

### 6. Monitoring & Maintenance

- **Monitor pipeline duration** (flag if >60 minutes)
- **Review test failures** promptly
- **Update flaky test** thresholds
- **Maintain backup strategy** (weekly verification)
- **Schedule maintenance windows** for updates
- **Document any manual interventions**

### 7. Cost Optimization

- **Use spot instances** for non-critical jobs
- **Set artifact retention limits** (30 days)
- **Schedule expensive tests** during off-hours
- **Monitor CloudFront costs** (invalidation patterns)
- **Compress build artifacts** before S3 upload
- **Clean up old backups** (retention policy)

---

## Support & Contact

For issues or questions:

1. **Check troubleshooting section** above
2. **Review GitHub Actions logs** for specific errors
3. **Contact QA Team**: qa-team@va.gov
4. **Open GitHub Issue**: Include logs and error messages
5. **Slack Channel**: #qa-automation-ops

---

## Appendix

### Useful Commands

```bash
# View specific GitHub Actions run
gh run view <run_id> --log

# Trigger workflow manually
gh workflow run ci-cd.yml --ref main

# List all workflows
gh workflow list

# Disable/enable workflow
gh workflow disable ci-cd.yml
gh workflow enable ci-cd.yml

# Download artifacts
gh run download <run_id> -n <artifact_name>

# View deployment status
gh deployment list

# Rerun specific job
gh run rerun <run_id> --failed
```

### Related Documentation

- [Testing Strategy](../VA_GOV_TEST_PLAN.md)
- [Docker Setup Guide](./DOCKER.md)
- [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md)
- [Performance Tuning](./PERFORMANCE_TUNING.md)
- [Security Guidelines](./SECURITY.md)

---

**Version**: 1.0
**Last Updated**: February 18, 2026
**Maintained By**: VA.gov QA Automation Team
