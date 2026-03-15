#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/avrai_app"

cd "${APP_DIR}"

echo "Running BHAM heavy consumer suites..."
echo "Scope: BHAM-critical consumer integration paths only."
echo "Deferred business, expertise, partnership, payment, and admin suites are excluded."

flutter test --concurrency=1 \
  test/integration/basic_integration_test.dart \
  test/integration/infrastructure/offline_online_sync_test.dart \
  test/integration/infrastructure/device_discovery_flow_integration_test.dart \
  test/integration/ai2ai/routing_test.dart \
  test/integration/security/security_integration_test.dart \
  test/integration/community/community_club_integration_test.dart \
  test/integration/events/community_event_integration_test.dart

echo
echo "BHAM heavy consumer suites passed."
