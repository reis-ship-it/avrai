# Reality-Model Simulation-To-Training Operator Runbook

Date: 2026-04-01
Purpose: make the current reality-model simulation-to-training workflow explicit, repeatable, and easy to audit.

Master Plan refs:
- `10.9.12`
- `10.9.22`
- `10.9.23`
- `10.9.24`
- `10.9.25`
- `12.4B.1`
- `12.4B.2`
- `12.4B.3`
- `12.4B.4`
- `12.4B.5`
- `12.4B.6`

Milestone anchors:
- `M31-P10-5`
- `M31-P10-6`
- `M31-P10-7`
- `M31-P12-1`
- `M31-P12-2`
- `M31-P12-3`

## What This Runbook Covers

This runbook covers the two coupled but different lanes that currently make up the reality-model simulation-to-training workflow:

1. the offline replay artifact lane that turns accepted BHAM replay material into training-grade export, staging, partition, and upload/index artifacts
2. the operator-governed admin lane that turns a strong local simulation into a bounded reality-model review, a local deeper-training candidate, and a governed deeper-training intake queue item

It also now defines the next governed extension to that workflow:

3. the future admin forecast-distillation lane that will let AVRAI learn from
   governed forecast predictions and later approximate useful teacher-sidecar
   behavior with a smaller native student model

This is the clearest current answer to:

1. how the world-model simulation path was finalized enough to support reality-model training
2. which parts are repeatable today
3. which parts are still operator-only or partially BHAM-first

## Current Truth In One Paragraph

The pipeline is materially real and repeatable for an informed repo operator. It is not yet a one-command, city-agnostic, self-service workflow for any contributor. The main reasons are:

1. the accepted replay artifact chain is still BHAM-first in naming and default paths
2. live replay upload requires replay Supabase credentials
3. the admin simulation-to-training path is intentionally fail-closed and operator-gated
4. `M31-P10-6` is still the active parity lane beneath the now-generic control-plane contract

## Canonical Supporting Documents

1. `work/docs/plans/methodology/REALITY_MODEL_TRAINING_AND_SIMULATION_BUILD_BASELINE_2026-03-31.md`
2. `work/docs/plans/methodology/M31_P10_6_REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_STAGE2_MULTI_ENVIRONMENT_EXECUTOR_PARITY_BASELINE.md`
3. `work/docs/plans/methodology/M31_P10_7_REALITY_MODEL_ENVIRONMENT_CITY_PACK_STRUCTURAL_REF_PARITY_BASELINE.md`
4. `work/docs/plans/methodology/M31_P12_1_AIR_GAP_COMPRESSION_SAFE_REPRESENTATION_BASELINE.md`
5. `work/docs/plans/methodology/M31_P12_2_AIR_GAP_COMPRESSION_RUNTIME_ADOPTION_BASELINE.md`
6. `work/docs/plans/methodology/M31_P12_3_COMPRESSED_REALITY_MODEL_TRAINING_ACCEPTANCE_GATE_BASELINE.md`
7. `work/docs/agents/status/status_tracker.md`

## Operator Classes

### 1. Repo Operator

Can run the offline replay build, local staging, partitioning, and dry-run upload/index flow.

### 2. Privileged Replay Operator

Can do everything a repo operator can do, plus live replay upload/index, because this role has:

1. `SUPABASE_REPLAY_URL`
2. `SUPABASE_REPLAY_ANON_KEY`
3. `SUPABASE_REPLAY_SERVICE_ROLE_KEY`

### 3. Admin Operator

Can review a strong local simulation and advance it through:

1. bounded reality-model review
2. local deeper-training candidate staging
3. governed deeper-training intake queueing

## Important Interpretation Rules

### 1. Artifact numbering is historical, not execution order

Do not assume `45` must be built before `68` and `69` just because the number is smaller. The current accepted BHAM replay pack contains historical artifact numbering that no longer matches the strict dependency order.

### 2. There are two different "training" handoffs

1. the offline replay lane produces training-grade export artifacts and storage-ready manifests
2. the admin lane produces a local operator-reviewed deeper-training candidate and optional intake queue material

These are coupled, but they are not the same step.

### 3. The admin lane is local-first by design

The admin flow is intentionally bounded and reviewable before broader training or serving changes happen.

## Workflow A: Offline Replay Artifact Lane

This is the spine that takes accepted BHAM replay source material and turns it into training-grade export and replay-only storage artifacts.

Recommended shell:

```bash
cd /Users/reisgordon/AVRAI/runtime/avrai_runtime_os
```

The commands below use explicit flags so the working directory is unambiguous.

### Step A1. Build the replay ingestion manifest

Purpose:
turn the authoritative source registry into the governed ingestion plan for the accepted replay year.

Inputs:
- `../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/03_BHAM_SOURCE_REGISTRY_DATA.json`

Outputs:
- `../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.md`
- `../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json`

Command:

```bash
dart run tool/build_bham_replay_ingestion_manifest.dart \
  --input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/03_BHAM_SOURCE_REGISTRY_DATA.json \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json
```

### Step A2. Consolidate accepted source packs

Purpose:
merge the accepted BHAM replay source packs into one replay-year pack.

Outputs:
- `../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.md`
- `../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json`

Command:

```bash
dart run tool/build_bham_consolidated_replay_source_pack.dart \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json
```

### Step A3. Normalize the consolidated replay pack

Purpose:
produce replay-admissible normalized observations from the consolidated pack under the authoritative ingestion manifest.

Inputs:
- `07_BHAM_REPLAY_INGESTION_MANIFEST.json`
- `35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json`

Outputs:
- `36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.md`
- `36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json`

Command:

```bash
dart run tool/build_bham_consolidated_replay_normalized_observations.dart \
  --manifest ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json \
  --pack ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json
```

### Step A4. Build the governed replay execution plan

Purpose:
turn accepted normalized observations into the governed replay execution plan and summary.

Inputs:
- `36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json`

Outputs:
- `37_BHAM_REPLAY_EXECUTION_PLAN_2023.md`
- `37_BHAM_REPLAY_EXECUTION_PLAN_2023.json`
- `38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.md`
- `38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.json`

Command:

```bash
dart run tool/build_bham_replay_execution_plan.dart \
  --input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json \
  --plan-output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.md \
  --plan-json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json \
  --summary-output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.md \
  --summary-json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.json
```

### Step A5. Build or validate the accepted governed replay artifact family

Purpose:
produce the finalized replay-only world, realism, calibration, exchange, and training-readiness artifact family that feeds export and training review.

Canonical builder set:

1. `tool/build_bham_replay_forecast_batch.dart`
2. `tool/build_bham_replay_virtual_world_environment.dart`
3. `tool/build_bham_replay_higher_agent_rollups.dart`
4. `tool/build_bham_replay_higher_agent_behavior_pass.dart`
5. `tool/build_bham_single_year_replay_pass.dart`
6. `tool/build_bham_replay_population_profile.dart`
7. `tool/build_bham_replay_place_graph.dart`
8. `tool/build_bham_replay_isolation_report.dart`
9. `tool/build_bham_replay_kernel_participation.dart`
10. `tool/build_bham_replay_realism_gate.dart`
11. `tool/build_bham_replay_action_explanations.dart`
12. `tool/build_bham_replay_daily_behavior.dart`
13. `tool/build_bham_replay_calibration.dart`
14. `tool/build_bham_replay_actor_kernel_coverage.dart`
15. `tool/build_bham_replay_connectivity_profiles.dart`
16. `tool/build_bham_replay_exchange_summary.dart`
17. `tool/build_bham_replay_physical_movement.dart`
18. `tool/build_bham_replay_training_signals.dart`
19. `tool/build_bham_replay_holdout_evaluation.dart`

Canonical accepted outputs in this family:

1. `39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.*`
2. `40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.*`
3. `41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.*`
4. `44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.*`
5. `45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.*`
6. `50_BHAM_REPLAY_POPULATION_PROFILE_2023.*`
7. `51_BHAM_REPLAY_PLACE_GRAPH_2023.*`
8. `52_BHAM_REPLAY_ISOLATION_REPORT_2023.*`
9. `53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.*`
10. `54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.*`
11. `55_BHAM_REPLAY_ACTION_EXPLANATIONS_2023.*`
12. `56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.*`
13. `57_BHAM_REPLAY_CALIBRATION_REPORT_2023.*`
14. `59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.*`
15. `60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.*`
16. `61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.*`
17. `67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.*`
18. `68_BHAM_REPLAY_TRAINING_SIGNALS_2023.*`
19. `69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.*`

Operator rule:
do not treat this step as optional. The later export and training steps assume this family is already accepted and internally consistent.

### Step A6. Build the replay training export manifest

Purpose:
package the accepted replay pass plus calibration and movement material into the training export manifest.

Inputs:
- `45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json`
- `57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json`
- `67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json`

Outputs:
- `58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md`
- `58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json`

Command:

```bash
dart run tool/build_bham_replay_training_export_manifest.dart \
  --summary-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json \
  --calibration-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json \
  --physical-movement-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json
```

### Step A7. Export replay storage staging

Purpose:
materialize replay-only storage artifacts into a local staging root without writing to live app storage.

Inputs:
- `58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json`

Outputs:
- local export root `runtime_exports/replay_storage_staging/bham_2023`
- `64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.md`
- `64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json`

Command:

```bash
dart run tool/export_bham_replay_storage_staging.dart \
  --manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json \
  --source-root ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation \
  --export-root runtime_exports/replay_storage_staging/bham_2023 \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json
```

### Step A8. Partition the staged replay artifacts

Purpose:
chunk large replay artifacts into replay-only semantic partitions before upload or indexing.

Inputs:
- `64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json`

Outputs:
- local partition root `runtime_exports/replay_storage_partitions/bham_2023`
- `65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.md`
- `65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json`

Command:

```bash
dart run tool/partition_bham_replay_storage_staging.dart \
  --export-manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json \
  --partition-root runtime_exports/replay_storage_partitions/bham_2023 \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json
```

### Step A9. Build the replay-only upload/index summary

Purpose:
turn the staged and partitioned replay artifacts into a replay-only upload/index manifest and summary. This can run in dry-run mode or live mode.

Inputs:
- `64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json`
- `65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json`

Outputs:
- `66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md`
- `66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.json`

Dry-run command:

```bash
dart run tool/upload_bham_replay_to_supabase.dart \
  --export-manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json \
  --partition-manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.json
```

Live command:

```bash
SUPABASE_REPLAY_URL=... \
SUPABASE_REPLAY_ANON_KEY=... \
SUPABASE_REPLAY_SERVICE_ROLE_KEY=... \
dart run tool/upload_bham_replay_to_supabase.dart \
  --live \
  --export-manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json \
  --partition-manifest-input ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json \
  --output ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md \
  --json-out ../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham\ simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.json
```

## Workflow B: Operator Local Simulation To Deeper-Training Intake

This is the local-first path exposed by the admin simulation tooling. It begins with a strong simulation snapshot and ends with a governed deeper-training intake queue artifact.

Canonical service:
- `runtime/avrai_runtime_os/lib/services/admin/replay_simulation_admin_service.dart`

Canonical admin surfaces:
- `apps/admin_app/lib/ui/pages/admin_command_center_page.dart`
- `apps/admin_app/lib/ui/pages/reality_system_oversight_page.dart`

### Step B1. Export the local simulation learning bundle

Purpose:
package the current simulation snapshot, learning summary, and bounded request previews for operator review.

Generated files:
- `simulation_snapshot.json`
- `simulation_learning_bundle.json`
- `reality_model_request_previews.json`
- `README.md`

Gate:
- none beyond successful snapshot generation, but later steps depend on `shareWithRealityModelAllowed`

### Step B2. Share the bundle through bounded reality-model review

Purpose:
evaluate each bounded preview request against the active reality-model contract and produce a review artifact.

Generated file:
- `reality_model_share_review.json`

Hard gates:

1. `shareWithRealityModelAllowed` must be true
2. there must be at least one bounded request preview

### Step B3. Stage the local deeper-training candidate

Purpose:
turn the strong simulation plus bounded review into a local candidate manifest that an operator can inspect before broader training action.

Generated files:
- `simulation_training_candidate_manifest.json`
- `SIMULATION_TRAINING_CANDIDATE_README.md`

Candidate manifest includes:

1. artifact refs back to the simulation bundle and share review
2. scenario, comparison, receipt, contradiction, and overlay metrics
3. intake-flow refs
4. sidecar refs
5. training artifact families
6. kernel states
7. locality, simulation-mode, and contract lineage metadata

### Step B4. Queue the deeper-training intake review

Purpose:
advance the local candidate into a governed intake-review posture without skipping human/operator review.

Generated files:
- `simulation_training_intake_queue.json`
- `SIMULATION_TRAINING_INTAKE_QUEUE_README.md`

If an intake repository is configured, this also mirrors into:

1. intake source descriptor
2. intake sync job
3. organizer review item

### Step B5. Interpret the queue correctly

The queue artifact means:

1. the simulation was strong enough to enter review for deeper training
2. the evidence package is locally inspectable
3. the result is still governed and local-first

It does not mean:

1. the candidate has already been promoted into universal training
2. the simulation can bypass reality-model review
3. the system is now fully generic across every environment

## Workflow C: Future Admin Forecast Distillation Lane

This lane is the planned extension after the admin-only TimesFM shadow
integration milestone. It is not the current live production path, but it is
the intended way AVRAI learns from forecast predictions without treating the
sidecar as truth or as an intake source.

### Step C1. Issue Native + Teacher Forecasts In Admin Shadow Mode

Purpose:
run AVRAI-native and teacher-sidecar forecasts together during replay or World
Simulation Lab evaluation.

Required outputs:

1. native forecast distribution
2. teacher forecast distribution
3. shared forecast metadata and lineage

Operator interpretation:

1. this is evidence collection
2. this is not yet training
3. this is not yet student promotion

### Step C2. Record Issued Forecast Evidence

Purpose:
persist the issued forecast evidence into the forecast skill ledger so the
prediction can later be resolved and scored.

Required stored elements:

1. forecast id
2. subject id
3. native distribution
4. teacher distribution
5. forecast strength and support quality
6. sidecar metadata
7. truth scope and governance context

### Step C3. Resolve Against Actual Outcome

Purpose:
anchor the forecast to eventual reality.

Required inputs:

1. the issued forecast record
2. the eventual actual outcome label or value
3. resolution metadata and timing

Rule:

1. no forecast-distillation tuple may be emitted before the forecast is
   resolved

### Step C4. Join Resolution With Lab And Daemon Context

Purpose:
let the supervisor daemon interpret not only prediction quality, but also the
operator-governed posture around that prediction.

Required join context:

1. World Simulation Lab disposition
2. bounded-review target posture
3. daemon learning snapshot state
4. acceptance, denial, or keep-iterating rationale

The daemon should retain denied forecast-learning cases as useful evidence for:

1. rejection memory
2. contradiction priors
3. anti-pattern detection
4. routing heuristics

But those denied cases must not self-promote into deeper training.

Implementation shape:

1. teacher-specific inference should stay inside separate teacher adapters
2. one umbrella coordinator should join issued forecast, teacher output,
   resolution, and operator disposition
3. student ownership should stay in separate student lane services

Recommended ownership split:

1. `TimesFmTeacherAdapter` owns TimesFM request translation and teacher output
2. `ForecastDistillationCoordinator` owns context assembly, tuple emission, and
   lineage enforcement
3. `MovementFlowStudentLaneService` and `EconomicSignalStudentLaneService` own
   the first lane-specific student training/evaluation paths

### Step C5. Emit Forecast Supervision Tuples

Purpose:
produce a governed teacher-student training signal.

Tuple ingredients:

1. native distribution
2. teacher distribution
3. resolved outcome
4. operator disposition
5. sidecar lineage
6. governed-for-training boolean
7. teacher adapter identity
8. coordinator identity
9. student lane owner

Interpretation:

1. the teacher distribution is a soft target
2. the actual resolved outcome is the hard target
3. operator disposition is the governance target

### Step C6. Stage A Local Forecast-Distillation Candidate

Purpose:
package the approved forecast supervision tuples into an operator-readable local
candidate before any broader training action.

Recommended generated files:

1. `forecast_supervision_tuples.json`
2. `forecast_distillation_candidate_manifest.json`
3. `FORECAST_DISTILLATION_CANDIDATE_README.md`

Recommended manifest contents:

1. issued forecast refs
2. resolution refs
3. native-vs-teacher score comparisons
4. operator dispositions
5. sidecar lineage
6. fallback lineage
7. tuple counts by forecast lane

### Step C7. Queue Governed Distillation Review

Purpose:
advance the local distillation candidate into the same local-first,
review-gated posture used elsewhere in the admin learning lane.

Governance rule:

1. only approved forecast supervision tuples may move into the deeper-training
   lane

Non-governance rule:

1. raw teacher predictions may never be queued as if they were direct training
   truth

### Step C8. Train The Native Student Offline

Purpose:
train a small AVRAI-native model to approximate the useful teacher behavior on
target lanes without shipping the teacher sidecar into user runtime.

Expected student objective:

1. match actual resolved outcomes
2. learn from the teacher distribution where the teacher helps
3. preserve calibration and governance honesty

### Step C9. Return The Student To Admin Shadow Evaluation

Purpose:
prove whether the student can replace, down-rank, or continue to require the
teacher sidecar.

Required comparison:

1. student vs teacher
2. student vs native baseline
3. student vs actual outcomes
4. operator acceptance

Only after that loop may the student become the preferred native forecast path
for a target lane.

Implementation note:

1. the coordinator should compare and report results across teacher adapters and
   student lane services
2. the student lane service should not own cross-lane routing or global lineage
3. the teacher adapter should not own promotion logic

### Step C10. Approve Or Reject Live-Reality Entry

Purpose:
keep the hard boundary between admin forecast learning and live governed
behavior.

Rule:

1. no teacher-informed student or fallback path enters live reality without
   explicit governed promotion
2. unresolved teacher wins are not enough
3. operator acceptance must point to a governed promotion receipt

### Step C11. Carry TimesFM Lineage Through The Hierarchy Loop

Purpose:
ensure that any teacher-informed live effect can be tracked through the same
post-learning chain already used by reality-model learning outcomes.

Required tracking surfaces:

1. `reality_model_learning_outcome`
2. `admin_evidence_refresh_snapshot_*`
3. `supervisor_learning_feedback_state_*`
4. `hierarchy_domain_delta_*`
5. downstream propagation receipts
6. governed live-consumer state

Required notation fields:

1. `timesfm_lineage_present`
2. `timesfm_influence_mode`
3. `forecast_teacher_family_ids`
4. `forecast_student_family_id`
5. `forecast_distillation_candidate_ref`
6. `forecast_supervision_tuple_refs`
7. `governed_promotion_ref`
8. `live_reality_notation`

### Step C12. Interpret Live-Reality Notation Correctly

If a propagated artifact is marked as TimesFM-informed, that means:

1. some governed part of its learning lineage involved a teacher-informed
   forecast path
2. the live artifact remains governed reality-model output, not raw TimesFM
   output
3. operators can audit and roll back that influence if needed

It does not mean:

1. TimesFM itself is the live authority
2. TimesFM became an intake source
3. prediction output bypassed the reality-model-first learning lane

## Repeatability Matrix

| Question | Answer | Why |
|---|---|---|
| Is the replay-to-training build real? | Yes | The artifact chain, staging flow, partition flow, upload/index flow, and admin review flow are all implemented. |
| Is it repeatable? | Yes, for repo operators | The commands and service outputs are deterministic enough to rerun with the same inputs. |
| Can any contributor do the whole thing unaided? | No | Live upload needs secrets, the admin lane is operator-gated, and the executor layer is still closing `M31-P10-6`. |
| Is it fully generic and city-pack agnostic? | Not yet | The control-plane contract is generic, but the deepest executor lane remains partially BHAM-first. |
| Is the workflow tracked thoroughly enough? | Better now, but not previously in one place | The source material existed across status docs, milestone baselines, scripts, and admin services; this runbook consolidates it. |

## Stop Conditions

Stop and investigate if any of the following happens:

1. `07_BHAM_REPLAY_INGESTION_MANIFEST.json` no longer selects the expected replay year
2. consolidated pack `35` and normalized observations `36` disagree on replay year or source coverage
3. the accepted governed replay artifact family contains missing or stale prerequisites for `45`, `58`, `64`, `65`, or `66`
4. upload/index tries to target non-replay buckets or non-`replay_simulation` schema surfaces
5. the admin snapshot says `shareWithRealityModelAllowed = false`
6. the admin share step has zero bounded request previews
7. the deeper-training candidate or queue artifact is created without the expected bundle, review, or lineage files

## Practical Reading Order For Future Operators

1. read this runbook first
2. read `REALITY_MODEL_TRAINING_AND_SIMULATION_BUILD_BASELINE_2026-03-31.md` for the March 31 build baseline
3. read the `M31-P10-6` and `M31-P10-7` baselines for the still-open executor parity and structural-ref cleanup lanes
4. read the `M31-P12-*` baselines for the compressed training lane
5. use `status_tracker.md` and `EXECUTION_BOARD.csv` for the live state

## Update Rule

Update this runbook when any of the following changes:

1. the accepted replay artifact spine changes materially
2. the admin simulation-to-training artifact names or gates change
3. the replay upload/index command contract changes
4. `M31-P10-6` closes and the executor lane becomes fully generic
5. the deeper-training intake path stops being local-first and review-gated
6. the forecast-sidecar shadow or distillation lane (`M31-P10-11` / `M31-P10-12`) changes materially
