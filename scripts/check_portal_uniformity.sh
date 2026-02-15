#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PAGES_DIR="lib/presentation/pages"
EXIT_CODE=0

echo "Portal Uniformity Check"
echo "======================="

card_count="$( (rg -n '\bCard\(' "$PAGES_DIR" || true) | wc -l | tr -d ' ')"
echo "Card usages in pages: $card_count"
if [[ "$card_count" != "0" ]]; then
  echo
  echo "ERROR: Found Card usages in page layer. Use PortalSurface instead."
  rg -n '\bCard\(' "$PAGES_DIR"
  EXIT_CODE=1
fi

portal_surface_count="$( (rg -n '\bPortalSurface\(' "$PAGES_DIR" || true) | wc -l | tr -d ' ')"
echo "PortalSurface usages in pages: $portal_surface_count"

box_dec_count="$( (rg -n 'BoxDecoration\(' "$PAGES_DIR" || true) | wc -l | tr -d ' ')"
echo "BoxDecoration usages in pages: $box_dec_count"
echo "Top files with BoxDecoration (review manually for card-like shells):"
(rg -n 'BoxDecoration\(' "$PAGES_DIR" || true) \
  | sed -E 's#^([^:]+):.*#\1#' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -20 || true

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo
  echo "PASS: No Card usage found in $PAGES_DIR."
fi

exit "$EXIT_CODE"
