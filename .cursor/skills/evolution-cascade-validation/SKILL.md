---
name: evolution-cascade-validation
description: Validates the evolution cascade executes atomically when personality changes. Use when modifying personality evolution, quantum state updates, knot calculations, or any service in the cascade chain. Ensures consistent state observations for the world model.
---

# Evolution Cascade Validation

## Core Principle

When personality evolves, ALL downstream systems must update atomically before the next state snapshot is captured. A partially updated state vector is worse than a stale one -- it's internally inconsistent.

## The Cascade Chain

```
PersonalityChange
  → QuantumVibeEngine.recompile()           // 24D quantum vibe state
  → PersonalityKnotService.recompute()       // 5-10D knot invariants
  → KnotFabricService.updateInvariants()     // 5-10D fabric invariants
  → WorldsheetEvolutionDynamics.step()       // 5D worldsheet trajectory
  → KnotEvolutionStringService.updateRates() // 5D string evolution rates
  → DecoherenceTrackingService.updatePhase() // 5D decoherence features
  → WorldModelFeatureExtractor.captureFullSnapshot() // Full state vector
```

## LeCun Alignment

The world model's perception module must produce a **single coherent state representation**. If personality evolves but quantum vibe state, knot invariants, fabric metrics, worldsheet trajectory, string evolution rates, and decoherence phase don't cascade-update, the state encoder receives an internally inconsistent observation. The energy function and transition predictor would be trained on corrupted data.

## Implementation Pattern

```dart
/// UnifiedEvolutionOrchestrator handles the cascade
Future<void> _handlePersonalityEvolution(PersonalityDelta delta) async {
  // ALL steps must complete before state snapshot
  await _quantumVibeEngine.recompile(delta);
  await _personalityKnotService.recompute(delta);
  await _knotFabricService.updateInvariants(delta);
  await _worldsheetDynamics.step(delta);
  await _knotEvolutionString.updateRates(delta);
  await _decoherenceTracking.updatePhase(delta);
  
  // Only NOW capture state snapshot for episodic memory
  final stateSnapshot = await _featureExtractor.captureFullSnapshot();
  developer.log('Evolution cascade complete', name: 'EvolutionOrchestrator');
}
```

## When This Applies

You MUST verify the cascade works when:
- Modifying `PersonalityLearning` or `ContinuousLearningSystem`
- Adding new personality dimensions or changing dimension calculations
- Modifying any service IN the cascade
- Adding new features to `WorldModelFeatureExtractor`
- Modifying `UnifiedEvolutionOrchestrator` cycle

## Current Known Issues

- `UnifiedEvolutionOrchestrator` quantum coordination method is a placeholder (log-only)
- `UnifiedEvolutionOrchestrator` AI2AI learning coordination is a placeholder
- `UnifiedEvolutionOrchestrator` continuous learning coordination is a placeholder
- Only knot evolution is properly wired (`KnotEvolutionCoordinatorService`)

## Checklist

- [ ] All 6 cascade steps execute in order
- [ ] No step is skipped or placeholder
- [ ] State snapshot captured AFTER cascade completes (not before or during)
- [ ] `AtomicClockService` timestamp on snapshot
- [ ] Error in any step prevents snapshot (no partial state)
- [ ] Cascade latency within evolution cycle budget (< 5 minutes total)

## Reference

- `docs/MASTER_PLAN.md` Phase 7.1.2 (Evolution cascade fix)
- `docs/MASTER_PLAN.md` Phase 7.4 (Dependency chain management)
- `lib/core/ai/unified_evolution_orchestrator.dart` - Current implementation
- `lib/core/ai/quantum/quantum_vibe_engine.dart` - Quantum step
- `packages/avrai_knot/` - Knot, fabric, worldsheet, string steps
