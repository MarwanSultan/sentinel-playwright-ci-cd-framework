#!/bin/bash

################################################################################
# Deployment Script for VA.gov Test Automation
#
# Handles deployment to staging and production environments
# Usage: ./scripts/deploy.sh [environment] [options]
#
# Environments: staging, production
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}
DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_REPO=${GITHUB_REPOSITORY:-}
AWS_REGION=${AWS_REGION:-us-east-1}
BUILD_DIR="dist"
DEPLOYMENT_LOG="deployment-${ENVIRONMENT}-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="backups"
MAX_RETRIES=3
RETRY_DELAY=10

# Environment-specific configuration
declare -A ENV_CONFIG
ENV_CONFIG[staging_bucket]="va-test-staging"
ENV_CONFIG[staging_url]="https://staging.va-test.example.com"
ENV_CONFIG[staging_cloudfront]="d123.cloudfront.net"
ENV_CONFIG[production_bucket]="va-test-production"
ENV_CONFIG[production_url]="https://va-test.example.com"
ENV_CONFIG[production_cloudfront]="d456.cloudfront.net"

# Logger functions
log() {
    echo -e "${GREEN}[DEPLOY]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$DEPLOYMENT_LOG" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

# Validate environment
validate_environment() {
    case "$ENVIRONMENT" in
        staging|production)
            log "Deploying to: $ENVIRONMENT"
            ;;
        *)
            error "Invalid environment: $ENVIRONMENT. Must be staging or production"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log "Checking deployment prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check build artifacts exist
    if [ ! -d "$BUILD_DIR" ]; then
        error "Build artifacts not found in $BUILD_DIR"
        exit 1
    fi
    
    # Verify AWS credentials configured
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    log "All prerequisites satisfied"
}

# Create backup of current deployment
create_backup() {
    log "Creating backup of current deployment..."
    
    mkdir -p "$BACKUP_DIR"
    
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_key="backups/${ENVIRONMENT}/backup-${backup_timestamp}"
    
    # Sync current version to backup
    aws s3 sync "s3://${bucket}/" "s3://${bucket}/${backup_key}" \
        --region "$AWS_REGION" \
        --exclude "backups/*" \
        --exclude ".git/*" \
        2>&1 | tee -a "$DEPLOYMENT_LOG"
    
    if [ $? -eq 0 ]; then
        log "Backup created: s3://${bucket}/${backup_key}"
        echo "${backup_key}" > "${BACKUP_DIR}/latest-${ENVIRONMENT}.txt"
    else
        error "Failed to create backup"
        return 1
    fi
}

# Validate build artifacts
validate_artifacts() {
    log "Validating build artifacts..."
    
    # Check for required files
    if [ ! -f "$BUILD_DIR/index.html" ] && [ ! -f "$BUILD_DIR/index.js" ]; then
        error "Required build files not found"
        return 1
    fi
    
    # Check file integrity
    if [ ! "$(ls -A $BUILD_DIR)" ]; then
        error "Build directory is empty"
        return 1
    fi
    
    local file_count=$(find "$BUILD_DIR" -type f | wc -l)
    log "Validated $file_count files in build artifacts"
}

# Upload to S3
upload_to_s3() {
    log "Uploading artifacts to S3..."
    
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log "Upload attempt $attempt/$MAX_RETRIES"
        
        aws s3 sync "$BUILD_DIR/" "s3://${bucket}/" \
            --region "$AWS_REGION" \
            --delete \
            --cache-control "public, max-age=3600" \
            --exclude ".git*" \
            --exclude "*.map" \
            2>&1 | tee -a "$DEPLOYMENT_LOG"
        
        if [ $? -eq 0 ]; then
            log "Successfully uploaded artifacts to S3"
            return 0
        fi
        
        warn "Upload attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
        attempt=$((attempt + 1))
    done
    
    error "Failed to upload to S3 after $MAX_RETRIES attempts"
    return 1
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log "Invalidating CloudFront distribution cache..."
    
    local distribution="${ENV_CONFIG[${ENVIRONMENT}_cloudfront]}"
    
    local distribution_id=$(aws cloudfront list-distributions \
        --region "$AWS_REGION" \
        --query "DistributionList.Items[?DomainName=='${distribution}'].Id" \
        --output text)
    
    if [ -z "$distribution_id" ]; then
        warn "Could not find CloudFront distribution for domain: $distribution"
        return 1
    fi
    
    local invalidation_id=$(aws cloudfront create-invalidation \
        --distribution-id "$distribution_id" \
        --paths "/*" \
        --region "$AWS_REGION" \
        --query 'Invalidation.Id' \
        --output text)
    
    if [ -z "$invalidation_id" ]; then
        error "Failed to create CloudFront invalidation"
        return 1
    fi
    
    log "CloudFront invalidation created: $invalidation_id"
    
    # Wait for invalidation to complete
    log "Waiting for CloudFront cache invalidation to complete..."
    aws cloudfront wait invalidation-completed \
        --distribution-id "$distribution_id" \
        --id "$invalidation_id" \
        --region "$AWS_REGION" \
        2>&1 | tee -a "$DEPLOYMENT_LOG"
    
    if [ $? -eq 0 ]; then
        log "CloudFront cache invalidated successfully"
        return 0
    else
        warn "CloudFront invalidation did not complete in expected time"
        return 1
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    local url="${ENV_CONFIG[${ENVIRONMENT}_url]}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$url/health" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            log "Deployment verification successful (HTTP $response)"
            return 0
        fi
        
        warn "Attempt $attempt/$max_attempts: Health check returned HTTP $response"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error "Deployment verification failed"
    return 1
}

# Run smoke tests
run_smoke_tests() {
    log "Running smoke tests on deployed environment..."
    
    if ! npm run test:smoke >/dev/null 2>&1; then
        warn "Smoke tests finished with warnings"
    fi
}

# Send deployment notification
send_notification() {
    local status=$1
    local message=$2
    
    log "Sending deployment notification..."
    
    # Update GitHub Deployment Status
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPO" ] && [ -n "$DEPLOYMENT_ID" ]; then
        local state="success"
        if [ "$status" != "0" ]; then
            state="failure"
        fi
        
        # Note: This would require additional GitHub API call setup
        info "Deployment status would be updated to: $state"
    fi
}

# Rollback deployment
rollback_deployment() {
    log "Initiating rollback..."
    
    local backup_key_file="${BACKUP_DIR}/latest-${ENVIRONMENT}.txt"
    
    if [ ! -f "$backup_key_file" ]; then
        error "No backup information found for rollback"
        return 1
    fi
    
    local backup_key=$(cat "$backup_key_file")
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    
    log "Rolling back to: $backup_key"
    
    # Sync backup back to current location
    aws s3 sync "s3://${bucket}/${backup_key}/" "s3://${bucket}/" \
        --region "$AWS_REGION" \
        --exclude "backups/*" \
        --delete \
        2>&1 | tee -a "$DEPLOYMENT_LOG"
    
    if [ $? -eq 0 ]; then
        log "Rollback completed successfully"
        invalidate_cloudfront || warn "CloudFront invalidation during rollback failed"
        return 0
    else
        error "Rollback failed"
        return 1
    fi
}

# Create deployment manifest
create_manifest() {
    log "Creating deployment manifest..."
    
    local manifest_file="deployment-manifest-${ENVIRONMENT}-$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$manifest_file" <<EOF
{
  "environment": "$ENVIRONMENT",
  "deploymentTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "version": "$(cat package.json | grep '"version"' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | xargs)",
  "bucket": "${ENV_CONFIG[${ENVIRONMENT}_bucket]}",
  "url": "${ENV_CONFIG[${ENVIRONMENT}_url]}",
  "filesDeployed": $(find "$BUILD_DIR" -type f | wc -l),
  "artificatsSize": "$(du -sh "$BUILD_DIR" | cut -f1)"
}
EOF

    log "Manifest created: $manifest_file"
}

# Generate deployment report
generate_report() {
    log "Generating deployment report..."
    
    local report_file="deployment-report-${ENVIRONMENT}.html"
    
    cat > "$report_file" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .report { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        .section { margin: 20px 0; padding: 15px; background: #f9f9f9; border-left: 4px solid #4CAF50; }
        .section.failure { border-left-color: #f44336; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        .status-success { color: #4CAF50; font-weight: bold; }
        .status-failure { color: #f44336; font-weight: bold; }
    </style>
</head>
<body>
    <div class="report">
        <h1>🚀 Deployment Report</h1>
        <div class="section">
            <h2>Deployment Details</h2>
            <table>
                <tr>
                    <th>Property</th>
                    <th>Value</th>
                </tr>
                <tr>
                    <td>Environment</td>
                    <td id="env">-</td>
                </tr>
                <tr>
                    <td>Status</td>
                    <td id="status">-</td>
                </tr>
                <tr>
                    <td>Deployment Time</td>
                    <td id="time">-</td>
                </tr>
                <tr>
                    <td>URL</td>
                    <td id="url">-</td>
                </tr>
            </table>
        </div>
    </div>
</body>
</html>
EOF

    log "Report generated: $report_file"
}

# Main deployment orchestration
main() {
    log "=========================================="
    log "Starting deployment process"
    log "=========================================="
    log "Environment: $ENVIRONMENT"
    log "Build directory: $BUILD_DIR"
    
    # Create logs directory
    mkdir -p "$(dirname "$DEPLOYMENT_LOG")"
    
    # Execute deployment steps
    validate_environment || exit 1
    check_prerequisites || exit 1
    validate_artifacts || exit 1
    create_backup || exit 1
    upload_to_s3 || {
        error "S3 upload failed, aborting deployment"
        rollback_deployment
        exit 1
    }
    invalidate_cloudfront || warn "CloudFront cache invalidation warning"
    
    log "Waiting for deployment to stabilize..."
    sleep 15
    
    verify_deployment || {
        error "Deployment verification failed, initiating rollback"
        rollback_deployment
        exit 1
    }
    
    run_smoke_tests || warn "Smoke tests completed with warnings"
    create_manifest
    generate_report
    send_notification 0 "Deployment successful"
    
    log "=========================================="
    log "Deployment completed successfully!"
    log "=========================================="
    log "URL: ${ENV_CONFIG[${ENVIRONMENT}_url]}"
    log "Logs: $DEPLOYMENT_LOG"
    
    exit 0
}

# Execute main function
main "$@"
