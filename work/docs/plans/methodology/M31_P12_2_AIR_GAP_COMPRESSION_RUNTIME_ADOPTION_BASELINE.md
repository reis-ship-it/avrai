# M31-P12-2 Baseline: Air Gap Compression Runtime Adoption + Resolution-Budget Enforcement

Date: 2026-03-31
Milestone: M31-P12-2
Master Plan refs: 12.4A.3, 12.4A.4, 12.4A.5, 12.4A.6, 12.4A.7

## Scope

Adopt the new Air Gap compression baseline into real runtime boundary-crossing surfaces so safe artifact envelopes, compressed knowledge packets, and resolution budgets govern runtime outputs instead of remaining shared-only primitives.

## Deliverables

1. Baseline doc:
   - `docs/plans/methodology/M31_P12_2_AIR_GAP_COMPRESSION_RUNTIME_ADOPTION_BASELINE.md`
2. Controls:
   - `apps/avrai_app/configs/runtime/air_gap_compression_runtime_adoption_controls.json`
3. Runtime adoption ownership:
   - `runtime/avrai_runtime_os/lib/services/events/event_planning_intake_adapter.dart`
   - `runtime/avrai_runtime_os/lib/services/events/event_learning_signal_service.dart`
   - `runtime/avrai_runtime_os/lib/services/passive_collection/dwell_event_intake_adapter.dart`
   - `runtime/avrai_runtime_os/lib/services/intake/air_gap_normalizer.dart`
   - `runtime/avrai_runtime_os/lib/endpoints/intake/device_intake_router.dart`
   - `runtime/avrai_runtime_os/lib/endpoints/intake/social_media_intake_adapter.dart`
   - `runtime/avrai_runtime_os/lib/services/integrations/spotify_airgap_service.dart`
4. Verification ownership:
   - `runtime/avrai_runtime_os/test/services/events/event_planning_intake_adapter_test.dart`
   - `runtime/avrai_runtime_os/test/services/events/event_learning_signal_service_test.dart`
   - `runtime/avrai_runtime_os/test/services/passive_collection/dwell_event_intake_adapter_test.dart`

## Explicit Objectives

1. wrap runtime-produced safe artifacts in `SafeArtifactEnvelope` rather than leaving compression semantics as implied metadata
2. apply resolution budgets so runtime surfaces can govern how much gas/liquid/solid detail survives beyond the Air Gap boundary
3. ensure environment and locality semantics remain attached to compressed safe artifacts where runtime already knows them
4. keep all runtime surfaces fail closed when a compressed artifact would exceed distortion budget or violate non-reconstructability invariants

## Guardrails

1. the milestone depends on `M31-P12-1`; it may reuse but not redesign the shared compression primitives
2. runtime adoption must not store or forward raw payloads under compression terminology
3. every adopted runtime surface must keep provenance, privacy ladder tags, and boundary lineage intact
4. this slice is runtime adoption only; it does not reopen `M31-P10-6` control-plane authority work

## Exact File Ownership

### Primary runtime adoption files

1. `runtime/avrai_runtime_os/lib/services/events/event_planning_intake_adapter.dart`
2. `runtime/avrai_runtime_os/lib/services/events/event_learning_signal_service.dart`
3. `runtime/avrai_runtime_os/lib/services/passive_collection/dwell_event_intake_adapter.dart`
4. `runtime/avrai_runtime_os/lib/services/intake/air_gap_normalizer.dart`
5. `runtime/avrai_runtime_os/lib/endpoints/intake/device_intake_router.dart`
6. `runtime/avrai_runtime_os/lib/endpoints/intake/social_media_intake_adapter.dart`
7. `runtime/avrai_runtime_os/lib/services/integrations/spotify_airgap_service.dart`

### Primary verification files

1. `runtime/avrai_runtime_os/test/services/events/event_planning_intake_adapter_test.dart`
2. `runtime/avrai_runtime_os/test/services/events/event_learning_signal_service_test.dart`
3. `runtime/avrai_runtime_os/test/services/passive_collection/dwell_event_intake_adapter_test.dart`

## Exit Criteria

1. the next bounded Phase 12 runtime-adoption milestone exists and is board-tracked
2. the named runtime surfaces produce or carry safe compressed artifacts through the real boundary path
3. resolution-budget enforcement exists in runtime rather than only in shared models
4. targeted runtime tests prove fail-closed distortion and non-reconstructability behavior on adopted surfaces

## March 31 Execution Slices

`M31-P12-2` landed in two bounded runtime slices so it could progress cleanly beside the active `M31-P10-6` lane without widening into control-plane work.

### Slice 1 landed

1. `runtime/avrai_runtime_os/lib/services/intake/air_gap_compression_runtime_service.dart`
2. `runtime/avrai_runtime_os/lib/services/events/event_planning_intake_adapter.dart`
3. `runtime/avrai_runtime_os/lib/services/events/event_learning_signal_service.dart`
4. `runtime/avrai_runtime_os/lib/services/passive_collection/dwell_event_intake_adapter.dart`
5. `runtime/avrai_runtime_os/test/services/events/event_planning_intake_adapter_test.dart`
6. `runtime/avrai_runtime_os/test/services/events/event_learning_signal_service_test.dart`
7. `runtime/avrai_runtime_os/test/services/passive_collection/dwell_event_intake_adapter_test.dart`

### Slice 2 landed

1. `runtime/avrai_runtime_os/lib/services/intake/air_gap_normalizer.dart`
2. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
3. `runtime/avrai_runtime_os/lib/endpoints/intake/device_intake_router.dart`
4. `runtime/avrai_runtime_os/lib/endpoints/intake/social_media_intake_adapter.dart`
5. `runtime/avrai_runtime_os/lib/services/integrations/spotify_airgap_service.dart`
6. `runtime/avrai_runtime_os/test/services/intake/air_gap_normalizer_test.dart`
7. `runtime/avrai_runtime_os/test/endpoints/intake/device_intake_router_test.dart`
8. `runtime/avrai_runtime_os/test/endpoints/intake/social_media_intake_adapter_test.dart`
9. `runtime/avrai_runtime_os/test/services/integrations/spotify_airgap_service_test.dart`

## Closeout

`M31-P12-2` is complete once both slices are present: event/dwell learning paths now emit compression envelopes and packets, intake normalization can carry canonical compression signals forward, and device/social/Spotify ingestion paths now expose bounded Air Gap compression metadata on the runtime observation side.
