---
name: world-model-development
description: Guides world model development patterns: state/action encoders, ONNX inference, feature extraction pipeline, latency budgets. Use when implementing world model components, state encoders, action encoders, feature extractors, or ONNX models. Core skill for Phases 3-6.
---

# World Model Development Patterns

## Core Principle

All world model components follow LeCun's autonomous machine intelligence framework. State observations flow through a perception module (feature extractor → state encoder), actions flow through an action encoder, and both feed into the energy function (critic) and transition predictor (world model).

## State Feature Vector (105-115D)

Every user's state is represented as a feature vector assembled from 15+ services:

```dart
/// WorldModelFeatureExtractor assembles the full state vector
class WorldModelFeatureExtractor {
  Future<StateFeatureVector> extractFeatures(String agentId) async {
    return StateFeatureVector(
      quantumVibe: await _quantumVibeEngine.getVibeState(agentId),          // 24D
      knotInvariants: await _personalityKnotService.getInvariants(agentId), // 5-10D
      fabricInvariants: await _knotFabricService.getInvariants(agentId),    // 5-10D
      decoherence: await _decoherenceService.getFeatures(agentId),          // 5D
      worldsheet: await _worldsheetAnalytics.getTrajectory(agentId),        // 5D
      localityVector: await _localityAgent.getVibeVector(agentId),          // 12D
      temporal: _atomicClock.getTemporalFeatures(),                         // 5D
      stringEvolution: await _knotEvolutionString.getRates(agentId),        // 5D
      entanglement: await _entanglementML.getCompressed(agentId),           // 10D
      wearable: await _wearableService.getFeatures(agentId),                // 3D (optional)
      crossApp: await _crossAppService.getFeatures(agentId),                // 3D (optional)
      behavioral: await _behaviorAssessment.getTrajectory(agentId),         // 5D
      languageProfile: await _languagePattern.getFeatures(agentId),         // 4D
      signalTrust: await _signalProtocol.getSessionStats(agentId),          // 3D
      chatActivity: await _chatMetrics.getFeatures(agentId),                // 3D
      timestamps: FeatureTimestamps.now(_atomicClock),                      // per-feature freshness
    );
  }
}
```

## Feature Freshness

Every feature carries a freshness weight. Stale features decay in influence:

```dart
/// Feature freshness tolerances
const featureStaleness = {
  'temporal': Duration(seconds: 1),
  'personality': Duration(seconds: 5),
  'knotFabric': Duration(minutes: 5),
  'wearable': Duration(hours: 1),
  'crossApp': Duration(days: 1),
  'languageProfile': Duration(hours: 1),
  'signalTrust': Duration(days: 1),
};

/// Freshness weight: 1.0 = fresh, decays toward 0.0
double freshnessWeight(DateTime lastUpdated, Duration tolerance) {
  final age = DateTime.now().difference(lastUpdated);
  if (age <= tolerance) return 1.0;
  // Exponential decay after tolerance exceeded
  return exp(-age.inSeconds / (tolerance.inSeconds * 2));
}
```

## ONNX Model Pattern

All neural network components use ONNX for on-device inference:

```dart
/// Standard ONNX inference pattern
class OnnxModelService {
  OrtSession? _session;
  
  Future<void> initialize() async {
    final modelBytes = await rootBundle.load('assets/models/state_encoder.onnx');
    _session = await OrtSession.create(modelBytes.buffer.asUint8List());
  }
  
  /// Graceful degradation: if model not loaded, fall back to raw features
  Future<List<double>> encode(List<double> features) async {
    if (_session == null) return features; // Fallback
    
    final input = OrtValueTensor.createTensorWithDataList(features);
    final outputs = await _session!.run([input]);
    return outputs.first.value as List<double>;
  }
}
```

## Latency Budgets (MANDATORY)

| Component | Budget | Measurement |
|-----------|--------|-------------|
| Feature extraction | < 50ms | `PerformanceMonitorService` |
| State encoder (ONNX) | < 20ms | `PerformanceMonitorService` |
| Action encoder (ONNX) | < 15ms | `PerformanceMonitorService` |
| Energy function (ONNX) | < 10ms | `PerformanceMonitorService` |
| Full scoring (50 candidates) | < 200ms | `PerformanceMonitorService` |
| MPC planning (3-step) | < 500ms | `PerformanceMonitorService` |
| All ONNX models combined | < 20MB | Build-time check |

> **Rule:** If any budget is exceeded, optimize before shipping. Never trade UX for model sophistication.

## Checklist

- [ ] Feature extractor collects ALL 15 feature groups
- [ ] Feature freshness weights applied
- [ ] ONNX models have fallback paths (graceful degradation)
- [ ] Latency budgets measured and enforced
- [ ] Registered in `injection_container.dart`
- [ ] Wired into `DeferredInitializationService` for warm-up
- [ ] No hardcoded scoring formulas created
- [ ] Episodic memory written for new actions

## Reference

- `docs/MASTER_PLAN.md` Phase 3 (State & Action Encoders)
- `docs/MASTER_PLAN.md` Phase 4 (Energy Function)
- `docs/MASTER_PLAN.md` Phase 5 (Transition Predictor)
- `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
- `lib/core/ml/inference_orchestrator.dart` - Existing ONNX inference path
