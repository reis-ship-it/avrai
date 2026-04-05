#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"

if [[ -f "$ROOT_DIR/.env.symphony" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "$ROOT_DIR/.env.symphony"
  set +a
fi

SYMPHONY_LOGS_ROOT="${SYMPHONY_LOGS_ROOT:-$HOME/code/symphony/log-avrai}"
pid_file="$SYMPHONY_LOGS_ROOT/symphony.pid"
console_log="$SYMPHONY_LOGS_ROOT/console.log"

mkdir -p "$SYMPHONY_LOGS_ROOT"

if [[ -f "$pid_file" ]]; then
  old_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "Symphony already running with pid $old_pid"
    exit 0
  fi
  rm -f "$pid_file"
fi

bash "$SCRIPT_DIR/doctor.sh"

nohup bash "$SCRIPT_DIR/start_local_symphony.sh" >"$console_log" 2>&1 &
new_pid=$!
echo "$new_pid" >"$pid_file"

sleep 2

if kill -0 "$new_pid" 2>/dev/null; then
  echo "Symphony started in background"
  echo "pid: $new_pid"
  echo "log: $console_log"
else
  echo "Symphony failed to stay running. Check $console_log" >&2
  exit 1
fi
