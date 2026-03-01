#!/bin/bash
# Audit Test File Headers
# Checks test files for Phase 3 documentation standards compliance

echo "📋 Phase 3: Test File Header Audit"
echo "=================================="
echo ""

TOTAL_TESTS=$(find test -name "*_test.dart" -type f | wc -l | tr -d ' ')
WITH_HEADERS=$(find test -name "*_test.dart" -type f -exec grep -l "^///" {} \; | wc -l | tr -d ' ')
WITHOUT_HEADERS=$((TOTAL_TESTS - WITH_HEADERS))

echo "Total test files: $TOTAL_TESTS"
echo "Files with documentation headers: $WITH_HEADERS"
echo "Files without documentation headers: $WITHOUT_HEADERS"
echo ""

if [ "$WITHOUT_HEADERS" -gt 0 ]; then
  echo "⚠️  Files missing documentation headers:"
  echo ""
  find test -name "*_test.dart" -type f | while read file; do
    if ! grep -q "^///" "$file"; then
      echo "  - $file"
    fi
  done | head -20
  
  if [ "$WITHOUT_HEADERS" -gt 20 ]; then
    echo "  ... and $((WITHOUT_HEADERS - 20)) more files"
  fi
else
  echo "✅ All test files have documentation headers!"
fi

echo ""
echo "Compliance Rate: $((WITH_HEADERS * 100 / TOTAL_TESTS))%"
echo ""

