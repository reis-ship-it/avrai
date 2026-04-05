# TimesFM Forecast Sidecar Integration Authority

**Date:** April 3, 2026  
**Status:** Ready - architecture and governance authority for external forecast compute sidecars, with seeded shadow and distillation milestones `M31-P10-11` and `M31-P10-12`  
**Purpose:** Define how TimesFM-class forecasting models integrate into AVRAI cleanly across terminology, admin simulation flow, tracking, provenance, rollout, and future implementation.

---

## 1. Why This Document Exists

AVRAI already uses the term `sidecar` in multiple ways:

- realism or city-pack artifact sidecars attached to simulation provenance
- model packs downloaded outside the base install
- future heavy compute helpers that may sit beside the runtime

That ambiguity is acceptable for historical documents but not for implementation.

TimesFM is the clearest current example of a heavy external forecasting model that could help AVRAI's admin simulation lane while still being a poor fit for:

- the shipped mobile app binary
- always-on user-device execution
- the core reality-model planning/training substrate

This document makes the integration pattern explicit before code is added.

---

## 2. Canonical Position

TimesFM is a **forecast compute sidecar candidate**.

It is:

- useful for numeric time-series forecasting
- suitable for admin-machine replay and simulation workflows
- a possible forecast component beneath the governed forecast kernel
- an optional external helper for admin/research execution

It is **not**:

- the AVRAI reality model
- a replacement for simulation, replay, or counterfactual reasoning
- a replacement for governed forecast evaluation
- a base app asset to bundle into the shipped admin app
- a live default dependency for user-facing runtime behavior

Canonical rule:

> TimesFM-class models may inform the forecast lane inside admin simulation and replay. They may not bypass the forecast kernel governance path, and they may not directly mutate the reality model or production serving behavior.

---

## 3. Sidecar Taxonomy

### 3.1 Artifact Sidecar

A persisted file or manifest that shaped a simulation or review outcome.

Examples:

- city-pack manifests
- realism-pack JSON
- locality overlays
- structured provenance snapshots

Storage/provenance rule:

- these belong in `sidecarRefs`
- they are part of simulation foundation or realism provenance

### 3.2 Compute Sidecar

A local or remote process that performs bounded computation for AVRAI and returns structured results.

Examples:

- TimesFM local forecast worker
- future external forecaster workers
- bounded research inference helpers for admin-only simulation

Storage/provenance rule:

- these do **not** go in `sidecarRefs` unless they also emit a persisted manifest/config file
- execution details belong in forecast/result metadata and run artifacts

### 3.3 Model Pack

A signed downloadable artifact family installed outside the base app payload.

Examples:

- local LLM model packs
- future optional admin-only model bundles if AVRAI later distributes them directly

Storage/provisioning rule:

- use explicit model-pack lifecycle and verification rules
- do not treat model packs as simulation provenance sidecars

### 3.4 Forecast Sidecar

A compute sidecar whose only job is to produce forecast distributions from historical numeric series and optional covariates.

TimesFM belongs here.

---

## 4. TimesFM Fit Assessment

TimesFM is appropriate where AVRAI needs:

- future counts
- future demand curves
- future intensity or probability bands
- quantiles over a bounded horizon

It is not appropriate where AVRAI needs:

- state/action/next_state learning
- multi-agent simulation logic
- counterfactual planning
- conviction synthesis
- final truth integration

Therefore the correct AVRAI role is:

`historical series -> TimesFM sidecar forecast -> governed forecast kernel -> admin simulation/review loop`

not:

`historical series -> TimesFM -> reality model`

---

## 5. Canonical Operating Model

### 5.1 Default Deployment Mode

TimesFM runs on the **admin machine** during replay/simulation execution.

Recommended execution forms:

1. localhost HTTP sidecar
2. local Python worker process
3. operator-started background service

The default assumption is:

- no user-device dependency
- no mandatory cloud dependency
- no base-app bundling

### 5.2 Why Admin-First Is Required

TimesFM-class artifacts are large and Python-oriented. They are appropriate for:

- offline replay
- world simulation lab
- bounded review
- shadow and hybrid forecast evaluation

They are not appropriate as a required dependency for:

- daily mobile runtime
- no-egress user-device inference
- instant low-latency user recommendations

### 5.3 Where It Fits In The Current Admin Flow

Canonical call path:

1. World Simulation Lab or replay execution starts an evaluation run.
2. `ReplaySimulationAdminService` or replay tooling reaches the forecast batch lane.
3. `BhamReplayForecastBatchService` builds `ForecastKernelRequest`.
4. `GovernedForecastRuntimeService` calls the forecast kernel.
5. A hybrid kernel calls:
   - the existing native or baseline kernel
   - the TimesFM sidecar
6. `ForecastStrengthService` pools component distributions.
7. `ForecastGovernanceProjectionService` calibrates, scores, and governs the result.
8. `ForecastSkillLedger` records issued forecasts and later resolutions.
9. Admin diagnostics render kernel identity, execution mode, strength, calibration, and disagreement.

This means TimesFM feeds the **admin loop first**.

---

## 6. Current Repo Seams To Use

### 6.1 Forecast Kernel Interface

- `engine/reality_engine/lib/forecast/forecast_kernel.dart`

### 6.2 Current Admin Forecast DI

- `apps/admin_app/lib/di/registrars/injection_container_ai.dart`

Current default:

- admin registers `buildNativeForecastKernel()` as `ForecastKernel`

Clean replacement:

- admin registers a `HybridForecastKernel`
- mobile/runtime can continue using `buildNativeForecastKernel()` until a separate decision is made

### 6.3 Forecast Request Builder

- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_forecast_batch_service.dart`

This is where forecast-eligible replay entries are turned into `ForecastKernelRequest`.

This is the correct place to attach:

- historical numeric context windows
- target horizon
- optional covariates
- series metadata for the TimesFM sidecar

### 6.4 Forecast Strength And Pooling

- `runtime/avrai_runtime_os/lib/services/prediction/forecast_strength_service.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/forecast_ensemble_service.dart`

Critical existing feature:

- `ForecastStrengthService` already supports `ensemble_predictive_distributions`

Canonical rule:

> A TimesFM sidecar should integrate by contributing a component distribution to `ensemble_predictive_distributions`, not by bypassing the existing forecast-strength and governance layers.

### 6.5 Admin Diagnostics

- `runtime/avrai_runtime_os/lib/services/admin/forecast_kernel_admin_service.dart`

This service already exposes:

- `forecast_kernel_id`
- `forecast_kernel_execution_mode`
- `outcome_probability`
- `representation_mix`

TimesFM integration must preserve and enrich that surface rather than creating a parallel diagnostics lane.

---

## 7. Canonical Metadata Contract

### 7.1 Keep `sidecarRefs` Strict

`sidecarRefs` remain reserved for persisted artifact sidecars.

Do not write entries such as:

- `timesfm`
- `localhost:8765`
- `python worker running`

into `sidecarRefs`.

### 7.2 Compute Sidecar Forecast Metadata

When a forecast uses TimesFM, record a structured metadata block in the forecast result and any later replay artifacts:

```json
{
  "forecast_kernel_id": "hybrid_timesfm_sidecar",
  "forecast_kernel_execution_mode": "sidecar_http_local",
  "forecast_sidecar": {
    "sidecar_id": "timesfm",
    "sidecar_kind": "compute_sidecar",
    "service_mode": "localhost_http",
    "service_version": "timesfm-sidecar-v1",
    "model_family": "timesfm-2.5-200m",
    "window_point_count": 168,
    "horizon_point_count": 24,
    "covariates_used": ["day_of_week", "holiday_flag", "weather_band"],
    "series_kind": "venue_demand_hourly"
  }
}
```

### 7.3 Ensemble Metadata

When running hybrid mode, include:

```json
{
  "ensemble_predictive_distributions": [
    {
      "componentId": "native_forecast_kernel",
      "representationComponent": "classical",
      "distribution": { "...": "..." }
    },
    {
      "componentId": "timesfm_sidecar",
      "representationComponent": "classical",
      "distribution": { "...": "..." }
    }
  ]
}
```

Note:

- `ForecastRepresentationComponent` currently has no dedicated `foundation_model` or `transformer` value
- until that enum expands, TimesFM distributions should be recorded as `classical`
- distinguish them via `componentId` and sidecar metadata

---

## 8. Use-Case Matrix

| Use Case | Fit | Recommended Stage | Notes |
|---|---|---|---|
| `movement_flow` forecasting | Strong | Shadow -> Hybrid | Numeric, high-temporal, low-semantic ambiguity |
| `economic_signal` forecasting | Strong | Shadow -> Hybrid | Good for continuous/count horizons |
| `venue` demand forecasting | Strong | Shadow -> Hybrid | Use attendance, dwell, reservation, footfall history |
| `event` attendance / interest forecasting | Strong | Shadow -> Hybrid | Use pre-event trajectory and demand curve |
| `community` activity forecasting | Limited | Shadow only initially | Series likely noisier and more behavior-derived |
| `club` forecasting | Limited | Shadow only initially | Needs careful feature engineering and stronger governance |

Initial AVRAI recommendation:

1. start with `movement_flow`
2. add `economic_signal`
3. then `venue`
4. then `event`
5. leave `community` and `club` for later validation

---

## 9. Rollout Modes

### 9.1 Mode 0: Documentation Only

No code path changes.

Required outputs:

- this authority document
- tracker and index entries

### 9.2 Mode 1: Shadow

The native kernel remains authoritative.

TimesFM sidecar:

- executes on the admin machine
- returns a distribution
- is recorded in metadata
- does not affect the final forecast used for governance

Success criteria:

- stable execution
- useful disagreement signals
- no provenance ambiguity

### 9.3 Mode 2: Hybrid

The final governed forecast uses both:

- native kernel distribution
- TimesFM sidecar distribution

through `ensemble_predictive_distributions`.

Success criteria:

- calibration improves or stays neutral
- skill lower confidence bound improves for target lanes
- admin operators can explain the change

### 9.4 Mode 3: Expanded Hybrid

Additional eligible entity types may use the sidecar after:

- shadow evidence
- hybrid evidence
- documented operator acceptance

### 9.5 Not Allowed

The following are explicitly disallowed without a separate authority document:

1. direct production-user dependency on TimesFM
2. replacing the full forecast kernel with TimesFM alone
3. direct reality-model training from raw TimesFM output
4. skipping the governed forecast projection layer
5. writing compute-sidecar execution markers into `sidecarRefs`

---

## 10. Tracking And Documentation Obligations

### 10.1 Architecture Documentation

When adding or materially changing a forecast compute sidecar, update:

1. `docs/plans/architecture/TIMESFM_FORECAST_SIDECAR_INTEGRATION_AUTHORITY_2026-04-03.md`
2. `docs/plans/architecture/ARCHITECTURE_INDEX.md`
3. `docs/MASTER_PLAN_TRACKER.md`
4. `docs/plans/methodology/BUILD_DOCS_WIRING_INDEX.md`

### 10.2 Seeded Execution Tracking

This authority now seeds the first concrete execution milestone directly into the
existing tracking surfaces rather than through a separate plan file.

Seeded milestone metadata:

- `milestone_id`: `M31-P10-11`
- `name`: `Admin-only TimesFM forecast sidecar shadow integration + governed diagnostics traceability`
- `dependencies`: `M31-P10-10`
- `prd_ids`: `PRD-012;PRD-013;PRD-014;PRD-021;PRD-022;PRD-033;PRD-034`
- `master_plan_refs`: `10.9.12;10.9.22;10.9.23;10.9.24;10.9.25`
- `architecture_spot`: `runtime/avrai_runtime_os`
- `urk_runtime_type`: `shared`
- `urk_prong`: `cross_prong`
- `privacy_mode_impact`: `multi_mode`
- `impact_tier_max`: `L4`
- `target_window`: `Week 120-122`

Authority:

- `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
- `docs/EXECUTION_BOARD.csv`

### 10.3 Execution Scope Lock

`M31-P10-11` is the initial implementation scope lock for this lane.

The milestone is limited to:

1. admin-only shadow execution
2. `movement_flow` and `economic_signal` target lanes
3. localhost or operator-managed TimesFM sidecar transport
4. governed metadata and diagnostics propagation
5. fail-closed fallback to the native kernel

The milestone explicitly excludes:

1. user-device dependency
2. bundled TimesFM weights in the admin app
3. direct reality-model training from raw sidecar output
4. hybrid weighting that affects promotion decisions before shadow evidence exists

### 10.4 Experiment And Simulation Tracking

If sidecar scripts, workers, or experiments are added:

1. register scripts in `configs/experiments/EXPERIMENT_REGISTRY.csv`
2. regenerate `docs/EXPERIMENT_REGISTRY.md`
3. record simulation runs in `configs/ml/simulation_experiment_runs.csv`
4. regenerate `docs/ML_SIMULATION_EXPERIMENT_LOG.md`

If sidecar-informed model training or promotion happens later:

1. update `configs/ml/model_training_registry.csv`
2. regenerate `docs/ML_MODEL_TRAINING_CHECKLIST.md`
3. preserve rollback artifact lineage

### 10.5 Status Tracking

Use `docs/agents/status/status_tracker.md` for:

- milestone start
- shadow-mode completion
- hybrid-mode acceptance or rejection
- follow-up parity or calibration outcomes

Do not use status tracker as the place to define architecture rules. Use it only to record execution state and evidence.

---

## 11. Implementation Package And Service Plan

The clean runtime split is:

### 11.1 New Runtime Services

- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_sidecar_client.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_sidecar_forecast_kernel.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/hybrid_forecast_kernel.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_series_builder.dart`

### 11.2 Dependency Injection

Admin app only:

- wrap the current `ForecastKernel` registration in `apps/admin_app/lib/di/registrars/injection_container_ai.dart`

Do not change mobile/runtime DI by default.

### 11.3 Request Enrichment

`BhamReplayForecastBatchService` should enrich request metadata with:

- `timesfm_context_values`
- `timesfm_horizon`
- `timesfm_covariates`
- `timesfm_series_kind`

### 11.4 Sidecar Launch And Health

Preferred first implementation:

- operator-managed localhost service
- no in-app process supervisor required

Future optional implementation:

- bounded admin-side process launcher with health checks

### 11.5 Initial File-By-File Scope (`M31-P10-11`)

Planned new runtime files:

- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_sidecar_client.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_sidecar_forecast_kernel.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/hybrid_forecast_kernel.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/timesfm_series_builder.dart`

Planned modifications to existing runtime/admin files:

- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_forecast_batch_service.dart`
- `runtime/avrai_runtime_os/lib/services/admin/forecast_kernel_admin_service.dart`
- `apps/admin_app/lib/di/registrars/injection_container_ai.dart`

Expected test surfaces:

- `runtime/avrai_runtime_os/test/services/prediction/`
- `apps/admin_app/test/`

Expected no-change interface boundary for the first slice:

- `engine/reality_engine/lib/forecast/forecast_kernel.dart`

The first slice should adapt to the existing kernel interface rather than
expanding that contract.

### 11.6 Initial Use-Case Scope (`M31-P10-11`)

Start with:

1. `movement_flow`
2. `economic_signal`

Do not include in the first slice:

1. `venue`
2. `event`
3. `community`
4. `club`

---

## 12. Packaging Rule

TimesFM is not a base asset.

Canonical packaging rule:

> The admin app ships the integration seam, not the TimesFM checkpoint itself.

Allowed packaging choices:

1. operator-installed Python environment
2. operator-downloaded sidecar bundle
3. future signed admin-only model pack, if AVRAI later decides to distribute one

Not allowed:

1. bundling TimesFM weights inside the base admin app install
2. making admin app startup depend on the sidecar being present

Fail-closed behavior:

- if the sidecar is unavailable, the system falls back to the existing native/baseline kernel path
- the forecast metadata must record the fallback

---

## 13. Provenance And Governance Rules

1. TimesFM results are evidence, not truth.
2. The governed forecast projection layer remains the admission gate.
3. Admin simulation remains the first review surface.
4. Any later training or promotion must preserve lineage to:
   - forecast request inputs
   - sidecar model family/version
   - execution mode
   - calibration context
   - fallback behavior when present
5. The reality model may consume only governed downstream artifacts, never raw sidecar output as direct authority.

### 13.1 Safe Boundary Contract: Intake vs Forecast Sidecar

The `GovernedUpwardLearningIntakeService` and any future
`TimesFmSidecarForecastKernel` must remain separate authority lanes.

`GovernedUpwardLearningIntakeService` owns:

1. staging explicit reality-intake classes into `UniversalIntakeRepository`
2. creating `ExternalSourceDescriptor`, `ExternalSyncJob`, and
   `OrganizerReviewItem`
3. assigning `sourceProvider`, `sourceKind`, `convictionTier`,
   `learningPathway`, and upward-review temporal lineage
4. preserving the explicit reality-intake catalog for human, AI2AI,
   onboarding, feedback, visits, locality observations, event outcomes, and
   other governed reverse-loop sources

`TimesFmSidecarForecastKernel` owns:

1. bounded forecast inference from a `ForecastKernelRequest`
2. returning a `ForecastKernelResult`
3. contributing forecast component evidence through
   `ensemble_predictive_distributions`
4. attaching forecast execution metadata such as kernel ID, execution mode,
   model family, horizon, covariates, and fallback state

### 13.2 Allowed Data Crossing

Allowed from intake/replay/governed artifacts into the TimesFM lane:

1. replay-approved numeric history windows
2. bounded covariates
3. target horizon metadata
4. source references or source counts as supporting context inside forecast
   metadata
5. governed simulation artifacts that already passed the replay/admin pipeline

Allowed from the TimesFM lane into later systems:

1. forecast result metadata
2. predictive distributions
3. governed replay or simulation artifacts that include sidecar lineage
4. later training/export artifacts only after admin review and governance gates

### 13.3 Explicitly Disallowed Crossing

The forecast sidecar lane must not:

1. call `UniversalIntakeRepository.upsertSource()`
2. call `UniversalIntakeRepository.upsertJob()`
3. call `UniversalIntakeRepository.upsertReviewItem()`
4. emit `sourceProvider = timesfm` or any other forecast-worker identity as an
   intake source
5. emit `sourceKind = timesfm_forecast` as if forecast output were a real-world
   intake class
6. write raw or calibrated predictive distributions into the upward-learning
   queue as intake payload
7. bypass forecast governance and write directly into reality-model training
   authority

The governed intake lane must not:

1. import or call `TimesFmSidecarForecastKernel`
2. persist forecast-kernel output as an `ExternalSourceDescriptor`
3. treat sidecar execution metadata as a replacement for human, AI2AI,
   onboarding, visit, locality, or event intake provenance
4. treat a forecast disagreement as a new intake class by itself

### 13.4 Bridge Rule

There is only one safe bridge from the forecast sidecar lane toward the
learning lane:

> raw intake -> governed simulation/replay -> forecast sidecar evidence ->
> governed forecast projection -> admin review -> governed downstream artifact

Only the final governed downstream artifact may later influence reality-model
learning. Raw TimesFM output may not.

### 13.5 Code Placement And Import Discipline

To keep the boundary hard in code:

1. TimesFM sidecar code stays under
   `runtime/avrai_runtime_os/lib/services/prediction/`
2. governed upward intake code stays under
   `runtime/avrai_runtime_os/lib/services/reality_model/`
3. TimesFM sidecar files must not import:
   - `services/intake/`
   - `services/reality_model/governed_upward_learning_intake_service.dart`
4. `governed_upward_learning_intake_service.dart` must not import:
   - `reality_engine/forecast/forecast_kernel.dart`
   - TimesFM sidecar client/kernel implementations
5. bridge services may read governed artifacts from replay/simulation lanes, but
   they may not re-register forecast output as raw intake

### 13.6 Operational Interpretation

If TimesFM changes operator attention, confidence, or ranking inside admin
simulation, that is acceptable.

If TimesFM starts appearing as a first-class intake source beside human, AI2AI,
onboarding, visits, locality observations, or event outcomes, the boundary has
been violated.

### 13.7 Native Learning Goal

The goal is not permanent dependency on TimesFM.

The long-term goal is:

1. use TimesFM as an admin-side teacher for selected forecast lanes
2. capture governed forecast evidence plus eventual resolution
3. train a smaller AVRAI-native student model to approximate the useful signal
4. re-evaluate the student against the teacher in admin shadow mode
5. eventually reduce or remove sidecar dependence when native parity is proven

Canonical rule:

> AVRAI may learn from predictions only through governed forecast distillation
> that is anchored to actual outcomes and operator-reviewed simulation
> evidence. AVRAI may not learn directly from unresolved sidecar predictions as
> if they were truth.

### 13.8 Forecast Distillation Learning Contract

Forecast distillation requires four ingredients:

1. the native AVRAI forecast output
2. the TimesFM teacher forecast output
3. the eventual resolved outcome
4. the operator or daemon governance context around that prediction

The supervision target is therefore:

- teacher distribution as soft signal
- actual resolved outcome as hard signal
- operator disposition as governance signal

This is a teacher-student lane, not a source-intake lane.

#### Recommended Service Topology

The implementation should not collapse teacher inference, tuple assembly,
governance context, and student-lane ownership into one monolithic service.

Recommended structure:

1. separate teacher adapters
2. one umbrella coordinator
3. separate student lane services

Teacher-adapter role:

1. normalize lane-specific forecast requests into teacher-specific input shape
2. execute teacher inference
3. return teacher distribution plus teacher metadata
4. remain replaceable without changing distillation governance

Recommended naming pattern:

1. `ForecastTeacherAdapter` as the abstract contract
2. `TimesFmTeacherAdapter` as the first implementation
3. future teacher adapters may be added later without changing student-lane
   ownership

Umbrella-coordinator role:

1. assemble the shared context pack for issued forecast, replay context,
   operator disposition, and later resolution
2. route eligible requests to the correct teacher adapter
3. join native forecast, teacher forecast, resolved outcome, and governance
   context
4. emit governed forecast supervision tuples
5. preserve lineage, fallback, and live-reality notation metadata
6. coordinate student-lane evaluation without becoming the teacher or the
   student

Recommended naming pattern:

1. `ForecastDistillationCoordinator`
2. `TeacherStudentDistillationCoordinator`

Student-lane-service role:

1. own one forecast lane or a tightly related lane family
2. receive governed tuples from the coordinator
3. train or evaluate the student for that lane
4. report parity, calibration, and promotion readiness back to the coordinator

Recommended first student lanes:

1. `MovementFlowStudentLaneService`
2. `EconomicSignalStudentLaneService`

Non-goal:

1. do not create one universal `TeacherStudentService` that owns every teacher,
   every lane, every tuple type, and every promotion decision

Rationale:

1. separate adapters preserve teacher replaceability
2. separate student lanes preserve lane-specific training and evaluation
3. the umbrella coordinator gives one authoritative place for lineage,
   tuple-shape enforcement, and governance context
4. this keeps the current TimesFM lane extensible to future teachers without
   redefining the entire forecast-learning boundary

### 13.9 Forecast Supervision Tuple Contract

The follow-on learning lane should emit governed forecast supervision tuples.

Canonical tuple fields:

```json
{
  "forecast_id": "forecast-123",
  "subject_id": "entity-456",
  "series_kind": "movement_flow",
  "forecast_family_id": "default_forecast_family",
  "request_features_ref": "artifact://replay/request/123",
  "native_distribution": { "...": "..." },
  "teacher_distribution": { "...": "..." },
  "actual_outcome_label": "positive",
  "actual_outcome_value": 0.81,
  "operator_disposition": "candidate_for_bounded_review",
  "teacher_primary_score": 0.11,
  "native_primary_score": 0.19,
  "teacher_won": true,
  "governed_for_training": true,
  "forecast_sidecar_metadata": {
    "sidecar_id": "timesfm",
    "service_mode": "localhost_http",
    "model_family": "timesfm-2.5-200m"
  }
}
```

Required properties:

1. link back to the issued forecast
2. include both native and teacher predictive distributions
3. include the resolved outcome
4. include operator or bounded-review disposition
5. include sidecar lineage and fallback metadata
6. mark whether the tuple is approved for downstream training
7. record which teacher adapter emitted the teacher output
8. record which coordinator version emitted the tuple
9. record which student lane service owns the tuple downstream

### 13.10 Admin And Daemon Responsibilities

In the admin app:

1. World Simulation Lab shows native result, teacher result, disagreement, and
   later the resolved outcome when available
2. Forecast admin surfaces show sidecar-vs-native disagreement and skill trends
3. bounded review decides whether a forecast-learning candidate is acceptable
   for export

In the supervisor daemon:

1. watch issued forecast records
2. watch resolved forecast records
3. pass that state into the umbrella coordinator
4. let the coordinator join native forecast, teacher forecast, lab outcome, and
   operator disposition lineage
5. compute teacher-vs-native win/loss and disagreement features
6. emit forecast supervision tuples
7. retain denied candidates as daemon learning evidence for rejection memory,
   routing heuristics, and anti-pattern detection

The daemon may create tuples, but those tuples are forecast-supervision tuples,
not raw intake records. The coordinator remains the canonical tuple-shape and
lineage owner; the daemon remains the process owner that watches the stream and
invokes the coordinator.

### 13.11 Export And Training Boundary

Forecast supervision tuples should move into training only through governed
export artifacts.

Recommended artifact additions for the follow-on lane:

1. a replay/admin-side `forecast_supervision_tuples.json` artifact family
2. a local `forecast_distillation_candidate_manifest.json`
3. a `FORECAST_DISTILLATION_CANDIDATE_README.md`
4. optional inclusion of approved tuple refs in later
   `simulation_training_candidate_manifest.json`

Recommended training-manifest additions when the lane is implemented:

1. `forecastDistillationIncluded`
2. `forecastDistillationTupleCount`
3. `forecastTeacherFamilyIds`
4. `forecastStudentFamilyId`
5. `forecastDistillationArtifactRefs`

Recommended training-table addition:

1. `replay_forecast_supervision_tuples`

### 13.12 Student Promotion Rule

The native student model may replace or down-rank the sidecar only after:

1. shadow-mode parity evidence exists
2. resolved forecast skill is acceptable on the target lanes
3. calibration remains acceptable
4. operator review accepts the handoff

Until then:

1. the sidecar remains teacher or auditor
2. the native model remains student or candidate
3. production-user runtime remains independent of the sidecar
4. admin shadow comparison remains the proving ground

### 13.13 Hierarchy-Loop Tracking Rule

If a TimesFM-informed learning result ever moves beyond admin shadow mode and
into governed reality-model learning, downstream propagation, or live
runtime-facing behavior, that influence must remain explicitly traceable through
the existing hierarchy loop.

Canonical rule:

> TimesFM influence may enter live reality only through governed reality-model
> learning outcomes and downstream propagation artifacts, and every such step
> must preserve machine-readable lineage plus operator-visible notation.

This tracking must follow the existing post-learning chain rather than creating
an alternative sidecar-specific path:

- `reality_model_learning_outcome`
- `admin_evidence_refresh_snapshot_*`
- `supervisor_learning_feedback_state_*`
- `hierarchy_domain_delta_*`
- downstream propagation receipts
- governed consumer state and any later live-runtime consumer state

### 13.14 Required Live-Reality Notation

If a teacher-informed student model or approved sidecar fallback contributes to
governed live behavior, the affected artifacts must record at least:

1. `timesfm_lineage_present`
2. `timesfm_influence_mode`
3. `forecast_teacher_family_ids`
4. `forecast_student_family_id`
5. `forecast_distillation_candidate_ref`
6. `forecast_supervision_tuple_refs`
7. `governed_promotion_ref`
8. `hierarchy_propagation_stage`
9. `live_reality_notation_required`
10. `live_reality_notation`

Recommended `timesfm_influence_mode` values:

1. `teacher_sidecar_shadow_only`
2. `distilled_student_live`
3. `sidecar_fallback_live`
4. `historical_teacher_lineage_only`

Recommended `hierarchy_propagation_stage` values:

1. `reality_model_learning_outcome`
2. `admin_evidence_refresh`
3. `supervisor_feedback`
4. `domain_delta`
5. `downstream_receipt`
6. `live_consumer_state`

### 13.15 Operator Surfaces And End-User Boundary

Operator/admin surfaces must be able to show:

1. whether a live artifact is TimesFM-informed
2. whether that influence came from a distilled student or a sidecar fallback
3. which governed promotion or distillation candidate introduced that lineage
4. which hierarchy tiers received that downstream effect

End-user/runtime surfaces do not need to expose the term `TimesFM` directly by
default.

However, the machine-readable lineage and operator-facing notation must exist so
AVRAI can always answer:

1. what was influenced
2. where it propagated
3. when it reached live runtime
4. whether the influence came from teacher fallback or student promotion

### 13.16 Promotion Gate For Live Reality

No TimesFM-informed artifact may enter live reality unless:

1. the student or fallback path has passed governed review
2. the resulting reality-model learning outcome exists
3. the downstream propagation plan preserves TimesFM lineage
4. operator/admin evidence surfaces can note that influence
5. later rollback can identify and isolate the affected propagation path

---

## 14. Seeded Milestones

### 14.1 First Milestone

The first concrete implementation milestone is now seeded as:

**`M31-P10-11` - Admin-only TimesFM forecast sidecar shadow integration + governed diagnostics traceability**

Milestone deliverables:

1. localhost sidecar request/response contract
2. `TimesFmSidecarClient`
3. admin-only `HybridForecastKernel`
4. request enrichment in replay forecast batch for `movement_flow` and `economic_signal`
5. metadata and diagnostics propagation through the governed forecast lane
6. explicit fallback behavior when the sidecar is missing or unhealthy
7. shadow-only execution mode with no user-runtime dependency

Exit criteria:

- the admin simulation/replay path can call TimesFM for the first two target
  lanes
- `ensemble_predictive_distributions` preserves both native and TimesFM
  component evidence
- admin diagnostics can distinguish the sidecar path by kernel ID, execution
  mode, and sidecar metadata
- the system falls back cleanly to the native kernel without bundling TimesFM
  weights into the app

This is the smallest useful slice that:

- proves the integration seam
- exercises board/status/registry tracking
- keeps governance intact
- avoids premature rollout into user-facing paths

### 14.2 Follow-On Distillation Milestone

The next concrete milestone after `M31-P10-11` should be:

**`M31-P10-12` - Admin forecast distillation + supervision tuple export**

Milestone deliverables:

1. a forecast-distillation signal service in the prediction lane
2. a governed forecast-supervision tuple schema
3. tuple emission from issued-forecast plus resolved-outcome joins
4. World Simulation Lab and daemon-learning visibility for forecast
   disagreement/win-loss history
5. a local forecast-distillation candidate manifest and README
6. governed export of approved forecast supervision tuples into the
   deeper-training lane
7. no direct promotion of unresolved teacher predictions

Exit criteria:

- forecast supervision tuples are created only from issued forecasts with
  later resolution
- daemon memory retains denied forecast-learning candidates without promoting
  them
- approved tuples can be exported as governed training candidates
- the distillation lane preserves teacher lineage, actual outcome lineage, and
  operator disposition lineage
- a later native student model can be benchmarked back against the teacher in
  admin shadow mode

### 14.3 Follow-On Hierarchy Tracking Milestone

The next concrete milestone after `M31-P10-12` should be:

**`M31-P10-13` - TimesFM-informed hierarchy-loop propagation + live reality notation**

Milestone deliverables:

1. machine-readable TimesFM lineage on governed reality-model learning outcomes
2. TimesFM lineage carried into admin evidence refresh and supervisor feedback
   artifacts
3. TimesFM lineage carried into hierarchy-domain deltas, downstream propagation
   receipts, and governed live-consumer state
4. operator-visible notation showing whether live influence came from distilled
   student promotion or sidecar fallback
5. rollback-ready mapping from live artifacts back to distillation candidate,
   supervision tuples, and promotion receipt

Exit criteria:

- any TimesFM-informed live artifact can be traced through the post-learning
  hierarchy chain
- operator/admin surfaces can note the presence of TimesFM-informed lineage
- lower-tier propagation can distinguish `distilled_student_live` from
  `sidecar_fallback_live`
- rollback and later audit can identify the exact affected live-reality path

---

## 15. External References

Primary external references reviewed for this authority:

1. TimesFM GitHub README: `https://github.com/google-research/timesfm?tab=readme-ov-file`
2. Raw README: `https://raw.githubusercontent.com/google-research/timesfm/master/README.md`
3. Paper: `https://arxiv.org/abs/2310.10688`
4. Google Research blog: `https://research.google/blog/a-decoder-only-foundation-model-for-time-series-forecasting/`
5. Hugging Face checkpoint reference: `https://huggingface.co/google/timesfm-2.5-200m-pytorch`

These references inform:

- model role
- packaging expectations
- suitability for admin-side execution
