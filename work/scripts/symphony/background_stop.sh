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

if [[ ! -f "$pid_file" ]]; then
  echo "No Symphony pid file found."
  exit 0
fi

pid="$(cat "$pid_file" 2>/dev/null || true)"
if [[ -z "$pid" ]]; then
  rm -f "$pid_file"
  echo "Empty Symphony pid file removed."
  exit 0
fi

if kill -0 "$pid" 2>/dev/null; then
  kill "$pid"
  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid"
  fi
  echo "Stopped Symphony pid $pid"
else
  echo "Symphony pid $pid was not running."
fi

rm -f "$pid_file"
