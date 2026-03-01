#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# BLE + Signal (Phase 14 / offline bootstrap) focused suite.
#
# Goal: Fast iteration while BLE prekey priming is under active development.
# This avoids paying the full "all_suites" cost on every change.
#
# Notes:
# - BLE side-effects are disabled by default in tests unless you opt in with:
#   --dart-define=SPOTS_ALLOW_BLE_SIDE_EFFECTS_IN_TESTS=true
# - Signal FFI “native” tests can SIGABRT during process finalization on macOS.
#   Keep this suite “safe” and focused on orchestration logic.
flutter test "$@" \
  test/unit/ai2ai/walkby_hotpath_simulation_test.dart \
  test/unit/ai2ai/connection_orchestrator_test.dart

