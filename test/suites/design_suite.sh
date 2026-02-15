#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Design regression suite: structural guardrails + design goldens.
dart run tool/design_guardrails.dart

flutter test "$@" \
  test/widget/design/
