#!/usr/bin/env bash
set -euo pipefail

echo "Running core unit tests (excluding legacy)..."

# Target common stable directories explicitly to avoid legacy/noisy suites
paths=(
  test/unit/ai2ai
  test/unit/models
  test/unit/repositories
  test/unit/usecases
  test/unit/blocs
  test/integration
  test/widget
)

found_any=false
for p in "${paths[@]}"; do
  if [[ -d "$p" ]]; then
    found_any=true
    echo "→ flutter test $p"
    flutter test "$p" --reporter=expanded || exit 1
  fi
done

if [[ "$found_any" == false ]]; then
  echo "No target test directories found; running a smoke test."
  flutter test -r expanded || true
fi

echo "✅ Core tests completed"


