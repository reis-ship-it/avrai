#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Expertise suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/expertise_service_test.dart \
  test/unit/services/expertise_calculation_service_test.dart \
  test/unit/services/expertise_matching_service_test.dart \
  test/unit/services/expertise_recognition_service_test.dart \
  test/unit/services/expertise_network_service_test.dart \
  test/unit/services/expertise_event_service_test.dart \
  test/unit/services/expertise_curation_service_test.dart \
  test/unit/services/expertise_community_service_test.dart \
  test/integration/expertise_flow_integration_test.dart \
  test/integration/expertise_services_integration_test.dart \
  test/integration/expertise_event_integration_test.dart \
  test/integration/expansion_expertise_gain_integration_test.dart \
  test/integration/expertise_partnership_integration_test.dart

