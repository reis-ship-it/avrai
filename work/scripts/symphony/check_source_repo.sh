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

source_repo="${SYMPHONY_LOCAL_REPO_SNAPSHOT:-${SYMPHONY_SOURCE_REPO_URL:-}}"
base_ref="${SYMPHONY_BASE_REF:-origin/main}"

if [[ -z "$source_repo" ]]; then
  echo "source repo: WARN  no local source repo configured"
  exit 1
fi

if [[ ! -d "$source_repo" ]]; then
  echo "source repo: OK    remote source configured; local git safety check skipped"
  exit 0
fi

if ! git -C "$source_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "source repo: WARN  local path is not a git work tree: $source_repo"
  exit 1
fi

printf '%-24s %s\n' "source repo" "OK    $source_repo"

git -C "$source_repo" fetch origin --prune >/dev/null 2>&1 || {
  echo "source fetch: WARN  failed to fetch origin"
  exit 1
}
printf '%-24s %s\n' "source fetch" "OK"

branch_name="$(git -C "$source_repo" branch --show-current || true)"
head_sha="$(git -C "$source_repo" rev-parse --short HEAD)"
printf '%-24s %s\n' "source HEAD" "INFO  ${branch_name:-detached}@$head_sha"

compare_ref="$base_ref"
if git -C "$source_repo" show-ref --verify --quiet "refs/remotes/origin/$base_ref"; then
  compare_ref="origin/$base_ref"
fi

if ! git -C "$source_repo" rev-parse --verify "$compare_ref" >/dev/null 2>&1; then
  echo "source base ref: WARN  missing comparison ref $compare_ref"
  exit 1
fi

counts="$(git -C "$source_repo" rev-list --left-right --count "$compare_ref...HEAD")"
behind_count="${counts%%[[:space:]]*}"
ahead_count="${counts##*[[:space:]]}"

if [[ "$behind_count" != "0" ]]; then
  echo "source sync: WARN  behind $compare_ref by $behind_count commit(s)"
  exit 1
fi

printf '%-24s %s\n' "source sync" "OK    ahead $ahead_count / behind $behind_count vs $compare_ref"

if ! git -C "$source_repo" diff --quiet --ignore-submodules HEAD --; then
  echo "source tracked files: WARN  unstaged tracked changes present"
  exit 1
fi
printf '%-24s %s\n' "source tracked files" "OK"

if ! git -C "$source_repo" diff --cached --quiet --ignore-submodules --; then
  echo "source staged files: WARN  staged changes present"
  exit 1
fi
printf '%-24s %s\n' "source staged files" "OK"

untracked_count="$(git -C "$source_repo" ls-files --others --exclude-standard | wc -l | tr -d ' ')"
if [[ "$untracked_count" != "0" ]]; then
  echo "source untracked: WARN  $untracked_count untracked file(s) present"
  exit 1
fi
printf '%-24s %s\n' "source untracked" "OK"

printf '\n%s\n' "Source repo safety check passed."
