#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
APP_DIR="$ROOT_DIR/apps/avrai_app"
VALIDATOR_SCRIPT="$ROOT_DIR/work/tools/validate_simulated_smoke_bundle.dart"
READINESS_SUMMARY_TOOL="$ROOT_DIR/work/tools/build_bham_beta_readiness_summary.dart"
PLATFORM="${1:-}"
SCENARIO_PROFILE="${2:-baseline}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-}"
TS="${SIMULATED_SMOKE_TIMESTAMP:-$(date +'%Y-%m-%d_%H-%M-%S')}"
TS_UTC="${SIMULATED_SMOKE_TIMESTAMP_UTC:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}"
ARTIFACT_ROOT="${SIMULATED_SMOKE_ARTIFACT_ROOT:-$ROOT_DIR/reports/proof_runs}"
STUB_RESPONSE_PATH="${SIMULATED_SMOKE_STUB_RESPONSE_PATH:-}"
STUB_BUNDLE_DIR="${SIMULATED_SMOKE_STUB_BUNDLE_DIR:-}"
ANDROID_SDK_DIR="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
ADB_BIN="${ADB_BIN:-}"
EMULATOR_BIN="${EMULATOR_BIN:-}"
DART_BIN="${DART_BIN:-}"
TMP_DIR=""
FINAL_DIR=""
ZIP_FILE=""

if [[ -z "$PLATFORM" ]]; then
  echo "usage: ./scripts/proof_run/run_simulated_headless_smoke.sh <ios|android> [baseline|duplicate_wake_delivery|restart_mid_headless_run|trusted_route_unavailable_deferred|multi_peer_single_confirmation]"
  exit 1
fi

case "$PLATFORM" in
  ios|android)
    ;;
  *)
    echo "unsupported platform: $PLATFORM"
    exit 1
    ;;
esac

case "$SCENARIO_PROFILE" in
  baseline|duplicate_wake_delivery|restart_mid_headless_run|trusted_route_unavailable_deferred|multi_peer_single_confirmation)
    ;;
  *)
    echo "unsupported simulated smoke scenario profile: $SCENARIO_PROFILE"
    exit 1
    ;;
esac

if [[ -z "$APP_BUNDLE_ID" ]]; then
  APP_BUNDLE_ID="com.avrai.app"
fi

if [[ -n "$STUB_RESPONSE_PATH" || -n "$STUB_BUNDLE_DIR" ]]; then
  if [[ -z "$STUB_RESPONSE_PATH" || -z "$STUB_BUNDLE_DIR" ]]; then
    echo "stub smoke mode requires both SIMULATED_SMOKE_STUB_RESPONSE_PATH and SIMULATED_SMOKE_STUB_BUNDLE_DIR"
    exit 1
  fi
fi

if [[ -z "$STUB_RESPONSE_PATH" ]] && ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required"
  exit 1
fi

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

mkdir -p "$ARTIFACT_ROOT"

create_pending_artifact_dir() {
  mktemp -d "$ARTIFACT_ROOT/${TS}_${PLATFORM}_${SCENARIO_PROFILE}_simulated_smoke_PENDING.XXXXXX"
}

reserve_final_artifact_dir() {
  local base_dir="$ARTIFACT_ROOT/${TS}_${PLATFORM}_${SCENARIO_PROFILE_VALUE:-$SCENARIO_PROFILE}_simulated_smoke_${RUN_ID}"
  local candidate="$base_dir"
  local suffix=1
  while [[ -e "$candidate" || -e "${candidate}.zip" ]]; do
    candidate="${base_dir}_$suffix"
    suffix=$((suffix + 1))
  done
  printf '%s\n' "$candidate"
}

on_failure() {
  local exit_code="$1"
  if [[ "$exit_code" -eq 0 ]]; then
    return
  fi
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    echo "Simulated smoke failed. Pending artifacts kept at: $TMP_DIR" >&2
  fi
  if [[ -n "${DRIVE_LOG:-}" && -f "$DRIVE_LOG" ]]; then
    echo "Last flutter_drive log lines:" >&2
    tail -n 40 "$DRIVE_LOG" >&2 || true
  fi
}

TMP_DIR="$(create_pending_artifact_dir)"
mkdir -p "$TMP_DIR"
trap 'on_failure $?' EXIT

RESPONSE_FILE="$TMP_DIR/simulated_smoke_response.json"
DRIVE_LOG="$TMP_DIR/flutter_drive.log"
VALIDATION_SUMMARY="$TMP_DIR/validation_summary.json"
MANIFEST_FILE="$TMP_DIR/manifest.json"
ARTIFACT_INDEX_FILE="$TMP_DIR/ARTIFACT_INDEX.md"
REQUIRED_BUNDLE_FILES=(
  "ledger_rows.csv"
  "ledger_rows.jsonl"
  "background_wake_runs.json"
  "field_validation_proofs.json"
  "ambient_social_diagnostics.json"
)

write_run_artifact_index() {
  local run_dir="$1"
  local index_file="$run_dir/ARTIFACT_INDEX.md"
  {
    echo "# Simulated Headless Smoke Artifact Index"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Platform: \`${PLATFORM}_simulator\`"
    echo "- Platform mode: \`$PLATFORM\`"
    echo "- Scenario profile: \`${SCENARIO_PROFILE_VALUE:-$SCENARIO_PROFILE}\`"
    echo "- Timestamp (local): \`$TS\`"
    echo "- Timestamp (UTC): \`$TS_UTC\`"
    echo "- Git SHA: \`${GIT_SHA:-unknown}\`"
    echo "- Run status: \`${RUN_STATUS:-unknown}\`"
    echo "- Success: \`${SUCCESS:-false}\`"
    echo "- Simulated-only coverage: \`true\`"
    if [[ -n "${FAILURE_SUMMARY:-}" ]]; then
      echo "- Failure summary: \`${FAILURE_SUMMARY}\`"
    fi
    echo
    echo "## Primary Files"
    echo
    echo "- \`manifest.json\`: run identity, platform, scenario profile, simulated labeling, pass/fail status"
    echo "- \`validation_summary.json\`: machine-readable validator output used by CI"
    echo "- \`simulated_smoke_response.json\`: direct automation response from the app runtime"
    echo "- \`background_wake_runs.json\`: exported headless wake execution records"
    echo "- \`field_validation_proofs.json\`: controlled trust, AI2AI, and ambient validation proofs"
    echo "- \`ambient_social_diagnostics.json\`: candidate vs confirmed social presence and promotion lineage"
    echo "- \`ledger_rows.jsonl\`: run-scoped milestone ledger receipts"
    echo
    echo "## Truth Note"
    echo
    echo "This artifact proves simulated wake and encounter behavior only. It is not a claim of physical BLE or live-radio validation."
  } >"$index_file"
}

update_simulated_smoke_index() {
  local index_json="$ARTIFACT_ROOT/simulated_headless_smoke_index.json"
  local index_md="$ARTIFACT_ROOT/simulated_headless_smoke_index.md"
  python3 - "$ARTIFACT_ROOT" "$index_json" "$index_md" <<'PY'
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
    is_simulated_smoke = manifest.get("artifact_kind") == "simulated_headless_smoke"
    if not is_simulated_smoke:
        continue
    entries.append(
        {
            "artifact_dir": child.name,
            "artifact_dir_path": str(child),
            "zip_path": str(child.with_suffix(".zip")) if child.with_suffix(".zip").exists() else None,
            "run_id": manifest.get("run_id"),
            "platform": manifest.get("platform"),
            "scenario_profile": manifest.get("scenario_profile"),
            "timestamp": manifest.get("timestamp"),
            "timestamp_utc": manifest.get("timestamp_utc"),
            "git_sha": manifest.get("git_sha"),
            "success": manifest.get("smoke_response_success"),
            "failure_summary": manifest.get("failure_summary"),
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

payload = {"artifact_kind": "simulated_headless_smoke_index", "entries": entries}
with tempfile.NamedTemporaryFile("w", delete=False, dir=str(index_json.parent), encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
    temp_json = handle.name
os.replace(temp_json, index_json)

lines = [
    "# Simulated Headless Smoke Index",
    "",
    f"- Artifact root: `{root}`",
    f"- Indexed runs: `{len(entries)}`",
    "",
    "| Timestamp | Platform | Scenario | Run ID | Success | Artifact Dir |",
    "| --- | --- | --- | --- | --- | --- |",
]
for entry in entries:
    lines.append(
        "| {timestamp} | {platform} | {scenario} | {run_id} | {success} | `{artifact_dir}` |".format(
            timestamp=entry.get("timestamp_utc") or entry.get("timestamp") or "-",
            platform=entry.get("platform") or "-",
            scenario=entry.get("scenario_profile") or "-",
            run_id=entry.get("run_id") or "-",
            success=str(entry.get("success")).lower() if entry.get("success") is not None else "-",
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
  local readiness_json="$ARTIFACT_ROOT/bham_beta_readiness_summary.json"
  local readiness_md="$ARTIFACT_ROOT/bham_beta_readiness_summary.md"
  if [[ ! -f "$READINESS_SUMMARY_TOOL" ]]; then
    echo "Skipping BHAM beta readiness summary; tool not found: $READINESS_SUMMARY_TOOL" >&2
    return 0
  fi
  resolve_dart_bin
  if ! "$DART_BIN" run "$READINESS_SUMMARY_TOOL" "$ARTIFACT_ROOT" \
    --json-output="$readiness_json" \
    --markdown-output="$readiness_md" \
    >/dev/null; then
    echo "BHAM beta readiness summary updated with blocking conditions: $readiness_json" >&2
  fi
}

json_string_field() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

path, key = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as handle:
    value = json.load(handle).get(key)
if value is None:
    sys.exit(0)
print(value)
PY
}

json_bool_field() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

path, key = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as handle:
    value = json.load(handle).get(key)
if value is True:
    print('true')
elif value is False:
    print('false')
PY
}

resolve_simulator_app_path() {
  local developer_dir
  developer_dir="$(xcode-select -p 2>/dev/null || true)"
  if [[ -z "$developer_dir" ]]; then
    return 1
  fi
  local simulator_app="$developer_dir/Applications/Simulator.app"
  if [[ -d "$simulator_app" ]]; then
    echo "$simulator_app"
    return 0
  fi
  return 1
}

open_ios_simulator_app() {
  local simulator_app
  simulator_app="$(resolve_simulator_app_path || true)"
  if [[ -n "$simulator_app" ]]; then
    open "$simulator_app" >/dev/null 2>&1 || true
    return 0
  fi
  open -a Simulator >/dev/null 2>&1 || true
}

simctl_list_devices_with_retry() {
  local attempts=0
  local max_attempts=5
  local output=""
  while [[ $attempts -lt $max_attempts ]]; do
    if output="$(xcrun simctl list devices "$@" 2>/dev/null)"; then
      printf '%s\n' "$output"
      return 0
    fi
    attempts=$((attempts + 1))
    if [[ -z "${CI:-}" ]]; then
      open_ios_simulator_app
    fi
    sleep 2
  done
  return 1
}

resolve_android_tools() {
  if [[ -z "$ADB_BIN" ]]; then
    if command -v adb >/dev/null 2>&1; then
      ADB_BIN="$(command -v adb)"
    elif [[ -x "$ANDROID_SDK_DIR/platform-tools/adb" ]]; then
      ADB_BIN="$ANDROID_SDK_DIR/platform-tools/adb"
    fi
  fi

  if [[ -z "$EMULATOR_BIN" ]]; then
    if command -v emulator >/dev/null 2>&1; then
      EMULATOR_BIN="$(command -v emulator)"
    elif [[ -x "$ANDROID_SDK_DIR/emulator/emulator" ]]; then
      EMULATOR_BIN="$ANDROID_SDK_DIR/emulator/emulator"
    fi
  fi
}

wait_for_android_device() {
  local device_id="$1"
  "$ADB_BIN" -s "$device_id" wait-for-device >/dev/null
  local waited=0
  until "$ADB_BIN" -s "$device_id" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q '^1$'; do
    sleep 2
    waited=$((waited + 2))
    if [[ $waited -ge 120 ]]; then
      echo "android emulator failed to boot within 120 seconds"
      exit 1
    fi
  done
}

resolve_android_device() {
  local booted
  resolve_android_tools
  booted="$("$ADB_BIN" devices | awk '/emulator-/{print $1; exit}')"
  if [[ -n "$booted" ]]; then
    echo "$booted"
    return
  fi

  if [[ -z "$EMULATOR_BIN" ]]; then
    echo "no booted Android emulator found and emulator command is unavailable"
    exit 1
  fi

  local avd_name="${ANDROID_AVD_NAME:-$("$EMULATOR_BIN" -list-avds | tail -n 1 | head -n 1)}"
  if [[ -z "$avd_name" ]]; then
    echo "no Android AVD available; set ANDROID_AVD_NAME or create an emulator"
    exit 1
  fi

  echo "Booting Android emulator: $avd_name" >&2
  "$EMULATOR_BIN" -avd "$avd_name" >/dev/null 2>&1 &
  local waited=0
  while [[ $waited -lt 120 ]]; do
    booted="$("$ADB_BIN" devices | awk '/emulator-/{print $1; exit}')"
    if [[ -n "$booted" ]]; then
      wait_for_android_device "$booted"
      echo "$booted"
      return
    fi
    sleep 2
    waited=$((waited + 2))
  done

  echo "failed to boot Android emulator"
  exit 1
}

is_ios_simulator_booted() {
  simctl_list_devices_with_retry | grep -i "booted" | grep -q "iPhone"
}

extract_ios_udid() {
  grep -oE '[A-F0-9-]{36}' | head -n 1
}

resolve_ios_udid() {
  local udid
  local device_list
  if is_ios_simulator_booted; then
    device_list="$(simctl_list_devices_with_retry)"
    printf '%s\n' "$device_list" | grep -i "booted" | grep "iPhone" | head -1 | extract_ios_udid
    return
  fi

  local simulator_name="${IOS_SIMULATOR_NAME:-iPhone 15 Pro}"
  if [[ -z "${CI:-}" ]]; then
    open_ios_simulator_app
    sleep 3
  fi

  device_list="$(simctl_list_devices_with_retry available)"
  udid="$(printf '%s\n' "$device_list" | grep -i "$simulator_name" | head -1 | extract_ios_udid)"
  if [[ -z "$udid" ]]; then
    udid="$(printf '%s\n' "$device_list" | grep -i "iPhone" | head -1 | extract_ios_udid)"
  fi
  if [[ -z "$udid" ]]; then
    echo "no iOS simulator available"
    exit 1
  fi

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  if xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
    echo "$udid"
    return
  fi
  local waited=0
  until is_ios_simulator_booted; do
    sleep 2
    waited=$((waited + 2))
    if [[ $waited -ge 120 ]]; then
      echo "iOS simulator failed to boot within 120 seconds"
      exit 1
    fi
  done
  echo "$udid"
}

run_flutter_drive() {
  local device_id="$1"
  pushd "$APP_DIR" >/dev/null
  if ! SIMULATED_SMOKE_RESPONSE_PATH="$RESPONSE_FILE" \
    SIMULATED_SMOKE_DEVICE_ID="$device_id" \
    SIMULATED_SMOKE_ADB_BIN="${ADB_BIN:-adb}" \
    flutter drive \
      --driver=test/integration_test_driver/simulated_headless_smoke_driver.dart \
      --target=integration_test/simulated_headless_smoke_test.dart \
      --dart-define=FLUTTER_TEST=true \
      --dart-define=AVRAI_ENABLE_DART_WHAT_FALLBACK=true \
      --dart-define=AVRAI_REQUIRE_NATIVE_LOCALITY=false \
      --dart-define="SIMULATED_SMOKE_PLATFORM=$PLATFORM" \
      --dart-define="SIMULATED_SMOKE_SCENARIO_PROFILE=$SCENARIO_PROFILE" \
      -d "$device_id" \
      >"$DRIVE_LOG" 2>&1; then
    popd >/dev/null
    return 1
  fi
  popd >/dev/null
}

use_stub_bundle() {
  cp "$STUB_RESPONSE_PATH" "$RESPONSE_FILE"
  cp -R "$STUB_BUNDLE_DIR"/. "$TMP_DIR"/
}

copy_ios_bundle() {
  local simulator_udid="$1"
  local run_id="$2"
  local export_dir="${3:-}"
  if [[ -z "$export_dir" || ! -d "$export_dir" ]]; then
    local container
    container="$(xcrun simctl get_app_container "$simulator_udid" "$APP_BUNDLE_ID" data)"
    if [[ -z "$container" ]]; then
      echo "failed to resolve iOS simulator app container"
      exit 1
    fi
    export_dir="$container/Documents/proof_runs/$run_id"
  fi
  if [[ ! -d "$export_dir" ]]; then
    echo "proof export directory not found in iOS simulator container: $export_dir"
    exit 1
  fi
  cp -R "$export_dir"/. "$TMP_DIR"/
}

copy_android_bundle() {
  local device_id="$1"
  local run_id="$2"
  local proof_run_dir
  proof_run_dir="$(
    "$ADB_BIN" -s "$device_id" exec-out run-as "$APP_BUNDLE_ID" \
      sh -c "find . -type d -path '*proof_runs/$run_id' | head -n 1" \
      2>/dev/null | tr -d '\r' | tr -d '\n'
  )"
  if [[ -z "$proof_run_dir" ]]; then
    echo "proof export directory not found in Android app storage for run $run_id"
    exit 1
  fi
  "$ADB_BIN" -s "$device_id" exec-out run-as "$APP_BUNDLE_ID" \
    sh -c "cd '$proof_run_dir' && tar -cf - ." >"$TMP_DIR/proof_bundle.tar"
  tar -xf "$TMP_DIR/proof_bundle.tar" -C "$TMP_DIR"
  rm -f "$TMP_DIR/proof_bundle.tar"
}

bundle_files_present() {
  local file_name
  for file_name in "${REQUIRED_BUNDLE_FILES[@]}"; do
    if [[ ! -f "$TMP_DIR/$file_name" ]]; then
      return 1
    fi
  done
  return 0
}

DEVICE_ID=""
if [[ -n "$STUB_RESPONSE_PATH" ]]; then
  echo "Running simulated headless smoke in stub mode on $PLATFORM"
  use_stub_bundle
else
  if [[ "$PLATFORM" == "ios" ]]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
      echo "iOS simulator smoke requires macOS"
      exit 1
    fi
    DEVICE_ID="$(resolve_ios_udid)"
  else
    resolve_android_tools
    if [[ -z "$ADB_BIN" ]]; then
      echo "adb is required for Android simulator smoke runs"
      exit 1
    fi
    DEVICE_ID="$(resolve_android_device)"
  fi

  echo "Running simulated headless smoke on $PLATFORM ($DEVICE_ID)"
  if ! run_flutter_drive "$DEVICE_ID"; then
    echo "flutter drive failed"
    echo "See $DRIVE_LOG for details"
    exit 1
  fi
fi

if [[ ! -f "$RESPONSE_FILE" ]]; then
  echo "smoke response file was not created: $RESPONSE_FILE"
  echo "See $DRIVE_LOG for details"
  exit 1
fi

RUN_ID="$(json_string_field "$RESPONSE_FILE" run_id)"
SUCCESS="$(json_bool_field "$RESPONSE_FILE" success)"
FAILURE_SUMMARY="$(json_string_field "$RESPONSE_FILE" failure_summary)"
EXPORT_DIRECTORY_PATH="$(json_string_field "$RESPONSE_FILE" export_directory_path)"
RESPONSE_SCENARIO_PROFILE="$(json_string_field "$RESPONSE_FILE" scenario_profile)"
SCENARIO_PROFILE_VALUE="${RESPONSE_SCENARIO_PROFILE:-$SCENARIO_PROFILE}"
RUN_STATUS="failed"
if [[ "$SUCCESS" == "true" ]]; then
  RUN_STATUS="passed"
fi
FAILURE_SUMMARY_ESCAPED="${FAILURE_SUMMARY//\"/\\\"}"

if [[ -z "$RUN_ID" ]]; then
  echo "smoke response did not include run_id"
  echo "See $RESPONSE_FILE and $DRIVE_LOG for details"
  exit 1
fi

if ! bundle_files_present; then
  if [[ "$PLATFORM" == "ios" ]]; then
    copy_ios_bundle "$DEVICE_ID" "$RUN_ID" "$EXPORT_DIRECTORY_PATH"
  else
    copy_android_bundle "$DEVICE_ID" "$RUN_ID"
  fi
fi

GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || true)"
cat >"$MANIFEST_FILE" <<EOF
{
  "artifact_kind": "simulated_headless_smoke",
  "run_id": "$RUN_ID",
  "platform": "${PLATFORM}_simulator",
  "platform_mode": "$PLATFORM",
  "scenario_profile": "$SCENARIO_PROFILE_VALUE",
  "run_status": "$RUN_STATUS",
  "simulated": true,
  "bundle_id": "$APP_BUNDLE_ID",
  "git_sha": "$GIT_SHA",
  "timestamp": "$TS",
  "timestamp_utc": "$TS_UTC",
  "notes": "Automated simulated headless smoke artifact. Encounter and wake coverage are simulated only; no physical BLE or radio claim is made.",
  "smoke_response_success": ${SUCCESS:-false},
  "failure_summary": "${FAILURE_SUMMARY_ESCAPED}"
}
EOF

resolve_dart_bin
"$DART_BIN" run "$VALIDATOR_SCRIPT" "$TMP_DIR" --summary-path="$VALIDATION_SUMMARY" >/dev/null
write_run_artifact_index "$TMP_DIR"

FINAL_DIR="$ARTIFACT_ROOT/${TS}_${PLATFORM}_${SCENARIO_PROFILE_VALUE}_simulated_smoke_${RUN_ID}"
FINAL_DIR="$(reserve_final_artifact_dir)"
mv "$TMP_DIR" "$FINAL_DIR"
TMP_DIR=""

ZIP_FILE="${FINAL_DIR}.zip"
if command -v zip >/dev/null 2>&1; then
  (
    cd "$ARTIFACT_ROOT"
    zip -rq "$(basename "$ZIP_FILE")" "$(basename "$FINAL_DIR")"
  )
fi
update_simulated_smoke_index
refresh_bham_beta_readiness_summary

echo "DONE"
echo "Artifact folder: $FINAL_DIR"
if [[ -f "$ZIP_FILE" ]]; then
  echo "Artifact zip:    $ZIP_FILE"
fi
echo "Response file:   $FINAL_DIR/$(basename "$RESPONSE_FILE")"
echo "Validation:      $FINAL_DIR/$(basename "$VALIDATION_SUMMARY")"
echo "Readiness:       $ARTIFACT_ROOT/bham_beta_readiness_summary.json"

if [[ "$SUCCESS" != "true" ]]; then
  echo "Simulated smoke reported failure: ${FAILURE_SUMMARY:-unknown}"
  exit 1
fi
