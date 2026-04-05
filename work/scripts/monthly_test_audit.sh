#!/bin/bash
#
# SPOTS Monthly Test Audit Script
# 
# Purpose: Review new tests added in the last month and ensure they follow quality standards
# 
# Usage:
#   ./scripts/monthly_test_audit.sh [days]
# 
# Examples:
#   ./scripts/monthly_test_audit.sh        # Last 30 days (default)
#   ./scripts/monthly_test_audit.sh 7      # Last 7 days
#   ./scripts/monthly_test_audit.sh 90     # Last 90 days
#
# See: docs/plans/test_refactoring/PHASE_6_CONTINUOUS_IMPROVEMENT_PLAN.md

DAYS=${1:-30}
REPORT_DIR="docs/plans/test_refactoring/audit_reports"
REPORT_FILE="$REPORT_DIR/monthly_audit_$(date +%Y-%m-%d).md"

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

echo "🔍 SPOTS Monthly Test Audit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📅 Period: Last $DAYS days"
echo "📁 Report: $REPORT_FILE"
echo ""

# Find test files added or modified in the last N days
echo "📊 Finding test files modified in last $DAYS days..."
TEST_FILES=$(git log --since="$DAYS days ago" --name-only --pretty=format: | grep "_test\.dart$" | sort -u)

if [ -z "$TEST_FILES" ]; then
  echo "✅ No test files modified in the last $DAYS days"
  echo ""
  exit 0
fi

FILE_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
echo "Found $FILE_COUNT test file(s)"
echo ""

# Initialize report
cat > "$REPORT_FILE" << EOF
# Monthly Test Audit Report

**Date:** $(date +"%B %d, %Y")  
**Period:** Last $DAYS days  
**Files Reviewed:** $FILE_COUNT

---

## Summary

EOF

# Analyze each file
TOTAL_ISSUES=0
FILES_WITH_ISSUES=0
ISSUE_DETAILS=""

for test_file in $TEST_FILES; do
  if [ ! -f "$test_file" ]; then
    continue
  fi

  echo "📄 Analyzing: $test_file"
  
  FILE_ISSUES=0
  FILE_ISSUE_LIST=""
  
  # Check 1: Property assignment tests
  PROP_CHECKS=$(grep -c "expect(.*\..*equals\|expect(.*\..*isNotNull\|expect(.*\..*isNull" "$test_file" 2>/dev/null || echo 0)
  if [ "$PROP_CHECKS" -gt 5 ]; then
    FILE_ISSUES=$((FILE_ISSUES + 1))
    FILE_ISSUE_LIST="${FILE_ISSUE_LIST}- ⚠️  Property-assignment tests: $PROP_CHECKS checks found\n"
  fi
  
  # Check 2: Constructor-only tests
  CONSTRUCTOR_TESTS=$(grep -c "test.*should create\|test.*should instantiate\|test.*can be created" "$test_file" 2>/dev/null || echo 0)
  if [ "$CONSTRUCTOR_TESTS" -gt 0 ]; then
    FILE_ISSUES=$((FILE_ISSUES + 1))
    FILE_ISSUE_LIST="${FILE_ISSUE_LIST}- ⚠️  Constructor-only tests: $CONSTRUCTOR_TESTS found\n"
  fi
  
  # Check 3: Field-by-field JSON tests
  JSON_CHECKS=$(grep -c "expect(.*json\[" "$test_file" 2>/dev/null || echo 0)
  if [ "$JSON_CHECKS" -gt 3 ]; then
    FILE_ISSUES=$((FILE_ISSUES + 1))
    FILE_ISSUE_LIST="${FILE_ISSUE_LIST}- ⚠️  Field-by-field JSON tests: $JSON_CHECKS checks found\n"
  fi
  
  # Check 4: Missing documentation
  HAS_HEADER=$(head -20 "$test_file" | grep -c "///.*SPOTS\|///.*Test" || echo 0)
  if [ "$HAS_HEADER" -eq 0 ]; then
    FILE_ISSUES=$((FILE_ISSUES + 1))
    FILE_ISSUE_LIST="${FILE_ISSUE_LIST}- ℹ️  Missing documentation header\n"
  fi
  
  if [ $FILE_ISSUES -gt 0 ]; then
    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
    TOTAL_ISSUES=$((TOTAL_ISSUES + FILE_ISSUES))
    ISSUE_DETAILS="${ISSUE_DETAILS}### \`$test_file\`\n\n${FILE_ISSUE_LIST}\n"
  fi
done

# Generate report summary
cat >> "$REPORT_FILE" << EOF
- **Files Reviewed:** $FILE_COUNT
- **Files with Issues:** $FILES_WITH_ISSUES
- **Total Issues:** $TOTAL_ISSUES

---

## Files with Issues

EOF

if [ $FILES_WITH_ISSUES -eq 0 ]; then
  echo "✅ All reviewed test files meet quality standards!" >> "$REPORT_FILE"
else
  echo -e "$ISSUE_DETAILS" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Recommendations

1. **Review flagged files** and apply refactoring patterns from:
   - \`docs/plans/test_refactoring/TEST_WRITING_GUIDE.md\`
   - \`docs/plans/test_refactoring/TEST_REFACTORING_PLAN.md\`

2. **Use test templates** when creating new tests:
   - \`test/templates/unit_test_template.dart\`
   - \`test/templates/widget_test_template.dart\`
   - \`test/templates/service_test_template.dart\`

3. **Run quality checker** before committing:
   \`\`\`bash
   dart run scripts/check_test_quality.dart [file]
   \`\`\`

4. **Follow pre-commit hook** warnings to catch issues early

---

## Next Steps

- [ ] Review and refactor flagged files
- [ ] Update test templates if patterns evolve
- [ ] Document any new patterns discovered
- [ ] Schedule next audit in 30 days

---

**Generated:** $(date)  
**Script:** \`scripts/monthly_test_audit.sh\`
EOF

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Audit Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Files Reviewed: $FILE_COUNT"
echo "Files with Issues: $FILES_WITH_ISSUES"
echo "Total Issues: $TOTAL_ISSUES"
echo ""
echo "📄 Full Report: $REPORT_FILE"
echo ""

if [ $FILES_WITH_ISSUES -eq 0 ]; then
  echo "✅ All test files meet quality standards!"
  exit 0
else
  echo "⚠️  Some files need review. See report for details."
  exit 0
fi
