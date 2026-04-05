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

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SYMPHONY_ELIXIR_DIR="${SYMPHONY_ELIXIR_DIR:-$HOME/code/symphony/elixir}"
SYMPHONY_WORKSPACE_ROOT="${SYMPHONY_WORKSPACE_ROOT:-$HOME/code/symphony-workspaces/avrai}"
SYMPHONY_LOGS_ROOT="${SYMPHONY_LOGS_ROOT:-$HOME/code/symphony/log-avrai}"
SYMPHONY_PORT="${SYMPHONY_PORT:-4020}"
MISE_BIN="${MISE_BIN:-$(command -v mise || true)}"
CODEX_BIN="${CODEX_BIN:-$(command -v codex || true)}"

failures=0

check() {
  local label="$1"
  local status="$2"
  local detail="${3:-}"
  printf '%-24s %s' "$label" "$status"
  if [[ -n "$detail" ]]; then
    printf '  %s' "$detail"
  fi
  printf '\n'
}

ok() { check "$1" "OK" "${2:-}"; }
warn() { check "$1" "WARN" "${2:-}"; failures=$((failures + 1)); }
info() { check "$1" "INFO" "${2:-}"; }

if [[ -n "$MISE_BIN" ]] && [[ -x "$MISE_BIN" ]]; then
  ok "mise" "$("$MISE_BIN" --version)"
else
  warn "mise" "missing"
fi

if [[ -n "$CODEX_BIN" ]]; then
  ok "codex" "$("$CODEX_BIN" --version 2>/dev/null || echo "$CODEX_BIN")"
else
  warn "codex" "missing from PATH"
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh auth" "authenticated"
  else
    warn "gh auth" "not authenticated"
  fi
else
  warn "gh" "missing"
fi

if [[ -x "$SYMPHONY_ELIXIR_DIR/bin/symphony" ]]; then
  ok "symphony bin" "$SYMPHONY_ELIXIR_DIR/bin/symphony"
else
  warn "symphony bin" "missing at $SYMPHONY_ELIXIR_DIR/bin/symphony"
fi

if [[ -n "${LINEAR_API_KEY:-}" ]]; then
  ok "LINEAR_API_KEY" "set"
else
  warn "LINEAR_API_KEY" "unset"
fi

if [[ -n "${SYMPHONY_LINEAR_PROJECT_SLUG:-}" ]]; then
  ok "project slug" "$SYMPHONY_LINEAR_PROJECT_SLUG"
else
  warn "project slug" "unset"
fi

mkdir -p "$SYMPHONY_WORKSPACE_ROOT" "$SYMPHONY_LOGS_ROOT"
ok "workspace root" "$SYMPHONY_WORKSPACE_ROOT"
ok "logs root" "$SYMPHONY_LOGS_ROOT"
ok "dashboard port" "$SYMPHONY_PORT"

if [[ -f "$ROOT_DIR/.env.symphony" ]]; then
  ok ".env.symphony" "present"
else
  info ".env.symphony" "missing; copy from .env.symphony.example if you want file-based config"
fi

if "$SCRIPT_DIR/check_source_repo.sh"; then
  :
else
  failures=$((failures + 1))
fi

if [[ $failures -ne 0 ]]; then
  printf '\n%s\n' "Symphony preflight found $failures issue(s)."
  exit 1
fi

printf '\n%s\n' "Symphony preflight passed."
