#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/apps/avrai_app"

cd "${APP_DIR}"

echo "Running BHAM consumer beta gate suites (serial mode)..."
flutter test --fail-fast --concurrency=1 \
  test/unit/domain/usecases/auth/ \
  test/unit/data/datasources/local/auth_sembast_datasource_test.dart \
  test/unit/data/datasources/remote/auth_remote_datasource_impl_test.dart \
  test/unit/data/repositories/auth_repository_impl_test.dart \
  test/widget/pages/auth/login_page_test.dart \
  test/widget/pages/auth/signup_page_test.dart \
  test/unit/data/datasources/local/onboarding_completion_service_test.dart \
  test/widget/pages/onboarding/ai_loading_page_test.dart \
  test/unit/controllers/onboarding_flow_controller_test.dart \
  test/unit/routes/app_router_test.dart \
  test/unit/services/bham_daily_drop_builder_test.dart \
  test/unit/services/bham_route_planner_test.dart \
  test/unit/services/direct_match_service_test.dart \
  test/unit/services/bham_notification_policy_service_test.dart \
  test/unit/services/friend_chat_service_test.dart \
  test/unit/services/event_chat_service_test.dart \
  test/unit/services/community_chat_service_test.dart \
  test/unit/services/personality_agent_chat_service_test.dart \
  test/unit/services/community_service_test.dart \
  test/unit/services/club_service_test.dart \
  test/widget/pages/home/home_page_test.dart \
  test/widget/pages/profile/profile_page_test.dart \
  test/widget/pages/settings/notifications_settings_page_test.dart

echo
echo "BHAM consumer beta gate suites passed."
echo "Deferred business, expertise, partnership, payment, admin, and legacy broad-suite integrations are intentionally excluded from this gate."
echo "To run the BHAM heavy consumer suites separately:"
echo "  RUN_HEAVY_INTEGRATION_TESTS=true bash work/scripts/run_bham_heavy_consumer_suites.sh"
