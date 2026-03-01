#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Spots & Lists suite (unit + widget + integration).
flutter test "$@" \
  test/unit/domain/usecases/lists/ \
  test/unit/domain/usecases/spots/ \
  test/unit/data/datasources/local/lists_sembast_datasource_test.dart \
  test/unit/data/datasources/local/spots_sembast_datasource_test.dart \
  test/unit/data/datasources/local/respected_lists_sembast_datasource_test.dart \
  test/unit/data/datasources/remote/lists_remote_datasource_impl_test.dart \
  test/unit/data/datasources/remote/spots_remote_datasource_impl_test.dart \
  test/unit/data/repositories/lists_repository_impl_test.dart \
  test/unit/data/repositories/spots_repository_impl_test.dart \
  test/unit/data/repositories/respected_lists_test.dart \
  test/unit/data/repositories/offline_mode_test.dart \
  test/widget/pages/lists/ \
  test/widget/pages/spots/ \
  test/integration/controllers/list_creation_controller_integration_test.dart \
  test/integration/offline_online_sync_test.dart

