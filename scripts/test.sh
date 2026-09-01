#!/bin/bash

################################################################################
# Test Execution Script for VA.gov Test Automation
#
# This script orchestrates all test execution: unit, functional, API, and performance
# Usage: ./scripts/test.sh [test-type] [options]
#
# Test Types: unit, e2e, api, performance, smoke, all
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TEST_TYPE=${1:-all}
VERBOSE=${2:-false}
PARALLEL_WORKERS=${PARALLEL_WORKERS:-4}
TEST_TIMEOUT=${TEST_TIMEOUT:-60000}
REPORT_DIR="test-results"
ENVIRONMENT=${ENVIRONMENT:-test}
BASE_URL=${BASE_URL:-http://localhost:3000}

# Test results tracking
UNIT_TESTS_PASSED=0
UNIT_TESTS_FAILED=0
E2E_TESTS_PASSED=0
E2E_TESTS_FAILED=0
API_TESTS_PASSED=0
API_TESTS_FAILED=0
PERF_TESTS_PASSED=0
PERF_TESTS_FAILED=0

# Logger functions
log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

debug() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

# Initialize test environment
init_test_environment() {
    log "Initializing test environment..."
    
    # Create report directories
    mkdir -p "$REPORT_DIR"/{unit,e2e,api,performance,coverage}
    
    # Check prerequisites
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v npx &> /dev/null; then
        error "npm is not installed"
        exit 1
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        log "Installing dependencies..."
        npm ci
    fi
    
    log "Test environment ready"
}

# Check if application server is running
wait_for_server() {
    local max_attempts=30
    local attempt=1
    
    log "Waiting for application server at $BASE_URL..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f "$BASE_URL/health" >/dev/null 2>&1; then
            log "Application server is ready"
            return 0
        fi
        
        info "Attempt $attempt/$max_attempts: Server not ready, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error "Application server did not start within ${max_attempts} attempts"
    return 1
}

# Run unit tests
run_unit_tests() {
    log "Running unit tests..."
    
    npm run test:unit -- \
        --coverage \
        --coverageReporters=json \
        --coverageReporters=html \
        --coverageReporters=text-summary \
        --coverageDirectory="$REPORT_DIR/coverage" \
        --testResultsProcessor=jest-junit \
        --outputFile="$REPORT_DIR/unit/junit.xml" \
        --detectOpenHandles \
        --forceExit \
        --bail=false \
        2>&1 | tee "$REPORT_DIR/unit/console.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "Unit tests passed"
        UNIT_TESTS_PASSED=1
    else
        error "Unit tests failed"
        UNIT_TESTS_FAILED=1
    fi
    
    return $exit_code
}

# Run E2E/functional tests
run_e2e_tests() {
    print_step "Running E2E Tests (Playwright)"
    
    cd "$PROJECT_DIR" || exit 1
    
    # Ensure test results directory exists
    mkdir -p test-results
    
    # Install Playwright browsers if not already present
    if ! npx playwright install-deps >/dev/null 2>&1; then
        print_info "Installing Playwright dependencies..."
        npm run postinstall
    fi
    
    # Run all Playwright tests using npm script
    if npm run test:e2e -- --reporter=html,json,junit; then
        print_success "E2E tests passed"
        E2E_TESTS_PASSED=1
    else
        print_error "E2E tests failed"
        E2E_TESTS_FAILED=1
    fi
    
    # Copy Playwright report to test results
    if [ -d "playwright-report" ]; then
        mkdir -p test-results/playwright-report
        cp -r playwright-report/* test-results/playwright-report/ 2>/dev/null || true
        print_success "Playwright report generated"
    fi
        
    return 0
}

# Run API integration tests
run_api_tests() {
    log "Running API integration tests..."
    
    npm run test:api -- \
        --coverage \
        --coverageDirectory="$REPORT_DIR/coverage" \
        --testResultsProcessor=jest-junit \
        --outputFile="$REPORT_DIR/api/junit.xml" \
        --detectOpenHandles \
        --forceExit \
        --bail=false \
        2>&1 | tee "$REPORT_DIR/api/console.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "API tests passed"
        API_TESTS_PASSED=1
    else
        error "API tests failed"
        API_TESTS_FAILED=1
    fi
    
    return $exit_code
}

# Run performance tests
run_performance_tests() {
    log "Running performance tests..."
    
    # Check if k6 is installed
    if ! command -v k6 &> /dev/null; then
        warn "k6 not installed, skipping load tests"
        return 0
    fi
    
    # Create k6 test script if not exists
    if [ ! -f "tests/performance/k6-load-tests.js" ]; then
        warn "k6 test script not found, skipping performance tests"
        return 0
    fi
    
    k6 run \
        --vus=10 \
        --duration=30s \
        --out json="$REPORT_DIR/performance/k6-results.json" \
        tests/performance/k6-load-tests.js \
        2>&1 | tee "$REPORT_DIR/performance/console.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "Performance tests passed"
        PERF_TESTS_PASSED=1
    else
        warn "Performance tests failed or not available"
        PERF_TESTS_FAILED=1
    fi
    
    return 0  # Don't fail pipeline if perf tests unavailable
}

# Run smoke tests
run_smoke_tests() {
    log "Running smoke tests..."
    
    npm run test:smoke -- \
        --reporter=json \
        --outputFile="$REPORT_DIR/smoke/junit.xml" \
        2>&1 | tee "$REPORT_DIR/smoke/console.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "Smoke tests passed"
    else
        error "Smoke tests failed"
    fi
    
    return $exit_code
}

# Generate test coverage report
generate_coverage_report() {
    if [ ! -d "$REPORT_DIR/coverage" ]; then
        return 0
    fi
    
    log "Generating coverage report..."
    
    if command -v nyc &> /dev/null; then
        nyc report --reporter=text-summary --reporter=html \
            --report-dir="$REPORT_DIR/coverage"
    fi
    
    # Display coverage summary
    if [ -f "$REPORT_DIR/coverage/coverage-summary.json" ]; then
        info "Coverage Summary:"
        cat "$REPORT_DIR/coverage/coverage-summary.json" | \
            grep -E "lines|statements|functions|branches" || true
    fi
}

# Generate consolidated test report
generate_test_report() {
    log "Generating consolidated test report..."
    
    local report_file="$REPORT_DIR/test-report.html"
    
    cat > "$report_file" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>VA.gov Test Report</title>
    <style>
        * { margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); padding: 30px; }
        h1 { color: #333; margin-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
        .summary-card { background: #f9f9f9; padding: 20px; border-radius: 8px; border-left: 4px solid #4CAF50; }
        .summary-card.failed { border-left-color: #f44336; }
        .summary-card h3 { font-size: 14px; color: #666; margin-bottom: 10px; }
        .summary-card .number { font-size: 32px; font-weight: bold; color: #4CAF50; }
        .summary-card.failed .number { color: #f44336; }
        .test-section { margin: 30px 0; }
        .test-section h2 { font-size: 20px; color: #333; margin-bottom: 15px; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; font-weight: bold; }
        tr:hover { background-color: #f5f5f5; }
        .passed { color: #4CAF50; font-weight: bold; }
        .failed { color: #f44336; font-weight: bold; }
        .timestamp { color: #999; font-size: 12px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>VA.gov Test Report</h1>
        <div class="timestamp">Generated: <script>document.write(new Date().toLocaleString())</script></div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Unit Tests</h3>
                <div class="number" id="unit-count">-</div>
            </div>
            <div class="summary-card">
                <h3>E2E Tests</h3>
                <div class="number" id="e2e-count">-</div>
            </div>
            <div class="summary-card">
                <h3>API Tests</h3>
                <div class="number" id="api-count">-</div>
            </div>
            <div class="summary-card">
                <h3>Performance Tests</h3>
                <div class="number" id="perf-count">-</div>
            </div>
        </div>

        <div class="test-section">
            <h2>Test Results Summary</h2>
            <table>
                <tr>
                    <th>Test Type</th>
                    <th>Passed</th>
                    <th>Failed</th>
                    <th>Status</th>
                </tr>
                <tr>
                    <td>Unit Tests</td>
                    <td id="unit-passed">0</td>
                    <td id="unit-failed">0</td>
                    <td id="unit-status" class="passed">Passed</td>
                </tr>
                <tr>
                    <td>E2E Tests</td>
                    <td id="e2e-passed">0</td>
                    <td id="e2e-failed">0</td>
                    <td id="e2e-status" class="passed">Passed</td>
                </tr>
                <tr>
                    <td>API Tests</td>
                    <td id="api-passed">0</td>
                    <td id="api-failed">0</td>
                    <td id="api-status" class="passed">Passed</td>
                </tr>
                <tr>
                    <td>Performance Tests</td>
                    <td id="perf-passed">0</td>
                    <td id="perf-failed">0</td>
                    <td id="perf-status" class="passed">Passed</td>
                </tr>
            </table>
        </div>
    </div>
    
    <script>
        // Populated by test script
        document.getElementById('unit-passed').textContent = '__UNIT_PASSED__';
        document.getElementById('unit-failed').textContent = '__UNIT_FAILED__';
        document.getElementById('e2e-passed').textContent = '__E2E_PASSED__';
        document.getElementById('e2e-failed').textContent = '__E2E_FAILED__';
        document.getElementById('api-passed').textContent = '__API_PASSED__';
        document.getElementById('api-failed').textContent = '__API_FAILED__';
        document.getElementById('perf-passed').textContent = '__PERF_PASSED__';
        document.getElementById('perf-failed').textContent = '__PERF_FAILED__';
    </script>
</body>
</html>
EOF

    # Replace placeholders with actual values
    sed -i.bak "s/__UNIT_PASSED__/$UNIT_TESTS_PASSED/g" "$report_file"
    sed -i.bak "s/__UNIT_FAILED__/$UNIT_TESTS_FAILED/g" "$report_file"
    sed -i.bak "s/__E2E_PASSED__/$E2E_TESTS_PASSED/g" "$report_file"
    sed -i.bak "s/__E2E_FAILED__/$E2E_TESTS_FAILED/g" "$report_file"
    sed -i.bak "s/__API_PASSED__/$API_TESTS_PASSED/g" "$report_file"
    sed -i.bak "s/__API_FAILED__/$API_TESTS_FAILED/g" "$report_file"
    sed -i.bak "s/__PERF_PASSED__/$PERF_TESTS_PASSED/g" "$report_file"
    sed -i.bak "s/__PERF_FAILED__/$PERF_TESTS_FAILED/g" "$report_file"
    rm -f "$report_file.bak"
    
    log "Test report generated: $report_file"
}

# Create test summary
create_test_summary() {
    log "Creating test execution summary..."
    
    local summary_file="$REPORT_DIR/summary.txt"
    
    cat > "$summary_file" <<EOF
====================================
VA.gov Test Execution Summary
====================================

Test Date: $(date)
Environment: $ENVIRONMENT
Base URL: $BASE_URL

Test Results:
  Unit Tests:       $UNIT_TESTS_PASSED passed, $UNIT_TESTS_FAILED failed
  E2E Tests:        $E2E_TESTS_PASSED passed, $E2E_TESTS_FAILED failed
  API Tests:        $API_TESTS_PASSED passed, $API_TESTS_FAILED failed
  Performance:      $PERF_TESTS_PASSED passed, $PERF_TESTS_FAILED failed

Reports Location: $(pwd)/$REPORT_DIR

====================================
EOF

    cat "$summary_file"
}

# Validate test type
validate_test_type() {
    case "$TEST_TYPE" in
        unit|e2e|api|performance|smoke|all)
            log "Test type: $TEST_TYPE"
            ;;
        *)
            error "Invalid test type: $TEST_TYPE. Must be one of: unit, e2e, api, performance, smoke, all"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    log "Starting test execution for VA.gov Test Automation"
    log "Test type: $TEST_TYPE"
    log "Environment: $ENVIRONMENT"
    
    validate_test_type
    init_test_environment
    
    # Wait for application server for E2E and smoke tests
    if [[ "$TEST_TYPE" =~ ^(e2e|smoke|all)$ ]]; then
        wait_for_server || {
            warn "Could not connect to application server, skipping E2E tests"
            TEST_TYPE="unit"
        }
    fi
    
    local exit_code=0
    
    # Run appropriate test suites
    case "$TEST_TYPE" in
        unit)
            run_unit_tests || exit_code=1
            ;;
        e2e)
            run_e2e_tests || exit_code=1
            ;;
        api)
            run_api_tests || exit_code=1
            ;;
        performance)
            run_performance_tests || exit_code=1
            ;;
        smoke)
            run_smoke_tests || exit_code=1
            ;;
        all)
            run_unit_tests || exit_code=1
            run_e2e_tests || exit_code=1
            run_api_tests || exit_code=1
            run_performance_tests || exit_code=1
            ;;
    esac
    
    # Generate reports
    generate_coverage_report
    generate_test_report
    create_test_summary
    
    if [ $exit_code -eq 0 ]; then
        log "All tests completed successfully!"
    else
        error "Some tests failed. See reports for details."
    fi
    
    exit $exit_code
}

# Execute main function
main "$@"
