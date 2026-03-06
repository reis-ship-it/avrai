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
4. **Treating LLM inputs as trusted**: Every LLM entry point (`TupleExtractionEngine`, `AICommandProcessor`) accepts user-sourced or external content. Without `PromptSanitizationService` (3.10.1), prompt injection can break context boundaries and have the LLM execute unintended instructions. Sanitization is defense-in-depth alongside the Air Gap.

---

**Last Updated:** March 5, 2026 -- Version 1.2 (added prompt injection hardening rationale 3.10, updated pitfalls. Previous: 1.1 Zeng et al. 2026)
