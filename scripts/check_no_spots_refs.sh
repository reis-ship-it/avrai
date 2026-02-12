#!/bin/bash
# Fail if new SPOTS domain refs are introduced outside _archive and allowed paths.
# Used by CI to prevent reintroducing legacy domain strings in active code/docs.
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Exclude: _archive, .git, this script, rename script (migration), historical reports
HITS=$(grep -rn "spots\.app\|spots\.com\|com\.spots\.app" \
  --include="*.dart" --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" \
  --exclude-dir="_archive" --exclude-dir=".git" \
  --exclude="check_no_spots_refs.sh" --exclude="rename_to_avra.sh" \
  --exclude-dir="reports" . 2>/dev/null || true)

# Also skip docs/reports and docs/agents/reports (historical)
HITS=$(echo "$HITS" | grep -v "^./docs/reports/" | grep -v "^./docs/agents/reports/" || true)

if [ -n "$HITS" ]; then
  echo "ERROR: Found legacy domain references outside _archive and allowed paths:"
  echo "$HITS"
  exit 1
fi
echo "OK: No legacy domain references in active paths"
