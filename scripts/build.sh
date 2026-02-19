#!/bin/bash

################################################################################
# Build Script for VA.gov Test Automation
# 
# This script handles application builds for different environments
# Usage: ./scripts/build.sh [environment] [options]
#
# Environments: development, staging, production
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-development}
VERBOSE=${2:-false}
BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUILD_DIR="dist"
SOURCE_DIR="src"

# Logger function
log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

debug() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

# Validate environment
validate_environment() {
    case "$ENVIRONMENT" in
        development|staging|production)
            log "Building for environment: $ENVIRONMENT"
            ;;
        *)
            error "Invalid environment: $ENVIRONMENT. Must be one of: development, staging, production"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed"
        exit 1
    fi
    debug "Node version: $(node --version)"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        error "npm is not installed"
        exit 1
    fi
    debug "npm version: $(npm --version)"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        log "node_modules not found, running npm install..."
        npm ci
    fi
    
    log "All prerequisites satisfied"
}

# Clean build directory
clean_build() {
    log "Cleaning build directory..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        debug "Removed $BUILD_DIR"
    fi
    mkdir -p "$BUILD_DIR"
}

# Run linting
run_linting() {
    log "Running ESLint..."
    npm run lint -- --format=json --output-file=build-reports/lint.json || {
        error "Linting failed. Review lint.json for details."
        return 1
    }
    log "Linting passed"
}

# Run TypeScript compilation
run_typescript() {
    log "Running TypeScript compiler..."
    npx tsc --listFiles || {
        error "TypeScript compilation failed"
        return 1
    }
    log "TypeScript compilation successful"
}

# Build application bundles
build_application() {
    log "Building application..."
    
    case "$ENVIRONMENT" in
        development)
            npm run build:dev
            ;;
        staging)
            npm run build:staging
            ;;
        production)
            npm run build:prod
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log "Application build successful"
    else
        error "Application build failed"
        return 1
    fi
}

# Generate build metadata
generate_metadata() {
    log "Generating build metadata..."
    
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local build_version=$(cat package.json | grep '"version"' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | trim)
    
    mkdir -p build-reports
    
    cat > build-reports/metadata.json <<EOF
{
  "buildTimestamp": "$BUILD_TIMESTAMP",
  "environment": "$ENVIRONMENT",
  "version": "$build_version",
  "gitCommit": "$git_commit",
  "gitBranch": "$git_branch",
  "nodeVersion": "$(node --version)",
  "npmVersion": "$(npm --version)"
}
EOF
    
    log "Metadata generated: build-reports/metadata.json"
}

# Generate build artifacts manifest
generate_manifest() {
    log "Generating build artifacts manifest..."
    
    mkdir -p build-reports
    
    find "$BUILD_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) | \
    while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "File: $file, Size: $size"
    done > build-reports/artifacts.txt
    
    log "Manifest generated: build-reports/artifacts.txt"
}

# Run security checks on build artifacts
security_checks() {
    if [ "$ENVIRONMENT" = "production" ]; then
        log "Running security checks..."
        
        # Check for secrets in built code
        if grep -r "password\|secret\|api_key" "$BUILD_DIR" --exclude-dir=node_modules 2>/dev/null; then
            warn "Potential secrets found in build artifacts"
        fi
        
        # Run npm audit
        npm audit --json > build-reports/audit.json 2>/dev/null || true
        
        log "Security checks completed"
    fi
}

# Generate source maps
generate_source_maps() {
    if [ "$ENVIRONMENT" != "production" ]; then
        log "Generating source maps..."
        npm run build:sourcemaps 2>/dev/null || true
    fi
}

# Verify build output
verify_build() {
    log "Verifying build output..."
    
    # Check if build directory has content
    if [ ! "$(ls -A $BUILD_DIR)" ]; then
        error "Build directory is empty"
        return 1
    fi
    
    # Check for entry files
    if [ -f "$BUILD_DIR/index.js" ] || [ -f "$BUILD_DIR/index.html" ]; then
        log "Build artifacts verified"
    else
        warn "No expected entry files found, but build directory has content"
    fi
}

# Create build summary
create_build_summary() {
    log "Creating build summary..."
    
    mkdir -p build-reports
    
    cat > build-reports/summary.txt <<EOF
====================================
VA.gov Test Automation Build Summary
====================================

Build Date: $BUILD_TIMESTAMP
Environment: $ENVIRONMENT
Build Status: SUCCESS

Source Directory: $SOURCE_DIR
Build Directory: $BUILD_DIR

Build Artifacts Location: $(pwd)/$BUILD_DIR

For detailed logs, see:
- build-reports/lint.json (linting results)
- build-reports/metadata.json (build metadata)
- build-reports/artifacts.txt (artifact manifest)

====================================
EOF
    
    cat build-reports/summary.txt
}

# Compress build artifacts (optional)
compress_artifacts() {
    if [ "$ENVIRONMENT" = "production" ]; then
        log "Compressing build artifacts..."
        tar -czf "${BUILD_DIR}-${BUILD_TIMESTAMP}.tar.gz" "$BUILD_DIR"
        log "Build artifacts compressed: ${BUILD_DIR}-${BUILD_TIMESTAMP}.tar.gz"
    fi
}

# Main execution
main() {
    log "Starting build process for VA.gov Test Automation"
    log "Environment: $ENVIRONMENT"
    
    # Create build reports directory
    mkdir -p build-reports
    
    # Execute build steps
    validate_environment || exit 1
    check_prerequisites || exit 1
    clean_build || exit 1
    run_linting || exit 1
    run_typescript || exit 1
    build_application || exit 1
    generate_metadata || exit 1
    generate_manifest || exit 1
    security_checks || exit 1
    generate_source_maps || exit 1
    verify_build || exit 1
    compress_artifacts || exit 1
    create_build_summary || exit 1
    
    log "Build process completed successfully!"
    exit 0
}

# Run main function
main "$@"
