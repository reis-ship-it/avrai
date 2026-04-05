# M31-P10-7 Baseline: Reality-Model Environment/City-Pack Structural-Ref Parity + Artifact-Boundary Hardening

Date: 2026-03-31
Milestone: M31-P10-7
Master Plan refs: 10.9.22, 10.9.23, 10.9.24, 10.9.25

## Scope

Follow `M31-P10-6` with a runtime-focused parity hardening slice that locks environment identity, city-pack semantics, structural refs, and storage-boundary reuse across replay/training artifacts.

## Deliverables

1. Follow-on baseline:
   - `docs/plans/methodology/M31_P10_7_REALITY_MODEL_ENVIRONMENT_CITY_PACK_STRUCTURAL_REF_PARITY_BASELINE.md`
2. Follow-on controls:
   - `apps/avrai_app/configs/runtime/reality_model_environment_city_pack_structural_ref_parity_controls.json`
3. Architecture authority:
   - `docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
4. Board/tracker wiring:
   - `docs/EXECUTION_BOARD.csv`
   - `docs/EXECUTION_BOARD.md`
   - `docs/agents/status/status_tracker.md`

## Explicit Objectives

1. ensure runtime environment registry outputs remain canonical for non-BHAM packs instead of being treated as advisory metadata
2. ensure training export manifests, storage boundaries, and storage partitions preserve and reuse structural refs consistently across environments
3. ensure downstream replay/training artifacts stay environment-correct without hidden BHAM-era fallback inference
4. keep admin/operator evidence surfaces able to trust these runtime artifacts without reconstructing missing environment semantics in UI code

## Guardrails

1. this follow-on starts only after `M31-P10-6` closeout
2. admin remains non-authoritative and should consume corrected runtime artifacts rather than compensating for them
3. no new path may weaken promotion, rejection, rollback, or supervisor fail-closed evidence gates
4. fixes must stay centered on runtime artifact integrity and storage-boundary correctness, not broad control-plane redesign

## Exit Criteria

1. a canonical queued milestone exists for the post-`M31-P10-6` environment/city-pack parity slice
2. the execution board explicitly records `M31-P10-7` as the locked next section after `M31-P10-6`
3. the architecture authority and status tracker both identify `M31-P10-7` as the follow-on for environment/city-pack structural-ref hardening
4. later implementation under this milestone proves canonical environment identity, city-pack semantics, structural refs, and storage-boundary reuse across runtime artifacts before closeout
