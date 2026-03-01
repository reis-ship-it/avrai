#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Business suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/business_service_test.dart \
  test/unit/services/business_account_service_test.dart \
  test/unit/services/business_verification_service_test.dart \
  test/unit/services/business_expert_matching_service_test.dart \
  test/unit/services/product_tracking_service_test.dart \
  test/unit/services/product_sales_service_test.dart \
  test/unit/services/brand_analytics_service_test.dart \
  test/unit/services/brand_discovery_service_test.dart \
  test/widget/pages/business/ \
  test/integration/business_flow_integration_test.dart \
  test/integration/business_expert_vibe_matching_integration_test.dart \
  test/integration/controllers/business_onboarding_controller_integration_test.dart \
  test/integration/ui/business_ui_integration_test.dart \
  test/integration/product_tracking_services_integration_test.dart \
  test/integration/product_tracking_flow_integration_test.dart \
  test/integration/brand_analytics_integration_test.dart \
  test/integration/brand_discovery_services_integration_test.dart \
  test/integration/brand_discovery_flow_integration_test.dart \
  test/integration/ui/brand_ui_integration_test.dart

