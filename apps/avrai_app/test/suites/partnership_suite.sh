#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Partnerships & Sponsorships suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/partnership_service_test.dart \
  test/unit/services/partnership_matching_service_test.dart \
  test/unit/services/partnership_profile_service_test.dart \
  test/unit/services/sponsorship_service_test.dart \
  test/widget/pages/partnerships/ \
  test/integration/partnership_flow_integration_test.dart \
  test/integration/partnership_profile_flow_integration_test.dart \
  test/integration/profile_partnership_display_integration_test.dart \
  test/integration/controllers/partnership_proposal_controller_integration_test.dart \
  test/integration/controllers/partnership_checkout_controller_integration_test.dart \
  test/integration/ui/partnership_ui_integration_test.dart \
  test/integration/brand_sponsorship_flow_integration_test.dart

