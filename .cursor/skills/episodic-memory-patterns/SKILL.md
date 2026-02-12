---
name: episodic-memory-patterns
description: Guides episodic memory implementation: (state, action, next_state, outcome) tuple storage, outcome collection, memory pruning. Use when implementing outcome tracking, writing episodic tuples, wiring new user actions to outcome collection, or working on Phase 1 tasks.
---

# Episodic Memory Patterns

## Core Principle

Every user action must produce an episodic tuple: `(state_before, action, state_after, outcome)`. This is the training data for the entire world model. No episodic data = no learning.

## Episodic Tuple Structure

```dart
/// Core episodic memory tuple
class EpisodicTuple {
  final StateFeatureVector stateBefore;    // Full 105-115D state snapshot
  final String actionType;                  // From action taxonomy
  final Map<String, dynamic> actionEntity;  // Entity features
  final StateFeatureVector stateAfter;      // State after action
  final OutcomeSignal outcome;              // What happened
  final AtomicTimestamp timestamp;          // From AtomicClockService
  final bool isContrastive;                // Was this a rejected recommendation?
  final String? recommendedAction;          // What was recommended (if contrastive)
}

/// Outcome signal types
enum OutcomeType {
  binary,      // did/didn't (attended event, joined community)
  quality,     // 1-5 rating (post-event feedback)
  behavioral,  // personality shift magnitude
  temporal,    // returned within N days
}
```

## Writing Episodic Tuples

Every new user action must be wired:

```dart
/// Pattern: Wire an action to episodic memory
Future<void> handleUserAction(String agentId, Action action) async {
  // 1. Capture state BEFORE action
  final stateBefore = await featureExtractor.extractFeatures(agentId);
  
  // 2. Execute the action
  final result = await executeAction(action);
  
  // 3. Capture state AFTER action (may be immediate or delayed)
  final stateAfter = await featureExtractor.extractFeatures(agentId);
  
  // 4. Record outcome
  final outcome = OutcomeSignal(
    type: OutcomeType.binary,
    value: result.success ? 1.0 : 0.0,
  );
  
  // 5. Store episodic tuple
  await episodicMemory.store(EpisodicTuple(
    stateBefore: stateBefore,
    actionType: action.type,
    actionEntity: action.entityFeatures,
    stateAfter: stateAfter,
    outcome: outcome,
    timestamp: atomicClock.now(),
    isContrastive: false,
  ));
}
```

## Action Taxonomy

All actions must use the defined taxonomy:

```
visit_spot, attend_event, join_community, connect_ai2ai,
save_list, create_reservation, message_friend, message_community,
ask_agent, host_event, consult_expert
```

## Outcome Collection Points

| Action | Outcome Source | Timing |
|--------|--------------|--------|
| attend_event | `ReservationCheckInService` confirmation | Immediate |
| attend_event | `PostEventFeedbackService` rating | Next app open |
| join_community | Return visits within 7 days | Delayed |
| visit_spot | Dwell time, return visits | Session end |
| connect_ai2ai | Connection quality, learning value | Session end |
| save_list | Did user act on saved items? | 24-48 hours |
| message_friend | Chat led to real-world meeting? | 7 days |
| create_reservation | Did user show up? | Event time |

## Memory Pruning

```dart
/// Keep last N episodes per action type, compress old episodes
Future<void> pruneMemory() async {
  for (final actionType in ActionTaxonomy.all) {
    final episodes = await episodicMemory.getByType(actionType);
    if (episodes.length > maxPerType) {
      // Keep most recent
      final toKeep = episodes.sublist(0, maxPerType);
      // Compress old into summary statistics
      final summary = _compressSummary(episodes.sublist(maxPerType));
      await episodicMemory.replaceWithSummary(actionType, toKeep, summary);
    }
  }
}
```

## Checklist

- [ ] Action uses defined taxonomy (not ad-hoc strings)
- [ ] State captured BEFORE action (via `WorldModelFeatureExtractor`)
- [ ] State captured AFTER action
- [ ] Outcome signal defined with appropriate `OutcomeType`
- [ ] Tuple stored via `EpisodicMemoryStore`
- [ ] `AtomicClockService` used for timestamps
- [ ] Memory pruning configured for this action type
- [ ] Contrastive tuples captured when recommendations are rejected

## Reference

- `docs/MASTER_PLAN.md` Phase 1 (Outcome Data & Episodic Memory)
- `lib/core/services/calling_score_data_collector.dart` - Outcome collection template
- `lib/core/ai/continuous_learning_system.dart` - Wire point for `processUserInteraction`
