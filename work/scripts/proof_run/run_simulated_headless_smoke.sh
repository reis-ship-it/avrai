#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
APP_DIR="$ROOT_DIR/apps/avrai_app"
VALIDATOR_SCRIPT="$ROOT_DIR/work/tools/validate_simulated_smoke_bundle.dart"
PLATFORM="${1:-}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-}"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
ARTIFACT_ROOT="$ROOT_DIR/reports/proof_runs"
ANDROID_SDK_DIR="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
ADB_BIN="${ADB_BIN:-}"
EMULATOR_BIN="${EMULATOR_BIN:-}"

if [[ -z "$PLATFORM" ]]; then
  echo "usage: ./scripts/proof_run/run_simulated_headless_smoke.sh <ios|android>"
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

if [[ -z "$APP_BUNDLE_ID" ]]; then
  if [[ "$PLATFORM" == "android" ]]; then
    APP_BUNDLE_ID="com.avrai.avrai"
  else
    APP_BUNDLE_ID="com.avrai.app"
  fi
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required"
  exit 1
fi

mkdir -p "$ARTIFACT_ROOT"

TMP_DIR="$ARTIFACT_ROOT/${TS}_${PLATFORM}_simulated_smoke_PENDING"
mkdir -p "$TMP_DIR"

RESPONSE_FILE="$TMP_DIR/simulated_smoke_response.json"
DRIVE_LOG="$TMP_DIR/flutter_drive.log"
VALIDATION_SUMMARY="$TMP_DIR/validation_summary.json"
MANIFEST_FILE="$TMP_DIR/manifest.json"
REQUIRED_BUNDLE_FILES=(
  "ledger_rows.csv"
  "ledger_rows.jsonl"
  "background_wake_runs.json"
  "field_validation_proofs.json"
  "ambient_social_diagnostics.json"
)

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
  SIMULATED_SMOKE_RESPONSE_PATH="$RESPONSE_FILE" \
    SIMULATED_SMOKE_DEVICE_ID="$device_id" \
    SIMULATED_SMOKE_ADB_BIN="${ADB_BIN:-adb}" \
    flutter drive \
      --driver=test/integration_test_driver/simulated_headless_smoke_driver.dart \
      --target=integration_test/simulated_headless_smoke_test.dart \
      --dart-define=FLUTTER_TEST=true \
      --dart-define=AVRAI_ENABLE_DART_WHAT_FALLBACK=true \
      --dart-define=AVRAI_REQUIRE_NATIVE_LOCALITY=false \
      --dart-define="SIMULATED_SMOKE_PLATFORM=$PLATFORM" \
      -d "$device_id" \
      >"$DRIVE_LOG" 2>&1
  popd >/dev/null
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
run_flutter_drive "$DEVICE_ID"

if [[ ! -f "$RESPONSE_FILE" ]]; then
  echo "smoke response file was not created: $RESPONSE_FILE"
  echo "See $DRIVE_LOG for details"
  exit 1
fi

RUN_ID="$(json_string_field "$RESPONSE_FILE" run_id)"
SUCCESS="$(json_bool_field "$RESPONSE_FILE" success)"
FAILURE_SUMMARY="$(json_string_field "$RESPONSE_FILE" failure_summary)"
EXPORT_DIRECTORY_PATH="$(json_string_field "$RESPONSE_FILE" export_directory_path)"
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
  "run_id": "$RUN_ID",
  "platform": "${PLATFORM}_simulator",
  "simulated": true,
  "bundle_id": "$APP_BUNDLE_ID",
  "git_sha": "$GIT_SHA",
  "timestamp": "$TS",
  "notes": "Automated simulated headless smoke artifact. Encounter and wake coverage are simulated only; no physical BLE or radio claim is made.",
  "smoke_response_success": ${SUCCESS:-false},
  "failure_summary": "${FAILURE_SUMMARY_ESCAPED}"
}
EOF

dart run "$VALIDATOR_SCRIPT" "$TMP_DIR" --summary-path="$VALIDATION_SUMMARY" >/dev/null

FINAL_DIR="$ARTIFACT_ROOT/${TS}_${PLATFORM}_simulated_smoke_${RUN_ID}"
mv "$TMP_DIR" "$FINAL_DIR"

ZIP_FILE="$ARTIFACT_ROOT/${TS}_${PLATFORM}_simulated_smoke_${RUN_ID}.zip"
if command -v zip >/dev/null 2>&1; then
  (
    cd "$ARTIFACT_ROOT"
    zip -rq "$(basename "$ZIP_FILE")" "$(basename "$FINAL_DIR")"
  )
fi

echo "DONE"
echo "Artifact folder: $FINAL_DIR"
if [[ -f "$ZIP_FILE" ]]; then
  echo "Artifact zip:    $ZIP_FILE"
fi
echo "Response file:   $FINAL_DIR/$(basename "$RESPONSE_FILE")"
echo "Validation:      $FINAL_DIR/$(basename "$VALIDATION_SUMMARY")"

if [[ "$SUCCESS" != "true" ]]; then
  echo "Simulated smoke reported failure: ${FAILURE_SUMMARY:-unknown}"
  exit 1
fi
