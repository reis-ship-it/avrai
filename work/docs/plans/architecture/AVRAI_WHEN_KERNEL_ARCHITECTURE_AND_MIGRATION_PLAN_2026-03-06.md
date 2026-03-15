# AVRAI When Kernel Architecture And Migration Plan

**Date:** March 6, 2026  
**Status:** Proposed implementation authority for `when` kernel rollout  
**Purpose:** Define `when` as a core cognitive OS kernel for AVRAI across app, runtime, engine, and reality model, then sequence migration of scattered timing/sequencing logic into one coherent kernel.

**Companion docs:** `UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`, `URK_INTERFACE_CONTRACTS_2026-02-27.md`, `AVRAI_COGNITIVE_OS_DOCTRINE_2026-03-06.md`, `AVRAI_RECURSIVE_GOVERNANCE_ARCHITECTURE_SPEC_2026-03-06.md`

---

## 1. Why This Exists

AVRAI already treats `who` and `where` as first-class system concepts. `when` must now receive the same treatment as a peer kernel substrate.

At present, timing and sequencing are distributed across:

1. atomic/server-sync time generation,
2. network ordering and timeout code,
3. freshness/staleness heuristics,
4. domain-specific temporal decay logic,
5. model constructors and persistence metadata,
6. prediction horizons and replay pathways.

This is not sufficient for a persistent runtime and reality model. A `when` kernel is required so AVRAI can operate as a standalone cognitive OS product with temporal truth at the kernel layer.

Specifically, a `when` kernel is required so AVRAI can:

1. track event lineage end to end,
2. order actions and observations coherently across subsystems,
3. reason about habits, rituals, recurrence, and cadence,
4. ingest uncertain historical events, including pre-AVRAI history,
5. compare forecasts against outcomes,
6. produce present suggestions grounded in temporal truth rather than local ad hoc clocks.

The architectural shift is:

1. from timestamps as metadata,
2. to temporal structure as system ontology.

---

## 2. Core Decision

`when` is a core cognitive OS kernel concern, not an app utility.

This means:

1. runtime and reality-model subsystems must consume a shared temporal ontology,
2. the standalone AVRAI OS must be able to provide temporal truth as a product-level kernel capability,
2. no subsystem may define its own authoritative concept of ordering, freshness, expiry, or drift,
3. user-visible semantic time and machine-visible atomic time must coexist,
4. uncertainty is a first-class field, not an afterthought,
5. historical and forecast temporal claims must be represented in the same lineage fabric as present observations.

---

## 3. Canonical Temporal Taxonomy

AVRAI must distinguish the following categories. Collapsing them into one `DateTime` is no longer acceptable.

### 3.1 Monotonic time

Used for:

1. ordering within a process or runtime boundary,
2. elapsed duration,
3. retries and backoff,
4. deadlines and leases,
5. timeout enforcement,
6. replay protection windows where elapsed time matters more than wall-clock semantics.

Monotonic time must never be inferred from wall-clock differences.

### 3.2 Civil time

Used for:

1. user-facing timestamps,
2. calendar semantics,
3. locale and timezone interpretation,
4. semantic bands such as `morning`, `afternoon`, `night`,
5. ritual and schedule reasoning.

Civil time is local-context-sensitive and may vary with timezone and daylight-saving rules.

### 3.3 Synchronized reference time

Used for:

1. cross-device ordering,
2. cross-runtime truth reconciliation,
3. external system alignment,
4. audit and replay,
5. governance escalation windows.

Current `AtomicTimestamp` behavior belongs here, but must become one part of a broader temporal ontology.

### 3.4 Historical time

Used for:

1. backfilled user history,
2. imported timelines,
3. reconstructed actions before AVRAI existed,
4. uncertain or approximate temporal evidence.

Historical time must support:

1. approximate dates,
2. granularity (`year`, `month`, `day`, `hour`, `unknown_exact`),
3. provenance,
4. uncertainty bounds,
5. inferred versus observed labeling.

### 3.5 Forecast time

Used for:

1. predicted events,
2. suggestion windows,
3. recommendation timing,
4. planner horizon reasoning,
5. later forecast-vs-outcome evaluation.

Forecasts are temporal claims, not observed facts.

### 3.6 Freshness and validity time

Used for:

1. staleness evaluation,
2. cache validity,
3. recommendation freshness,
4. trust decay,
5. policy expiry,
6. break-glass or override validity windows.

Freshness must be governed by policy objects, not scattered thresholds.

### 3.7 Cadence and recurrence time

Used for:

1. rituals,
2. habits,
3. periodic sampling,
4. behavioral rhythms,
5. recurring event suggestions,
6. string/worldsheet phase transitions and oscillations.

Cadence is distinct from a single timestamp and must be modeled explicitly.

---

## 4. Required Temporal Ontology

The minimum shared temporal types to introduce in `shared/avrai_core` are:

1. `TemporalInstant`
2. `TemporalInterval`
3. `TemporalSnapshot`
4. `TemporalUncertainty`
5. `TemporalProvenance`
6. `TemporalFreshnessPolicy`
7. `TemporalOrderingPolicy`
8. `TemporalCadence`
9. `HistoricalTemporalEvidence`
10. `ForecastTemporalClaim`
11. `TemporalLineageRef`
12. `TemporalConflictResolution`

### 4.1 `TemporalInstant`

Minimum fields:

1. `monotonicTicks` when available,
2. `civilTime`,
3. `referenceTime`,
4. `timezoneId`,
5. `uncertainty`,
6. `provenance`,
7. `clockAuthority`.

### 4.2 `TemporalSnapshot`

Represents the temporal envelope attached to any meaningful observation or action.

Minimum fields:

1. `observedAt`
2. `recordedAt`
3. `effectiveAt`
4. `expiresAt` if applicable
5. `semanticBand`
6. `cadence`
7. `uncertainty`
8. `lineageRef`

### 4.3 `HistoricalTemporalEvidence`

Minimum fields:

1. `estimatedStart`
2. `estimatedEnd`
3. `granularity`
4. `confidence`
5. `provenance`
6. `reconstructionMethod`
7. `sourceArtifactRefs`

### 4.4 `ForecastTemporalClaim`

Minimum fields:

1. `forecastCreatedAt`
2. `targetWindow`
3. `evidenceWindow`
4. `confidence`
5. `modelVersion`
6. `laterOutcomeRef`

---

## 5. Kernel Responsibilities

The `when` kernel is the authoritative subsystem for:

1. issuing temporal snapshots,
2. exposing monotonic, civil, and synchronized reference time,
3. ordering and comparability judgments,
4. freshness, expiry, and validity policy evaluation,
5. scheduling and tolerance windows,
6. cadence and recurrence modeling,
7. historical evidence ingestion,
8. forecast registration and later outcome reconciliation,
9. drift, sync, and uncertainty reporting,
10. replay and lineage support for runtime and governance.

The kernel is not responsible for domain recommendations by itself. It provides temporal truth to the systems that do.

---

## 6. Package Boundaries

### 6.1 `shared/avrai_core`

Owns:

1. temporal primitives,
2. serialization contracts,
3. policy types,
4. semantic-band enums,
5. historical and forecast temporal envelopes.

Must not own:

1. network sync implementation,
2. OS timers,
3. Rust FFI bindings,
4. runtime-specific schedulers.

### 6.2 `runtime/avrai_runtime_os`

Owns:

1. `TemporalKernel` interface,
2. Dart implementation and adapters,
3. scheduling integration,
4. policy execution,
5. runtime lineage and replay integration,
6. future FFI boundary to native implementation.

### 6.3 `runtime/avrai_network`

Consumes:

1. monotonic deadlines,
2. replay windows,
3. retry/backoff policies,
4. ordering policy,
5. synchronized reference timestamps for cross-node traces.

Must stop owning:

1. authoritative timeout semantics,
2. duplicated freshness logic,
3. ad hoc sequencing authority.

### 6.4 `engine/*` and `reality_engine`

Consume:

1. temporal snapshots,
2. cadence abstractions,
3. historical evidence,
4. forecast windows,
5. ordering and uncertainty metadata.

Must stop embedding:

1. hardcoded temporal-decay policy as domain truth,
2. direct wall-clock assumptions for sequence meaning,
3. implicit recency semantics with no provenance.

### 6.5 Native/Rust authority

The long-term authority point should be a Rust timing core, parallel to native kernel directions already present for locality. Dart remains the integration layer; Rust becomes the deepest timing truth source for high-integrity sequencing and validation.

---

## 7. Canonical Interface Sketch

The first `TemporalKernel` contract in `runtime/avrai_runtime_os` should minimally expose:

1. `TemporalInstant nowMonotonic()`
2. `TemporalInstant nowCivil()`
3. `TemporalSnapshot snapshot(TemporalSnapshotRequest request)`
4. `TemporalOrderingResult compare(TemporalSnapshot a, TemporalSnapshot b)`
5. `TemporalFreshnessResult freshnessOf(TemporalSnapshot snapshot, TemporalFreshnessPolicy policy)`
6. `bool isExpired(TemporalSnapshot snapshot, TemporalFreshnessPolicy policy)`
7. `SchedulingReceipt schedule(TemporalScheduleRequest request)`
8. `TemporalSyncStatus syncStatus()`
9. `HistoricalTemporalEvidenceReceipt recordHistoricalEvidence(HistoricalTemporalEvidence evidence)`
10. `ForecastTemporalClaimReceipt recordForecast(ForecastTemporalClaim claim)`
11. `ForecastOutcomeResolution resolveForecastOutcome(ForecastOutcomeResolutionRequest request)`

### 7.1 Policy objects

At minimum:

1. `TemporalFreshnessPolicy`
2. `TemporalOrderingPolicy`
3. `TemporalRetryPolicy`
4. `TemporalReplayPolicy`
5. `TemporalCadencePolicy`
6. `TemporalForecastPolicy`

---

## 8. Existing Repo Surface To Migrate

The current timing surface already demonstrates the migration lanes.

### 8.1 Kernel-compatible source of truth

Current anchor:

1. `shared/avrai_core/lib/services/atomic_clock_service.dart`

Role in migration:

1. retain initially as a compatibility adapter,
2. refactor behind `ClockSource` and `TemporalKernel`,
3. stop treating it as the complete timing solution.

### 8.2 Runtime sequencing and timeout debt

Representative files:

1. `runtime/avrai_network/lib/network/message_ordering_buffer.dart`
2. `runtime/avrai_network/lib/network/delivery_ack_service.dart`
3. `runtime/avrai_network/lib/network/replay_protection.dart`
4. `runtime/avrai_network/lib/network/rate_limiter.dart`
5. `runtime/avrai_network/lib/network/device_discovery.dart`
6. `runtime/avrai_network/lib/models/sync_status.dart`

These lanes must migrate first because behavioral regressions here are immediate and user-visible.

### 8.3 Freshness and validity debt

Representative files:

1. `runtime/avrai_runtime_os/lib/services/admin/remote_source_health_service.dart`
2. `shared/avrai_core/lib/models/spots/source_indicator.dart`
3. `shared/avrai_core/lib/models/user_vibe.dart`
4. `shared/avrai_core/lib/models/quantum/group_session.dart`

These lanes currently make local staleness judgments that should become policy-driven.

### 8.4 Engine and reality-model temporal heuristics

Representative files:

1. `engine/avrai_knot/lib/services/knot/temporal_string_integration_service.dart`
2. `engine/reality_engine/lib/memory/air_gap/tuple_extraction_engine.dart`

These lanes are where temporal structure must evolve from heuristic timestamps to actual sequencing semantics.

### 8.5 Model constructor defaults

Large classes of models in `shared/avrai_core` currently default missing fields to `DateTime.now()`.

This is lower-risk than runtime timeouts, but it undermines:

1. determinism,
2. replay,
3. provenance clarity,
4. testability.

### 8.6 Current scale

A repository scan found roughly 1218 files with direct timing constructs such as:

1. `DateTime.now()`
2. `Timer(...)`
3. `Timer.periodic(...)`
4. `Stopwatch()`
5. `Future.delayed(...)`
6. raw `Duration(...)` timing decisions

This confirms the need for phased migration rather than wholesale replacement.

---

## 9. Migration Phases

### Phase 0: Doctrine and contract freeze

Deliverables:

1. this architecture document,
2. canonical `when` taxonomy,
3. approval that `when` is a URK subsystem.

Exit criteria:

1. new timing work must not introduce additional ad hoc time semantics,
2. all new timing logic references kernel direction explicitly.

### Phase 1: Introduce shared temporal primitives

Deliverables:

1. temporal primitives in `shared/avrai_core`,
2. serialization formats,
3. policy object shells,
4. deterministic test clock support.

Exit criteria:

1. new runtime code can compile against the temporal ontology,
2. no production behavior changed yet.

### Phase 2: Introduce `TemporalKernel` and compatibility adapters

Deliverables:

1. `TemporalKernel` interface in `runtime_os`,
2. Dart implementation,
3. `AtomicClockService` adapter,
4. bridge utilities for legacy `DateTime` consumers.

Exit criteria:

1. new code can request kernel snapshots,
2. legacy services can be wrapped without invasive rewrites.

### Phase 3: Migrate high-risk runtime sequencing and timeout paths

Targets:

1. ACK deadlines,
2. retry/backoff,
3. replay windows,
4. message ordering,
5. device discovery lifetimes,
6. sync aging metrics.

Exit criteria:

1. runtime timeout behavior runs on monotonic policy-driven semantics,
2. sequence handling exposes comparable temporal envelopes.

### Phase 4: Centralize freshness and validity policies

Targets:

1. source health freshness,
2. recommendation freshness,
3. cache validity,
4. session expiry,
5. policy override expiry,
6. stale-data judgments.

Exit criteria:

1. local threshold logic is replaced with shared policy evaluation,
2. freshness judgments become explainable and auditable.

### Phase 5: Refactor engine and reality-model temporal logic

Targets:

1. event lineage,
2. memory tuple temporal envelopes,
3. temporal-string sequencing,
4. cadence and ritual detection,
5. phase and stability windows,
6. planner horizons and forecast tracking.

Exit criteria:

1. the reality model consumes temporal structure, not just timestamps,
2. present suggestions can cite temporal evidence windows.

### Phase 6: Historical and pre-AVRAI event ingestion

Targets:

1. imported personal history,
2. inferred historical timelines,
3. approximate event dating,
4. provenance-aware reconstruction.

Exit criteria:

1. uncertain history can enter the same temporal graph,
2. AVRAI does not require perfect timestamp precision to preserve lineage.

### Phase 7: Native timing authority

Targets:

1. Rust timing core,
2. stronger monotonic/reference-time discipline,
3. FFI boundary in `runtime_os`,
4. validation against Dart fallback implementation.

Exit criteria:

1. high-integrity timing flows can rely on native authority,
2. Dart remains a compatibility and orchestration layer.

---

## 10. Reality Model And Suggestion Semantics

The `when` kernel is the foundation for present suggestions that are correct because they are temporally grounded.

This enables:

1. future inference from past recurrence,
2. recommendation timing rather than only recommendation content,
3. ritual and cadence detection,
4. forecast-vs-outcome learning,
5. sequencing of personality/string/worldsheet evolution,
6. persistent lineage from historical evidence to present action.

Example interpretation rule:

1. a recommendation must be able to cite not only `similar users liked X`,
2. but also `similar temporal patterns recur in this context, with this freshness and confidence`.

This is necessary for both:

1. human ritual modeling such as morning behaviors,
2. string/worldsheet sequencing where order, interval, cadence, and phase matter.

---

## 11. Validation Strategy

### 11.1 Deterministic clocks

Every kernel-facing subsystem must be testable with injectable deterministic clocks and fixed temporal snapshots.

### 11.2 Replay and lineage tests

Required:

1. event ordering replay fixtures,
2. timeout and retry determinism checks,
3. historical evidence reconstruction tests,
4. forecast registration and resolution tests.

### 11.3 Drift and uncertainty tests

Required:

1. sync loss behavior,
2. stale offset fallback behavior,
3. uncertainty threshold enforcement,
4. governance fail-closed behavior when temporal confidence is insufficient.

### 11.4 Migration guards

Required:

1. static scans for direct timing constructs in kernel-managed zones,
2. architecture boundary checks,
3. regression baselines for timeout, ordering, freshness, and replay.

---

## 12. Immediate Implementation Backlog

### 12.1 First code slice

Implement first:

1. `TemporalInstant`
2. `TemporalSnapshot`
3. `TemporalFreshnessPolicy`
4. `TemporalKernel`
5. `ClockSource`
6. deterministic test clock
7. `AtomicClockService` adapter

### 12.2 First migration slice

Refactor first:

1. `runtime/avrai_network/lib/network/delivery_ack_service.dart`
2. `runtime/avrai_network/lib/network/message_ordering_buffer.dart`
3. `runtime/avrai_runtime_os/lib/services/admin/remote_source_health_service.dart`

These are the cleanest initial proof points because they cover:

1. monotonic deadlines,
2. ordering semantics,
3. freshness policy.

### 12.3 Deferred but planned

Later migrate:

1. model constructor `DateTime.now()` defaults,
2. engine temporal heuristics,
3. historical event ingestion,
4. native Rust authority layer.

---

## 13. Non-Negotiable Invariants

1. Every meaningful observation or action must be representable with temporal provenance.
2. Freshness and expiry may not be encoded as scattered magic thresholds.
3. Ordering semantics may not depend on wall-clock comparisons alone.
4. Historical evidence is allowed to be uncertain; uncertainty must be explicit.
5. Forecasts are first-class temporal claims and must later be comparable with outcomes.
6. Runtime and reality model must share one temporal ontology.
7. New code must prefer kernel-issued temporal structures over raw `DateTime.now()`.

---

## 14. Decision Summary

AVRAI should implement `when` as a persistent kernel spanning runtime and reality model.

The near-term implementation path is:

1. shared temporal ontology in `shared/avrai_core`,
2. `TemporalKernel` contract in `runtime/avrai_runtime_os`,
3. adapters for existing clock and legacy timing services,
4. migration of runtime ordering/timeout/freshness first,
5. later migration of engine temporal reasoning and historical ingestion,
6. eventual Rust authority for high-integrity timing.

This is the correct direction if AVRAI is meant to learn from past, act in the present, and project into the future with coherent temporal truth.
