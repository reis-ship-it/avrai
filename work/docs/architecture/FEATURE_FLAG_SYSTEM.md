# Feature Flag System

**Date:** December 23, 2025  
**Status:** ✅ Complete  
**Purpose:** Gradual rollout and A/B testing for quantum enhancements

---

## Overview

The Feature Flag System enables runtime control of quantum enhancement features without requiring app rebuilds. This allows for:

- **Gradual Rollout:** Start with 5% of users, gradually increase to 100%
- **Quick Rollback:** Disable features instantly if issues arise
- **A/B Testing:** Test features with specific user groups
- **Remote Control:** Update flags from server (future enhancement)

---

## Architecture

### Core Components

1. **FeatureFlagService** (`lib/core/services/feature_flag_service.dart`)
   - Manages feature flag state
   - Supports percentage rollouts
   - Handles local overrides (for testing)
   - Stores remote config locally for offline use

2. **FeatureFlagConfig**
   - Configuration for a single feature flag
   - Includes: enabled status, rollout percentage, target users

3. **QuantumFeatureFlags**
   - Centralized definitions for all quantum enhancement flags
   - Default configurations

### Quantum Enhancement Feature Flags

- `quantum_location_entanglement` - Phase 1: Location Entanglement Integration
- `quantum_decoherence_tracking` - Phase 2: Decoherence Behavior Tracking
- `quantum_prediction_features` - Phase 3: Quantum Prediction Features
- `quantum_satisfaction_enhancement` - Phase 4: Quantum Satisfaction Enhancement

---

## Usage

### Basic Usage

```dart
final featureFlags = sl<FeatureFlagService>();

// Check if feature is enabled for a user
if (await featureFlags.isEnabled(
  QuantumFeatureFlags.locationEntanglement,
  userId: userId,
)) {
  // Use location entanglement
}
```

### Integration in Services

Services check feature flags before using quantum enhancements:

```dart
class SpotVibeMatchingService {
  final FeatureFlagService? _featureFlags;
  
  Future<double> calculateCompatibility(...) async {
    final locationEntanglementEnabled = _featureFlags != null
        ? await _featureFlags!.isEnabled(
            QuantumFeatureFlags.locationEntanglement,
            userId: user.id,
            defaultValue: false,
          )
        : false;
    
    if (locationEntanglementEnabled && userLocation != null && spotLocation != null) {
      // Use location entanglement
    } else {
      // Use standard compatibility
    }
  }
}
```

---

## Rollout Strategy

### Phase 1: Internal Testing (0-5%)
- Enable for internal/beta users
- Monitor metrics closely
- Fix any issues

### Phase 2: Small Rollout (5-25%)
- Expand to 5% of users
- Monitor for 1-2 weeks
- Check metrics: satisfaction, accuracy, performance

### Phase 3: Medium Rollout (25-50%)
- Expand to 25% if metrics are positive
- Monitor for 1 week
- Continue monitoring

### Phase 4: Large Rollout (50-100%)
- Expand to 50%, then 100%
- Monitor continuously
- Keep feature flags for quick rollback if needed

---

## Configuration

### Default Configuration

All quantum features start at **0% rollout** (disabled by default):

```dart
QuantumFeatureFlags.getDefaultConfigs()
```

### Updating Configuration

#### Local Override (for testing)

```dart
// Enable for testing
await featureFlags.setLocalOverride(
  QuantumFeatureFlags.locationEntanglement,
  true,
);

// Clear override (revert to remote/stored config)
await featureFlags.clearLocalOverride(
  QuantumFeatureFlags.locationEntanglement,
);
```

#### Remote Configuration (future)

```dart
// Update from server
await featureFlags.updateRemoteConfig({
  QuantumFeatureFlags.locationEntanglement: FeatureFlagConfig(
    enabled: true,
    rolloutPercentage: 10.0, // 10% of users
    targetUsers: ['user_1', 'user_2'], // Specific users
  ),
});
```

---

## Rollout Logic

The service uses deterministic hash-based assignment for consistent rollout:

1. **Check Remote Config** (highest priority)
2. **Check Local Override** (for testing)
3. **Check Stored Config** (from previous remote fetch)
4. **Return Default Value** (if not configured)

For percentage rollouts:
- Uses `userId.hashCode` for consistent assignment
- Same user always gets same assignment
- Percentage determines how many users are enabled

---

## Integration Points

### Services with Feature Flags

1. **SpotVibeMatchingService**
   - Checks `quantum_location_entanglement` flag
   - Uses location entanglement if enabled

2. **QuantumVibeEngine** (to be integrated)
   - Checks `quantum_decoherence_tracking` flag
   - Uses decoherence tracking if enabled

3. **QuantumPredictionEnhancer** (to be integrated)
   - Checks `quantum_prediction_features` flag
   - Uses quantum prediction features if enabled

4. **UserFeedbackAnalyzer** (to be integrated)
   - Checks `quantum_satisfaction_enhancement` flag
   - Uses quantum satisfaction enhancement if enabled

---

## Monitoring

### Metrics to Track

- **User Satisfaction:** Compare enabled vs disabled users
- **Prediction Accuracy:** Measure improvement
- **Performance:** Latency, CPU, memory usage
- **Error Rates:** Any increase in errors
- **User Engagement:** Feature usage patterns

### Rollback Criteria

Rollback if:
- User satisfaction decreases significantly
- Error rates increase
- Performance degrades
- User complaints increase

---

## Future Enhancements

1. **Remote Control:** Fetch flags from server
2. **Analytics Integration:** Track flag usage
3. **A/B Testing Framework:** Built-in A/B test support
4. **Admin UI:** Visual interface for managing flags
5. **Flag History:** Track changes over time

---

## Testing

### Unit Tests

- Feature flag evaluation logic
- Rollout percentage calculation
- Local override handling
- Config storage/retrieval

### Integration Tests

- Service integration with feature flags
- Fallback behavior when flags disabled
- Performance with flags enabled/disabled

---

**Reference:** `docs/plans/methodology/QUANTUM_ENHANCEMENT_IMPLEMENTATION_PLAN.md`

