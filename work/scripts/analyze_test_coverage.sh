#!/bin/bash
# analyze_test_coverage.sh
# Generate and view test coverage report

set -e

echo "🧪 Running tests with coverage..."
flutter test --coverage

echo "📊 Generating coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ Coverage report generated at coverage/html/index.html"
echo "📈 Opening coverage report..."
open coverage/html/index.html

echo ""
echo "📋 Coverage Summary:"
lcov --summary coverage/lcov.info | grep -E "lines|functions|branches"

