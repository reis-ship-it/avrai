#!/bin/bash

# Fix Critical Errors in Main Code (lib/)
# Focuses on errors that block compilation
# Date: $(date +%Y-%m-%d)

set -e

echo "🔴 Fixing Critical Errors in Main Code"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_action() { echo -e "${BLUE}→${NC} $1"; }

# Check if in project root
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Must run from SPOTS project root"
    exit 1
fi

echo "Current error count in lib/:"
MAIN_ERRORS=$(flutter analyze 2>&1 | grep "^  error" | grep -v "test/" | wc -l | xargs)
echo "  $MAIN_ERRORS errors in main code"
echo ""

if [ "$MAIN_ERRORS" -eq 0 ]; then
    log_info "No errors in main code! You can debug now."
    exit 0
fi

log_action "Top priority errors to fix:"
echo ""

# Show top 10 errors
flutter analyze 2>&1 | grep "^  error" | grep -v "test/" | head -10 | while read line; do
    echo "  $line"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Fix Strategy:"
echo ""
echo "1. Fix missing imports (Target of URI doesn't exist)"
echo "2. Fix undefined classes/names (Undefined class/name)"
echo "3. Fix missing required parameters"
echo "4. Fix type errors"
echo ""
echo "After fixing these, try: flutter build apk --debug"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

