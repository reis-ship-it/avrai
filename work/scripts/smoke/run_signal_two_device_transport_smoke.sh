#!/usr/bin/env bash
set -euo pipefail

# Two-device Signal transport smoke runner.
#
# Runs `integration_test/signal_two_device_transport_smoke_test.dart` on two devices:
# - Role A (sender) on DEVICE_A
# - Role B (receiver) on DEVICE_B
#
# Required env:
# - SUPABASE_URL
# - SUPABASE_ANON_KEY
# - DEVICE_A, DEVICE_B            (flutter device ids)
# - A_EMAIL, A_PASSWORD
# - B_EMAIL, B_PASSWORD
#
# Optional env:
# - RUN_ID                        (defaults to random uuid)
# - SIGNAL_SMOKE_COMMUNITY_ID     (enables community stream portion)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_PATH="integration_test/signal_two_device_transport_smoke_test.dart"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Missing SUPABASE_URL or SUPABASE_ANON_KEY"
  exit 1
fi

if [[ -z "${DEVICE_A:-}" || -z "${DEVICE_B:-}" ]]; then
  echo "Missing DEVICE_A or DEVICE_B (flutter device ids)"
  exit 1
fi

if [[ -z "${A_EMAIL:-}" || -z "${A_PASSWORD:-}" || -z "${B_EMAIL:-}" || -z "${B_PASSWORD:-}" ]]; then
  echo "Missing A_EMAIL/A_PASSWORD or B_EMAIL/B_PASSWORD"
  exit 1
fi

RUN_ID="${RUN_ID:-$(python3 -c 'import uuid; print(uuid.uuid4())')}"
export RUN_ID

COMMON_DEFINES=(
  "--dart-define=RUN_SIGNAL_NATIVE_TESTS=true"
  "--dart-define=SUPABASE_URL=${SUPABASE_URL}"
  "--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
  "--dart-define=SIGNAL_SMOKE_RUN_ID=${RUN_ID}"
  "--dart-define=SPOTS_LEDGER_AUDIT=true"
  "--dart-define=SPOTS_LEDGER_AUDIT_CORRELATION_ID=${RUN_ID}"
)

if [[ -n "${SIGNAL_SMOKE_COMMUNITY_ID:-}" ]]; then
  COMMON_DEFINES+=("--dart-define=SIGNAL_SMOKE_COMMUNITY_ID=${SIGNAL_SMOKE_COMMUNITY_ID}")
fi

echo "RUN_ID=${RUN_ID}"
echo "DEVICE_A=${DEVICE_A} (role A)"
echo "DEVICE_B=${DEVICE_B} (role B)"
if [[ -n "${SIGNAL_SMOKE_COMMUNITY_ID:-}" ]]; then
  echo "SIGNAL_SMOKE_COMMUNITY_ID=${SIGNAL_SMOKE_COMMUNITY_ID}"
fi

set +e

flutter test "${TEST_PATH}" -d "${DEVICE_A}" -r expanded \
  "${COMMON_DEFINES[@]}" \
  --dart-define=SIGNAL_SMOKE_ROLE=A \
  --dart-define=SIGNAL_SMOKE_EMAIL="${A_EMAIL}" \
  --dart-define=SIGNAL_SMOKE_PASSWORD="${A_PASSWORD}" &
PID_A=$!

sleep 8

flutter test "${TEST_PATH}" -d "${DEVICE_B}" -r expanded \
  "${COMMON_DEFINES[@]}" \
  --dart-define=SIGNAL_SMOKE_ROLE=B \
  --dart-define=SIGNAL_SMOKE_EMAIL="${B_EMAIL}" \
  --dart-define=SIGNAL_SMOKE_PASSWORD="${B_PASSWORD}"
STATUS_B=$?

wait "${PID_A}"
STATUS_A=$?

set -e

echo "Role B exit: ${STATUS_B}"
echo "Role A exit: ${STATUS_A}"

if [[ "${STATUS_A}" -ne 0 || "${STATUS_B}" -ne 0 ]]; then
  exit 1
fi

echo "✅ Two-device Signal transport smoke passed (RUN_ID=${RUN_ID})"

