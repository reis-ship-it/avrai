#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# BHAM onboarding suite (focused unit + widget).
flutter test --dart-define=FLUTTER_TEST=true "$@" \
  test/unit/data/datasources/local/onboarding_completion_service_test.dart \
  test/widget/pages/onboarding/ai_loading_page_test.dart
