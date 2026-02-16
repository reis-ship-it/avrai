#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/phase_root_sync.sh --phase P1 [--remote origin] [--push]

What this does:
  1) Verifies clean working tree.
  2) Fetches latest refs from remote.
  3) Fast-forwards local main to <remote>/main.
  4) Merges updated main into phase#_work.
  5) Optionally pushes phase#_work with --push.

Examples:
  scripts/phase_root_sync.sh --phase P1 --push
  scripts/phase_root_sync.sh --phase P7 --remote origin --push
USAGE
}

phase=""
remote_name="origin"
push_branch="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      phase="${2:-}"
      shift 2
      ;;
    --remote)
      remote_name="${2:-}"
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
start_branch="$(git rev-parse --abbrev-ref HEAD)"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit/stash before running phase sync." >&2
  exit 1
fi

echo "Fetching latest refs from ${remote_name}"
git fetch --prune "${remote_name}"

echo "Switching to main"
git switch main

echo "Fast-forwarding main from ${remote_name}/main"
git pull --ff-only "${remote_name}" main

if git show-ref --verify --quiet "refs/heads/${phase_branch}"; then
  echo "Switching to ${phase_branch}"
  git switch "${phase_branch}"
else
  if git show-ref --verify --quiet "refs/remotes/${remote_name}/${phase_branch}"; then
    echo "Creating local ${phase_branch} from ${remote_name}/${phase_branch}"
    git switch -c "${phase_branch}" --track "${remote_name}/${phase_branch}"
  else
    echo "Phase branch '${phase_branch}' not found locally or on ${remote_name}." >&2
    git switch "${start_branch}"
    exit 1
  fi
fi

echo "Merging main into ${phase_branch}"
git merge --no-edit main

if [[ "${push_branch}" == "true" ]]; then
  echo "Pushing ${phase_branch}"
  git push "${remote_name}" "${phase_branch}"
fi

echo "Returning to starting branch: ${start_branch}"
git switch "${start_branch}"

echo "Done. ${phase_branch} is synced with main."
