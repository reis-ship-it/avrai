#!/bin/bash
# Comprehensive Test Failure Fix Script
# 
# This script orchestrates fixing test failures in a systematic way:
# 1. Fix compilation errors (automated)
# 2. Generate missing mocks
# 3. Provide guidance for runtime errors

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "========================================="
echo "Test Failure Fix Automation"
echo "========================================="
echo ""

# Step 1: Analyze failures
echo "Step 1: Analyzing test failures..."
echo "----------------------------------------"
python3 scripts/analyze_test_failures.py test/unit/services/ || echo "Analysis script not ready yet"

echo ""
echo "Step 2: Fixing compilation errors (dry run)..."
echo "----------------------------------------"
python3 scripts/fix_test_compilation_errors.py --dry-run

echo ""
read -p "Apply compilation error fixes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying fixes..."
    python3 scripts/fix_test_compilation_errors.py
fi

echo ""
echo "Step 3: Generating missing mock files..."
echo "----------------------------------------"
echo "Running build_runner to generate mocks..."
dart run build_runner build --delete-conflicting-outputs || echo "Some mocks may need manual generation"

echo ""
echo "Step 4: Re-running tests to check progress..."
echo "----------------------------------------"
echo "Running tests (this may take a few minutes)..."
flutter test test/unit/services/ --reporter expanded 2>&1 | tail -20

echo ""
echo "========================================="
echo "Fix Process Complete"
echo "========================================="
echo ""
echo "Remaining manual fixes needed:"
echo "- Platform channel issues (most runtime errors)"
echo "- Test logic errors (assertion mismatches)"
echo "- Type mismatches (require code review)"
echo ""
echo "See docs/test_failure_analysis_report.md for details"

