# External Research Execution Backlog (2026-02-15)

**Date:** February 15, 2026  
**Status:** Active planning backlog (execution-ready, no scaffolding implied)  
**Primary plan:** `docs/MASTER_PLAN.md`  
**Backlog parent:** `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`  
**Companion contract:** `docs/plans/architecture/EXTERNAL_RESEARCH_CROSS_REFERENCE_2026-02-15.md`  
**Coherence gates:** `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`

---

## 1) Purpose

Provide a consolidated, phase-mapped backlog that converts the full research pass (papers, patents, companies, protocols) into executable architecture/documentation updates aligned to AVRAI's reality model:
- self-learning,
- self-healing,
- self-questioning,
- self-improving,
- quantum-ready backend abstraction.

---

## 2) Story List (Execution Pack)

## Phase 2 (Security, Compliance, PQ Agility)

- [ ] `MPA-P2-E5-S1`  
  Step: Add post-quantum agility runbook contract (rotation, migration rehearsal, rollback criteria) and map to `RCM-SEC-028`.  
  Owner: `SEC`  
  Dependencies: `MPA-P2-E2-S1`  
  Acceptance: runbook section added and linked in checklist/coherence docs.

- [ ] `MPA-P2-E5-S2`  
  Step: Add claim-sensitive privacy language guardrail for location-linked matching to avoid promotion-style framing.  
  Owner: `SEC` + `AIC`  
  Dependencies: none  
  Acceptance: design language guardrail documented and linked to Phase 2 gate.

## Phase 3 (Encoders + Matching Contracts)

- [ ] `MPA-P3-E4-S1`  
  Step: Define claim-sensitive matching contract for bilateral consent, profile-behavior-location inputs, and explicit separation from ad/content promotion semantics.  
  Owner: `AIC` + `APP`  
  Dependencies: `MPA-P3-E2-S1`  
  Acceptance: contract fields/versioning and exclusions documented.

- [ ] `MPA-P3-E4-S2`  
  Step: Add graph-encoder research track contract (GAT-aligned) with parity fallback to current encoder path.  
  Owner: `AIC` + `MLP`  
  Dependencies: `MPA-P3-E2-S1`  
  Acceptance: interface and fallback policy documented.

## Phase 5 (Predictor + Control Robustness)

- [ ] `MPA-P5-E4-S1`  
  Step: Define hard-start recovery benchmark suite specification (adversarial initial state recovery), mapped to `RCM-CTL-023`.  
  Owner: `QAE` + `AIC`  
  Dependencies: `MPA-P5-E1-S1`  
  Acceptance: benchmark scenarios, pass thresholds, evidence format documented.

- [ ] `MPA-P5-E4-S2`  
  Step: Define distal-objective alignment evidence schema for predictor/planner data, mapped to `RCM-LRN-022`.  
  Owner: `AIC` + `MLP`  
  Dependencies: `MPA-P5-E1-S1`, `MPA-P6-E1-S1`  
  Acceptance: evidence schema and reporting cadence documented.

## Phase 6 (Planner + Translation)

- [ ] `MPA-P6-E4-S1`  
  Step: Add planner objective non-negotiable: optimize real-world outcome vectors, not engagement-only proxies.  
  Owner: `AIC`  
  Dependencies: `MPA-P6-E1-S1`  
  Acceptance: objective contract and no-go criterion linked in coherence matrix.

- [ ] `MPA-P6-E4-S2`  
  Step: Add matching notification contract with user-agency constraints and anti-spam policy in claim-sensitive flows.  
  Owner: `APP` + `SEC`  
  Dependencies: `MPA-P6-E2-S2`  
  Acceptance: channel policy contract updated with guardrails and evidence fields.

## Phase 7 (Self-Healing, Self-Questioning, Bounded Improvement)

- [ ] `MPA-P7-E5-S1`  
  Step: Require conviction challenge execution reports in phase exits (`RCM-SQ-024`).  
  Owner: `ADM` + `AIC`  
  Dependencies: `MPA-P7-E2-S1`  
  Acceptance: report schema and gate checklist linkage documented.

- [ ] `MPA-P7-E5-S2`  
  Step: Require bounded self-improvement evidence bundle (`RCM-SIM-025`) for all autonomous optimization changes.  
  Owner: `ADM` + `QAE`  
  Dependencies: `MPA-P7-E2-S3`  
  Acceptance: bounds/canary/rollback evidence contract documented.

## Phase 10 (Documentation + Risk Register Hardening)

- [ ] `MPA-P10-E6-S1`  
  Step: Maintain element-by-element claim checklist for red/yellow patent families and map to affected modules.  
  Owner: `ARC` + `SEC` + `PMO`  
  Dependencies: none  
  Acceptance: checklist present, linked, with owner + review cadence.

- [ ] `MPA-P10-E6-S2`  
  Step: Add monthly external research/prosecution watch update process to architecture planning docs.  
  Owner: `PMO`  
  Dependencies: none  
  Acceptance: cadence, owners, and update fields documented.

## Phase 11 (Hardware Abstraction + Quantum Readiness)

- [ ] `MPA-P11-E4-S1`  
  Step: Define quantum-classical contract parity test specification (`RCM-QNT-026`).  
  Owner: `MLP` + `AIC` + `QAE`  
  Dependencies: `MPA-P11-E1-S1`  
  Acceptance: parity test matrix and failover criteria documented.

- [ ] `MPA-P11-E4-S2`  
  Step: Define quantum readiness gate evidence package (`RCM-QNT-027`) including uplift, latency/cost, privacy/offline non-regression.  
  Owner: `MLP` + `SEC` + `QAE`  
  Dependencies: `MPA-P11-E4-S1`  
  Acceptance: gate template added and linked to checklist phase-11 exit.

---

## 3) Execution Notes

1. These stories are documentation/contract-first and can be executed immediately.
2. No implementation code changes are required to complete this backlog pack.
3. Any story touching security, identity, disclosure, or crypto requires `SEC` signoff.
