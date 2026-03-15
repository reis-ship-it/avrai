#!/usr/bin/env bash
set -euo pipefail

# Skeptic-proof “proof run” bundle generator (iOS simulator)
#
# Captures:
# - iOS simulator screen recording (mp4)
# - iOS simulator log stream (txt)
# - proof-run export files pulled from app container
#   - ledger rows (csv/jsonl)
#   - background wake run records (json)
#   - field validation proofs (json)
#   - ambient-social diagnostics (json)
# - flutter analyze output
# - focused BLE/Signal suite output
#
# Requires:
# - a booted iOS simulator with the SPOTS app installed & running
# - in-app: use the Proof Run (debug) page to Export receipts

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.avrai.app}"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
PROOF_RUN_AUTO="${PROOF_RUN_AUTO:-0}"
RECORD_SECONDS="${RECORD_SECONDS:-360}"
RUN_ID="${RUN_ID:-}"

BASE_DIR="$PROJECT_DIR/reports/proof_runs"
TMP_DIR="$BASE_DIR/${TS}_proof_run_PENDING"

mkdir -p "$TMP_DIR"/{video,logs,ledger,tests}

VIDEO_FILE="$TMP_DIR/video/proof_run_${TS}.mp4"
LOG_FILE="$TMP_DIR/logs/ios_simulator_log_stream.txt"
MANIFEST_FILE="$TMP_DIR/manifest.json"

LOG_PID=""
VIDEO_PID=""

cleanup() {
  set +e
  if [[ -n "${VIDEO_PID}" ]]; then
    kill -INT "${VIDEO_PID}" >/dev/null 2>&1 || true
    wait "${VIDEO_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${LOG_PID}" ]]; then
    kill "${LOG_PID}" >/dev/null 2>&1 || true
    wait "${LOG_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "== AVRAI proof run bundle =="
echo "timestamp: ${TS}"
echo "bundle_id: ${APP_BUNDLE_ID}"
echo
echo "This script will start capturing:"
echo "- video (iOS simulator) -> ${VIDEO_FILE}"
echo "- logs  (iOS simulator) -> ${LOG_FILE}"
echo
echo "In-app recording checklist (3–7 minutes):"
echo "1) Onboarding (or show onboarding already complete)"
echo "2) Offline AI provisioning progress/state (On-Device AI page)"
echo "3) One AI chat (Proof Run page AI chat, or Home -> Explore -> AI)"
echo "4) One AI2AI encounter (iOS sim = simulated; press 'Simulate encounter')"
echo "5) Export receipts (Proof Run page -> Export)"
echo

# Best-effort: get git SHA
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || true)"

cat >"$MANIFEST_FILE" <<EOF
{
  "run_id": null,
  "timestamp": "${TS}",
  "bundle_id": "${APP_BUNDLE_ID}",
  "git_sha": "${GIT_SHA}",
  "notes": "iOS simulator proof run bundle. Encounter and wake coverage are simulated; no physical BLE transport claim is made."
}
EOF

echo "Starting simulator log capture..."
(
  # Filter to the app process name (Runner) to keep logs readable.
  # If this filter is too strict on your machine, remove the predicate.
  xcrun simctl spawn booted log stream \
    --style syslog \
    --level debug \
    --predicate 'process == "Runner"' \
    2>&1
) >"$LOG_FILE" &
LOG_PID="$!"

echo "Starting simulator video recording..."
xcrun simctl io booted recordVideo --codec=h264 --force "$VIDEO_FILE" >/dev/null 2>&1 &
VIDEO_PID="$!"

echo
echo "Recording is live."
if [[ "${PROOF_RUN_AUTO}" == "1" ]]; then
  echo "Auto mode enabled: recording for ${RECORD_SECONDS}s..."
  sleep "${RECORD_SECONDS}"
else
  read -r -p "Press ENTER when you finished the in-app steps + exported receipts... " _
fi

echo "Stopping recording..."
cleanup
trap - EXIT

echo
echo "Running flutter analyze..."
flutter analyze >"$TMP_DIR/tests/flutter_analyze.txt" 2>&1 || true

echo "Running BLE/Signal focused suite..."
bash "$PROJECT_DIR/test/suites/ble_signal_suite.sh" -j 1 -r expanded \
  >"$TMP_DIR/tests/ble_signal_suite.txt" 2>&1 || true

echo "Pulling exported receipts from iOS simulator container..."
APP_CONTAINER="$(xcrun simctl get_app_container booted "$APP_BUNDLE_ID" data)"
PROOF_DIR="$APP_CONTAINER/Documents/proof_runs"

if [[ -z "${RUN_ID}" ]]; then
  # Auto-detect the most recently exported run directory.
  if [[ -d "${PROOF_DIR}" ]]; then
    RUN_ID="$(ls -1t "${PROOF_DIR}" 2>/dev/null | head -n 1 || true)"
    RUN_ID="$(echo "$RUN_ID" | tr -d '[:space:]')"
  fi
fi

if [[ -z "${RUN_ID}" ]]; then
  echo "ERROR: run_id is required to pull ledger export."
  echo "Either:"
  echo "- set RUN_ID=<run_id> when running this script, or"
  echo "- ensure you tapped 'Export' on the Proof Run page (it creates Documents/proof_runs/<run_id>/)"
  exit 1
fi

SRC_DIR="$PROOF_DIR/$RUN_ID"
if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: expected export directory not found:"
  echo "  $SRC_DIR"
  echo "Make sure you tapped 'Export' on the Proof Run page."
  exit 1
fi

cp -R "$SRC_DIR"/* "$TMP_DIR/ledger/" || true

FINAL_DIR="$BASE_DIR/${TS}_proof_run_${RUN_ID}"
mv "$TMP_DIR" "$FINAL_DIR"

# Update manifest with run_id
cat >"$FINAL_DIR/manifest.json" <<EOF
{
  "run_id": "${RUN_ID}",
  "timestamp": "${TS}",
  "bundle_id": "${APP_BUNDLE_ID}",
  "git_sha": "${GIT_SHA}",
  "artifacts": {
    "video": "video/$(basename "$VIDEO_FILE")",
    "logs": "logs/ios_simulator_log_stream.txt",
    "ledger_dir": "ledger/",
    "flutter_analyze": "tests/flutter_analyze.txt",
    "ble_signal_suite": "tests/ble_signal_suite.txt"
  },
  "notes": "iOS simulator proof run bundle. Encounter and wake coverage are simulated; no physical BLE transport claim is made."
}
EOF

cat >"$FINAL_DIR/README.md" <<EOF
## AVRAI proof run bundle

This bundle is designed to be **handed to a skeptic**. It contains:

- **Video**: \`video/\`
- **Logs**: \`logs/ios_simulator_log_stream.txt\`
- **Proof export**: \`ledger/\` (ledger rows + background wake runs + field proofs + ambient-social diagnostics)
- **Focused tests**: \`tests/\` (\`flutter analyze\` + BLE/Signal fast loop)

### Run identifiers

- **run_id**: \`${RUN_ID}\`
- **timestamp**: \`${TS}\`
- **bundle_id**: \`${APP_BUNDLE_ID}\`
- **git_sha**: \`${GIT_SHA}\`

### Truth note

iOS simulator cannot do real BLE discovery. The encounter and background wake
coverage in this bundle are **simulated orchestrator/headless-path proofs** and
are labeled as simulated in \`manifest.json\`.

EOF

echo "Computing checksums..."
(
  cd "$FINAL_DIR"
  shasum -a 256 \
    manifest.json \
    logs/ios_simulator_log_stream.txt \
    tests/flutter_analyze.txt \
    tests/ble_signal_suite.txt \
    video/*.mp4 \
    ledger/* \
    >checksums.sha256 2>/dev/null || true
)

ZIP_FILE="$BASE_DIR/${TS}_proof_run_${RUN_ID}.zip"
echo "Creating zip: $ZIP_FILE"
(cd "$BASE_DIR" && zip -r "$(basename "$ZIP_FILE")" "$(basename "$FINAL_DIR")" >/dev/null)

echo
echo "DONE."
echo "Folder: $FINAL_DIR"
echo "Zip:    $ZIP_FILE"
