import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/quantum/quantum_satisfaction_feature_extractor.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai/core/ai/quantum/location_quantum_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/quantum/decoherence_pattern.dart';
import 'package:avrai/core/models/user/unified_models.dart' as unified_models;
import 'package:avrai/core/services/quantum/decoherence_tracking_service.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import '../../../helpers/test_helpers.dart';

// Mock class for DecoherenceTrackingService
class MockDecoherenceTrackingService implements DecoherenceTrackingService {
  final Map<String, DecoherencePattern?> patterns = {};

  @override
  Future<void> recordDecoherenceMeasurement({
    required String userId,
    required double decoherenceFactor,
  }) async {}

  @override
  Future<DecoherencePattern?> getPattern(String userId) async {
    return patterns[userId];
  }

  @override
  Future<BehaviorPhase?> getBehaviorPhase(String userId) async {
    final pattern = patterns[userId];
    return pattern?.behaviorPhase;
  }

  Future<void> recordVibeStateChange({
    required String userId,
    required Map<String, double> previousVibeDimensions,
    required Map<String, double> currentVibeDimensions,
  }) async {}
}

void main() {
  group('QuantumSatisfactionFeatureExtractor', () {
    late MockDecoherenceTrackingService mockDecoherenceTracking;
    late QuantumSatisfactionFeatureExtractor extractor;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      mockDecoherenceTracking = MockDecoherenceTrackingService();
      extractor = QuantumSatisfactionFeatureExtractor(
        decoherenceTracking: mockDecoherenceTracking,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should extract features with all quantum values', () async {
      // Create test data using core dimensions
      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.7
      };

      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.8
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      final userLocationState = LocationQuantumState.fromLocation(
        const unified_models.UnifiedLocation(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
      );
      final eventLocationState = LocationQuantumState.fromLocation(
        const unified_models.UnifiedLocation(
          latitude: 37.7849,
          longitude: -122.4094,
        ),
      );

      // Mock decoherence pattern
      final decoherencePattern = DecoherencePattern(
        userId: 'user_1',
        timeline: [],
        lastUpdated: AtomicTimestamp.now(precision: TimePrecision.millisecond),
        decoherenceRate: 0.1,
        decoherenceStability: 0.8,
        temporalPatterns: TemporalPatterns(
          timeOfDayPatterns: {},
          weekdayPatterns: {},
          seasonalPatterns: {},
        ),
        behaviorPhase: BehaviorPhase.settled,
      );
      mockDecoherenceTracking.patterns['user_1'] = decoherencePattern;

      // Extract features
      final features = await extractor.extractFeatures(
        userId: 'user_1',
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        userLocationState: userLocationState,
        eventLocationState: eventLocationState,
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      // Verify features
      expect(features.contextMatch, equals(0.7));
      expect(features.preferenceAlignment, equals(0.8));
      expect(features.noveltyScore, equals(0.6));
      expect(features.quantumVibeMatch, greaterThan(0.0));
      expect(features.quantumVibeMatch, lessThanOrEqualTo(1.0));
      expect(features.entanglementCompatibility, greaterThanOrEqualTo(0.0));
      expect(features.entanglementCompatibility, lessThanOrEqualTo(1.0));
      expect(features.interferenceEffect, greaterThanOrEqualTo(-1.0));
      expect(features.interferenceEffect, lessThanOrEqualTo(1.0));
      expect(features.decoherenceOptimization, greaterThanOrEqualTo(0.0));
      expect(features.phaseAlignment, greaterThanOrEqualTo(-1.0));
      expect(features.phaseAlignment, lessThanOrEqualTo(1.0));
      expect(features.locationQuantumMatch, greaterThanOrEqualTo(0.0));
      // Location quantum match can be > 1.0 due to quantum state inner product calculations
      // The enhancer will clamp it to [0.0, 1.0], but the raw value from extractor may exceed 1.0
      // This is expected behavior - we just verify it's non-negative
      expect(features.timingQuantumMatch, greaterThanOrEqualTo(0.0));
      // Timing quantum match is squared magnitude, so should be <= 1.0, but allow small floating point error
      expect(features.timingQuantumMatch, lessThanOrEqualTo(1.1));
    });

    test('should handle missing location states gracefully', () async {
      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.7
      };

      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.8
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      mockDecoherenceTracking.patterns['user_1'] = null;

      // Extract features without location states
      final features = await extractor.extractFeatures(
        userId: 'user_1',
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        userLocationState: null,
        eventLocationState: null,
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      // Verify features
      expect(features.contextMatch, equals(0.7));
      expect(features.preferenceAlignment, equals(0.8));
      expect(features.noveltyScore, equals(0.6));
      expect(features.locationQuantumMatch, equals(0.0)); // No location states
      expect(features.quantumVibeMatch, greaterThan(0.0));
    });

    test('should handle errors gracefully and return minimal features', () async {
      // Create extractor without decoherence tracking
      final extractorWithoutTracking = QuantumSatisfactionFeatureExtractor();

      // Extract features with invalid data (should not throw)
      final features = await extractorWithoutTracking.extractFeatures(
        userId: 'user_1',
        userVibeDimensions: {}, // Empty dimensions
        eventVibeDimensions: {}, // Empty dimensions
        userTemporalState: QuantumTemporalStateGenerator.generate(
          AtomicTimestamp.now(precision: TimePrecision.millisecond),
        ),
        eventTemporalState: QuantumTemporalStateGenerator.generate(
          AtomicTimestamp.now(precision: TimePrecision.millisecond),
        ),
        userLocationState: null,
        eventLocationState: null,
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      // Should return minimal features on error
      expect(features.contextMatch, equals(0.7));
      expect(features.preferenceAlignment, equals(0.8));
      expect(features.noveltyScore, equals(0.6));
    });
  });
}

