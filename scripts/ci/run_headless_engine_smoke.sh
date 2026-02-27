#!/bin/bash
set -euo pipefail

# Headless smoke gate for core loop surfaces (no app boot path).
# Keep this small and deterministic for CI reliability.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

flutter test test/unit/ai/continuous_learning_system_first_occurrence_alert_test.dart
flutter test test/unit/ai/world_model/mpc_planner/planner_action_prefilter_test.dart
flutter test test/unit/ai/engine_contracts/engine_schema_contract_test.dart
flutter test test/unit/services/infrastructure/runtime/runtime_contract_registry_test.dart
flutter test test/unit/services/infrastructure/runtime/runtime_bootstrap_guard_test.dart
flutter test test/unit/services/infrastructure/runtime/runtime_capability_profile_test.dart
flutter test test/unit/services/infrastructure/runtime/runtime_host_adapter_conformance_test.dart

echo "OK: Headless engine smoke lane passed."
