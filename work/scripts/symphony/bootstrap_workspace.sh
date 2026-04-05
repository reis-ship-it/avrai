#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"

bootstrap_mode="${AVRAI_SYMPHONY_BOOTSTRAP_MODE:-full}"
base_ref="${SYMPHONY_BASE_REF:-origin/main}"
push_remote_url="${SYMPHONY_GIT_PUSH_REMOTE_URL:-}"
local_snapshot="${SYMPHONY_LOCAL_REPO_SNAPSHOT:-}"
workspace_root="${SYMPHONY_WORKSPACE_ROOT:-}"
branch_prefix="${SYMPHONY_WORK_BRANCH_PREFIX:-agent/symphony}"

overlay_local_snapshot() {
  local snapshot_root="$1"

  if [[ ! -d "$snapshot_root" ]]; then
    echo "SYMPHONY_LOCAL_REPO_SNAPSHOT does not exist: $snapshot_root" >&2
    exit 1
  fi

  rsync -a --delete \
    --exclude '.git/' \
    --exclude '.symphony-workspaces/' \
    --exclude '.symphony-logs/' \
    --exclude '.env.symphony' \
    --exclude '.dart_tool/' \
    --exclude 'build/' \
    --exclude 'Pods/' \
    --exclude 'logs/' \
    --exclude 'tmp/' \
    --exclude 'temp/' \
    --exclude 'runtime_exports/' \
    "$snapshot_root"/ "$ROOT_DIR"/
}

safe_branch_segment() {
  local value="${1:-}"

  value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  value="$(printf '%s' "$value" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"

  if [[ -z "$value" ]]; then
    value="workspace"
  fi

  printf '%s\n' "$value"
}

install_pre_push_guard() {
  local git_dir hook_path

  git_dir="$(git rev-parse --git-dir)"
  hook_path="$git_dir/hooks/pre-push"

  cat >"$hook_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

current_branch="\$(git branch --show-current 2>/dev/null || true)"

if [[ "\$current_branch" == "main" ]]; then
  echo "Symphony guard: refusing to push from main. Use a dedicated branch under ${branch_prefix%/}/." >&2
  exit 1
fi

while read -r local_ref local_sha remote_ref remote_sha; do
  if [[ "\$local_ref" == "refs/heads/main" || "\$remote_ref" == "refs/heads/main" ]]; then
    echo "Symphony guard: refusing to push anything to main." >&2
    exit 1
  fi
done
EOF

  chmod +x "$hook_path"
}

maybe_prepare_workspace_branch() {
  local canonical_workspace_root workspace_parent issue_identifier branch_segment branch_name current_branch

  if [[ -z "$workspace_root" || ! -d "$workspace_root" ]]; then
    return 0
  fi

  canonical_workspace_root="$(cd "$workspace_root" && pwd -P)"
  workspace_parent="$(cd "$(dirname "$ROOT_DIR")" && pwd -P)"

  if [[ "$workspace_parent" != "$canonical_workspace_root" ]]; then
    return 0
  fi

  issue_identifier="$(basename "$ROOT_DIR")"
  branch_segment="$(safe_branch_segment "$issue_identifier")"
  branch_name="${branch_prefix%/}/${branch_segment}"
  current_branch="$(git branch --show-current || true)"

  if [[ "$current_branch" != "$branch_name" ]]; then
    git checkout -B "$branch_name"
  fi

  git config push.default current
  git config branch."$branch_name".pushRemote origin
  install_pre_push_guard

  echo "AVRAI Symphony branch ready: $branch_name"
}

cd "$ROOT_DIR"

git config rerere.enabled true
git config rerere.autoupdate true

git fetch origin --prune
git checkout -B main "$base_ref"

if [[ -n "$push_remote_url" ]]; then
  git remote set-url origin "$push_remote_url"
  git fetch origin --prune || true
fi

if [[ -n "$local_snapshot" ]]; then
  overlay_local_snapshot "$local_snapshot"
fi

maybe_prepare_workspace_branch

if command -v melos >/dev/null 2>&1; then
  melos bootstrap
fi

case "$bootstrap_mode" in
  full)
    bash work/scripts/ci/bootstrap_avrai_app_ci_env.sh
    ;;
  light)
    ;;
  minimal)
    ;;
  *)
    echo "Unsupported AVRAI_SYMPHONY_BOOTSTRAP_MODE: $bootstrap_mode" >&2
    exit 1
    ;;
esac

echo "AVRAI Symphony bootstrap complete (mode=$bootstrap_mode)"
