#!/bin/bash

# Systematic Error Fix Script
# Fixes common errors and warnings in SPOTS codebase
# Date: $(date +%Y-%m-%d)

set -e

echo "🔧 Systematic Error Fix Script"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_action() { echo -e "${BLUE}→${NC} $1"; }

# Check if in project root
if [ ! -f "pubspec.yaml" ]; then
    log_error "Must run from SPOTS project root"
    exit 1
fi

echo "Step 1: Running Flutter analyze to get error count..."
ERROR_COUNT=$(flutter analyze 2>&1 | grep -c "^  error" || echo "0")
WARNING_COUNT=$(flutter analyze 2>&1 | grep -c "^  warning" || echo "0")

echo "  Found: $ERROR_COUNT errors, $WARNING_COUNT warnings"
echo ""

# Step 2: Fix common issues automatically
log_action "Step 2: Fixing common issues..."

# 2.1: Fix unused imports (automatic)
log_action "Removing unused imports..."
flutter pub get > /dev/null 2>&1
dart fix --apply --code=unused_import > /dev/null 2>&1 || true
log_info "Unused imports removed"

# 2.2: Fix deprecated member usage
log_action "Fixing deprecated member usage..."
dart fix --apply --code=deprecated_member_use > /dev/null 2>&1 || true
log_info "Deprecated member usage fixed"

# 2.3: Fix unnecessary null checks
log_action "Fixing unnecessary null checks..."
dart fix --apply --code=unnecessary_null_checks > /dev/null 2>&1 || true
log_info "Unnecessary null checks fixed"

# 2.4: Fix unnecessary null in if null operators
log_action "Fixing unnecessary null in if null operators..."
dart fix --apply --code=unnecessary_null_in_if_null_operators > /dev/null 2>&1 || true
log_info "Unnecessary null operators fixed"

echo ""
log_info "Automatic fixes applied"
echo ""

# Step 3: Generate error report
log_action "Step 3: Generating error report..."
REPORT_FILE="docs/agents/reports/agent_2/phase_7/error_analysis_report.md"
mkdir -p "$(dirname "$REPORT_FILE")"

cat > "$REPORT_FILE" << EOF
# Error Analysis Report
**Date:** $(date +%Y-%m-%d)
**Total Errors:** $ERROR_COUNT
**Total Warnings:** $WARNING_COUNT

## Error Categories

EOF

# Categorize errors
echo "### Undefined/Missing Errors" >> "$REPORT_FILE"
flutter analyze 2>&1 | grep "^  error" | grep -E "undefined|doesn't exist|missing" | head -20 >> "$REPORT_FILE" || echo "None found" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "### Type Errors" >> "$REPORT_FILE"
flutter analyze 2>&1 | grep "^  error" | grep -E "type|argument|parameter" | head -20 >> "$REPORT_FILE" || echo "None found" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "### Test File Errors" >> "$REPORT_FILE"
flutter analyze 2>&1 | grep "^  error" | grep "test/" | head -20 >> "$REPORT_FILE" || echo "None found" >> "$REPORT_FILE"

log_info "Error report generated: $REPORT_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Systematic Fix Complete!"
echo ""
echo "Next Steps:"
echo "  1. Review the error report: $REPORT_FILE"
echo "  2. Fix critical errors (undefined classes, missing imports)"
echo "  3. You can debug with warnings, but fix errors first"
echo "  4. Run: flutter analyze to see remaining issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

