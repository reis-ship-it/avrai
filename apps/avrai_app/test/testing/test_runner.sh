#!/bin/bash

# SPOTS Test Runner Script
# Runs every 30 minutes for continuous testing
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
LOG_FILE="$LOG_DIR/test_run_$TIMESTAMP.log"
REPORT_FILE="$REPORT_DIR/test_report_$TIMESTAMP.md"

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

# Start test run
log_message "=== SPOTS Test Runner Started ==="
log_message "Timestamp: $TIMESTAMP"
log_message "Project Directory: $PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

# 1. Run Flutter Tests
log_message "Running Flutter tests..."
if flutter test --coverage --reporter=expanded > "$LOG_DIR/flutter_tests_$TIMESTAMP.log" 2>&1; then
    log_message "✅ Flutter tests completed successfully"
    TEST_RESULT="PASS"
else
    log_message "❌ Flutter tests failed"
    TEST_RESULT="FAIL"
    create_alert "CRITICAL" "Flutter tests failed - check $LOG_DIR/flutter_tests_$TIMESTAMP.log"
fi

# 2. Run Code Analysis
log_message "Running code analysis..."
if flutter analyze > "$LOG_DIR/analysis_$TIMESTAMP.log" 2>&1; then
    log_message "✅ Code analysis completed successfully"
    ANALYSIS_RESULT="PASS"
else
    log_message "❌ Code analysis found issues"
    ANALYSIS_RESULT="FAIL"
    create_alert "WARNING" "Code analysis found issues - check $LOG_DIR/analysis_$TIMESTAMP.log"
fi

# 3. Check for Outdated Dependencies
log_message "Checking for outdated dependencies..."
flutter pub outdated > "$LOG_DIR/dependencies_$TIMESTAMP.log" 2>&1
if grep -q "No outdated packages" "$LOG_DIR/dependencies_$TIMESTAMP.log"; then
    log_message "✅ All dependencies are up to date"
    DEPENDENCIES_RESULT="UP_TO_DATE"
else
    log_message "⚠️ Some dependencies are outdated"
    DEPENDENCIES_RESULT="OUTDATED"
    create_alert "INFO" "Some dependencies are outdated - check $LOG_DIR/dependencies_$TIMESTAMP.log"
fi

# 4. Generate Test Coverage Report
log_message "Generating coverage report..."
if [ -d "coverage" ]; then
    # Convert coverage data to HTML report
    genhtml coverage/lcov.info -o coverage/html > "$LOG_DIR/coverage_$TIMESTAMP.log" 2>&1
    log_message "✅ Coverage report generated"
else
    log_message "⚠️ No coverage data found"
fi

# 5. Check Test Coverage Percentage
if [ -f "coverage/lcov.info" ]; then
    COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines......:" | cut -d'%' -f1 | awk '{print $3}')
    log_message "📊 Test Coverage: ${COVERAGE_PERCENT}%"
    
    # Alert if coverage is low
    if (( $(echo "$COVERAGE_PERCENT < 80" | bc -l) )); then
        create_alert "WARNING" "Test coverage is low: ${COVERAGE_PERCENT}%"
    fi
else
    COVERAGE_PERCENT="N/A"
    log_message "📊 Test Coverage: N/A (no coverage data)"
fi

# 6. Count Linting Issues
LINT_ISSUES=$(grep -c "info\|warning\|error" "$LOG_DIR/analysis_$TIMESTAMP.log" || echo "0")
log_message "🔍 Linting Issues Found: $LINT_ISSUES"

# Alert if too many linting issues
if [ "$LINT_ISSUES" -gt 50 ]; then
    create_alert "WARNING" "High number of linting issues: $LINT_ISSUES"
fi

# 7. Generate Summary Report
log_message "Generating summary report..."
cat > "$REPORT_FILE" << EOF
# SPOTS Test Run Report
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Duration:** $(($(date +%s) - $(date -d "$TIMESTAMP" +%s))) seconds

## Test Results
- **Flutter Tests:** $TEST_RESULT
- **Code Analysis:** $ANALYSIS_RESULT
- **Dependencies:** $DEPENDENCIES_RESULT
- **Test Coverage:** ${COVERAGE_PERCENT}%
- **Linting Issues:** $LINT_ISSUES

## Log Files
- **Test Log:** \`$LOG_FILE\`
- **Flutter Tests:** \`$LOG_DIR/flutter_tests_$TIMESTAMP.log\`
- **Code Analysis:** \`$LOG_DIR/analysis_$TIMESTAMP.log\`
- **Dependencies:** \`$LOG_DIR/dependencies_$TIMESTAMP.log\`
- **Coverage:** \`$LOG_DIR/coverage_$TIMESTAMP.log\`

## Alerts Generated
$(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0") alerts

## Next Steps
- Review any failed tests
- Address linting issues
- Update outdated dependencies if needed
- Improve test coverage if below 80%
EOF

log_message "✅ Summary report generated: $REPORT_FILE"

# 8. Cleanup old logs (keep last 7 days)
find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
find "$REPORT_DIR" -name "*.md" -mtime +7 -delete 2>/dev/null || true
find "$ALERT_DIR" -name "*.txt" -mtime +7 -delete 2>/dev/null || true

# 9. Final Summary
log_message "=== Test Run Summary ==="
log_message "Tests: $TEST_RESULT"
log_message "Analysis: $ANALYSIS_RESULT"
log_message "Dependencies: $DEPENDENCIES_RESULT"
log_message "Coverage: ${COVERAGE_PERCENT}%"
log_message "Linting Issues: $LINT_ISSUES"
log_message "Alerts: $(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0")"
log_message "=== Test Runner Completed ==="

# Exit with appropriate code
if [ "$TEST_RESULT" = "FAIL" ] || [ "$ANALYSIS_RESULT" = "FAIL" ]; then
    exit 1
else
    exit 0
fi 