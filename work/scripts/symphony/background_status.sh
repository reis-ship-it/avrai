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
SYMPHONY_PORT="${SYMPHONY_PORT:-4020}"
pid_file="$SYMPHONY_LOGS_ROOT/symphony.pid"
console_log="$SYMPHONY_LOGS_ROOT/console.log"
launchd_stdout="$SYMPHONY_LOGS_ROOT/launchd.stdout.log"
launchd_stderr="$SYMPHONY_LOGS_ROOT/launchd.stderr.log"
launchd_label="com.avrai.symphony"
launchd_domain="gui/$(id -u)"

if [[ -f "$pid_file" ]]; then
  pid="$(cat "$pid_file" 2>/dev/null || true)"
else
  pid=""
fi

if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  echo "process: running (manual pid $pid)"
elif launchctl print "$launchd_domain/$launchd_label" >/dev/null 2>&1; then
  echo "process: running via launchd ($launchd_label)"
else
  echo "process: not running"
fi

if command -v curl >/dev/null 2>&1 && curl -fsS "http://127.0.0.1:$SYMPHONY_PORT/api/v1/state" >/dev/null 2>&1; then
  echo "dashboard: reachable at http://127.0.0.1:$SYMPHONY_PORT/"
else
  echo "dashboard: not reachable"
fi

if [[ -f "$console_log" ]]; then
  echo "log: $console_log"
elif [[ -f "$launchd_stdout" ]] || [[ -f "$launchd_stderr" ]]; then
  echo "log: $launchd_stdout"
  echo "err: $launchd_stderr"
else
  echo "log: missing"
fi
