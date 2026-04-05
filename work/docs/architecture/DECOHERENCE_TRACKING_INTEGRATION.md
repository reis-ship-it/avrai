# Decoherence Tracking Integration

**Status:** ✅ Complete  
**Phase:** Quantum Enhancement Implementation Plan - Phase 2.1  
**Date:** December 2024

## Overview

Decoherence tracking enables the system to understand agent behavior patterns by tracking how quantum temporal states decay over time. This provides insights into user behavior phases (exploration vs. settled) and enables adaptive recommendations.

## Purpose

**Core Goals:**
- Track how fast preferences are changing (decoherence rate)
- Measure how stable preferences are (decoherence stability)
- Identify behavior phases (exploration vs. settled)
- Analyze temporal patterns (time-of-day, weekday, season)

**Doors Opened:**
- Adaptive recommendations based on user behavior patterns
- Prediction of preference changes
- Optimization of recommendations based on behavior phase
- Understanding temporal behavior patterns

## Architecture

### Components

1. **DecoherencePattern Model** (`lib/core/models/decoherence_pattern.dart`)
   - `BehaviorPhase` enum: `exploration`, `settling`, `settled`
   - `DecoherenceTimeline`: Historical decoherence measurements
   - `TemporalPatterns`: Patterns by time-of-day, weekday, season
   - `DecoherencePattern`: Complete pattern for a user

2. **DecoherenceTrackingService** (`lib/core/services/decoherence_tracking_service.dart`)
   - Records decoherence measurements
   - Calculates decoherence rate and stability
   - Detects behavior phases
   - Analyzes temporal patterns

3. **DecoherencePatternRepository** (`lib/domain/repositories/decoherence_pattern_repository.dart`)
   - Interface for storing/retrieving patterns
   - Offline-first storage

4. **DecoherencePatternRepositoryImpl** (`lib/data/repositories/decoherence_pattern_repository_impl.dart`)
   - Implementation using local Sembast database

5. **DecoherencePatternSembastDataSource** (`lib/data/datasources/local/decoherence_pattern_sembast_datasource.dart`)
   - Local storage implementation

## Integration

### QuantumVibeEngine Integration

The `QuantumVibeEngine` now tracks decoherence when calculating quantum vibe dimensions:

```dart
// In QuantumVibeEngine._applyDecoherence()
if (_decoherenceTracking != null && userId != null) {
  _decoherenceTracking!.recordDecoherenceMeasurement(
    userId: userId,
    decoherenceFactor: decoherenceFactor,
  );
}
```

**Usage:**
```dart
// Compile vibe dimensions with decoherence tracking
final dimensions = await quantumEngine.compileVibeDimensionsQuantum(
  personality,
  behavioral,
  social,
  relationship,
  temporal,
  userId: userId, // Optional - enables tracking
);
```

### Dependency Injection

All services are registered in `lib/injection_container.dart`:

```dart
// Register Decoherence Pattern Repository
sl.registerLazySingleton<DecoherencePatternLocalDataSource>(
  () => DecoherencePatternSembastDataSource(),
);
sl.registerLazySingleton<DecoherencePatternRepository>(
  () => DecoherencePatternRepositoryImpl(
    localDataSource: sl<DecoherencePatternLocalDataSource>(),
  ),
);

// Register Decoherence Tracking Service
sl.registerLazySingleton<DecoherenceTrackingService>(
  () => DecoherenceTrackingService(
    repository: sl<DecoherencePatternRepository>(),
    atomicClock: sl<AtomicClockService>(),
  ),
);

// Update QuantumVibeEngine with tracking
sl.registerLazySingleton(() => QuantumVibeEngine(
      decoherenceTracking: sl<DecoherenceTrackingService>(),
    ));
```

## Behavior Phase Detection

**Phases:**
- **Exploration**: High decoherence rate (>0.1), low stability (<0.7)
  - User is exploring new preferences
  - Recommendations should be diverse and exploratory
- **Settling**: Moderate decoherence rate, moderate stability
  - Preferences are stabilizing
  - Recommendations should balance exploration and stability
- **Settled**: Low decoherence rate (<0.05), high stability (>0.8)
  - Stable preferences
  - Recommendations should focus on known preferences

**Detection Logic:**
```dart
BehaviorPhase _detectBehaviorPhase(
  double decoherenceRate,
  double decoherenceStability,
) {
  if (decoherenceRate > 0.1 && decoherenceStability < 0.7) {
    return BehaviorPhase.exploration;
  }
  if (decoherenceRate < 0.05 && decoherenceStability > 0.8) {
    return BehaviorPhase.settled;
  }
  return BehaviorPhase.settling;
}
```

## Temporal Pattern Analysis

Tracks decoherence patterns by:
- **Time-of-day**: morning, afternoon, evening, night
- **Weekday**: monday through sunday
- **Season**: spring, summer, fall, winter

**Usage:**
```dart
final pattern = await decoherenceTracking.getPattern(userId);
final morningDecoherence = pattern?.temporalPatterns
    .timeOfDayPatterns['morning'];
```

## Calculations

### Decoherence Rate

Formula: `rate = (decoherence_current - decoherence_previous) / time_delta`

Normalized to per-hour rate for readability.

### Decoherence Stability

Formula: `stability = 1.0 - variance(decoherence_timeline)`

Higher stability = more consistent preferences.

## Storage

**Database:** Sembast (local, offline-first)  
**Store:** `decoherence_patterns`  
**Key:** User ID

## Testing

**Unit Tests:** `test/unit/services/decoherence_tracking_service_test.dart`

**Test Coverage:**
- Recording measurements
- Calculating rates and stability
- Detecting behavior phases
- Analyzing temporal patterns
- Error handling

## Future Enhancements

**Phase 3:** Quantum Prediction Features
- Use decoherence patterns to predict future preferences
- Improve prediction accuracy to 90%

**Phase 4:** Quantum Satisfaction Enhancement
- Use decoherence patterns to optimize recommendations
- Improve user satisfaction to 85-90%

## References

- **Plan:** `docs/plans/methodology/QUANTUM_ENHANCEMENT_IMPLEMENTATION_PLAN.md`
- **Model:** `lib/core/models/decoherence_pattern.dart`
- **Service:** `lib/core/services/decoherence_tracking_service.dart`
- **Repository:** `lib/domain/repositories/decoherence_pattern_repository.dart`

