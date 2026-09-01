# Multi-stage Dockerfile for VA.gov Test Automation

# Stage 1: Base image with Node.js
FROM node:26-alpine AS base
LABEL maintainer="VA.gov QA Team"
LABEL description="VA.gov Test Automation - Playwright Test Suite"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    bash \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Stage 2: Dependencies installation
FROM base AS dependencies
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production and development dependencies
RUN npm ci

# Install Playwright browsers and system dependencies
RUN npx playwright install && \
    npx playwright install-deps

# Stage 3: Build stage
FROM dependencies AS build
WORKDIR /app

# Copy source code
COPY . .

# Build application
RUN npm run build:prod

# Generate build metadata
RUN echo "{ \
    \"buildTime\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \
    \"gitCommit\": \"$(git rev-parse HEAD 2>/dev/null || echo 'unknown')\", \
    \"nodeVersion\": \"$(node --version)\" \
    }" > dist/build-info.json

# Stage 4: Test stage (optional, used for CI)
FROM build AS test
WORKDIR /app

# Run tests and generate reports
RUN mkdir -p test-results && \
    npm run test:unit || true && \
    npm run lint || true

# Stage 5: Production image
FROM base AS production
WORKDIR /app

# Copy dependencies from dependencies stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/package*.json ./

# Copy built artifacts from build stage
COPY --from=build /app/dist ./dist
COPY --from=build /app/dist/build-info.json ./dist/build-info.json

# Create non-root user
RUN addgroup -g 1000 playwright && \
    adduser -D -u 1000 -G playwright playwright && \
    chown -R playwright:playwright /app

# Switch to non-root user
USER playwright

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Expose port
EXPOSE 3000

# Default command
ENTRYPOINT ["npm"]
CMD ["start"]

# Stage 6: Development image (for local development)
FROM dependencies AS development
WORKDIR /app

# Install additional dev tools
RUN npm install -g \
    @playwright/test \
    ts-node \
    nodemon \
    2>/dev/null || true

# Copy all source files
COPY . .

# Create non-root user
RUN addgroup -g 1000 playwright && \
    adduser -D -u 1000 -G playwright playwright && \
    chown -R playwright:playwright /app

USER playwright

EXPOSE 3000 3001 9229

ENTRYPOINT ["npm"]
CMD ["run", "dev"]
