#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_step() {
  printf '\n==> %s\n' "$1"
}

run_step "Running runtime security activation tests"
cd "$ROOT_DIR/runtime/avrai_runtime_os"
flutter test \
  test/services/security/security_trigger_ingress_service_test.dart \
  test/services/security/security_campaign_registry_test.dart \
  test/services/security/security_kernel_release_gate_service_test.dart \
  test/services/security/countermeasure_propagation_service_test.dart \
  test/services/security/sandbox_orchestrator_service_test.dart \
  test/services/admin/security_immune_system_admin_service_test.dart

run_step "Running admin security cockpit widget tests"
cd "$ROOT_DIR/apps/admin_app"
flutter test \
  test/widget/pages/admin/security_immune_system_card_test.dart \
  test/widget/pages/admin/security_immune_system_page_test.dart

run_step "Running consumer-app security wiring regressions"
cd "$ROOT_DIR/apps/avrai_app"
flutter test \
  test/unit/kernel/kernel_incident_recorder_test.dart \
  test/unit/services/kernel_governance_enforce_integration_test.dart
