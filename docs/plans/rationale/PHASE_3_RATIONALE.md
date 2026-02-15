# Phase 3 Rationale: World Model State & Action Encoders + List Quantum Entity

**Phase:** 3 | **Tier:** 1 (Core intelligence) | **Duration:** 5-6 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 3  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #2, #6, #9, #13)

---

## Why This Phase Exists

The world model needs to understand two things: "where is the user right now?" (state) and "what could the user do?" (actions). Phase 3 builds the perception module -- the eyes of the world model.

Without state/action encoders, the energy function (Phase 4) has no input and the transition predictor (Phase 5) has nothing to predict from.

**External validation (Zeng et al., arXiv:2602.01630, Feb 2026):** The Zeng paper's Interaction module calls for "generalized perception, enabling the understanding and processing of multimodal inputs to form a unified representation of the world state." AVRAI's `WorldModelFeatureExtractor` -- fusing 145-155D from 19+ services (quantum vibe, knot invariants, fabric metrics, temporal patterns, behavioral signals, location intelligence) into a single `StateFeatureVector` -- is the social/personality analog of this. Where Zeng's framework unifies text, images, video, audio, and 3D point clouds for physical world understanding, AVRAI unifies personality dynamics, community health, spatiotemporal context, and behavioral trajectories for social world understanding. The paper further requires "generalized operation" -- parsing diverse task instructions including natural language commands and low-level control signals. AVRAI's action encoder (Phase 3.3) with 18+ action types (visit_spot, attend_event, join_community, create_list, connect_ai2ai, etc.) fills this role in the social domain. Both frameworks agree: the perception module must produce structured, unified input for all downstream reasoning.

---

## Key Design Decisions

### Why 145-155D State Vector (Not Simpler)
The existing system already extracts rich features from 19+ services: quantum vibe (24D), knot invariants (5-10D), fabric metrics (5-10D), decoherence (5D), worldsheet (5D), locality (12D), etc. These features capture aspects of personality that no other recommendation system has.

A simpler 12D personality vector would throw away all of this. The 145-155D vector preserves every feature source and lets the state encoder learn which ones matter (Foundational Decision #9).

### Why Feature Freshness Tracking (3.1A)
Features update at different rates: temporal features change every second, personality dimensions change every few interactions, cross-app data updates daily. If the state encoder treats a 24-hour-old cross-app feature the same as a 1-second-old temporal feature, it's using stale data as if it were current.

Freshness weights (1.0 = fresh, decays toward 0.0) let the model learn to rely less on stale features without treating them as wrong.

### Why Lists as Full Quantum Entities (3.4)
See Foundational Decision #13. The short version: a list is a compressed preference manifold. Adding `QuantumEntityType.list` means lists can participate in the same matching, evolution, and prediction systems as users and spots.

**Integration risk**: Adding `list` to `QuantumEntityType` changes every `switch` statement on that enum. A codebase-wide search for `QuantumEntityType` switch statements is required.

### Why Mesh Communication Unification (3.7)
Two competing mesh pathways (`AdvancedAICommunication` and `AnonymousCommunicationProtocol`) means the world model gets information from two channels with different reliability. LeCun's framework assumes a single coherent perception module. Unifying the mesh ensures one channel, one reliability model.

### Why Latency Budgets Are Defined Here (3.6)
The world model runs on-device. If feature extraction takes 200ms and the energy function takes another 100ms, the app is visibly slow. Defining latency budgets NOW (feature extraction < 50ms, state encoder < 20ms, energy function < 10ms) prevents building components that are technically correct but too slow to use.

---

## Pre-Flight Checklist for Phases That Depend on Phase 3

**Before starting Phase 4 (Energy Function):**
- [ ] `WorldModelFeatureExtractor` produces `StateFeatureVector` from all 19+ services
- [ ] State encoder ONNX model produces embeddings from feature vectors
- [ ] Action encoder handles all 18 action types with entity features
- [ ] Feature freshness tracking is active
- [ ] Latency budgets are being tracked (even if not all met yet)

**Before starting Phase 5 (Transition Predictor):**
- [ ] State encoder produces consistent embeddings (VICReg training prevents collapse)
- [ ] State snapshots are being captured in episodic memory (full 145-155D, not just 12D personality)
- [ ] List quantum states exist if list actions are in the training data

---

## Common Pitfalls

1. **Building the state encoder without freshness weights**: The model will treat stale features as current, producing subtly wrong predictions that are hard to debug.
2. **Forgetting the evolution cascade (7.1.2 dependency)**: Phase 3 defines what the state encoder reads; Phase 7.1.2 ensures it reads a CONSISTENT state. If quantum vibe updates but knot invariants don't cascade-update, the state is internally inconsistent.
3. **Hardcoding feature dimensions**: Use the `StateFeatureVector` model, not raw arrays. When new features are added later, the vector extends cleanly.

---

## Additional Design Rationale

### Why Weather, App Usage, Friend Network & Cross-App Features (3.1.20A-3.1.20D)

**The problem:** Four data streams are collected but never reach the state encoder:
1. **Weather** -- `ContinuousLearningSystem` has weather data but the 145D→156D state vector had no weather slot. Weather affects where users want to go (outdoor spots on sunny days, indoor on rainy).
2. **App usage** -- `UsagePatternTracker` and `AppUsageService` collect session data but the MPC planner doesn't know HOW the user uses the app (frequent short sessions vs. rare long ones).
3. **Friend network** -- Friend count, braided knot compatibility, and friend-driven activity rate are available from `SocialSignalProvider` but not in the state vector.
4. **Cross-app** -- `CrossAppLearningInsightService` records insights but nothing extracts numeric features for the 3D slot reserved in Phase 3.1.11.

**Why these are all additive (not replacements):** These features add 14D to the state vector (3D weather + 4D app usage + 4D friend network + 3D cross-app extraction). Default weight is 0.0 until validated by the self-optimization engine (Phase 7.9) or manually enabled. This means they can't hurt -- they only help if they correlate with happiness.

---

**Last Updated:** February 11, 2026 -- Version 1.1 (added Zeng et al. 2026 external validation for unified perception. Previous: 1.0)
