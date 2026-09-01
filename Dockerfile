# Multi-stage Dockerfile for VA.gov Test Automation

# ============================================================
# Stage 1: Base image with Node.js
# ============================================================
FROM node:18-alpine AS base

LABEL maintainer="VA.gov QA Team"
LABEL description="VA.gov Test Automation - Full Test Suite"

WORKDIR /app

# System dependencies
RUN apk add --no-cache \
    curl \
    bash \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*


# ============================================================
# Stage 2: Dependencies
# ============================================================
FROM base AS dependencies

WORKDIR /app

# Copy dependency files first for Docker layer caching
COPY package*.json ./

# Install all dependencies, including devDependencies
RUN npm ci

# Install Playwright browsers
RUN npx playwright install chromium

# Install Playwright browser system dependencies
RUN npx playwright install-deps chromium


# ============================================================
# Stage 3: Build
# ============================================================
FROM dependencies AS build

WORKDIR /app

# Copy application/test source
COPY . .

# Build application if build script exists
RUN npm run build:prod

# Generate build metadata
RUN mkdir -p dist && \
    echo "{ \
    \"buildTime\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \
    \"gitCommit\": \"$(git rev-parse HEAD 2>/dev/null || echo 'unknown')\", \
    \"nodeVersion\": \"$(node --version)\" \
    }" > dist/build-info.json


# ============================================================
# Stage 4: FULL TEST STAGE
# ============================================================
FROM build AS test

WORKDIR /app

# Create directories for test artifacts
RUN mkdir -p \
    test-results \
    playwright-report \
    coverage

# ------------------------------------------------------------
# Run linting
# ------------------------------------------------------------
RUN npm run lint

# ------------------------------------------------------------
# Run unit tests
# ------------------------------------------------------------
RUN npm run test:unit

# ------------------------------------------------------------
# Run ALL Playwright tests
# ------------------------------------------------------------
RUN npx playwright test

# ------------------------------------------------------------
# Optional API tests
# Uncomment if your package.json contains this script
# ------------------------------------------------------------
# RUN npm run test:api

# ------------------------------------------------------------
# Optional integration tests
# Uncomment if your package.json contains this script
# ------------------------------------------------------------
# RUN npm run test:integration


# ============================================================
# Stage 5: Production image
# ============================================================
FROM base AS production

WORKDIR /app

# Copy dependencies
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/package*.json ./

# Copy build artifacts
COPY --from=build /app/dist ./dist

# Create non-root user
RUN addgroup -g 1000 playwright && \
    adduser -D -u 1000 -G playwright playwright && \
    chown -R playwright:playwright /app

USER playwright

# Health check
HEALTHCHECK --interval=30s \
    --timeout=10s \
    --start-period=5s \
    --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

ENTRYPOINT ["npm"]
CMD ["start"]


# ============================================================
# Stage 6: Development image
# ============================================================
FROM dependencies AS development

WORKDIR /app

# Install development tools
RUN npm install -g \
    @playwright/test \
    ts-node \
    nodemon

# Copy source
COPY . .

# Create non-root user
RUN addgroup -g 1000 playwright && \
    adduser -D -u 1000 -G playwright playwright && \
    chown -R playwright:playwright /app

USER playwright

EXPOSE 3000 3001 9229

ENTRYPOINT ["npm"]
CMD ["run", "dev"]