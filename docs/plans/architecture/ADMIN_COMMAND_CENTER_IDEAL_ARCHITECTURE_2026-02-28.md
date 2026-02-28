# Admin Command Center Ideal Architecture

**Date:** February 28, 2026  
**Status:** Active planning authority  
**Purpose:** Define the robust oversight architecture for the admin app across reality, universe, and world model surfaces with privacy-safe observability and operator controls.

---

## 1. Outcome This Locks In

The admin app is the command center for safe, explainable system oversight:

1. Separate oversight pages for:
   1. Reality model (`convictions`, `knowledge`, `thoughts`, planning/prep state)
   2. Universe model (`clubs`, `communities`, `events`, grouped types)
   3. World model (`users`, `businesses`, `services`, grouped types)
2. Operator-to-model check-ins (conversation and reasoning introspection) across all three layers.
3. Live visualization surfaces for knots, planes, and related topology states.
4. Live AI2AI network health and communication mesh with `admin_agent_globe` integration.
5. Privacy-safe rendering where only agent identity is shown (never direct user identity).

---

## 2. Mandatory Privacy And Identity Rules

1. UI and telemetry payloads shown in admin surfaces must use agent identity only.
2. User-level PII must be redacted, tokenized, or omitted before rendering.
3. All conversation introspection views must carry lineage/policy metadata so admins can verify why data is visible.
4. Violations fail closed:
   1. Hide sensitive fields in UI
   2. Emit policy breach telemetry
   3. Require explicit governed override flow for any temporary debug exception

---

## 3. Oversight Surface Architecture

### 3.1 Reality Oversight Page

1. Convictions/knowledge/thoughts layer explorer with temporal snapshots.
2. Reasoning path inspection:
   1. What changed
   2. Why it changed
   3. What policy gates applied
3. Model check-in panel for operator conversation with structured prompts and response lineage.

### 3.2 Universe Oversight Page

1. Entity inventory for clubs/communities/events with live health state.
2. 3D globe map showing real-time agent placement/activity.
3. Grouping lens:
   1. Logical category groupings
   2. Learned grouping candidates proposed by reality model
   3. Human approval controls before promotion

### 3.3 World Oversight Page

1. Entity inventory for users/businesses/services using agent-only identity.
2. 3D globe map showing real-time agent placement/activity.
3. Grouping lens with model-proposed taxonomy expansion under human oversight.

---

## 4. Visualization And Network Operations

1. `admin_agent_globe` is the canonical spatial view for world/universe activity.
2. AI2AI communication visualizer includes:
   1. Live message/edge throughput
   2. Link health and congestion states
   3. Failure domain highlighting
3. Mesh view supports:
   1. Real-time state
   2. Temporal replay by timestamp
   3. Quantum/atomic timing state slices for internal universal time inspection

---

## 5. State Tracking Contract

Current approved direction:

1. State is not admin-only; admin reads from canonical system state services.
2. Persistent state tracking target is an internal backend server (pending setup).
3. Until backend is available, temporary local/admin caches are explicitly non-authoritative and diagnostic-only.
4. On backend cutover:
   1. Move durable state/event logs to backend authority
   2. Keep admin app as read/operate surface only
   3. Enforce signed event lineage for replay integrity

---

## 6. Research Oversight Integration

1. Admin app includes a research section:
   1. Active studies/experiments
   2. Hypothesis status and replication evidence
   3. Promotion blockers and risk flags
2. Reality model can read approved research context to align learning and grouping expansion proposals.
3. All research-driven updates remain human-governed before production promotion.

---

## 7. Master Plan + Execution Board Mapping

This architecture directly governs and depends on:

1. `docs/MASTER_PLAN.md`
   1. `10.9.22` unified graph + temporal replay
   2. `10.9.23` cross-layer correlation + SLO burn-rate center
   3. `10.9.24` policy/lineage/SOC observability hardening
   4. `10.9.25` digital twins + intervention console
2. `docs/EXECUTION_BOARD.csv`
   1. `M24-P10-3` command-center delivery milestone for this architecture package

---

## 8. Implementation Gates

1. Privacy conformance tests for agent-only identity rendering.
2. Deterministic replay checks for globe/mesh/time-slice states.
3. Policy lineage completeness checks for all admin-inspection surfaces.
4. Integration tests for research visibility + reality-model read alignment.
5. Fail-closed behavior checks when backend state service is unavailable.
