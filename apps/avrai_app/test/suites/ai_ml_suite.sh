#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# AI & ML suite (unit + widget + integration).
flutter test "$@" \
  test/unit/services/ai2ai_realtime_service_test.dart \
  test/unit/services/llm_service_test.dart \
  test/unit/services/llm_service_language_style_test.dart \
  test/unit/services/personality_analysis_service_test.dart \
  test/unit/services/personality_sync_service_test.dart \
  test/unit/services/user_preference_learning_service_test.dart \
  test/widget/pages/network/ \
  test/widget/pages/profile/ \
  test/integration/ai2ai_complete_integration_test.dart \
  test/integration/ai2ai_ecosystem_test.dart \
  test/integration/ai2ai_learning_methods_integration_test.dart \
  test/integration/continuous_learning_integration_test.dart \
  test/integration/ai_improvement_tracking_integration_test.dart \
  test/integration/ui_llm_integration_test.dart

