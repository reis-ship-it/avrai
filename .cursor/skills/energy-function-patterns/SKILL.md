---
name: energy-function-patterns
description: Guides energy function (critic network) implementation and formula replacement protocol. Use when replacing hardcoded formulas, implementing energy-based scoring, creating A/B tests between formulas and learned functions, or working on Phase 4 tasks.
---

# Energy Function Patterns

## Core Principle

The energy function replaces ALL hardcoded scoring formulas. It takes `(state_embedding, action_embedding) → scalar energy` where low energy = good match. This is LeCun's "cost module" (critic).

## Energy Function Architecture

```dart
/// Energy function: Concat(StateEmbed, ActionEmbed) → MLP(128→64→32→1) → Energy
class EnergyFunctionService {
  final OrtSession _criticModel;
  
  /// Score a (user, entity) pair. Lower energy = better match.
  Future<double> energy(
    List<double> stateEmbedding,  // 32-64D from state encoder
    List<double> actionEmbedding, // 32-64D from action encoder
  ) async {
    final combined = [...stateEmbedding, ...actionEmbedding];
    final input = OrtValueTensor.createTensorWithDataList(combined);
    final output = await _criticModel.run([input]);
    return output.first.value as double;
  }
}
```

## Formula Replacement Protocol (MANDATORY)

Every formula replacement follows this exact sequence:

### Step 1: Parallel Run
```dart
// Log both outputs, don't change behavior yet
final formulaScore = existingFormula.calculate(user, entity);
final energyScore = energyFunction.energy(userEmbed, entityEmbed);
developer.log(
  'Formula=$formulaScore Energy=$energyScore',
  name: 'FormulaComparison',
);
```

### Step 2: Collect Comparison Data (N days)
- Track: do formula-preferred and energy-preferred recommendations lead to different outcomes?
- Use `FormulaABTestingService` (generalized from `CallingScoreABTestingService`)

### Step 3: Flip When Energy Matches or Beats Formula
```dart
// Feature flag controls which path is active
if (featureFlagService.isEnabled('energy_function_${formulaName}')) {
  return energyFunction.energy(userEmbed, entityEmbed);
} else {
  return existingFormula.calculate(user, entity);
}
```

### Step 4: Keep Formula as Fallback (M weeks)
- Per-user rollback if outcomes worsen
- Monitor transition metrics

### Step 5: Remove Formula Code
- Only after M weeks with no rollbacks needed

## Bidirectional Energy (Community Actions)

For group actions, evaluate from BOTH perspectives:

```dart
/// Bidirectional energy for join_community
Future<double> bidirectionalEnergy({
  required List<double> userState,
  required List<double> communityState,
  required List<double> actionEmbed,
  double alpha = 0.6, // Learned per action type
}) async {
  final userEnergy = await energy(userState, actionEmbed);
  final communityEnergy = await energy(communityState, actionEmbed);
  return alpha * userEnergy + (1 - alpha) * communityEnergy;
}
```

## Contrastive Training

The most valuable training signal: recommended A, user chose B.

```dart
/// Record contrastive tuple when user rejects recommendation
void recordContrastive({
  required StateFeatureVector state,
  required String recommendedAction,
  required String actualAction,
  required double outcome,
}) {
  episodicMemory.store(EpisodicTuple(
    state: state,
    recommendedAction: recommendedAction,
    actualAction: actualAction,
    outcome: outcome,
    timestamp: atomicClock.now(),
    isContrastive: true,
  ));
}
```

## Checklist

- [ ] Parallel run implemented (both formula and energy logged)
- [ ] Feature flag created via `FeatureFlagService`
- [ ] `FormulaABTestingService` configured for this formula
- [ ] Comparison data collection active
- [ ] Per-user rollback implemented
- [ ] Transition metrics monitored
- [ ] No new hardcoded formulas introduced
- [ ] Contrastive signals captured for rejected recommendations

## Reference

- `docs/MASTER_PLAN.md` Phase 4 (Energy Function & Formula Replacement)
- `docs/MASTER_PLAN.md` Phase 4.2 (Formula Replacement Schedule - 26 formulas)
- `lib/core/services/calling_score_calculator.dart` - Template (first formula to replace)
- `lib/core/services/calling_score_data_collector.dart` - Outcome collection template
- `lib/core/services/calling_score_ab_testing_service.dart` - A/B testing template
