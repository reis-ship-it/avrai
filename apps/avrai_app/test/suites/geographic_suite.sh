#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Geographic & Location suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/geographic_scope_service_test.dart \
  test/unit/services/geographic_expansion_service_test.dart \
  test/unit/services/neighborhood_boundary_service_test.dart \
  test/unit/services/location_obfuscation_service_test.dart \
  test/widget/pages/map/ \
  test/integration/locality_value_integration_test.dart \
  test/integration/connectivity_integration_test.dart

