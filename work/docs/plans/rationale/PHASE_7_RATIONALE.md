# Phase 7 Rationale: Orchestrators, Triggers, Device Tiers & Integration

**Phase:** 7 | **Tier:** 2 (Depends on Phase 4 minimum) | **Duration:** 5-6 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 7  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #9, #10)

---

## Why This Phase Exists

Phases 3-6 build new intelligence components. Phase 7 wires them into the EXISTING system. The codebase has 6 orchestrators, 21 controllers, 330+ services -- all currently running on hardcoded formulas. Phase 7 replaces their decision-making with the world model.

This is the integration phase. Without it, the world model exists in isolation and users never see its benefits.

---

## Key Design Decisions

### Why the Evolution Cascade Must Be Atomic (7.1.2)
When personality changes, 6 systems must update in sequence:
```
PersonalityChange → QuantumVibeEngine.recompile()
                  → PersonalityKnotService.recompute()
                  → KnotFabricService.updateInvariants()
                  → WorldsheetEvolutionDynamics.step()
                  → KnotEvolutionStringService.updateRates()
                  → DecoherenceTrackingService.updatePhase()
                  → WorldModelFeatureExtractor.captureFullSnapshot()
```

Currently, only knot evolution is wired. The rest are placeholder log-only methods. If the state encoder reads features mid-cascade (quantum updated but knot not yet), it sees an internally inconsistent state. LeCun's framework requires coherent state observation.

### Why Event-Driven Triggers Replace Polling (7.4)
`ContinuousLearningOrchestrator` currently uses a 1-second `Timer.periodic`. Running inference every second means:
- Constant battery drain even when nothing changes
- ~5-30ms compute 86,400 times per day = significant cumulative cost
- Most cycles do nothing (user hasn't moved, no new data)

Event-driven triggers (app open, location change, AI2AI connection, timer every 2hr) fire 20-50 times per day instead of 86,400. Between triggers, the agent SLEEPS (zero battery). Each activation: 1-5 reasoning steps, 6-30ms compute, negligible impact.

**Integration risk**: The orchestrator's state tracking (cycle counting, convergence) assumes periodic execution. Refactor to track "activations" instead of "cycles."

### Why 4 Device Tiers (7.5)
See Foundational Decision #10. Every user gets an agent, but its capabilities scale with hardware. The key insight: the SAME codebase serves all devices. `DeferredInitializationService` only loads components available at the detected tier. No wasted memory loading world model ONNX on a Tier 0 device that will never use it.

**Integration risk**: The existing `OfflineLlmTier` enum overlaps with the new `AgentCapabilityTier`. Resolution: `AgentCapabilityTier` subsumes `OfflineLlmTier`. Keep the old enum as a derived property for backward compatibility with settings pages.

### Why Dependency Chain Management Is Documented Here (7.6)
When replacing a formula in a service, ALL downstream consumers must update atomically. Example: if `VibeCompatibilityService` switches from formula to energy function, `CallingScoreCalculator`, `CommunityService`, and `GroupMatchingService` all use it. Feature flags must flip atomically, not one-at-a-time.

### Why Model Lifecycle Management (7.7)
OTA model delivery is necessary because App Store updates are too slow for iterative model improvement. Users expect weekly or monthly releases; the world model needs to evolve faster. Staged rollout with canary prevents regressions from hitting all users simultaneously -- a small percentage receives the new model first, and metrics are validated before broader deployment. Per-user rollback is needed in addition to global rollback because some users degrade while global metrics stay fine; individual users may have edge-case data or device states that cause the new model to fail. The model-episodic compatibility gate prevents crashes from schema mismatch: when the model expects a different feature structure than the episodic store provides, the gate blocks deployment.

### Why Multi-Device Reconciliation (7.8)
Primary/secondary architecture (not peer-to-peer model merge) is the right approach. Peer-to-peer merge would require conflict resolution across arbitrary device graphs; primary/secondary gives a clear source of truth. Episodic data flows secondary → primary (accumulate experiences from all devices) while personality state flows primary → secondary (the canonical AI state is defined on the primary device). Device migration should transfer AI state so users don't cold-start on a new phone; the personality, learning history, and world model state should move with the user.

---

## Pre-Flight Checklist for Phases That Depend on Phase 7

**Before starting Phase 8 (Ecosystem Intelligence):**
- [ ] Evolution cascade (7.1.2) executes atomically on personality changes
- [ ] Agent trigger system (7.4) fires on AI2AI connection events
- [ ] World model sync step wired into `BackupSyncCoordinator` (7.3.1)
- [ ] Device tier detection works and gates world model components

**Before starting Phase 10.6 (Deferred Codebase Reorganization):**
- [ ] Orchestrator restructuring (7.1) is complete -- moving orchestrator files after restructuring avoids double work
- [ ] Quantum code consolidation (10.6.2) waits for Phase 7 because quantum orchestrators are being rewired

---

## Common Pitfalls

1. **Updating one orchestrator without the others**: If `AIMasterOrchestrator` uses energy functions but `ContinuousLearningOrchestrator` still uses formulas, the system is in a split-brain state.
2. **Forgetting `_saveLearningState()` and `_saveOrchestrationState()`**: Both are currently TODO placeholders. Without persistence, state is lost on app restart.
3. **Breaking the tier fallback chain**: If Tier 2 inference fails, the system must automatically degrade to Tier 1 behavior. Don't assume the happy path.

---

**Last Updated:** February 10, 2026 (v12 gap fill)
