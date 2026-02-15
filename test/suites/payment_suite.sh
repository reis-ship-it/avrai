#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Payment & Revenue suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/payment_event_service_test.dart \
  test/unit/services/payment_service_partnership_test.dart \
  test/unit/services/stripe_service_test.dart \
  test/unit/services/refund_service_test.dart \
  test/unit/services/revenue_split_service_brand_test.dart \
  test/unit/services/revenue_split_service_partnership_test.dart \
  test/unit/services/sales_tax_service_test.dart \
  test/unit/services/tax_compliance_service_test.dart \
  test/integration/payments/payment_flow_integration_test.dart \
  test/integration/payments/stripe_payment_integration_test.dart \
  test/integration/payments/tax_compliance_flow_integration_test.dart \
  test/integration/payments/revenue_split_services_integration_test.dart \
  test/integration/payments/dispute_resolution_integration_test.dart \
  test/integration/controllers/payment_processing_controller_integration_test.dart \
  test/integration/ui/payment_ui_integration_test.dart

