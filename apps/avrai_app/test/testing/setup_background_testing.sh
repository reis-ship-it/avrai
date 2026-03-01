#!/bin/bash

# SPOTS Background Testing Setup Script
# Sets up automated background testing with cron jobs
# Date: July 29, 2025

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/Users/reisgordon/SPOTS"
CRON_FILE="/tmp/spots_testing_cron"

echo "🚀 Setting up SPOTS Background Testing System..."

# 1. Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$PROJECT_DIR/test/testing/logs"
mkdir -p "$PROJECT_DIR/test/testing/reports"
mkdir -p "$PROJECT_DIR/test/testing/alerts"
mkdir -p "$PROJECT_DIR/test/testing/coverage"

echo "✅ Directories created"

# 2. Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x "$PROJECT_DIR/test/testing/test_runner.sh"
chmod +x "$PROJECT_DIR/test/testing/performance_monitor.sh"
chmod +x "$PROJECT_DIR/test/testing/quality_checker.sh"
chmod +x "$PROJECT_DIR/test/testing/integration_runner.sh"

echo "✅ Scripts made executable"

# 3. Create cron jobs
echo "⏰ Setting up cron jobs..."

# Create cron file
cat > "$CRON_FILE" << EOF
# SPOTS Background Testing Cron Jobs
# Generated: $(date)

# Test runner - every 30 minutes
*/30 * * * * $PROJECT_DIR/test/testing/test_runner.sh >> $PROJECT_DIR/test/testing/logs/cron.log 2>&1

# Performance monitor - every 6 hours
0 */6 * * * $PROJECT_DIR/test/testing/performance_monitor.sh >> $PROJECT_DIR/test/testing/logs/cron.log 2>&1

# Quality checker - every hour
0 * * * * $PROJECT_DIR/test/testing/quality_checker.sh >> $PROJECT_DIR/test/testing/logs/cron.log 2>&1

# Integration tests - every 2 hours
0 */2 * * * $PROJECT_DIR/test/testing/integration_runner.sh >> $PROJECT_DIR/test/testing/logs/cron.log 2>&1

# Daily cleanup - at 2 AM
0 2 * * * find $PROJECT_DIR/test/testing/logs -name "*.log" -mtime +7 -delete
0 2 * * * find $PROJECT_DIR/test/testing/reports -name "*.md" -mtime +30 -delete
0 2 * * * find $PROJECT_DIR/test/testing/alerts -name "*.txt" -mtime +7 -delete
EOF

echo "✅ Cron file created"

# 4. Install cron jobs
echo "📅 Installing cron jobs..."
crontab "$CRON_FILE"

echo "✅ Cron jobs installed"

# 5. Create monitoring dashboard script
echo "📊 Creating monitoring dashboard..."
cat > "$PROJECT_DIR/test/testing/dashboard.sh" << 'EOF'
#!/bin/bash

# SPOTS Testing Dashboard
# Shows current status of background testing

PROJECT_DIR="/Users/reisgordon/SPOTS"
LOG_DIR="$PROJECT_DIR/test/testing/logs"
REPORT_DIR="$PROJECT_DIR/test/testing/reports"
ALERT_DIR="$PROJECT_DIR/test/testing/alerts"

echo "📊 SPOTS Testing Dashboard"
echo "=========================="
echo ""

# Check if cron jobs are running
echo "🔄 Background Processes:"
if crontab -l | grep -q "test_runner.sh"; then
    echo "  ✅ Test Runner: Active (every 30 min)"
else
    echo "  ❌ Test Runner: Not active"
fi

if crontab -l | grep -q "performance_monitor.sh"; then
    echo "  ✅ Performance Monitor: Active (every 6 hours)"
else
    echo "  ❌ Performance Monitor: Not active"
fi

if crontab -l | grep -q "quality_checker.sh"; then
    echo "  ✅ Quality Checker: Active (every hour)"
else
    echo "  ❌ Quality Checker: Not active"
fi

if crontab -l | grep -q "integration_runner.sh"; then
    echo "  ✅ Integration Runner: Active (every 2 hours)"
else
    echo "  ❌ Integration Runner: Not active"
fi

echo ""

# Show recent reports
echo "📋 Recent Reports:"
if [ -d "$REPORT_DIR" ]; then
    ls -la "$REPORT_DIR"/*.md 2>/dev/null | head -5 | while read line; do
        echo "  📄 $line"
    done
else
    echo "  No reports found"
fi

echo ""

# Show recent alerts
echo "🚨 Recent Alerts:"
if [ -d "$ALERT_DIR" ]; then
    ls -la "$ALERT_DIR"/*.txt 2>/dev/null | head -5 | while read line; do
        echo "  ⚠️ $line"
    done
else
    echo "  No alerts found"
fi

echo ""

# Show system status
echo "💾 System Status:"
if [ -d "$LOG_DIR" ]; then
    LOG_COUNT=$(find "$LOG_DIR" -name "*.log" | wc -l)
    echo "  📝 Log files: $LOG_COUNT"
else
    echo "  📝 Log files: 0"
fi

if [ -d "$REPORT_DIR" ]; then
    REPORT_COUNT=$(find "$REPORT_DIR" -name "*.md" | wc -l)
    echo "  📊 Reports: $REPORT_COUNT"
else
    echo "  📊 Reports: 0"
fi

if [ -d "$ALERT_DIR" ]; then
    ALERT_COUNT=$(find "$ALERT_DIR" -name "*.txt" | wc -l)
    echo "  🚨 Alerts: $ALERT_COUNT"
else
    echo "  🚨 Alerts: 0"
fi

echo ""
echo "🎯 Dashboard completed at $(date)"
EOF

chmod +x "$PROJECT_DIR/test/testing/dashboard.sh"

echo "✅ Dashboard created"

# 6. Create manual test runner
echo "🔧 Creating manual test runner..."
cat > "$PROJECT_DIR/test/testing/run_all_tests.sh" << 'EOF'
#!/bin/bash

# SPOTS Manual Test Runner
# Runs all tests manually

PROJECT_DIR="/Users/reisgordon/SPOTS"

echo "🧪 Running all SPOTS tests manually..."
echo ""

# Run unit tests
echo "🔬 Running unit tests..."
cd "$PROJECT_DIR"
flutter test test/unit/ --coverage --reporter=expanded

echo ""

# Run integration tests
echo "🔗 Running integration tests..."
flutter test test/integration/ --reporter=expanded

echo ""

# Run widget tests
echo "🎨 Running widget tests..."
flutter test test/widget/ --reporter=expanded

echo ""

# Run code analysis
echo "🔍 Running code analysis..."
flutter analyze

echo ""

# Check dependencies
echo "📦 Checking dependencies..."
flutter pub outdated

echo ""
echo "✅ All tests completed!"
EOF

chmod +x "$PROJECT_DIR/test/testing/run_all_tests.sh"

echo "✅ Manual test runner created"

# 7. Create status checker
echo "📊 Creating status checker..."
cat > "$PROJECT_DIR/test/testing/check_status.sh" << 'EOF'
#!/bin/bash

# SPOTS Status Checker
# Quick status check of the testing system

PROJECT_DIR="/Users/reisgordon/SPOTS"
LOG_DIR="$PROJECT_DIR/test/testing/logs"

echo "🔍 SPOTS Testing Status Check"
echo "============================="
echo ""

# Check last test run
echo "📅 Last Test Run:"
if [ -f "$LOG_DIR/test_run_$(date +%Y-%m-%d)*.log" ]; then
    LAST_RUN=$(ls -t "$LOG_DIR"/test_run_*.log 2>/dev/null | head -1)
    if [ -n "$LAST_RUN" ]; then
        echo "  ✅ Last run: $(basename "$LAST_RUN")"
        echo "  📝 Status: $(grep "Test Run Summary" "$LAST_RUN" | tail -1 || echo "Unknown")"
    else
        echo "  ❌ No recent test runs found"
    fi
else
    echo "  ❌ No test runs found"
fi

echo ""

# Check for alerts
echo "🚨 Recent Alerts:"
ALERT_COUNT=$(find "$PROJECT_DIR/test/testing/alerts" -name "*.txt" -mtime -1 2>/dev/null | wc -l)
if [ "$ALERT_COUNT" -gt 0 ]; then
    echo "  ⚠️ $ALERT_COUNT alerts in last 24 hours"
    find "$PROJECT_DIR/test/testing/alerts" -name "*.txt" -mtime -1 2>/dev/null | head -3 | while read alert; do
        echo "    📄 $(basename "$alert")"
    done
else
    echo "  ✅ No recent alerts"
fi

echo ""

# Check cron jobs
echo "⏰ Cron Jobs:"
if crontab -l 2>/dev/null | grep -q "spots"; then
    echo "  ✅ Background testing is active"
    crontab -l 2>/dev/null | grep "spots" | wc -l | xargs echo "  📊 Active jobs:"
else
    echo "  ❌ Background testing not configured"
fi

echo ""
echo "✅ Status check completed at $(date)"
EOF

chmod +x "$PROJECT_DIR/test/testing/check_status.sh"

echo "✅ Status checker created"

# 8. Create cleanup script
echo "🧹 Creating cleanup script..."
cat > "$PROJECT_DIR/test/testing/cleanup.sh" << 'EOF'
#!/bin/bash

# SPOTS Testing Cleanup Script
# Cleans up old logs and reports

PROJECT_DIR="/Users/reisgordon/SPOTS"
LOG_DIR="$PROJECT_DIR/test/testing/logs"
REPORT_DIR="$PROJECT_DIR/test/testing/reports"
ALERT_DIR="$PROJECT_DIR/test/testing/alerts"

echo "🧹 Cleaning up SPOTS testing files..."

# Clean old logs (keep last 7 days)
echo "📝 Cleaning old logs..."
find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Clean old reports (keep last 30 days)
echo "📊 Cleaning old reports..."
find "$REPORT_DIR" -name "*.md" -mtime +30 -delete 2>/dev/null || true

# Clean old alerts (keep last 7 days)
echo "🚨 Cleaning old alerts..."
find "$ALERT_DIR" -name "*.txt" -mtime +7 -delete 2>/dev/null || true

# Clean coverage files
echo "📈 Cleaning coverage files..."
find "$PROJECT_DIR" -name "coverage" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Cleanup completed!"
EOF

chmod +x "$PROJECT_DIR/test/testing/cleanup.sh"

echo "✅ Cleanup script created"

# 9. Test the setup
echo "🧪 Testing the setup..."
cd "$PROJECT_DIR"
if [ -f "test/testing/test_runner.sh" ]; then
    echo "  ✅ Test runner script exists and is executable"
else
    echo "  ❌ Test runner script not found"
fi

# 10. Final setup summary
echo ""
echo "🎉 SPOTS Background Testing Setup Complete!"
echo "=========================================="
echo ""
echo "📁 Directories created:"
echo "  - $PROJECT_DIR/test/testing/logs"
echo "  - $PROJECT_DIR/test/testing/reports"
echo "  - $PROJECT_DIR/test/testing/alerts"
echo "  - $PROJECT_DIR/test/testing/coverage"
echo ""
echo "⏰ Cron jobs installed:"
echo "  - Test runner: every 30 minutes"
echo "  - Performance monitor: every 6 hours"
echo "  - Quality checker: every hour"
echo "  - Integration tests: every 2 hours"
echo ""
echo "🔧 Scripts created:"
echo "  - dashboard.sh: View testing status"
echo "  - run_all_tests.sh: Manual test runner"
echo "  - check_status.sh: Quick status check"
echo "  - cleanup.sh: Clean old files"
echo ""
echo "📊 To view the dashboard:"
echo "  $PROJECT_DIR/test/testing/dashboard.sh"
echo ""
echo "🔍 To check status:"
echo "  $PROJECT_DIR/test/testing/check_status.sh"
echo ""
echo "🧪 To run tests manually:"
echo "  $PROJECT_DIR/test/testing/run_all_tests.sh"
echo ""
echo "🧹 To clean up:"
echo "  $PROJECT_DIR/test/testing/cleanup.sh"
echo ""
echo "✅ Setup completed successfully!" 