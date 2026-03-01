# Patent Integration Quick Start Checklist

**Date:** January 3, 2026  
**Purpose:** Day 1 execution checklist for patent integration  
**Reference:** `COMPREHENSIVE_PATENT_INTEGRATION_PLAN.md`

---

## 🚀 Day 1: Foundation Verification

### Pre-Flight Checks

```bash
# 1. Verify build compiles
flutter build ios --debug --no-codesign
flutter build apk --debug

# 2. Run core patent test suite
flutter test test/unit/services/quantum_entanglement_service_test.dart
flutter test test/unit/ai2ai/connection_orchestrator_test.dart

# 3. Verify Rust FFI compiles (knot theory)
cd packages/spots_knot && cargo build --release
```

### Foundation Services Verification

#### ✅ Atomic Clock (Patent #30)
```bash
# Test atomic clock sync
flutter test test/unit/services/atomic_clock_service_test.dart
```

**Manual Check:**
- [ ] `AtomicClockService.syncWithServer()` completes without error
- [ ] Atomic timestamps have nanosecond precision
- [ ] RTT estimation produces reasonable values

#### ✅ Quantum Compatibility (Patent #1)
```bash
# Test quantum calculations
flutter test test/unit/services/quantum_entanglement_service_test.dart
```

**Manual Check:**
- [ ] `calculateFidelity()` returns value in [0, 1]
- [ ] Inner product formula matches |⟨ψ_A|ψ_B⟩|²
- [ ] Bures distance metric is symmetric

#### ✅ 12-Dimensional Personality (Patent #5)
**Manual Check:**
- [ ] `VibeConstants.coreDimensions` has 12 entries
- [ ] All dimensions have [0, 1] range
- [ ] Dimension weights sum to 1.0

---

## 📋 Priority 1 Gaps (Days 2-5)

### Gap B.1: Drift Resistance (Patent #3)

**File:** `lib/core/ai/personality_learning.dart`

**Add at top of class:**
```dart
/// Maximum drift allowed from core personality (30%)
static const double maxDriftFromCore = 0.30;
```

**Add method:**
```dart
/// Check if proposed changes exceed drift limit
bool _exceedsDriftLimit(List<double> proposed, List<double> core) {
  for (var i = 0; i < proposed.length; i++) {
    final drift = (proposed[i] - core[i]).abs();
    if (drift > maxDriftFromCore) return true;
  }
  return false;
}

/// Clamp changes to stay within drift limit
List<double> _clampToDriftLimit(List<double> proposed, List<double> core) {
  return List.generate(proposed.length, (i) {
    final drift = proposed[i] - core[i];
    if (drift.abs() > maxDriftFromCore) {
      return core[i] + (drift.sign * maxDriftFromCore);
    }
    return proposed[i];
  });
}
```

**Modify `_applyLearning()`** to call `_clampToDriftLimit()`

---

### Gap B.2: Check-In Atomic Timing (Patent #14)

**File:** `lib/core/services/automatic_check_in_service.dart`

**Add dependency:**
```dart
final AtomicClockService _atomicClock;
```

**Replace:**
```dart
// OLD
final timestamp = DateTime.now();

// NEW
final atomicTs = await _atomicClock.getAtomicTimestamp();
final timestamp = atomicTs.serverTime;
```

---

### Gap B.4: RealTimeRecommendationEngine (Patent #8)

**File:** `lib/core/ml/real_time_recommendations.dart`

**Replace stub with:**
```dart
Future<List<Recommendation>> getRealTimeRecommendations({
  required String userId,
  required UnifiedLocationData location,
  int limit = 10,
}) async {
  // 1. Get user's current vibe
  final userVibe = await _vibeService.getLatestVibe(userId);
  
  // 2. Get nearby spots within 5km
  final nearbySpots = await _spotService.getSpotsNear(
    location.latitude,
    location.longitude,
    radiusKm: 5.0,
  );
  
  // 3. Calculate compatibility for each
  final scored = <Recommendation>[];
  for (final spot in nearbySpots) {
    final compatibility = await _vibeCompatibilityService
        .calculateCompatibility(userVibe, spot.vibe);
    scored.add(Recommendation(
      spot: spot,
      score: compatibility,
      source: RecommendationSource.realtime,
    ));
  }
  
  // 4. Sort by score and return top N
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).toList();
}
```

---

## 🔍 Validation Commands

### Full Test Suite
```bash
# Run all unit tests
flutter test

# Run specific patent-related suites
flutter test test/unit/services/
flutter test test/unit/ai2ai/
flutter test test/unit/ml/
```

### Device Testing
```bash
# iOS Simulator
flutter run -d "iPhone 15 Pro"

# Android Emulator
flutter run -d emulator-5554

# Physical devices
flutter run -d <device-id>
```

### Integration Tests
```bash
# BLE signal suite (simulated)
./test/suites/ble_signal_suite.sh

# Knot FFI (requires device)
flutter drive --driver=integration_test_driver/driver.dart \
  --target=integration_test/knot_ffi_integration_test.dart
```

---

## 📊 Progress Tracking

### Phase A: Foundation Verification
- [ ] Atomic Clock verified
- [ ] Quantum Compatibility verified
- [ ] 12-Dimensional verified
- [ ] Build passes on iOS
- [ ] Build passes on Android

### Phase B: Critical Gaps
- [ ] B.1: Drift resistance implemented
- [ ] B.2: Check-in atomic timing
- [ ] B.3: Federated priors stabilized
- [ ] B.4: RealTime engine implemented
- [ ] B.5: Location consensus

### Phase C-H: See full plan
Refer to `COMPREHENSIVE_PATENT_INTEGRATION_PLAN.md` for complete checklist.

---

## 🆘 Common Issues

### Rust FFI Not Found
```bash
cd native/knot_math
cargo build --release
cd ../.. && flutter clean && flutter pub get
```

### Atomic Clock Sync Fails
Check network connectivity and Supabase function deployment:
```bash
supabase functions deploy atomic-timing-orchestrator
```

### ONNX Model Not Loading
Verify assets are included in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/onnx/
```

---

**Next Step:** Start with `flutter test` to verify baseline passing tests.
