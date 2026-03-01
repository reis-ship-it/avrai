#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Events suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/event_matching_service_test.dart \
  test/unit/services/event_recommendation_service_test.dart \
  test/unit/services/event_template_service_test.dart \
  test/unit/services/event_safety_service_test.dart \
  test/unit/services/event_success_analysis_service_test.dart \
  test/integration/event_discovery_integration_test.dart \
  test/integration/event_hosting_integration_test.dart \
  test/integration/event_matching_integration_test.dart \
  test/integration/event_recommendation_integration_test.dart \
  test/integration/event_template_integration_test.dart \
  test/integration/controllers/event_creation_controller_integration_test.dart \
  test/integration/controllers/event_cancellation_controller_integration_test.dart \
  test/integration/controllers/event_attendance_controller_integration_test.dart

