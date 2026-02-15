# Reality Coherence Test Matrix

**Date:** February 15, 2026  
**Status:** Active contract artifact (release-gating)  
**Primary Plan Source:** `docs/MASTER_PLAN.md` (Phase 2.8 + Phases 1-15)  
**Companion Contracts:**
- `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`
- `docs/plans/architecture/MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_CROSS_REFERENCE_2026-02-15.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`
- `docs/plans/architecture/PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`

---

## 1) Purpose

Define mandatory, phase-by-phase coherence tests that prove the reality model behaves as a single connected system across:
- learning systems,
- world/environment/context systems,
- AI2AI transport (BLE/WiFi + online/offline),
- self-learning and self-healing loops,
- federation pathways,
- access/security/privacy guardrails,
- UI/UX behavior under degraded and recovery conditions.

No phase is release-ready without matrix evidence.

---

## 2) Global Coherence Invariants (Non-Negotiable)

1. Offline-first baseline remains functional without network dependency for core decision loops.
2. Online pathways are enhancement-only unless explicitly approved as required by policy/security.
3. Weather/environment uncertainty is represented, propagated, and handled with deterministic fallback.
4. Learning, world, and environment systems remain causally connected via typed contracts + lineage IDs.
5. Self-healing cannot bypass immutable guardrails, access policy, or legal/security boundaries.
6. Federation shares only policy-safe aggregates with unlinkability guarantees.
7. Access matrix is fail-closed, non-bypassable, and drift-detected.
8. Disclosure plane (P3) is non-user-facing; only authorized non-user roles can access it with purpose binding.
9. Admin visibility exists for major coherence mode shifts and risk conditions.
10. Every phase must map stories to scenario IDs in this matrix and attach evidence.
11. Self-questioning loops must execute on schedule and remain causally tied to evidence updates.
12. Quantum backend paths must remain contract-parity compatible with classical fallback.

---

## 3) Scenario Catalog (Canonical IDs)

| ID | Scenario | Pass Criteria |
|---|---|---|
| RCM-OFF-001 | Offline baseline operation | Core flows run with deterministic behavior and no blocking network call |
| RCM-ONL-002 | Online enhancement path | Online improves quality/freshness without changing safety baseline |
| RCM-NET-003 | BLE/WiFi arbitration | Transport switches follow policy/confidence/latency/battery rules and are logged |
| RCM-NET-004 | Connectivity mode adaptation learning | Arbitration thresholds adapt over time with admin-visible justification |
| RCM-ENV-005 | Weather/environment confidence propagation | Freshness/confidence travel through encoders/planner and influence action weights |
| RCM-ENV-006 | Weather/environment fallback tiers | Stale/low-confidence inputs trigger deterministic fallback tier |
| RCM-LRN-007 | Local learning continuity | Learning loops continue locally under offline/degraded conditions |
| RCM-LRN-008 | Cross-system learning linkage | Learning updates reflect world/environment/context linkage with traceable lineage |
| RCM-SHL-009 | System-wide self-healing coverage | Every mutable component registers health signals + rollback path |
| RCM-SHL-010 | Self-healing safety boundary | Healing proposals fail closed on guardrail/policy violations |
| RCM-FED-011 | Federation coherence transfer | Local->locality->world->universe transfers preserve integrity + policy tags |
| RCM-FED-012 | Federated rollback/recovery | Bad federated updates are reversible with bounded blast radius |
| RCM-SEC-013 | Identity unlinkability | No unauthorized join path can re-link `agent_id` to `account_id` |
| RCM-SEC-014 | Access matrix robustness | Role+tier+purpose checks enforce fail-closed and non-bypass behavior |
| RCM-SEC-015 | Disclosure governance | P3 never appears on user surfaces; non-user access is fully audited |
| RCM-MIG-016 | Identity migration parity | Dual-read/dual-write parity gates hold through bounded migration window |
| RCM-MIG-017 | Strict cutoff enforcement | Legacy `user_id` paths are rejected after cutoff with no silent fallback |
| RCM-OBS-018 | Admin coherence observability | Mode shifts and coherence failures emit actionable admin events |
| RCM-UX-019 | Degraded UX contract | Loading/empty/error/offline states are explicit and policy-correct |
| RCM-UX-020 | Recovery UX contract | System surfaces recovery state, freshness, and resumed confidence |
| RCM-E2E-021 | End-to-end cohesion build suite | CI suite validates connected flows across offline/online/weather/transport/federation |
| RCM-LRN-022 | Distal objective alignment | Planner/predictor optimize real-world outcome objectives, not proxy engagement-only targets |
| RCM-CTL-023 | Hard-start recovery benchmark | Controller recovers from adversarial initial states within bounded safety and quality thresholds |
| RCM-SQ-024 | Self-questioning integrity | Conviction challenge scheduler runs, produces challenge outcomes, and records revision decisions |
| RCM-SIM-025 | Bounded self-improvement | Autonomous optimizations stay inside registered bounds, canary policy, and rollback guarantees |
| RCM-QNT-026 | Quantum-classical parity + fallback | Quantum path respects identical contracts/guardrails and auto-falls back to classical on failure |
| RCM-QNT-027 | Quantum readiness gate | Quantum rollout requires uplift, latency/cost fit, and privacy/offline non-regression evidence |
| RCM-SEC-028 | Post-quantum agility | Key rotation/migration and algorithm agility pass with no identity/policy regression |

---

## 4) Phase-by-Phase Coherence Matrix

| Phase | Required Scenario IDs | Required Evidence |
|---|---|---|
| 1 | RCM-OFF-001, RCM-LRN-007, RCM-LRN-008, RCM-OBS-018 | Schema contract tests, lineage sample, offline learning simulation |
| 2 | RCM-SEC-013, RCM-SEC-014, RCM-SEC-015, RCM-SEC-028, RCM-OBS-018 | Policy tests, denial-path tests, access audit evidence, PQ agility report |
| 3 | RCM-ENV-005, RCM-ENV-006, RCM-LRN-008, RCM-UX-019 | Encoder tests, stale-data fallback tests, UI degraded-state tests |
| 4 | RCM-OFF-001, RCM-LRN-008, RCM-SHL-010, RCM-UX-020 | Critic fallback tests, explainability linkage tests, safety boundary tests |
| 5 | RCM-OFF-001, RCM-LRN-007, RCM-SHL-009, RCM-LRN-022, RCM-CTL-023, RCM-OBS-018 | Predictor offline continuity tests, distal-objective alignment tests, hard-start recovery benchmarks, health coverage map evidence |
| 6 | RCM-OFF-001, RCM-ONL-002, RCM-NET-003, RCM-NET-004, RCM-LRN-022, RCM-UX-019 | Planner arbitration tests, transport-switch traces, distal-objective planning evidence, degraded UX evidence |
| 7 | RCM-SHL-009, RCM-SHL-010, RCM-LRN-008, RCM-SQ-024, RCM-SIM-025, RCM-OBS-018 | Self-healing policy tests, rollback drills, conviction challenge evidence, bounded self-improvement evidence, observation bus coverage report |
| 8 | RCM-FED-011, RCM-FED-012, RCM-LRN-008, RCM-SEC-013 | Federation integrity tests, rollback simulation, privacy-tag audit |
| 9 | RCM-OFF-001, RCM-ONL-002, RCM-SEC-014, RCM-UX-020 | Marketplace/business path coherence tests + policy enforcement evidence |
| 10 | RCM-E2E-021, RCM-UX-019, RCM-UX-020, RCM-OBS-018 | Cohesion integration suite run + grouped test path evidence |
| 11 | RCM-NET-003, RCM-OFF-001, RCM-SHL-009, RCM-FED-011, RCM-QNT-026, RCM-QNT-027, RCM-SEC-028 | Hardware/transport fallback tests, quantum parity and fallback tests, readiness gate evidence, crypto agility evidence |
| 12 | RCM-SEC-014, RCM-SEC-015, RCM-SHL-010, RCM-OBS-018 | Admin governance tests, self-coding gate tests, disclosure audit evidence |
| 13 | RCM-FED-011, RCM-FED-012, RCM-SEC-013, RCM-NET-004 | Sovereignty and federated rollback tests + adaptation telemetry |
| 14 | RCM-SEC-014, RCM-SEC-015, RCM-FED-011, RCM-UX-019 | Research access/purpose tests + non-user-plane UI/access evidence |
| 15 | RCM-SEC-015, RCM-MIG-016, RCM-MIG-017, RCM-SEC-014, RCM-E2E-021 | Spectrum/disclosure gate tests, migration parity report, strict-cutoff verification |

---

## 5) Release Blockers (No-Go Criteria)

Any single condition below blocks release/cutover:
- Missing scenario coverage for a phase/story.
- Missing evidence links for required scenario IDs.
- Any failing RCM-SEC-013/014/015 tests.
- Any failing RCM-MIG-017 strict-cutoff test after cutoff date.
- Any unapproved bypass of offline-first arbitration policy.
- Any self-healing path that can mutate immutable guardrails or policy boundaries.
- Any failing RCM-SQ-024 or RCM-SIM-025 evidence for phases with autonomous optimization scope.
- Any quantum rollout attempt without passing RCM-QNT-026 and RCM-QNT-027.
- Any failing RCM-SEC-028 evidence where cryptographic pathways are modified.
- Any federated flow without policy tags, lineage, or rollback path.
- Any user-facing surface rendering P3 disclosure outputs.

---

## 6) Evidence Package Contract

Each phase gate submission must include:
- story IDs (`MPA-Px-Ex-Sx`) mapped to scenario IDs,
- test artifact links (CI runs, logs, reports),
- rollback test result where applicable,
- hard-start recovery and distal-objective evidence where applicable,
- self-questioning (conviction challenge) and bounded self-improvement evidence where applicable,
- quantum parity/readiness evidence where applicable,
- policy/security signoff references for restricted scenarios,
- unresolved risk list with owner + due date.

Evidence must be attached in:
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md` phase gate record,
- PR metadata as required by orchestration contracts.

---

## 7) Automation and Governance Hooks

1. `docs/plans/master_plan_execution.yaml` includes this document in `required_global_docs`.
2. Orchestration validation fails if this document path is missing.
3. Backlog stories that affect cross-system coherence must reference scenario IDs from this matrix.
4. Design docs must include degraded/recovery UX states aligned to `RCM-UX-019` and `RCM-UX-020`.
5. Tracker phase-specific plans must include this artifact for execution visibility.

---

## 8) Ownership and Change Control

- Primary owners: `ARC` + `QAE` + `SEC` + `AIC` + `PMO`.
- Any change to scenario IDs, pass criteria, or no-go criteria requires:
  - architecture council review,
  - security review for `RCM-SEC-*` and `RCM-MIG-*` changes,
  - tracker/version note update in `docs/MASTER_PLAN_TRACKER.md`.
