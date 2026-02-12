#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Onboarding suite (unit + widget + integration).
flutter test --dart-define=FLUTTER_TEST=true "$@" \
  test/unit/data/datasources/local/onboarding_completion_service_test.dart \
  test/unit/domain/usecases/lists/ \
  test/widget/pages/onboarding/ \
  test/integration/onboarding_flow_integration_test.dart \
  test/integration/onboarding/

