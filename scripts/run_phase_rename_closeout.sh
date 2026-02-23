#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "" ]]; then
  echo "Usage: $0 P# [--limit N]"
  echo "Example: $0 P1 --limit 50"
  exit 1
fi

PHASE_TARGET="$1"
shift || true

echo "[rename-closeout] Autofilling untracked rename candidates for ${PHASE_TARGET}..."
python3 scripts/suggest_rename_candidates_inventory.py --apply --phase-close-target "${PHASE_TARGET}" "$@"

echo "[rename-closeout] Validating rename governance register..."
python3 scripts/validate_rename_candidates.py

echo "[rename-closeout] Complete. Next: set proposed_name/architecture refs/milestones and execute approved renames."

