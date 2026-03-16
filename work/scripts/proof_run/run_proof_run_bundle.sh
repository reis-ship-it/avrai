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
ROOT_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

READINESS_SUMMARY_TOOL="$ROOT_DIR/work/tools/build_bham_beta_readiness_summary.dart"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.avrai.app}"
TS="${PROOF_RUN_TIMESTAMP:-$(date +'%Y-%m-%d_%H-%M-%S')}"
TS_UTC="${PROOF_RUN_TIMESTAMP_UTC:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}"
PROOF_RUN_AUTO="${PROOF_RUN_AUTO:-0}"
RECORD_SECONDS="${RECORD_SECONDS:-360}"
RUN_ID="${RUN_ID:-}"
STUB_EXPORT_DIR="${PROOF_RUN_STUB_EXPORT_DIR:-}"
DART_BIN="${DART_BIN:-}"

BASE_DIR="${PROOF_RUN_ARTIFACT_ROOT:-$PROJECT_DIR/reports/proof_runs}"
TMP_DIR=""
FINAL_DIR=""
ZIP_FILE=""

mkdir -p "$BASE_DIR"

resolve_dart_bin() {
  if [[ -n "$DART_BIN" ]]; then
    return
  fi

  if command -v flutter >/dev/null 2>&1; then
    local flutter_bin
    local flutter_root
    local flutter_dart
    flutter_bin="$(command -v flutter)"
    flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd -P)"
    flutter_dart="$flutter_root/bin/cache/dart-sdk/bin/dart"
    if [[ -x "$flutter_dart" ]]; then
      DART_BIN="$flutter_dart"
      return
    fi
  fi

  if command -v dart >/dev/null 2>&1; then
    DART_BIN="$(command -v dart)"
    return
  fi

  echo "dart is required"
  exit 1
}

create_pending_artifact_dir() {
  mktemp -d "$BASE_DIR/${TS}_proof_run_PENDING.XXXXXX"
}

reserve_final_artifact_dir() {
  local base_dir="$BASE_DIR/${TS}_proof_run_${RUN_ID}"
  local candidate="$base_dir"
  local suffix=1
  while [[ -e "$candidate" || -e "${candidate}.zip" ]]; do
    candidate="${base_dir}_$suffix"
    suffix=$((suffix + 1))
  done
  printf '%s\n' "$candidate"
}

TMP_DIR="$(create_pending_artifact_dir)"
mkdir -p "$TMP_DIR"/{video,logs,ledger,tests}

VIDEO_FILE="$TMP_DIR/video/proof_run_${TS}.mp4"
LOG_FILE="$TMP_DIR/logs/ios_simulator_log_stream.txt"
MANIFEST_FILE="$TMP_DIR/manifest.json"
ARTIFACT_INDEX_FILE="$TMP_DIR/ARTIFACT_INDEX.md"

LOG_PID=""
VIDEO_PID=""

cleanup() {
  local exit_code="${1:-0}"
  set +e
  if [[ -n "${VIDEO_PID}" ]]; then
    kill -INT "${VIDEO_PID}" >/dev/null 2>&1 || true
    wait "${VIDEO_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${LOG_PID}" ]]; then
    kill "${LOG_PID}" >/dev/null 2>&1 || true
    wait "${LOG_PID}" >/dev/null 2>&1 || true
  fi
  if [[ "$exit_code" -ne 0 && -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    echo "Proof run bundle failed. Pending artifacts kept at: $TMP_DIR" >&2
  fi
}
trap 'cleanup $?' EXIT

write_run_artifact_index() {
  local run_dir="$1"
  local index_file="$run_dir/ARTIFACT_INDEX.md"
  {
    echo "# Proof Run Bundle Artifact Index"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Bundle ID: \`$APP_BUNDLE_ID\`"
    echo "- Timestamp (local): \`$TS\`"
    echo "- Timestamp (UTC): \`$TS_UTC\`"
    echo "- Git SHA: \`${GIT_SHA:-unknown}\`"
    echo
    echo "## Files"
    echo
    while IFS= read -r -d '' file; do
      local relative_path="${file#$run_dir/}"
      local byte_size
      byte_size="$(wc -c <"$file" | tr -d ' ')"
      local sha256
      sha256="$(shasum -a 256 "$file" | awk '{print $1}')"
      echo "- \`$relative_path\` (\`${byte_size} bytes\`, \`sha256:$sha256\`)"
    done < <(find "$run_dir" -type f ! -name 'ARTIFACT_INDEX.md' -print0 | sort -z)
  } >"$index_file"
}

update_proof_run_bundle_index() {
  local index_json="$BASE_DIR/proof_run_bundle_index.json"
  local index_md="$BASE_DIR/proof_run_bundle_index.md"
  python3 - "$BASE_DIR" "$index_json" "$index_md" <<'PY'
import json
import os
import pathlib
import tempfile
import sys

root = pathlib.Path(sys.argv[1])
index_json = pathlib.Path(sys.argv[2])
index_md = pathlib.Path(sys.argv[3])

entries = []
for child in sorted(root.iterdir()):
    if not child.is_dir():
        continue
    if "_PENDING" in child.name:
        continue
    manifest_path = child / "manifest.json"
    if not manifest_path.exists():
        continue
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception:
        continue
    if manifest.get("artifact_kind") != "proof_run_bundle":
        continue
    entries.append(
        {
            "artifact_dir": child.name,
            "artifact_dir_path": str(child),
            "zip_path": str(child.with_suffix(".zip")) if child.with_suffix(".zip").exists() else None,
            "run_id": manifest.get("run_id"),
            "bundle_id": manifest.get("bundle_id"),
            "timestamp": manifest.get("timestamp"),
            "timestamp_utc": manifest.get("timestamp_utc"),
            "git_sha": manifest.get("git_sha"),
        }
    )

entries.sort(
    key=lambda entry: (
        entry.get("timestamp") or "",
        entry.get("run_id") or "",
        entry.get("artifact_dir") or "",
    ),
    reverse=True,
)

payload = {"artifact_kind": "proof_run_bundle_index", "entries": entries}
with tempfile.NamedTemporaryFile("w", delete=False, dir=str(index_json.parent), encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
    temp_json = handle.name
os.replace(temp_json, index_json)

lines = [
    "# Proof Run Bundle Index",
    "",
    f"- Artifact root: `{root}`",
    f"- Indexed runs: `{len(entries)}`",
    "",
    "| Timestamp | Run ID | Bundle ID | Artifact Dir |",
    "| --- | --- | --- | --- |",
]
for entry in entries:
    lines.append(
        "| {timestamp} | {run_id} | {bundle_id} | `{artifact_dir}` |".format(
            timestamp=entry.get("timestamp_utc") or entry.get("timestamp") or "-",
            run_id=entry.get("run_id") or "-",
            bundle_id=entry.get("bundle_id") or "-",
            artifact_dir=entry.get("artifact_dir") or "-",
        )
    )

with tempfile.NamedTemporaryFile("w", delete=False, dir=str(index_md.parent), encoding="utf-8") as handle:
    handle.write("\n".join(lines))
    handle.write("\n")
    temp_md = handle.name
os.replace(temp_md, index_md)
PY
}

refresh_bham_beta_readiness_summary() {
  local readiness_json="$BASE_DIR/bham_beta_readiness_summary.json"
  local readiness_md="$BASE_DIR/bham_beta_readiness_summary.md"
  if [[ ! -f "$READINESS_SUMMARY_TOOL" ]]; then
    echo "Skipping BHAM beta readiness summary; tool not found: $READINESS_SUMMARY_TOOL" >&2
    return 0
  fi
  resolve_dart_bin
  if ! "$DART_BIN" run "$READINESS_SUMMARY_TOOL" "$BASE_DIR" \
    --json-output="$readiness_json" \
    --markdown-output="$readiness_md" \
    >/dev/null; then
    echo "BHAM beta readiness summary updated with blocking conditions: $readiness_json" >&2
  fi
}

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
  "artifact_kind": "proof_run_bundle",
  "run_id": null,
  "timestamp": "${TS}",
  "timestamp_utc": "${TS_UTC}",
  "bundle_id": "${APP_BUNDLE_ID}",
  "git_sha": "${GIT_SHA}",
  "notes": "iOS simulator proof run bundle. Encounter and wake coverage are simulated; no physical BLE transport claim is made."
}
EOF

if [[ -n "$STUB_EXPORT_DIR" ]]; then
  echo "Running proof run bundle in stub mode."
  echo "stub log capture" >"$LOG_FILE"
  echo "stub video placeholder" >"$VIDEO_FILE"
  echo "flutter analyze stub output" >"$TMP_DIR/tests/flutter_analyze.txt"
  echo "ble signal suite stub output" >"$TMP_DIR/tests/ble_signal_suite.txt"
  if [[ -z "$RUN_ID" ]]; then
    RUN_ID="$(basename "$STUB_EXPORT_DIR")"
  fi
else
  echo "Starting simulator log capture..."
  (
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
fi

echo "Pulling exported receipts from iOS simulator container..."
if [[ -n "$STUB_EXPORT_DIR" ]]; then
  PROOF_DIR="$(dirname "$STUB_EXPORT_DIR")"
else
  APP_CONTAINER="$(xcrun simctl get_app_container booted "$APP_BUNDLE_ID" data)"
  PROOF_DIR="$APP_CONTAINER/Documents/proof_runs"
fi

if [[ -z "${RUN_ID}" ]]; then
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

if [[ -n "$STUB_EXPORT_DIR" ]]; then
  SRC_DIR="$STUB_EXPORT_DIR"
else
  SRC_DIR="$PROOF_DIR/$RUN_ID"
fi
if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: expected export directory not found:"
  echo "  $SRC_DIR"
  echo "Make sure you tapped 'Export' on the Proof Run page."
  exit 1
fi

cp -R "$SRC_DIR"/* "$TMP_DIR/ledger/" || true

FINAL_DIR="$(reserve_final_artifact_dir)"
mv "$TMP_DIR" "$FINAL_DIR"
TMP_DIR=""

# Update manifest with run_id
cat >"$FINAL_DIR/manifest.json" <<EOF
{
  "artifact_kind": "proof_run_bundle",
  "run_id": "${RUN_ID}",
  "timestamp": "${TS}",
  "timestamp_utc": "${TS_UTC}",
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

write_run_artifact_index "$FINAL_DIR"

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

ZIP_FILE="${FINAL_DIR}.zip"
echo "Creating zip: $ZIP_FILE"
(
  cd "$BASE_DIR"
  zip -r "$(basename "$ZIP_FILE")" "$(basename "$FINAL_DIR")" >/dev/null
)
update_proof_run_bundle_index
refresh_bham_beta_readiness_summary

echo
echo "DONE."
echo "Folder: $FINAL_DIR"
echo "Zip:    $ZIP_FILE"
echo "Readiness: $BASE_DIR/bham_beta_readiness_summary.json"
