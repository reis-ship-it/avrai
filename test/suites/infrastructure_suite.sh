#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Infrastructure suite (unit + integration).
flutter test "$@" \
  test/unit/services/config_service_test.dart \
  test/unit/services/storage_service_test.dart \
  test/unit/services/supabase_service_test.dart \
  test/unit/services/enhanced_connectivity_service_test.dart \
  test/unit/services/dynamic_threshold_service_test.dart \
  test/integration/infrastructure/cloud_infrastructure_integration_test.dart \
  test/integration/infrastructure/supabase_service_integration_test.dart \
  test/integration/infrastructure/connectivity_integration_test.dart

