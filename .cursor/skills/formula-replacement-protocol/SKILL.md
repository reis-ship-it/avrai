---
name: formula-replacement-protocol
description: Enforces the 5-step formula replacement protocol for replacing hardcoded scoring formulas with learned energy functions. Use when working on any formula in the Phase 4.2 replacement schedule, implementing A/B tests, or transitioning from formula to energy function scoring.
---

# Formula Replacement Protocol

## Core Principle

Every hardcoded formula is replaced following the same 5-step protocol. No exceptions. No shortcuts. The protocol protects users from bad model transitions and provides rollback safety.

## The 30+ Formulas

See `docs/MASTER_PLAN.md` Phase 4.2 for the complete prioritized list. Key ones:

| Priority | Service | Formula | Current Weights |
|----------|---------|---------|-----------------|
| 4.2.1 | `CallingScoreCalculator` | Calling Score | 40/30/15/10/5 |
| 4.2.2 | `VibeCompatibilityService` | Combined compatibility | 50/30/20 |
| 4.2.5 | `GroupMatchingService` | Group core + modifiers | geometric mean + 40/30/20/10 |
| 4.2.9 | `BusinessExpertMatchingService` | Expert matching | 50/30/20 |
| 4.2.12 | `DiscoveryManager` | AI2AI discovery priority | 40/30/20/10 |

## 5-Step Protocol

### Step 1: Parallel Run (No behavior change)
```dart
/// Run BOTH, log comparison, keep formula as primary
Future<double> score(User user, Entity entity) async {
  final formulaScore = _existingFormula(user, entity);
  
  // Energy function runs in parallel but doesn't affect output
  final energyScore = await _energyFunction.energy(
    await _stateEncoder.encode(user),
    await _actionEncoder.encode(entity),
  );
  
  // Log for comparison analysis
  _comparisonLogger.log(
    formula: formulaScore,
    energy: energyScore,
    userId: user.agentId,
    entityId: entity.id,
    timestamp: _atomicClock.now(),
  );
  
  return formulaScore; // Formula still primary
}
```

### Step 2: Collect Comparison Data (N days, minimum 7)
- Use `FormulaABTestingService` to track both paths
- Track: does energy-preferred differ from formula-preferred?
- Track: which path leads to better outcomes?
- Minimum data: 100 comparisons with outcome data

### Step 3: Flip via Feature Flag
```dart
/// Feature flag controls the switch
Future<double> score(User user, Entity entity) async {
  if (_featureFlags.isEnabled('energy_${_formulaName}')) {
    return await _energyFunction.energy(userEmbed, actionEmbed);
  }
  return _existingFormula(user, entity);
}
```

### Step 4: Monitor + Per-User Rollback (M weeks, minimum 4)
```dart
/// If outcomes worsen for a specific user, revert them
void monitorTransition(String userId, List<Outcome> recentOutcomes) {
  final preFlipAvg = _getPreFlipOutcomeAverage(userId);
  final postFlipAvg = _average(recentOutcomes);
  
  if (postFlipAvg < preFlipAvg * 0.8) { // 20% worse
    developer.log('Rolling back $userId', name: 'FormulaTransition');
    _userOverrides[userId] = FormulaOverride.useFormula;
  }
}
```

### Step 5: Remove Formula Code
- Only after M weeks with no rollbacks
- Remove the formula method
- Remove the feature flag
- Keep the comparison logging for regression detection

## Transition UX

During Step 1-2 (blending period):
```dart
/// Blend formula and energy scores during transition
final blendedScore = alpha * formulaScore + (1 - alpha) * energyScore;
// alpha starts at 1.0, decreases to 0.0 over transition period
```

Show "Personalized for you" badge once energy function has sufficient data.

## Checklist

- [ ] Formula identified in Phase 4.2 schedule
- [ ] Step 1: Parallel run implemented with comparison logging
- [ ] Step 2: `FormulaABTestingService` configured, collecting data
- [ ] Step 3: Feature flag created in `FeatureFlagService`
- [ ] Step 4: Per-user rollback monitoring active
- [ ] Step 5: Formula code removed only after M weeks clean
- [ ] Transition metrics tracked (diversity change, outcome rate, retention)
- [ ] Surprise detection: flag if energy recommendations differ dramatically

## Reference

- `docs/MASTER_PLAN.md` Phase 4.2 (Formula Replacement Schedule)
- `docs/MASTER_PLAN.md` Phase 4.5 (Transition Period UX)
- `lib/core/services/calling_score_calculator.dart` - First formula to replace
- `lib/core/services/calling_score_ab_testing_service.dart` - A/B testing template
- `lib/core/services/calling_score_data_collector.dart` - Data collection template
