#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
RUNTIME_DIR="$ROOT_DIR/runtime/avrai_runtime_os"

COMMIT_REF="${SECURITY_TRIGGER_COMMIT_REF:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
ACTOR_ALIAS="${SECURITY_TRIGGER_ACTOR_ALIAS:-ci_release}"

collect_changed_paths() {
  if [[ -n "${SECURITY_TRIGGER_CHANGED_PATHS_FILE:-}" ]]; then
    grep -v '^[[:space:]]*$' "$SECURITY_TRIGGER_CHANGED_PATHS_FILE" | awk '!seen[$0]++'
  elif [[ $# -gt 0 && -n "$1" ]]; then
    git -C "$ROOT_DIR" diff --name-only "$1" | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++'
  elif git -C "$ROOT_DIR" rev-parse --verify HEAD^ >/dev/null 2>&1; then
    git -C "$ROOT_DIR" diff --name-only HEAD^ HEAD | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++'
  else
    git -C "$ROOT_DIR" show --pretty='' --name-only HEAD | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++'
  fi
}

main() {
  local diff_range="${1:-}"
  local -a changed_paths=()
  local path
  while IFS= read -r path; do
    changed_paths+=("$path")
  done < <(collect_changed_paths "$diff_range")

  if [[ "${#changed_paths[@]}" -eq 0 ]]; then
    echo "No changed paths detected for security trigger ingress; skipping queue."
    return 0
  fi

  echo "Queueing security code-change triggers for ${#changed_paths[@]} changed path(s) at ${COMMIT_REF}."

  local changed_paths_file
  changed_paths_file="$(mktemp)"
  trap 'rm -f "$changed_paths_file"' EXIT
  printf '%s\n' "${changed_paths[@]}" > "$changed_paths_file"

  local -a cmd=(
    flutter test
    test/tools/security_code_change_trigger_ci_driver_test.dart
    --reporter compact
    --dart-define="SECURITY_TRIGGER_COMMIT_REF=$COMMIT_REF"
    --dart-define="SECURITY_TRIGGER_ACTOR_ALIAS=$ACTOR_ALIAS"
    --dart-define="SECURITY_TRIGGER_CHANGED_PATHS_FILE=$changed_paths_file"
  )

  (
    cd "$RUNTIME_DIR"
    "${cmd[@]}"
  )
}

main "$@"
