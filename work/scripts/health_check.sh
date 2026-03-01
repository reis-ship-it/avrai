#!/bin/bash

# Health check script for background agent
echo "🔍 Running health checks..."

# Check Flutter installation
echo "Checking Flutter installation..."
if flutter doctor; then
    echo "✅ Flutter installation OK"
else
    echo "❌ Flutter installation issues detected"
    exit 1
fi

# Check disk space
echo "Checking disk space..."
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 90 ]; then
    echo "✅ Disk space OK: ${DISK_USAGE}% used"
else
    echo "❌ Low disk space: ${DISK_USAGE}% used"
    exit 1
fi

# Check memory
echo "Checking memory..."
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEMORY_USAGE" -lt 90 ]; then
    echo "✅ Memory OK: ${MEMORY_USAGE}% used"
else
    echo "❌ High memory usage: ${MEMORY_USAGE}% used"
    exit 1
fi

# Check network connectivity
echo "Checking network connectivity..."
if curl -s https://pub.dev > /dev/null; then
    echo "✅ Network connectivity OK"
else
    echo "❌ Network connectivity issues"
    exit 1
fi

echo "✅ All health checks passed"
