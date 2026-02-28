# Codebase -> Master Plan File Mapping (2026-02-15)

**Purpose:** File-level architecture mapping for keep/update/refactor/delete decisions aligned to `docs/MASTER_PLAN.md`.
**Coverage:** All tracked non-doc files under runtime/source/tooling roots (`lib/`, `packages/`, `native/`, `scripts/`, `supabase/`, `test/`, `tool/`, `assets/`, platform dirs).
**Total mapped files:** 3068
**Generated artifact:** `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv`
**Method:** Deterministic path-to-phase rules with explicit confidence values and strict per-file dependency-graph payloads (`dependency_graph`).

## Disposition Summary

| Disposition | File Count |
|---|---:|
| keep_update | 2584 |
| keep_review | 369 |
| review_required | 86 |
| refactor_planned | 29 |

## Domain Summary

| Domain | File Count |
|---|---:|
| testing-quality | 886 |
| presentation | 381 |
| core-services-general | 378 |
| tooling-ops | 317 |
| package-modules | 207 |
| core-models | 142 |
| supabase-infra | 124 |
| world-model-ai-core | 115 |
| unclassified | 86 |
| ai2ai-network | 68 |
| platform-runtime | 62 |
| data-layer | 55 |
| assets | 26 |
| ml-legacy-and-transition | 25 |
| native-modules | 24 |
| workflow-controllers | 23 |
| security-signal-ffi | 21 |
| domain-layer | 19 |
| config-and-theme | 15 |
| security-signal | 14 |
| app-composition-root | 13 |
| security-services | 12 |
| monitoring-observability | 9 |
| quantum-package | 7 |
| data-platform-sql | 6 |
| cloud-integration | 5 |
| tooling-dev | 5 |
| bootstrap-boundary | 3 |
| crypto-core | 3 |
| legal-domain | 3 |
| search-retrieval | 3 |
| core-utils | 2 |
| deployment-sync | 2 |
| legacy-advanced-services | 2 |
| legacy-p2p | 2 |
| supabase-integration-entrypoints | 2 |
| places-location-intelligence | 1 |

## Highest-Volume Buckets (Top 40)

| Bucket | File Count |
|---|---:|
| lib/core/services | 391 |
| lib/presentation/widgets | 204 |
| test/unit/services | 190 |
| lib/presentation/pages | 173 |
| lib/core/models | 142 |
| lib/core/ai | 115 |
| test/widget/widgets | 101 |
| packages/avrai_knot/lib | 84 |
| lib/runtime/avrai_runtime_os | 83 |
| lib/core/ai2ai | 68 |
| packages/avrai_network/lib | 67 |
| test/unit/models | 56 |
| test/widget/pages | 56 |
| test/unit/ai | 52 |
| packages/avrai_core/lib | 34 |
| scripts/ecommerce_experiments/results | 28 |
| android/app | 27 |
| lib/data/datasources | 26 |
| lib/core/ml | 25 |
| test/core/services | 24 |
| lib/core/controllers | 23 |
| test/unit/controllers | 20 |
| test/unit/data | 20 |
| test/integration/ai | 19 |
| test/unit/ai2ai | 18 |
| lib/core/crypto | 17 |
| test/integration/controllers | 17 |
| lib/domain/usecases | 15 |
| native/knot_math/src | 15 |
| test/unit/domain | 14 |
| lib/data/repositories | 13 |
| test/core/crypto | 13 |
| test/unit/ml | 13 |
| test/integration/infrastructure | 12 |
| test/integration/services | 12 |
| assets/three_js/lib | 10 |
| lib/core/theme | 10 |
| lib/data/database | 10 |
| lib/core/monitoring | 9 |
| test/integration/security | 9 |

## Delete Candidates

- None identified by deterministic rules.

## Manual Review Required (Sample)

- `lib/di/registrars/app_service_registrar.dart`
- `lib/di/registrars/engine_service_registrar.dart`
- `lib/di/registrars/runtime_service_registrar.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/active_connection_management_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/active_connection_metrics_index.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ai2ai_discovery_prekey_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_discovery_start_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_inbox_processing_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_inbox_processing_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_node_identity.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_replay_hash_cache.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/ble_seen_hashes_persistence_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/braided_knot_connection_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_attempt_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_attempt_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_completion_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_establishment_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_identity_binding_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_lifecycle_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_maintenance_loop.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_management_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_request_encoding_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_routing_policy.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_shutdown_cleanup_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/connection_worthiness_validation_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/discovery_loop.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_broadcast_flags_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_buffered_learning_insight.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_initiator_policy.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_learning_buffer_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_scan_window_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_scan_window_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/event_mode_target_selector.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/federated_cloud_orchestration_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/federated_cloud_queue_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/federated_cloud_sync_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/federated_cloud_sync_start_lane.dart`
- `lib/runtime/avrai_runtime_os/services/transport/ble/inactive_session_cleanup_lane.dart`
- ... plus 46 more (see CSV).

## Operational Use

1. Use the CSV as the execution source when scheduling keep/update/refactor/delete actions.
2. Any `delete_candidate` or `review_required` entry must be validated against runtime references (`rg`, DI registrations, imports) before deletion.
3. Refactor execution should follow phased dependencies in `docs/MASTER_PLAN.md` (notably 10.2, 10.7, 10.8).
