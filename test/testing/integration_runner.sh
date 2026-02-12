#!/bin/bash

# SPOTS Integration Test Runner Script
# Runs every 2 hours for integration testing
# Date: July 29, 2025

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/Users/reisgordon/SPOTS"
LOG_DIR="$PROJECT_DIR/test/testing/logs"
REPORT_DIR="$PROJECT_DIR/test/testing/reports"
ALERT_DIR="$PROJECT_DIR/test/testing/alerts"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"
mkdir -p "$ALERT_DIR"

# Log file for this run
LOG_FILE="$LOG_DIR/integration_$TIMESTAMP.log"
REPORT_FILE="$REPORT_DIR/integration_report_$TIMESTAMP.md"

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to create alert
create_alert() {
    local alert_type="$1"
    local message="$2"
    local alert_file="$ALERT_DIR/${alert_type}_${TIMESTAMP}.txt"
    echo "[$alert_type] $message" > "$alert_file"
    log_message "ALERT: $alert_type - $message"
}

# Function to run test category
run_test_category() {
    local category="$1"
    local test_path="$2"
    local log_file="$LOG_DIR/${category}_$TIMESTAMP.log"
    
    log_message "Running $category tests..."
    
    if flutter test "$test_path" --reporter=expanded > "$log_file" 2>&1; then
        log_message "✅ $category tests passed"
        echo "PASS"
    else
        log_message "❌ $category tests failed"
        create_alert "WARNING" "$category tests failed - check $log_file"
        echo "FAIL"
    fi
}

# Function to count test results
count_test_results() {
    local log_file="$1"
    local passed=$(grep -c "PASSED" "$log_file" 2>/dev/null || echo "0")
    local failed=$(grep -c "FAILED" "$log_file" 2>/dev/null || echo "0")
    local skipped=$(grep -c "SKIPPED" "$log_file" 2>/dev/null || echo "0")
    echo "$passed|$failed|$skipped"
}

# Start integration testing
log_message "=== SPOTS Integration Test Runner Started ==="
log_message "Timestamp: $TIMESTAMP"
log_message "Project Directory: $PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

# 1. Run Integration Tests
log_message "Running integration tests..."
INTEGRATION_RESULT=$(run_test_category "integration" "test/integration/")

# 2. Run Widget Tests
log_message "Running widget tests..."
WIDGET_RESULT=$(run_test_category "widget" "test/widget/")

# 3. Run BLoC Tests (if they exist)
log_message "Running BLoC tests..."
if [ -d "test/unit/blocs" ]; then
    BLOC_RESULT=$(run_test_category "blocs" "test/unit/blocs/")
else
    log_message "⚠️ No BLoC tests found"
    BLOC_RESULT="SKIP"
fi

# 4. Run Repository Integration Tests
log_message "Running repository integration tests..."
REPOSITORY_RESULT=$(run_test_category "repository" "test/unit/data/repositories/")

# 5. Run Data Source Integration Tests
log_message "Running data source integration tests..."
DATASOURCE_RESULT=$(run_test_category "datasource" "test/unit/data/datasources/")

# 6. Count Test Results
log_message "Analyzing test results..."
INTEGRATION_COUNTS=$(count_test_results "$LOG_DIR/integration_$TIMESTAMP.log")
WIDGET_COUNTS=$(count_test_results "$LOG_DIR/widget_$TIMESTAMP.log")
REPOSITORY_COUNTS=$(count_test_results "$LOG_DIR/repository_$TIMESTAMP.log")
DATASOURCE_COUNTS=$(count_test_results "$LOG_DIR/datasource_$TIMESTAMP.log")

# Parse counts
INTEGRATION_PASSED=$(echo "$INTEGRATION_COUNTS" | cut -d'|' -f1)
INTEGRATION_FAILED=$(echo "$INTEGRATION_COUNTS" | cut -d'|' -f2)
INTEGRATION_SKIPPED=$(echo "$INTEGRATION_COUNTS" | cut -d'|' -f3)

WIDGET_PASSED=$(echo "$WIDGET_COUNTS" | cut -d'|' -f1)
WIDGET_FAILED=$(echo "$WIDGET_COUNTS" | cut -d'|' -f2)
WIDGET_SKIPPED=$(echo "$WIDGET_COUNTS" | cut -d'|' -f3)

REPOSITORY_PASSED=$(echo "$REPOSITORY_COUNTS" | cut -d'|' -f1)
REPOSITORY_FAILED=$(echo "$REPOSITORY_COUNTS" | cut -d'|' -f2)
REPOSITORY_SKIPPED=$(echo "$REPOSITORY_COUNTS" | cut -d'|' -f3)

DATASOURCE_PASSED=$(echo "$DATASOURCE_COUNTS" | cut -d'|' -f1)
DATASOURCE_FAILED=$(echo "$DATASOURCE_COUNTS" | cut -d'|' -f2)
DATASOURCE_SKIPPED=$(echo "$DATASOURCE_COUNTS" | cut -d'|' -f3)

# Calculate totals
TOTAL_PASSED=$((INTEGRATION_PASSED + WIDGET_PASSED + REPOSITORY_PASSED + DATASOURCE_PASSED))
TOTAL_FAILED=$((INTEGRATION_FAILED + WIDGET_FAILED + REPOSITORY_FAILED + DATASOURCE_FAILED))
TOTAL_SKIPPED=$((INTEGRATION_SKIPPED + WIDGET_SKIPPED + REPOSITORY_SKIPPED + DATASOURCE_SKIPPED))
TOTAL_TESTS=$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))

# Calculate success rate
if [ "$TOTAL_TESTS" -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=1; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc -l)
else
    SUCCESS_RATE=0
fi

log_message "📊 Test Results Summary:"
log_message "  Total Tests: $TOTAL_TESTS"
log_message "  Passed: $TOTAL_PASSED"
log_message "  Failed: $TOTAL_FAILED"
log_message "  Skipped: $TOTAL_SKIPPED"
log_message "  Success Rate: ${SUCCESS_RATE}%"

# 7. Check for Specific Integration Issues
log_message "Checking for specific integration issues..."

# Check for connectivity issues
CONNECTIVITY_ISSUES=$(grep -c "connectivity\|network" "$LOG_DIR"/*"$TIMESTAMP"*.log 2>/dev/null || echo "0")
if [ "$CONNECTIVITY_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $CONNECTIVITY_ISSUES connectivity-related test failures"
fi

# Check for database issues
DATABASE_ISSUES=$(grep -c "database\|sembast\|storage" "$LOG_DIR"/*"$TIMESTAMP"*.log 2>/dev/null || echo "0")
if [ "$DATABASE_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $DATABASE_ISSUES database-related test failures"
fi

# Check for BLoC issues
BLOC_ISSUES=$(grep -c "bloc\|state\|event" "$LOG_DIR"/*"$TIMESTAMP"*.log 2>/dev/null || echo "0")
if [ "$BLOC_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $BLOC_ISSUES BLoC-related test failures"
fi

# Check for UI issues
UI_ISSUES=$(grep -c "widget\|ui\|render" "$LOG_DIR"/*"$TIMESTAMP"*.log 2>/dev/null || echo "0")
if [ "$UI_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $UI_ISSUES UI-related test failures"
fi

# 8. Test Component Interactions
log_message "Testing component interactions..."

# Test Auth + Lists interaction
log_message "Testing Auth + Lists integration..."
if [ -f "test/integration/auth_lists_integration_test.dart" ]; then
    if flutter test test/integration/auth_lists_integration_test.dart > "$LOG_DIR/auth_lists_$TIMESTAMP.log" 2>&1; then
        log_message "✅ Auth + Lists integration passed"
        AUTH_LISTS_RESULT="PASS"
    else
        log_message "❌ Auth + Lists integration failed"
        AUTH_LISTS_RESULT="FAIL"
        create_alert "WARNING" "Auth + Lists integration failed"
    fi
else
    log_message "⚠️ Auth + Lists integration test file not found (skipping)"
    AUTH_LISTS_RESULT="SKIP"
fi

# Test Lists + Spots interaction
log_message "Testing Lists + Spots integration..."
if [ -f "test/integration/lists_spots_integration_test.dart" ]; then
    if flutter test test/integration/lists_spots_integration_test.dart > "$LOG_DIR/lists_spots_$TIMESTAMP.log" 2>&1; then
        log_message "✅ Lists + Spots integration passed"
        LISTS_SPOTS_RESULT="PASS"
    else
        log_message "❌ Lists + Spots integration failed"
        LISTS_SPOTS_RESULT="FAIL"
        create_alert "WARNING" "Lists + Spots integration failed"
    fi
else
    log_message "⚠️ Lists + Spots integration test file not found (skipping)"
    LISTS_SPOTS_RESULT="SKIP"
fi

# Test Offline + Online sync
log_message "Testing Offline + Online sync..."
if flutter test test/integration/offline_online_sync_test.dart > "$LOG_DIR/offline_sync_$TIMESTAMP.log" 2>&1; then
    log_message "✅ Offline + Online sync passed"
    OFFLINE_SYNC_RESULT="PASS"
else
    log_message "❌ Offline + Online sync failed"
    OFFLINE_SYNC_RESULT="FAIL"
    create_alert "WARNING" "Offline + Online sync failed"
fi

# 9. Test Error Handling
log_message "Testing error handling scenarios..."

# Test network error handling
log_message "Testing network error handling..."
if [ -f "test/integration/network_error_test.dart" ]; then
    if flutter test test/integration/network_error_test.dart > "$LOG_DIR/network_error_$TIMESTAMP.log" 2>&1; then
        log_message "✅ Network error handling passed"
        NETWORK_ERROR_RESULT="PASS"
    else
        log_message "❌ Network error handling failed"
        NETWORK_ERROR_RESULT="FAIL"
        create_alert "WARNING" "Network error handling failed"
    fi
else
    log_message "⚠️ Network error handling test file not found (skipping)"
    NETWORK_ERROR_RESULT="SKIP"
fi

# Test database error handling
log_message "Testing database error handling..."
if [ -f "test/integration/database_error_test.dart" ]; then
    if flutter test test/integration/database_error_test.dart > "$LOG_DIR/database_error_$TIMESTAMP.log" 2>&1; then
        log_message "✅ Database error handling passed"
        DATABASE_ERROR_RESULT="PASS"
    else
        log_message "❌ Database error handling failed"
        DATABASE_ERROR_RESULT="FAIL"
        create_alert "WARNING" "Database error handling failed"
    fi
else
    log_message "⚠️ Database error handling test file not found (skipping)"
    DATABASE_ERROR_RESULT="SKIP"
fi

# 10. Generate Integration Report
log_message "Generating integration report..."
cat > "$REPORT_FILE" << EOF
# SPOTS Integration Test Report
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Success Rate:** ${SUCCESS_RATE}%

## Test Results Summary

### Overall Statistics
- **Total Tests:** $TOTAL_TESTS
- **Passed:** $TOTAL_PASSED
- **Failed:** $TOTAL_FAILED
- **Skipped:** $TOTAL_SKIPPED
- **Success Rate:** ${SUCCESS_RATE}%

### Test Categories
| Category | Status | Passed | Failed | Skipped |
|----------|--------|--------|--------|---------|
| Integration | $INTEGRATION_RESULT | $INTEGRATION_PASSED | $INTEGRATION_FAILED | $INTEGRATION_SKIPPED |
| Widget | $WIDGET_RESULT | $WIDGET_PASSED | $WIDGET_FAILED | $WIDGET_SKIPPED |
| Repository | $REPOSITORY_RESULT | $REPOSITORY_PASSED | $REPOSITORY_FAILED | $REPOSITORY_SKIPPED |
| Data Source | $DATASOURCE_RESULT | $DATASOURCE_PASSED | $DATASOURCE_FAILED | $DATASOURCE_SKIPPED |
| BLoC | $BLOC_RESULT | - | - | - |

### Component Integration Tests
| Integration | Status |
|-------------|--------|
| Auth + Lists | $AUTH_LISTS_RESULT |
| Lists + Spots | $LISTS_SPOTS_RESULT |
| Offline + Online Sync | $OFFLINE_SYNC_RESULT |

### Error Handling Tests
| Scenario | Status |
|----------|--------|
| Network Error | $NETWORK_ERROR_RESULT |
| Database Error | $DATABASE_ERROR_RESULT |

## Issue Analysis

### Specific Issues Found
- **Connectivity Issues:** $CONNECTIVITY_ISSUES
- **Database Issues:** $DATABASE_ISSUES
- **BLoC Issues:** $BLOC_ISSUES
- **UI Issues:** $UI_ISSUES

## Log Files
- **Integration Log:** \`$LOG_FILE\`
- **Integration Tests:** \`$LOG_DIR/integration_$TIMESTAMP.log\`
- **Widget Tests:** \`$LOG_DIR/widget_$TIMESTAMP.log\`
- **Repository Tests:** \`$LOG_DIR/repository_$TIMESTAMP.log\`
- **Data Source Tests:** \`$LOG_DIR/datasource_$TIMESTAMP.log\`
- **Auth + Lists:** \`$LOG_DIR/auth_lists_$TIMESTAMP.log\`
- **Lists + Spots:** \`$LOG_DIR/lists_spots_$TIMESTAMP.log\`
- **Offline Sync:** \`$LOG_DIR/offline_sync_$TIMESTAMP.log\`
- **Network Error:** \`$LOG_DIR/network_error_$TIMESTAMP.log\`
- **Database Error:** \`$LOG_DIR/database_error_$TIMESTAMP.log\`

## Alerts Generated
$(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0") alerts

## Recommendations

### Immediate Actions
- Fix any failed integration tests
- Address connectivity issues
- Resolve database integration problems
- Fix BLoC state management issues

### Improvement Areas
- Increase test coverage for new features
- Add more error handling scenarios
- Improve offline/online sync testing
- Add performance integration tests

### Success Targets
- **Target Success Rate:** >95%
- **Target Integration Coverage:** >80%
- **Target Error Handling:** 100% coverage
- **Target Component Integration:** 100% coverage
EOF

log_message "✅ Integration report generated: $REPORT_FILE"

# 11. Final Summary
log_message "=== Integration Test Runner Summary ==="
log_message "Success Rate: ${SUCCESS_RATE}%"
log_message "Total Tests: $TOTAL_TESTS"
log_message "Passed: $TOTAL_PASSED"
log_message "Failed: $TOTAL_FAILED"
log_message "Integration: $INTEGRATION_RESULT"
log_message "Widget: $WIDGET_RESULT"
log_message "Repository: $REPOSITORY_RESULT"
log_message "Data Source: $DATASOURCE_RESULT"
log_message "Alerts: $(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0")"
log_message "=== Integration Test Runner Completed ==="

# Exit with appropriate code
if [ "$SUCCESS_RATE" -lt 80 ] || [ "$TOTAL_FAILED" -gt 5 ]; then
    exit 1
else
    exit 0
fi 