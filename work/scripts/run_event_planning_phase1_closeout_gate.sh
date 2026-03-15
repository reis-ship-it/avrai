#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RECEIPT_DIR="${EVENT_PLANNING_SMOKE_RECEIPT_DIR:-}"
JSONL_PATH=""
CSV_PATH=""

run_step() {
  local label="$1"
  shift
  echo
  echo "==> ${label}"
  "$@"
}

require_contains() {
  local needle="$1"
  if ! grep -q "${needle}" "${JSONL_PATH}"; then
    echo
    echo "Missing required receipt marker: ${needle}"
    exit 1
  fi
}

echo "Running phase-1 event-planning closeout gate..."
echo "Root: ${ROOT_DIR}"

run_step "Targeted analyze" \
  dart analyze --no-fatal-warnings \
    "${ROOT_DIR}/shared/avrai_core/lib/models/events/event_planning.dart" \
    "${ROOT_DIR}/runtime/avrai_runtime_os/lib/services/events/event_planning_intake_adapter.dart" \
    "${ROOT_DIR}/runtime/avrai_runtime_os/lib/services/events/event_planning_telemetry_service.dart" \
    "${ROOT_DIR}/runtime/avrai_runtime_os/lib/services/events/event_host_debrief_service.dart" \
    "${ROOT_DIR}/runtime/avrai_runtime_os/lib/controllers/event_creation_controller.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/controllers/human_chat_controller.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/pages/chat/agent_chat_view.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/pages/events/quick_event_builder_page.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/pages/events/event_success_dashboard.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/pages/debug/proof_run_page.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/presentation/widgets/debug/event_planning_telemetry_debug_card.dart" \
    "${ROOT_DIR}/apps/avrai_app/lib/services/debug/proof_run_automation_service.dart"

run_step "Runtime telemetry tests" \
  flutter test \
    "${ROOT_DIR}/runtime/avrai_runtime_os/test/services/events/event_planning_telemetry_service_test.dart"

run_step "Personal-agent controller tests" \
  flutter test \
    "${ROOT_DIR}/apps/avrai_app/test/unit/controllers/human_chat_controller_test.dart"

run_step "Event-planning debug telemetry widget test" \
  flutter test \
    "${ROOT_DIR}/apps/avrai_app/test/widget/debug/event_planning_telemetry_debug_card_test.dart"

run_step "Quick builder air-gap widget tests" \
  flutter test \
    "${ROOT_DIR}/apps/avrai_app/test/widget/pages/events/quick_event_builder_page_test.dart"

run_step "Host debrief air-gap widget test" \
  flutter test \
    "${ROOT_DIR}/apps/avrai_app/test/widget/pages/events/event_success_dashboard_test.dart"

run_step "Proof-run smoke tooling tests" \
  flutter test \
    "${ROOT_DIR}/apps/avrai_app/test/services/debug/proof_run_automation_service_test.dart"

if [[ -z "${RECEIPT_DIR}" ]]; then
  echo
  echo "Closeout gate blocked: EVENT_PLANNING_SMOKE_RECEIPT_DIR is not set."
  echo "Run the manual iOS smoke using:"
  echo "  ${ROOT_DIR}/work/docs/plans/easy_event_hosting/BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md"
  exit 1
fi

if [[ ! -d "${RECEIPT_DIR}" ]]; then
  echo
  echo "Closeout gate blocked: receipt directory does not exist: ${RECEIPT_DIR}"
  exit 1
fi

JSONL_PATH="${RECEIPT_DIR}/ledger_rows.jsonl"
CSV_PATH="${RECEIPT_DIR}/ledger_rows.csv"

if [[ ! -f "${JSONL_PATH}" ]]; then
  echo
  echo "Closeout gate blocked: missing ${JSONL_PATH}"
  exit 1
fi

if [[ ! -f "${CSV_PATH}" ]]; then
  echo
  echo "Closeout gate blocked: missing ${CSV_PATH}"
  exit 1
fi

require_contains "event_planning_beta_smoke_v1"
require_contains "proof_event_planning_smoke_started"
require_contains "proof_event_planning_event_truth_entered"
require_contains "proof_event_planning_air_gap_crossed"
require_contains "proof_event_planning_suggestion_shown"
require_contains "proof_event_planning_publish_completed"
require_contains "proof_event_planning_safety_checklist_opened"
require_contains "proof_event_planning_debrief_completed"
require_contains "\"manual\":true"

echo
echo "Phase-1 event-planning closeout gate passed."
echo "Receipt bundle: ${RECEIPT_DIR}"
