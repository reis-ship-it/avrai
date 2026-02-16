#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/verify_phase_naming.sh --phase P1 [--branch phase1_work/s1_2_8]

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

if ! [[ "$branch" =~ ^${phase_branch}(/.*)?$ ]]; then
  echo "Branch naming check failed: '$branch' is not within '$phase_branch'." >&2
  exit 1
fi

IFS='/' read -r -a branch_parts <<<"$branch"
if [[ ${#branch_parts[@]} -gt 1 ]]; then
  for ((i=1; i<${#branch_parts[@]}; i++)); do
    part="${branch_parts[$i]}"
    if ! [[ "$part" =~ ^s[a-z0-9_]+(_r[0-9]+)?$ ]]; then
      echo "Branch naming check failed: segment '$part' must match '^s[a-z0-9_]+(_r[0-9]+)?$'." >&2
      exit 1
    fi
  done
fi

echo "Branch naming check passed: $branch"

echo "Running rename register validation"
python3 scripts/validate_rename_candidates.py

echo "Running rename inventory coverage check"
python3 scripts/suggest_rename_candidates_inventory.py --fail-on-untracked

echo "Naming verification passed"
