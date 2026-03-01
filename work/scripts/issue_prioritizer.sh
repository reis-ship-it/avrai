#!/bin/bash

# Issue prioritization script
# Focuses on critical errors first

echo "🎯 Running issue prioritization..."

# Run analysis and capture output
ANALYSIS_OUTPUT=$(flutter analyze 2>&1 || true)

# Extract critical errors
CRITICAL_ERRORS=$(echo "$ANALYSIS_OUTPUT" | grep -i "error" | head -10)
echo "Critical errors found:"
echo "$CRITICAL_ERRORS"

# Extract warnings
WARNINGS=$(echo "$ANALYSIS_OUTPUT" | grep -i "warning" | head -5)
echo "Warnings found:"
echo "$WARNINGS"

# Extract info issues
INFO_ISSUES=$(echo "$ANALYSIS_OUTPUT" | grep -i "info" | head -3)
echo "Info issues found:"
echo "$INFO_ISSUES"

# Prioritize fixes
echo "Prioritizing fixes..."
echo "1. Fixing critical errors first..."
# Add auto-fix logic here

echo "2. Fixing warnings..."
# Add auto-fix logic here

echo "3. Fixing info issues..."
# Add auto-fix logic here

echo "✅ Issue prioritization complete"
