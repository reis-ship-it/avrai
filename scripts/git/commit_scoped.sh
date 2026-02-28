#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"<commit message>\" <path1> [path2 ...]"
  exit 1
fi

msg="$1"
shift

# Always start with a clean index so unrelated pre-staged files cannot leak in.
git restore --staged :/

# Stage only the requested paths.
git add -- "$@"

# Verify staged set exactly matches requested set.
tmp_expected="$(mktemp)"
tmp_actual="$(mktemp)"
trap 'rm -f "$tmp_expected" "$tmp_actual"' EXIT

for p in "$@"; do
  printf '%s\n' "$p"
done | sort -u > "$tmp_expected"

git diff --cached --name-only | sort -u > "$tmp_actual"

if ! diff -u "$tmp_expected" "$tmp_actual" >/dev/null; then
  echo "ERROR: staged files do not exactly match requested paths."
  echo "--- expected"
  cat "$tmp_expected"
  echo "--- actual"
  cat "$tmp_actual"
  exit 2
fi

echo "Staged files:"
cat "$tmp_actual"

git commit -m "$msg"
