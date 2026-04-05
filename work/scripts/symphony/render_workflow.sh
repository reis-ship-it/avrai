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
SYMPHONY_PORT="${SYMPHONY_PORT:-4020}"
SYMPHONY_WORK_BRANCH_PREFIX="${SYMPHONY_WORK_BRANCH_PREFIX:-agent/symphony}"
CODEX_BIN="${CODEX_BIN:-$(command -v codex || true)}"
SYMPHONY_CODEX_COMMAND="${SYMPHONY_CODEX_COMMAND:-$CODEX_BIN app-server}"

if [[ -z "${SYMPHONY_LINEAR_PROJECT_SLUG:-}" ]]; then
  echo "SYMPHONY_LINEAR_PROJECT_SLUG is not set." >&2
  exit 1
fi

export SYMPHONY_LINEAR_PROJECT_SLUG
export SYMPHONY_SOURCE_REPO_URL
export SYMPHONY_WORKSPACE_ROOT
export SYMPHONY_PORT
export SYMPHONY_WORK_BRANCH_PREFIX
export SYMPHONY_CODEX_COMMAND

mkdir -p "$(dirname "$SYMPHONY_GENERATED_WORKFLOW")"

python3 - "$SYMPHONY_TEMPLATE" "$SYMPHONY_GENERATED_WORKFLOW" <<'PY'
from pathlib import Path
import os
import sys

template = Path(sys.argv[1]).read_text()
replacements = {
    "__SYMPHONY_LINEAR_PROJECT_SLUG__": os.environ["SYMPHONY_LINEAR_PROJECT_SLUG"],
    "__SYMPHONY_SOURCE_REPO_URL__": os.environ["SYMPHONY_SOURCE_REPO_URL"],
    "__SYMPHONY_WORKSPACE_ROOT__": os.environ["SYMPHONY_WORKSPACE_ROOT"],
    "__SYMPHONY_PORT__": os.environ["SYMPHONY_PORT"],
    "__SYMPHONY_WORK_BRANCH_PREFIX__": os.environ["SYMPHONY_WORK_BRANCH_PREFIX"],
    "__SYMPHONY_CODEX_COMMAND__": os.environ["SYMPHONY_CODEX_COMMAND"],
}

for old, new in replacements.items():
    template = template.replace(old, new)

Path(sys.argv[2]).write_text(template)
PY

echo "$SYMPHONY_GENERATED_WORKFLOW"
