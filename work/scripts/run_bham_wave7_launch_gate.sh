#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/avrai_app"
SNAPSHOT_PATH="${BHAM_LAUNCH_SNAPSHOT_PATH:-${ROOT_DIR}/runtime_exports/bham_launch_snapshot.json}"

run_step() {
  local label="$1"
  shift
  echo
  echo "==> ${label}"
  "$@"
}

echo "Running BHAM Wave 7 consumer launch gate..."
echo "Root: ${ROOT_DIR}"

run_step "Deterministic beta gate" bash "${ROOT_DIR}/work/scripts/run_beta_gate_tests.sh"
run_step "Consumer/runtime analyze" \
  dart analyze --no-fatal-warnings \
    "${ROOT_DIR}/apps/avrai_app" "${ROOT_DIR}/runtime" "${ROOT_DIR}/shared" "${ROOT_DIR}/engine"
run_step "Architecture boundary check" \
  dart run "${ROOT_DIR}/work/scripts/ci/check_architecture.dart"
run_step "Repo hygiene check" \
  dart run "${ROOT_DIR}/work/scripts/ci/check_repo_hygiene.dart"
run_step "Formatting check" dart format --set-exit-if-changed "${ROOT_DIR}"

echo
echo "==> BHAM critical consumer suites"
(
  cd "${APP_DIR}"
  flutter test \
    test/unit/controllers/onboarding_flow_controller_test.dart \
    test/unit/services/bham_daily_drop_builder_test.dart \
    test/unit/services/bham_route_planner_test.dart \
    test/unit/services/direct_match_service_test.dart \
    test/unit/services/bham_notification_policy_service_test.dart
)

if [[ "${RUN_HEAVY_INTEGRATION_TESTS:-false}" == "true" ]]; then
  echo
  echo "==> BHAM heavy consumer suites"
  bash "${ROOT_DIR}/work/scripts/run_bham_heavy_consumer_suites.sh"
else
  echo
  echo "BHAM heavy consumer suites were not run."
  echo "Set RUN_HEAVY_INTEGRATION_TESTS=true for canonical launch validation."
  if [[ "${BHAM_ALLOW_MANUAL_HEAVY_SIGNOFF:-false}" != "true" ]]; then
    echo "Launch gate blocked: BHAM heavy consumer suite signoff is still required."
    exit 1
  fi
fi

if [[ -f "${SNAPSHOT_PATH}" ]]; then
  run_step \
    "Generate BHAM launch report" \
    dart run "${ROOT_DIR}/work/tools/generate_bham_launch_report.dart" \
      --input "${SNAPSHOT_PATH}"
else
  echo
  echo "No launch snapshot found at ${SNAPSHOT_PATH}."
  echo "Export a runtime/admin launch snapshot before final human go/no-go review."
  if [[ "${BHAM_ALLOW_MISSING_SNAPSHOT:-false}" != "true" ]]; then
    exit 1
  fi
fi

echo
echo "BHAM Wave 7 consumer launch gate completed."
