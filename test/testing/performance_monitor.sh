#!/bin/bash

# SPOTS Performance Monitor Script
# Runs every 6 hours for performance monitoring
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
LOG_FILE="$LOG_DIR/performance_$TIMESTAMP.log"
REPORT_FILE="$REPORT_DIR/performance_report_$TIMESTAMP.md"

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

# Function to get system metrics
get_system_metrics() {
    # Memory usage
    MEMORY_USAGE=$(ps aux | grep -i flutter | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
    MEMORY_USAGE=${MEMORY_USAGE:-0}
    
    # CPU usage
    CPU_USAGE=$(ps aux | grep -i flutter | grep -v grep | awk '{sum+=$3} END {print sum}')
    CPU_USAGE=${CPU_USAGE:-0}
    
    # Disk usage
    DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    
    echo "$MEMORY_USAGE|$CPU_USAGE|$DISK_USAGE"
}

# Function to measure startup time
measure_startup_time() {
    log_message "Measuring app startup time..."
    
    START_TIME=$(date +%s.%N)
    
    # Run app in profile mode and measure startup
    timeout 30s flutter run --profile --dart-define=performance=true --dart-define=startup_test=true > "$LOG_DIR/startup_$TIMESTAMP.log" 2>&1 &
    STARTUP_PID=$!
    
    # Wait for app to start (look for specific startup indicator)
    local startup_complete=false
    local attempts=0
    while [ $attempts -lt 30 ] && [ "$startup_complete" = false ]; do
        if grep -q "App started successfully" "$LOG_DIR/startup_$TIMESTAMP.log" 2>/dev/null; then
            startup_complete=true
        fi
        sleep 1
        attempts=$((attempts + 1))
    done
    
    END_TIME=$(date +%s.%N)
    STARTUP_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
    
    # Kill the app if it's still running
    kill $STARTUP_PID 2>/dev/null || true
    
    echo "$STARTUP_TIME"
}

# Function to test database performance
test_database_performance() {
    log_message "Testing database performance..."
    
    # Create a simple database performance test
    cat > "$LOG_DIR/db_test_$TIMESTAMP.dart" << 'EOF'
import 'dart:io';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init('perf_test');
  final box = GetStorage('perf_test');
  
  // Test write performance
  final writeStart = DateTime.now();
  for (int i = 0; i < 1000; i++) {
    await box.write('key_$i', {'id': i, 'data': 'test_data_$i'});
  }
  final writeEnd = DateTime.now();
  final writeTime = writeEnd.difference(writeStart).inMilliseconds;
  
  // Test read performance
  final readStart = DateTime.now();
  int count = 0;
  for (int i = 0; i < 1000; i++) {
    final val = box.read('key_$i');
    if (val != null) count++;
  }
  final readEnd = DateTime.now();
  final readTime = readEnd.difference(readStart).inMilliseconds;
  
  print('Write time: ${writeTime}ms');
  print('Read time: ${readTime}ms');
  print('Records: $count');
  
  await box.erase();
}
EOF
    
    # Run the database test
    cd "$PROJECT_DIR"
    dart "$LOG_DIR/db_test_$TIMESTAMP.dart" > "$LOG_DIR/db_performance_$TIMESTAMP.log" 2>&1
    
    # Extract performance metrics
    WRITE_TIME=$(grep "Write time:" "$LOG_DIR/db_performance_$TIMESTAMP.log" | awk '{print $3}' | sed 's/ms//')
    READ_TIME=$(grep "Read time:" "$LOG_DIR/db_performance_$TIMESTAMP.log" | awk '{print $3}' | sed 's/ms//')
    
    echo "$WRITE_TIME|$READ_TIME"
}

# Start performance monitoring
log_message "=== SPOTS Performance Monitor Started ==="
log_message "Timestamp: $TIMESTAMP"
log_message "Project Directory: $PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

# 1. Get System Metrics
log_message "Collecting system metrics..."
SYSTEM_METRICS=$(get_system_metrics)
MEMORY_USAGE=$(echo "$SYSTEM_METRICS" | cut -d'|' -f1)
CPU_USAGE=$(echo "$SYSTEM_METRICS" | cut -d'|' -f2)
DISK_USAGE=$(echo "$SYSTEM_METRICS" | cut -d'|' -f3)

log_message "📊 System Metrics:"
log_message "  Memory Usage: ${MEMORY_USAGE}MB"
log_message "  CPU Usage: ${CPU_USAGE}%"
log_message "  Disk Usage: ${DISK_USAGE}%"

# Alert if metrics are high
if (( $(echo "$MEMORY_USAGE > 500" | bc -l) )); then
    create_alert "WARNING" "High memory usage: ${MEMORY_USAGE}MB"
fi

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    create_alert "WARNING" "High CPU usage: ${CPU_USAGE}%"
fi

if [ "$DISK_USAGE" -gt 90 ]; then
    create_alert "CRITICAL" "High disk usage: ${DISK_USAGE}%"
fi

# 2. Measure Startup Time
STARTUP_TIME=$(measure_startup_time)
log_message "🚀 App Startup Time: ${STARTUP_TIME}s"

# Alert if startup is slow
if (( $(echo "$STARTUP_TIME > 5" | bc -l) )); then
    create_alert "WARNING" "Slow app startup: ${STARTUP_TIME}s"
fi

# 3. Test Database Performance
log_message "Testing database performance..."
DB_METRICS=$(test_database_performance)
WRITE_TIME=$(echo "$DB_METRICS" | cut -d'|' -f1)
READ_TIME=$(echo "$DB_METRICS" | cut -d'|' -f2)

log_message "💾 Database Performance:"
log_message "  Write Time: ${WRITE_TIME}ms"
log_message "  Read Time: ${READ_TIME}ms"

# Alert if database is slow
if [ "$WRITE_TIME" -gt 1000 ]; then
    create_alert "WARNING" "Slow database writes: ${WRITE_TIME}ms"
fi

if [ "$READ_TIME" -gt 500 ]; then
    create_alert "WARNING" "Slow database reads: ${READ_TIME}ms"
fi

# 4. Test Network Performance (if possible)
log_message "Testing network performance..."
NETWORK_START=$(date +%s.%N)
curl -s --connect-timeout 5 --max-time 10 https://httpbin.org/get > /dev/null 2>&1
NETWORK_END=$(date +%s.%N)
NETWORK_TIME=$(echo "$NETWORK_END - $NETWORK_START" | bc -l)

log_message "🌐 Network Response Time: ${NETWORK_TIME}s"

if (( $(echo "$NETWORK_TIME > 2" | bc -l) )); then
    create_alert "WARNING" "Slow network response: ${NETWORK_TIME}s"
fi

# 5. Check Build Performance
log_message "Testing build performance..."
BUILD_START=$(date +%s.%N)
flutter build apk --debug > "$LOG_DIR/build_$TIMESTAMP.log" 2>&1
BUILD_END=$(date +%s.%N)
BUILD_TIME=$(echo "$BUILD_END - $BUILD_START" | bc -l)

log_message "🔨 Build Time: ${BUILD_TIME}s"

if (( $(echo "$BUILD_TIME > 300" | bc -l) )); then
    create_alert "WARNING" "Slow build time: ${BUILD_TIME}s"
fi

# 6. Generate Performance Report
log_message "Generating performance report..."
cat > "$REPORT_FILE" << EOF
# SPOTS Performance Report
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Duration:** $(($(date +%s) - $(date -d "$TIMESTAMP" +%s))) seconds

## Performance Metrics

### System Resources
- **Memory Usage:** ${MEMORY_USAGE}MB
- **CPU Usage:** ${CPU_USAGE}%
- **Disk Usage:** ${DISK_USAGE}%

### Application Performance
- **Startup Time:** ${STARTUP_TIME}s
- **Build Time:** ${BUILD_TIME}s
- **Network Response:** ${NETWORK_TIME}s

### Database Performance
- **Write Time:** ${WRITE_TIME}ms
- **Read Time:** ${READ_TIME}ms

## Performance Benchmarks

### Targets vs Actual
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Startup Time | <3s | ${STARTUP_TIME}s | $([ $(echo "$STARTUP_TIME < 3" | bc -l) -eq 1 ] && echo "✅" || echo "❌") |
| Memory Usage | <100MB | ${MEMORY_USAGE}MB | $([ $(echo "$MEMORY_USAGE < 100" | bc -l) -eq 1 ] && echo "✅" || echo "❌") |
| Database Write | <100ms | ${WRITE_TIME}ms | $([ "$WRITE_TIME" -lt 100 ] && echo "✅" || echo "❌") |
| Database Read | <100ms | ${READ_TIME}ms | $([ "$READ_TIME" -lt 100 ] && echo "✅" || echo "❌") |
| Build Time | <5min | ${BUILD_TIME}s | $([ $(echo "$BUILD_TIME < 300" | bc -l) -eq 1 ] && echo "✅" || echo "❌") |

## Log Files
- **Performance Log:** \`$LOG_FILE\`
- **Startup Test:** \`$LOG_DIR/startup_$TIMESTAMP.log\`
- **Database Test:** \`$LOG_DIR/db_performance_$TIMESTAMP.log\`
- **Build Test:** \`$LOG_DIR/build_$TIMESTAMP.log\`

## Alerts Generated
$(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0") alerts

## Recommendations
- Monitor memory usage trends
- Optimize startup time if >3s
- Review database queries if slow
- Consider build optimization if >5min
EOF

log_message "✅ Performance report generated: $REPORT_FILE"

# 7. Cleanup temporary files
rm -f "$LOG_DIR/db_test_$TIMESTAMP.dart" 2>/dev/null || true

# 8. Final Summary
log_message "=== Performance Monitor Summary ==="
log_message "Memory: ${MEMORY_USAGE}MB"
log_message "CPU: ${CPU_USAGE}%"
log_message "Startup: ${STARTUP_TIME}s"
log_message "Database Write: ${WRITE_TIME}ms"
log_message "Database Read: ${READ_TIME}ms"
log_message "Build: ${BUILD_TIME}s"
log_message "Network: ${NETWORK_TIME}s"
log_message "Alerts: $(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0")"
log_message "=== Performance Monitor Completed ==="

# Exit with appropriate code
if (( $(echo "$MEMORY_USAGE > 1000" | bc -l) )) || (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
    exit 1
else
    exit 0
fi 