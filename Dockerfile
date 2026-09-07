# ============================================================
# Sentinel QA Automation Framework
# Playwright + TypeScript + AI + DevSecOps
# ============================================================

# IMPORTANT:
# Keep this version synchronized with @playwright/test
# in package.json/package-lock.json.
ARG PLAYWRIGHT_VERSION=1.63.0

# ============================================================
# Stage 1: Base Playwright Environment
# ============================================================

FROM mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble AS base

LABEL org.opencontainers.image.title="Sentinel QA Automation"
LABEL org.opencontainers.image.description="AI-driven Playwright Test Automation and DevSecOps Framework"
LABEL org.opencontainers.image.vendor="Sentinel QA"

WORKDIR /app

# ------------------------------------------------------------
# Runtime environment
# ------------------------------------------------------------

ENV CI=true \
    NODE_ENV=test \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    npm_config_update_notifier=false \
    npm_config_fund=false

# ============================================================
# Stage 2: Dependencies
# ============================================================

FROM base AS dependencies

WORKDIR /app

# Copy dependency manifests first.
# This maximizes Docker layer caching.
COPY package.json package-lock.json ./

# Install exact dependencies from package-lock.json.
# BuildKit cache keeps npm downloads between builds.
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# ============================================================
# Stage 3: Build / TypeScript Validation
# ============================================================

FROM dependencies AS build

WORKDIR /app

# Copy application and test source.
COPY . .

# TypeScript compilation if a build script exists.
# Remove this line if the project intentionally has no build script.
RUN npm run build:prod

# ------------------------------------------------------------
# Generate build metadata
# ------------------------------------------------------------

RUN mkdir -p dist && \
    printf '{\n' > dist/build-info.json && \
    printf '  "buildTime": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> dist/build-info.json && \
    printf '  "nodeVersion": "%s",\n' "$(node --version)" >> dist/build-info.json && \
    printf '  "playwrightVersion": "%s"\n' "${PLAYWRIGHT_VERSION}" >> dist/build-info.json && \
    printf '}\n' >> dist/build-info.json

# ============================================================
# Stage 4: Sentinel Test Runner
# ============================================================

FROM dependencies AS test-runner

WORKDIR /app

# Copy project source.
COPY . .

# ------------------------------------------------------------
# Create non-root Sentinel user
# ------------------------------------------------------------

RUN groupadd --gid 1001 sentinel && \
    useradd \
        --uid 1001 \
        --gid 1001 \
        --create-home \
        --shell /bin/bash \
        sentinel && \
    mkdir -p \
        /app/test-results \
        /app/playwright-report \
        /app/coverage && \
    chown -R sentinel:sentinel /app

USER sentinel

# ------------------------------------------------------------
# Playwright directories
# ------------------------------------------------------------

ENV HOME=/home/sentinel

# ------------------------------------------------------------
# Default test command
# ------------------------------------------------------------

ENTRYPOINT ["npm"]

CMD ["test"]

# ============================================================
# Stage 5: Development Environment
# ============================================================

FROM dependencies AS development

WORKDIR /app

# Copy source.
COPY . .

# ------------------------------------------------------------
# Create non-root development user
# ------------------------------------------------------------

RUN groupadd --gid 1001 sentinel && \
    useradd \
        --uid 1001 \
        --gid 1001 \
        --create-home \
        --shell /bin/bash \
        sentinel && \
    chown -R sentinel:sentinel /app

USER sentinel

ENV HOME=/home/sentinel \
    NODE_ENV=development

# Development ports.
# 3000  - optional application
# 3001  - optional secondary service
# 9229  - Node.js debugger
EXPOSE 3000 3001 9229

ENTRYPOINT ["npm"]

CMD ["run", "dev"]