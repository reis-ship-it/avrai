# Codebase -> Master Plan File Mapping (2026-02-15)

**Purpose:** File-level architecture mapping for the current 3-prong monorepo.
**Coverage:** All tracked files under `apps/`, `runtime/`, `engine/`, `shared/`, `work/scripts/`, `work/tools/`, and `work/supabase/`.
**Total mapped files:** 6716
**Full inventory export:** generate on demand with `python3 scripts/generate_master_plan_file_mapping.py --emit-csv /tmp/codebase_master_plan_mapping_2026-02-15.csv`.
**Method:** Deterministic path-to-domain rules with per-file dependency-graph payloads aligned to current package ownership.

## Disposition Summary

| Disposition | File Count |
|---|---:|
| keep_update | 6251 |
| keep_review | 465 |

## Domain Summary

| Domain | File Count |
|---|---:|
| security-signal-ffi | 1494 |
| app-testing-quality | 1057 |
| runtime-os-prong | 1027 |
| user-app-surface | 457 |
| tooling-ops | 346 |
| shared-core | 338 |
| app-package-root | 324 |
| runtime-testing-quality | 267 |
| runtime-package-root | 168 |
| apps-runtime-config | 142 |
| supabase-infra | 129 |
| runtime-transport | 120 |
| knot-engine | 116 |
| prediction-runtime | 104 |
| admin-oversight-surface | 86 |
| runtime-ai2ai | 84 |
| runtime-network-prong | 68 |
| tooling-dev | 48 |
| tooling-runtime | 44 |
| runtime-network-native | 40 |
| apps-bootstrap | 31 |
| reality-engine | 31 |
| supabase-functions | 30 |
| runtime-security | 28 |
| runtime-orchestration | 23 |
| business-runtime | 22 |
| apps-config | 20 |
| unclassified-monorepo-surface | 20 |
| admin-bootstrap | 16 |
| quantum-engine | 7 |
| data-platform-sql | 6 |
| legacy-knot-engine | 4 |
| runtime-memory | 4 |
| runtime-world-model | 4 |
| ai-engine | 3 |
| runtime-transport-legacy | 3 |
| reality-engine-contracts | 2 |
| admin-runtime-config | 1 |
| ml-engine | 1 |
| reality-air-gap | 1 |

## Highest-Volume Buckets (Top 40)

| Bucket | File Count |
|---|---:|
| runtime/avrai_network/native/signal_ffi | 1494 |
| apps/avrai_app/test | 984 |
| runtime/avrai_runtime_os/lib/services | 878 |
| apps/avrai_app/lib/presentation | 446 |
| shared/avrai_core/lib/models | 302 |
| runtime/avrai_runtime_os/test/services | 220 |
| runtime/avrai_runtime_os/lib/kernel | 156 |
| apps/avrai_app/configs/runtime | 142 |
| supabase/migrations | 124 |
| runtime/avrai_runtime_os/lib/ai | 118 |
| runtime/avrai_runtime_os/tool | 117 |
| apps/admin_app/lib/ui | 75 |
| apps/admin_app/test | 68 |
| runtime/avrai_runtime_os/lib/ai2ai | 68 |
| apps/avrai_app/assets | 65 |
| runtime/avrai_runtime_os/lib/data | 57 |
| engine/avrai_knot/lib/services | 53 |
| apps/avrai_app/android | 51 |
| apps/avrai_app/ios | 51 |
| runtime/avrai_runtime_os/data | 49 |
| tool/_root | 48 |
| scripts/runtime | 44 |
| runtime/avrai_network/lib/network | 42 |
| scripts/ecommerce_experiments | 37 |
| engine/avrai_knot/lib/models | 32 |
| scripts/personality_data | 30 |
| supabase/functions | 30 |
| apps/admin_app/macos | 25 |
| apps/avrai_app/macos | 25 |
| runtime/avrai_runtime_os/lib/ml | 25 |
| runtime/avrai_runtime_os/test/kernel | 25 |
| engine/avrai_knot/native/knot_math | 24 |
| runtime/avrai_runtime_os/lib/controllers | 23 |
| runtime/avrai_runtime_os/lib/domain | 22 |
| scripts/ml | 21 |
| scripts/ci | 20 |
| apps/admin_app/windows | 18 |
| apps/avrai_app/windows | 18 |
| scripts/knot_validation | 18 |
| runtime/avrai_runtime_os/lib/crypto | 17 |

## Explicit Review Buckets (Sample)

- `engine/reality_engine/pubspec.yaml`
- `engine/reality_engine/test/forecast/baseline_forecast_kernel_test.dart`
- `engine/reality_engine/test/forecast/native_forecast_kernel_test.dart`
- `engine/reality_engine/test/research/governed_autoresearch_worker_test.dart`
- `engine/reality_engine/test/research/procedural_memory_context_resolver_test.dart`
- `engine/reality_engine/test/serving/kernel_guide_head_scoring_service_test.dart`
- `engine/reality_engine/test/serving/kernel_guide_promotion_gate_service_test.dart`
- `engine/reality_engine/test/serving/kernel_guide_shadow_evaluation_service_test.dart`
- `engine/reality_engine/test/serving/reality_model_head_scoring_service_test.dart`
- `engine/reality_engine/test/serving/reality_model_promotion_gate_service_test.dart`
- `engine/reality_engine/test/serving/reality_model_shadow_evaluation_service_test.dart`
- `engine/reality_engine/test/serving/shared_reality_model_family_scoring_service_test.dart`
- `engine/reality_engine/test/state/actor_context_goal_encoder_test.dart`
- `engine/reality_engine/test/state/environment_context_graph_test.dart`
- `engine/reality_engine/test/training/compressed_reality_model_training_service_test.dart`
- `engine/reality_engine/test/training/kernel_guide_head_profile_service_test.dart`
- `engine/reality_engine/test/training/reality_model_head_profile_service_test.dart`
- `engine/reality_engine/test/training/shared_reality_model_training_service_test.dart`
- `engine/reality_engine/test/training/training_retrieval_index_test.dart`
- `engine/spots_knot/lib/services/knot/bridge/knot_math_bridge.dart/api.dart`
- `engine/spots_knot/lib/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart`
- `engine/spots_knot/lib/services/knot/bridge/knot_math_bridge.dart/frb_generated.io.dart`
- `engine/spots_knot/lib/services/knot/bridge/knot_math_bridge.dart/frb_generated.web.dart`
- `runtime/avrai_data/pubspec.yaml`
- `runtime/avrai_runtime_os/lib/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart`
- `runtime/avrai_runtime_os/lib/services/transport/legacy/legacy_conversation_transport_adapter.dart`
- `runtime/avrai_runtime_os/lib/services/transport/legacy/legacy_protocol_codec_adapter.dart`
- `work/scripts/EXECUTE_SPOTS_DEVELOPMENT.sh`
- `work/scripts/README_ADMIN_BACKEND_TEST.md`
- `work/scripts/README_DESIGN_TOKEN_FIX.md`
- `work/scripts/README_INTEGRATION_TESTING.md`
- `work/scripts/README_TEST_FIX_AUTOMATION.md`
- `work/scripts/add_admin_credential.dart`
- `work/scripts/add_business_credential.dart`
- `work/scripts/ai_list_generator.sh`
- `work/scripts/ai_list_optimizer.sh`
- `work/scripts/analyze_test_coverage.sh`
- `work/scripts/analyze_test_failures.py`
- `work/scripts/analyze_test_quality.py`
- `work/scripts/analyze_unused_imports.py`
- ... plus 425 more (generate a local CSV export with `python3 scripts/generate_master_plan_file_mapping.py --emit-csv /tmp/codebase_master_plan_mapping_2026-02-15.csv`).

## Operational Use

1. `validate_architecture_placement.py` generates the full per-file mapping in memory for build enforcement.
2. `keep_review` rows are still valid placements; they indicate tooling or legacy surfaces that remain tracked and intentionally visible.
3. Regenerate this summary alongside the spot registry before merging package-placement changes; only emit a CSV locally when full inventory inspection is needed.
