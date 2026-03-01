#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Search suite (unit + widget + integration).
flutter test "$@" \
  test/unit/domain/usecases/search/ \
  test/unit/data/repositories/hybrid_search_repository_test.dart \
  test/widget/pages/search/ \
  test/integration/hybrid_search_performance_test.dart

