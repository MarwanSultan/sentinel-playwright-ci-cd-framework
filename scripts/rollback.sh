#!/bin/bash

################################################################################
# Rollback Script for VA.gov Test Automation
#
# Handles emergency rollback of deployments in staging or production
# Usage: ./scripts/rollback.sh [environment] [options]
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-production}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_REPO=${GITHUB_REPOSITORY:-}
AWS_REGION=${AWS_REGION:-us-east-1}
BACKUP_DIR="backups"
ROLLBACK_LOG="rollback-${ENVIRONMENT}-$(date +%Y%m%d_%H%M%S).log"
NOTIFICATION_SLACK=${SLACK_WEBHOOK_URL:-}

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
    echo -e "${GREEN}[ROLLBACK]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$ROLLBACK_LOG" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

# Validate environment
validate_environment() {
    case "$ENVIRONMENT" in
        staging|production)
            log "Rollback environment: $ENVIRONMENT"
            ;;
        *)
            error "Invalid environment: $ENVIRONMENT. Must be staging or production"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log "Checking rollback prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
        exit 1
    fi
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    log "Prerequisites satisfied"
}

# List available backups
list_backups() {
    log "Listing available backups for $ENVIRONMENT..."
    
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    
    # List all backups in S3
    aws s3 ls "s3://${bucket}/backups/${ENVIRONMENT}/" \
        --region "$AWS_REGION" \
        2>&1 | tee -a "$ROLLBACK_LOG" | tail -20
}

# Get latest backup
get_latest_backup() {
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    local backup_key_file="${BACKUP_DIR}/latest-${ENVIRONMENT}.txt"
    
    if [ -f "$backup_key_file" ]; then
        cat "$backup_key_file"
    else
        # Try to find latest backup in S3
        aws s3 ls "s3://${bucket}/backups/${ENVIRONMENT}/" \
            --region "$AWS_REGION" \
            --recursive \
            | sort | tail -1 | awk '{print $NF}'
    fi
}

# Verify backup exists
verify_backup() {
    local backup_key=$1
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    
    log "Verifying backup: $backup_key"
    
    # Check if backup has at least some files
    local file_count=$(aws s3 ls "s3://${bucket}/${backup_key}/" \
        --region "$AWS_REGION" \
        --recursive | wc -l)
    
    if [ "$file_count" -gt 0 ]; then
        log "Backup verified: $file_count files found"
        return 0
    else
        error "Backup appears to be empty"
        return 1
    fi
}

# Perform rollback
perform_rollback() {
    local backup_key=$1
    local bucket="${ENV_CONFIG[${ENVIRONMENT}_bucket]}"
    
    log "Performing rollback from: $backup_key"
    
    # Sync backup back to production
    aws s3 sync "s3://${bucket}/${backup_key}/" "s3://${bucket}/" \
        --region "$AWS_REGION" \
        --exclude "backups/*" \
        --delete \
        2>&1 | tee -a "$ROLLBACK_LOG"
    
    if [ $? -eq 0 ]; then
        log "S3 sync completed successfully"
        return 0
    else
        error "S3 sync failed during rollback"
        return 1
    fi
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log "Invalidating CloudFront distribution..."
    
    local distribution="${ENV_CONFIG[${ENVIRONMENT}_cloudfront]}"
    
    # Find distribution ID
    local distribution_id=$(aws cloudfront list-distributions \
        --region "$AWS_REGION" \
        --query "DistributionList.Items[?DomainName=='${distribution}'].Id" \
        --output text)
    
    if [ -z "$distribution_id" ]; then
        warn "Could not find CloudFront distribution for domain: $distribution"
        return 1
    fi
    
    # Create invalidation
    local invalidation_id=$(aws cloudfront create-invalidation \
        --distribution-id "$distribution_id" \
        --paths "/*" \
        --region "$AWS_REGION" \
        --query 'Invalidation.Id' \
        --output text)
    
    log "Waiting for CloudFront invalidation: $invalidation_id"
    
    # Wait for completion
    aws cloudfront wait invalidation-completed \
        --distribution-id "$distribution_id" \
        --id "$invalidation_id" \
        --region "$AWS_REGION" \
        2>&1 | tee -a "$ROLLBACK_LOG"
    
    if [ $? -eq 0 ]; then
        log "CloudFront cache invalidated"
        return 0
    else
        warn "CloudFront invalidation did not complete as expected"
        return 1
    fi
}

# Verify rollback
verify_rollback() {
    log "Verifying rollback..."
    
    local url="${ENV_CONFIG[${ENVIRONMENT}_url]}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$url/health" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            log "Rollback verified: Environment is healthy"
            return 0
        fi
        
        warn "Attempt $attempt/$max_attempts: Health check returned HTTP $response"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error "Rollback verification failed"
    return 1
}

# Create rollback record
create_rollback_record() {
    local backup_key=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    log "Creating rollback record..."
    
    local record_file="rollback-records-${ENVIRONMENT}.json"
    
    if [ ! -f "$record_file" ]; then
        echo "[]" > "$record_file"
    fi
    
    # Append rollback record (simple JSON append - not ideal, but works for demo)
    local new_record="{\"timestamp\":\"$timestamp\",\"environment\":\"$ENVIRONMENT\",\"backupKey\":\"$backup_key\",\"reason\":\"${ROLLBACK_REASON:-automated}\",\"executor\":\"${GITHUB_ACTOR:-system}\"}"
    
    # Store in new file (would need jq for proper JSON manipulation)
    echo "$new_record" >> "$record_file"
    
    log "Rollback record created"
}

# Send notifications
send_notifications() {
    local status=$1
    local backup_key=$2
    local message="Rollback of $ENVIRONMENT environment completed"
    
    log "Sending notifications..."
    
    # Send Slack notification if webhook configured
    if [ -n "$NOTIFICATION_SLACK" ]; then
        local color="good"
        local emoji="✅"
        
        if [ "$status" != "0" ]; then
            color="danger"
            emoji="❌"
        fi
        
        local payload="{
            \"blocks\": [
                {
                    \"type\": \"section\",
                    \"text\": {
                        \"type\": \"mrkdwn\",
                        \"text\": \"$emoji *${ENVIRONMENT^^} Rollback Executed*\\nBackup: \`$backup_key\`\\nTime: $(date)\"
                    }
                },
                {
                    \"type\": \"section\",
                    \"text\": {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Status:* $([[ $status -eq 0 ]] && echo \"Success\" || echo \"Failed\")\n*URL:* ${ENV_CONFIG[${ENVIRONMENT}_url]}\"
                    }
                }
            ]
        }"
        
        curl -X POST "$NOTIFICATION_SLACK" \
            -H 'Content-Type: application/json' \
            -d "$payload" \
            2>/dev/null || warn "Failed to send Slack notification"
    fi
    
    # Create GitHub issue if rollback failed
    if [ "$status" != "0" ] && [ -n "$GITHUB_TOKEN" ]; then
        info "Would create GitHub issue for rollback failure"
    fi
}

# Generate rollback report
generate_report() {
    local backup_key=$1
    local status=$2
    
    log "Generating rollback report..."
    
    local report_file="rollback-report-${ENVIRONMENT}-$(date +%Y%m%d_%H%M%S).html"
    
    local status_text="SUCCESS"
    local status_color="#4CAF50"
    
    if [ "$status" != "0" ]; then
        status_text="FAILED"
        status_color="#f44336"
    fi
    
    cat > "$report_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Rollback Report - $ENVIRONMENT</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .report { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        .status-box { padding: 20px; border-radius: 8px; background: $status_color; color: white; margin: 20px 0; font-size: 24px; font-weight: bold; }
        .details { background: #f9f9f9; padding: 15px; margin: 15px 0; border-left: 4px solid $status_color; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #555; color: white; }
    </style>
</head>
<body>
    <div class="report">
        <h1>🔄 Rollback Report</h1>
        <div class="status-box">Status: $status_text</div>
        
        <div class="details">
            <h2>Rollback Details</h2>
            <table>
                <tr>
                    <th>Property</th>
                    <th>Value</th>
                </tr>
                <tr>
                    <td>Environment</td>
                    <td>$ENVIRONMENT</td>
                </tr>
                <tr>
                    <td>Backup Restored</td>
                    <td>$backup_key</td>
                </tr>
                <tr>
                    <td>Timestamp</td>
                    <td>$(date -u +%Y-%m-%dT%H:%M:%SZ)</td>
                </tr>
                <tr>
                    <td>Executor</td>
                    <td>${GITHUB_ACTOR:-system}</td>
                </tr>
                <tr>
                    <td>Status</td>
                    <td>$status_text</td>
                </tr>
            </table>
        </div>
    </div>
</body>
</html>
EOF

    log "Report generated: $report_file"
}

# Interactive confirm
confirm_rollback() {
    if [ "$ENVIRONMENT" = "production" ]; then
        warn "⚠️  PRODUCTION ROLLBACK INITIATED ⚠️"
        warn "You are about to rollback PRODUCTION environment"
        warn "This action may affect all users"
        
        read -p "Type 'yes' to confirm production rollback: " confirmation
        
        if [ "$confirmation" != "yes" ]; then
            error "Rollback cancelled"
            exit 1
        fi
        
        log "Production rollback confirmed by user"
    fi
}

# Main execution
main() {
    log "=========================================="
    log "Starting rollback process"
    log "=========================================="
    log "Environment: $ENVIRONMENT"
    log "Time: $(date)"
    
    # Create logs directory
    mkdir -p "$(dirname "$ROLLBACK_LOG")"
    
    validate_environment || exit 1
    check_prerequisites || exit 1
    
    # Confirm before proceeding with production rollback
    confirm_rollback
    
    # List available backups
    list_backups
    
    # Get latest backup
    local backup_key=$(get_latest_backup)
    
    if [ -z "$backup_key" ]; then
        error "No backup found for rollback"
        exit 1
    fi
    
    log "Latest backup identified: $backup_key"
    
    # Verify backup exists
    verify_backup "$backup_key" || exit 1
    
    # Perform rollback
    perform_rollback "$backup_key" || exit 1
    
    # Invalidate CloudFront cache
    invalidate_cloudfront || warn "CloudFront invalidation warning"
    
    log "Waiting for changes to propagate..."
    sleep 15
    
    # Verify rollback success
    local rollback_status=0
    verify_rollback || rollback_status=1
    
    # Create records and reports
    create_rollback_record "$backup_key"
    generate_report "$backup_key" "$rollback_status"
    send_notifications "$rollback_status" "$backup_key"
    
    log "=========================================="
    if [ "$rollback_status" -eq 0 ]; then
        log "Rollback completed successfully!"
        log "Environment URL: ${ENV_CONFIG[${ENVIRONMENT}_url]}"
    else
        log "Rollback completed with warnings"
        error "Please verify environment health manually"
    fi
    log "=========================================="
    log "Rollback logs: $ROLLBACK_LOG"
    
    exit "$rollback_status"
}

# Execute main function
main "$@"
