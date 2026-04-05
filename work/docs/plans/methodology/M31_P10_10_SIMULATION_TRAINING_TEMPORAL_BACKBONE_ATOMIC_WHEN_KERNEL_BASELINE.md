# M31-P10-10 Baseline: Simulation/Training Temporal Backbone + Atomic/When-Kernel Lineage Authority

Date: 2026-04-02
Milestone: M31-P10-10
Master Plan refs: 10.9.12, 10.9.22, 10.9.23, 10.9.24, 10.9.25, 12.6.10

## Scope

Follow `M31-P10-9` with a runtime/shared/admin slice that moves the simulation-to-training lane onto AVRAI's canonical temporal backbone instead of leaving timing spread across plain UTC fields. Simulation snapshots, lab outcomes, rerun requests/jobs, bounded-review handoffs, and training exports should share additive temporal receipts rooted in `AtomicClockService -> AtomicClockTemporalAdapter -> TemporalKernel -> When/native kernel`, with system-kernel fallback preserved and legacy UTC fields retained during migration.

## Deliverables

1. Follow-on baseline:
   - `docs/plans/methodology/M31_P10_10_SIMULATION_TRAINING_TEMPORAL_BACKBONE_ATOMIC_WHEN_KERNEL_BASELINE.md`
2. Follow-on controls:
   - `apps/avrai_app/configs/runtime/simulation_training_temporal_backbone_atomic_when_kernel_controls.json`
3. Architecture authority:
   - `docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
   - `docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md`
4. Temporal backbone contracts and targets:
   - `shared/avrai_core/lib/services/atomic_clock_service.dart`
   - `runtime/avrai_runtime_os/lib/kernel/temporal/atomic_clock_temporal_adapter.dart`
   - `runtime/avrai_runtime_os/lib/kernel/temporal/temporal_kernel.dart`
   - `runtime/avrai_runtime_os/lib/kernel/temporal/native_backed_temporal_kernel.dart`
   - `shared/avrai_core/lib/models/temporal/replay_temporal_envelope.dart`
5. Simulation/training lane targets:
   - `runtime/avrai_runtime_os/lib/services/admin/replay_simulation_admin_service.dart`
   - `shared/avrai_core/lib/models/reality/reality_model_contracts.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
6. Board/tracker wiring:
   - `docs/EXECUTION_BOARD.csv`
   - `docs/EXECUTION_BOARD.md`
   - `docs/agents/status/status_tracker.md`
   - `docs/MASTER_PLAN.md`
   - `docs/MASTER_PLAN_TRACKER.md`

## Explicit Objectives

1. make the temporal-kernel layer authoritative for simulation-to-training timing, freshness, and ordering instead of relying on scattered `DateTime.now()` comparisons
2. inject the atomic/temporal backbone into the lane through `AtomicClockService`, `AtomicClockTemporalAdapter`, `TemporalKernel`, and the When/native-backed temporal kernel with audited system fallback
3. add additive temporal receipts or envelopes to simulation snapshots, lab outcomes, rerun requests/jobs, bounded-review handoffs, and training exports without removing existing UTC fields on day one
4. record simulation-lab lifecycle transitions as kernel-backed runtime temporal events so reruns, reviews, and training exports can be queried and replayed by temporal lineage rather than only filesystem chronology
5. make downstream bounded-review and training-export gates fail closed on temporal freshness/ordering policy instead of ad hoc timestamp checks
6. keep the lane compatible with current classical/native execution while preserving atomic-time validity context and future quantum-time reconciliation requirements

## Guardrails

1. this follow-on starts only after `M31-P10-9` closeout
2. temporal receipts are additive first; migration must preserve current UTC fields until all readers switch safely
3. When/native temporal execution is preferred, but system-kernel fallback must remain explicit, audited, and fail closed when uncertainty exceeds policy
4. atomic or quantum-time metadata may improve coherence and reconciliation, but it must not bypass existing governance, promotion, or review authority
5. every simulation/training handoff must preserve lineage between source artifact, temporal receipt, and downstream consumer; no silent time-source substitution is allowed
6. latest-state city-pack hydration remains versioned and rollback-safe; this milestone upgrades timing authority, not the governance model for what evidence is allowed in

## Exit Criteria

1. a canonical queued milestone exists for the post-`M31-P10-9` temporal-backbone lane
2. the execution board explicitly records `M31-P10-10` as the next tracked follow-on after `M31-P10-9`
3. architecture authority and status tracking both state that simulation snapshots, lab outcomes, rerun jobs, bounded-review handoffs, and training exports should share temporal-kernel lineage
4. later implementation proves the lane carries additive temporal receipts from simulation snapshot through rerun and bounded review into training export
5. later implementation proves freshness and ordering gates depend on temporal-kernel policy rather than only plain UTC comparisons
