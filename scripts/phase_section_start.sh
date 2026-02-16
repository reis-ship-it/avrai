#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/phase_section_start.sh --phase P1 --section 1.2.8 [--parent <branch>] [--push]

What this does:
  1) Resolves the parent branch (explicit --parent, current phase branch path, or phase#_work).
  2) Creates the next section branch as a child of the parent:
     <parent>/sX_Y_Z
  3) Switches to the new branch.
  4) Optionally pushes branch with --push.

Examples:
  scripts/phase_section_start.sh --phase P1 --section 1.2.8
  scripts/phase_section_start.sh --phase P1 --section 1.2.8.1 --parent phase1_work/s1_2_8
USAGE
}

phase=""
section=""
parent_override=""
push_branch="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      phase="${2:-}"
      shift 2
      ;;
    --section)
      section="${2:-}"
      shift 2
      ;;
    --parent)
      parent_override="${2:-}"
      shift 2
      ;;
    --push)
      push_branch="true"
      shift
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

if [[ -z "$phase" || -z "$section" ]]; then
  echo "Missing required args: --phase and --section" >&2
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
current_branch="$(git rev-parse --abbrev-ref HEAD)"

parent_branch="$parent_override"
if [[ -z "$parent_branch" ]]; then
  if [[ "$current_branch" =~ ^${phase_branch}(/.*)?$ ]]; then
    parent_branch="$current_branch"
  else
    parent_branch="$phase_branch"
  fi
fi

if ! [[ "$parent_branch" =~ ^${phase_branch}(/.*)?$ ]]; then
  echo "Parent branch '$parent_branch' is not under phase root '$phase_branch'." >&2
  exit 1
fi

if [[ "$current_branch" != "$parent_branch" ]]; then
  echo "Switching to parent branch: $parent_branch"
  git switch "$parent_branch"
fi

section_slug="$(echo "$section" | tr '.' '_' | tr -cd '[:alnum:]_')"
if [[ -z "$section_slug" ]]; then
  echo "Invalid --section value: $section" >&2
  exit 1
fi

new_branch="${parent_branch}/s${section_slug}"
if git show-ref --verify --quiet "refs/heads/${new_branch}"; then
  echo "Branch already exists locally. Switching to: $new_branch"
  git switch "$new_branch"
else
  echo "Creating branch: $new_branch"
  git switch -c "$new_branch"
fi

if [[ "$push_branch" == "true" ]]; then
  echo "Pushing branch: $new_branch"
  git push -u origin "$new_branch"
fi

echo "Done. Current branch: $(git rev-parse --abbrev-ref HEAD)"
