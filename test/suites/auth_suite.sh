#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Authentication & Authorization suite (unit + widget + integration).
flutter test "$@" \
  test/unit/domain/usecases/auth/ \
  test/unit/data/datasources/local/auth_sembast_datasource_test.dart \
  test/unit/data/datasources/remote/auth_remote_datasource_impl_test.dart \
  test/unit/data/repositories/auth_repository_impl_test.dart \
  test/widget/pages/auth/ \
  test/integration/admin_auth_integration_test.dart

