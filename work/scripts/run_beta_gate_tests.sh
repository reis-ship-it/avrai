#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/avrai_app"

cd "${APP_DIR}"

echo "Running beta gate suites (unit + widget + core, serial mode)..."
flutter test --coverage --fail-fast --concurrency=1 test/unit test/widget test/core

echo
echo "Beta gate suites passed."
echo "To run heavy integration/performance suites separately:"
echo "  RUN_HEAVY_INTEGRATION_TESTS=true flutter test test/integration test/performance test/platform"
