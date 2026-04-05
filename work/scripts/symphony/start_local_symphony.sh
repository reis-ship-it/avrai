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
SYMPHONY_TEMPLATE="${SYMPHONY_TEMPLATE:-$ROOT_DIR/WORKFLOW.symphony.template.md}"
SYMPHONY_GENERATED_WORKFLOW="${SYMPHONY_GENERATED_WORKFLOW:-$SYMPHONY_ELIXIR_DIR/WORKFLOW.avrai.generated.md}"
SYMPHONY_SOURCE_REPO_URL="${SYMPHONY_SOURCE_REPO_URL:-$(git -C "$ROOT_DIR" remote get-url origin)}"
SYMPHONY_WORKSPACE_ROOT="${SYMPHONY_WORKSPACE_ROOT:-$HOME/code/symphony-workspaces/avrai}"
SYMPHONY_LOGS_ROOT="${SYMPHONY_LOGS_ROOT:-$HOME/code/symphony/log-avrai}"
SYMPHONY_PORT="${SYMPHONY_PORT:-4020}"
CODEX_BIN="${CODEX_BIN:-$(command -v codex || true)}"
MISE_BIN="${MISE_BIN:-$(command -v mise || true)}"
SYMPHONY_CODEX_COMMAND="${SYMPHONY_CODEX_COMMAND:-$CODEX_BIN app-server}"

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "LINEAR_API_KEY is not set. Run: bash work/scripts/symphony/doctor.sh" >&2
  exit 1
fi

if [[ -z "${SYMPHONY_LINEAR_PROJECT_SLUG:-}" ]]; then
  echo "SYMPHONY_LINEAR_PROJECT_SLUG is not set. Run: bash work/scripts/symphony/doctor.sh" >&2
  exit 1
fi

if [[ -z "$CODEX_BIN" ]]; then
  echo "Could not find codex in PATH. Set CODEX_BIN explicitly or run the doctor script." >&2
  exit 1
fi

if [[ -z "$MISE_BIN" ]]; then
  echo "Could not find mise in PATH. Set MISE_BIN explicitly or run the doctor script." >&2
  exit 1
fi

if [[ ! -x "$SYMPHONY_ELIXIR_DIR/bin/symphony" ]]; then
  echo "Symphony binary not found at $SYMPHONY_ELIXIR_DIR/bin/symphony" >&2
  echo "Build it first with: cd $SYMPHONY_ELIXIR_DIR && mise trust && mise install && mise exec -- mix setup && mise exec -- mix build" >&2
  exit 1
fi

mkdir -p "$SYMPHONY_WORKSPACE_ROOT" "$SYMPHONY_LOGS_ROOT"

"$SCRIPT_DIR/check_source_repo.sh"

generated_workflow="$("$SCRIPT_DIR/render_workflow.sh")"

echo "Starting Symphony"
echo "Workflow: $generated_workflow"
echo "Workspaces: $SYMPHONY_WORKSPACE_ROOT"
echo "Dashboard: http://127.0.0.1:$SYMPHONY_PORT/"

cd "$SYMPHONY_ELIXIR_DIR"
exec "$MISE_BIN" exec -- ./bin/symphony \
  --i-understand-that-this-will-be-running-without-the-usual-guardrails \
  --logs-root "$SYMPHONY_LOGS_ROOT" \
  "$generated_workflow"
