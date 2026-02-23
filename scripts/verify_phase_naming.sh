#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/verify_phase_naming.sh --phase P1 [--branch phase1_work__s1_2_8]

Checks:
  1) Branch naming/layout follows phase hierarchy.
  2) Deferred rename register validates.
  3) Rename candidate inventory has no untracked service/orchestrator names.
USAGE
}

phase=""
branch="${BRANCH_NAME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      phase="${2:-}"
      shift 2
      ;;
    --branch)
      branch="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$phase" ]]; then
  echo "Missing required arg: --phase" >&2
  usage
  exit 1
fi

phase_num="${phase#P}"
phase_num="${phase_num#p}"
if ! [[ "$phase_num" =~ ^[0-9]+$ ]]; then
  echo "Invalid --phase value: $phase (expected P# like P1)" >&2
  exit 1
fi

phase_branch="phase${phase_num}_work"

if [[ -z "$branch" ]]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
fi

valid_pattern="^${phase_branch}(__s[a-z0-9_]+(_r[0-9]+)?)*$"
if ! [[ "$branch" =~ $valid_pattern ]]; then
  echo "Branch naming check failed: '$branch' is not a valid child of '$phase_branch'." >&2
  exit 1
fi

echo "Branch naming check passed: $branch"

echo "Running rename register validation"
python3 scripts/validate_rename_candidates.py

echo "Running rename inventory coverage check"
python3 scripts/suggest_rename_candidates_inventory.py --fail-on-untracked

echo "Naming verification passed"
