---
name: lecun-framework-compliance
description: Validates that new features and services align with LeCun's world model framework. Use when creating new services, adding features, reviewing architecture decisions, or questioning whether a component fits the intelligence-first architecture.
---

# LeCun Framework Compliance

## Core Principle

Every component in the system maps to a specific role in LeCun's autonomous machine intelligence architecture. If a proposed change doesn't fit this framework, it doesn't belong.

## Framework Mapping

| LeCun Component | Role | Our Implementation | Phase |
|----------------|------|-------------------|-------|
| **Perception Module** | Observes the world, produces state | `WorldModelFeatureExtractor` (105-115D) + `FeatureFreshnessTracker` | 3.1 |
| **World Model** | Predicts next state given state + action | `TransitionPredictor` (ONNX MLP) | 5.1 |
| **Cost Module (Critic)** | Evaluates state-action pair quality | `EnergyFunctionService` (ONNX critic) | 4.1 |
| **Actor** | Proposes action sequences to minimize cost | `MPCPlanner` (N-step simulation) | 6.1 |
| **Guardrail Module** | Hard constraints actor cannot violate | Diversity, safety, doors, notification constraints | 6.2 |
| **Short-Term Memory** | Recent observations and predictions | `EpisodicMemoryStore` (state, action, outcome tuples) | 1.1 |
| **Configurator** | Adjusts modules based on context | `DeferredInitializationService` + `FeatureFlagService` | 3.5, 7.3 |
| **Latent Variable** | Represents future uncertainty | Variance head + multi-future z-vector sampling | 5.3 |

## Compliance Questions

Before creating or modifying any service, answer these:

### 1. Does this create a new scoring formula?
- **If yes:** STOP. Use the energy function instead (Phase 4).
- **If it's a new feature that needs scoring:** Wire it as input features to the state/action encoder, let the energy function learn the scoring.

### 2. Does this produce data the world model should learn from?
- **If yes:** Wire an episodic tuple via `UnifiedOutcomeCollector`.
- Actions without outcomes are invisible to the world model.

### 3. Does this change user state?
- **If yes:** Ensure the evolution cascade triggers (Phase 7.1.2).
- Personality changes must propagate through quantum → knot → fabric → worldsheet → string → decoherence.

### 4. Does this add a new action type?
- **If yes:** Add to the action taxonomy (Phase 3.3.1), define entity features (Phase 3.3.2-3.3.7), and ensure episodic tuples are captured.

### 5. Does this use the mesh network?
- **If yes:** Use `AnonymousCommunicationProtocol` (not `AdvancedAICommunication`).
- Define the `MessageType` (Phase 3.6.2).

### 6. Does this access user data?
- **If yes:** Check GDPR consent (Phase 2.1), ensure data is never shared raw (Phase 2.2), and verify privacy notes (Phase 3.1).

## Key LeCun Principles

1. **Energy-based, not probabilistic**: Learn energy functions (low = good), not probability distributions.
2. **JEPA over generative**: Learn abstract representations, not reconstructions.
3. **Hierarchical planning**: Short plans are concrete, long plans are abstract.
4. **Self-supervised**: Learn from episodic memory, not labeled datasets.
5. **Consistent observation**: Evolution cascade ensures atomic state consistency.

## Anti-Patterns (NEVER Do These)

```dart
// ❌ BAD: New hardcoded formula
final score = 0.4 * vibeScore + 0.3 * locationScore + 0.3 * timingScore;

// ✅ GOOD: Use energy function
final energy = await energyFunction.energy(userStateEmbed, actionEmbed);
```

```dart
// ❌ BAD: Action without outcome tracking
await userService.joinCommunity(communityId);

// ✅ GOOD: Capture episodic tuple
final stateBefore = await featureExtractor.extractFeatures(agentId);
await userService.joinCommunity(communityId);
final stateAfter = await featureExtractor.extractFeatures(agentId);
await episodicMemory.store(EpisodicTuple(...));
```

```dart
// ❌ BAD: Sharing raw data over mesh
await advancedAICommunication.sendEncryptedMessage(personalityData, 'ai_network');

// ✅ GOOD: Share anonymized gradients via unified mesh
await anonymousComm.sendEncryptedMessage(
  dpProtectedGradient,
  MessageType.gradient,
);
```

## Checklist

- [ ] No new hardcoded scoring formulas
- [ ] New actions have episodic memory integration
- [ ] State changes trigger evolution cascade
- [ ] New action types added to taxonomy
- [ ] Mesh communication uses `AnonymousCommunicationProtocol`
- [ ] User data access checked for GDPR consent
- [ ] Latency budgets respected
- [ ] Feature freshness tracked

## Reference

- `docs/MASTER_PLAN.md` (Philosophy + Methodology section, LeCun Framework Mapping)
- `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
