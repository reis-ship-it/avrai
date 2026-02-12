import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/quantum/quantum_feature_extractor.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/quantum/decoherence_pattern.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/services/quantum/decoherence_tracking_service.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuantumFeatureExtractor', () {
    late QuantumFeatureExtractor extractor;
    late MockDecoherenceTrackingService mockDecoherenceTracking;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      mockDecoherenceTracking = MockDecoherenceTrackingService();
      extractor = QuantumFeatureExtractor(
        decoherenceTracking: mockDecoherenceTracking,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should extract quantum features with all components', () async {
      // Arrange
      const userId = 'test_user_1';
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

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
      );

      // Assert
      expect(features.temporalCompatibility, equals(0.7));
      expect(features.weekdayMatch, equals(0.8));
      expect(features.quantumVibeMatch.length, equals(12));
      expect(features.temporalQuantumMatch, greaterThan(0.0));
      expect(features.coherenceLevel, greaterThan(0.0));
    });

    test('should calculate interference strength correctly', () async {
      // Arrange
      const userId = 'test_user_2';
      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };
      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      // Identical vibes should have high interference
      expect(features.interferenceStrength, greaterThan(0.0));
      expect(features.interferenceStrength, lessThanOrEqualTo(1.0));
    });

    test('should calculate entanglement strength correctly', () async {
      // Arrange
      const userId = 'test_user_3';
      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };
      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      expect(features.entanglementStrength, greaterThanOrEqualTo(0.0));
      expect(features.entanglementStrength, lessThanOrEqualTo(1.0));
    });

    test('should calculate phase alignment correctly', () async {
      // Arrange
      const userId = 'test_user_4';
      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };
      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      // Phase alignment should be in [-1, 1] range
      expect(features.phaseAlignment, greaterThanOrEqualTo(-1.0));
      expect(features.phaseAlignment, lessThanOrEqualTo(1.0));
    });

    test('should extract quantum vibe match for all 12 dimensions', () async {
      // Arrange
      const userId = 'test_user_5';
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

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      expect(features.quantumVibeMatch.length, equals(12));
      // Compatibility should be high (1.0 - |0.7 - 0.8| = 0.9)
      expect(features.quantumVibeMatch[0], closeTo(0.9, 0.1));
    });

    test('should calculate preference drift correctly', () async {
      // Arrange
      const userId = 'test_user_6';
      final currentVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.8
      };
      final previousVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.7
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: currentVibeDimensions,
        eventVibeDimensions: currentVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: previousVibeDimensions,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      // Preference drift should be > 0 (preferences changed)
      expect(features.preferenceDrift, greaterThanOrEqualTo(0.0));
      expect(features.preferenceDrift, lessThanOrEqualTo(1.0));
    });

    test('should handle missing decoherence pattern gracefully', () async {
      // Arrange
      const userId = 'test_user_7';
      mockDecoherenceTracking.patterns[userId] = null; // No pattern

      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };
      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.5,
        weekdayMatch: 0.5,
      );

      // Assert
      // Should use default values when pattern is missing
      expect(features.decoherenceRate, equals(0.0));
      expect(features.decoherenceStability, equals(1.0));
    });

    test('should handle errors gracefully and return minimal features', () async {
      // Arrange
      const userId = 'test_user_error';
      mockDecoherenceTracking.shouldThrow = true;

      final userVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };
      final eventVibeDimensions = {
        for (final dim in VibeConstants.coreDimensions) dim: 0.5
      };

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState = QuantumTemporalStateGenerator.generate(timestamp);

      // Act
      final features = await extractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        previousVibeDimensions: null,
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
      );

      // Assert
      // Should return minimal features on error
      expect(features.temporalCompatibility, equals(0.7));
      expect(features.weekdayMatch, equals(0.8));
      expect(features.decoherenceRate, equals(0.0));
      expect(features.decoherenceStability, equals(1.0));
    });
  });
}

/// Mock decoherence tracking service for testing
class MockDecoherenceTrackingService implements DecoherenceTrackingService {
  final Map<String, DecoherencePattern?> patterns = {};
  bool shouldThrow = false;

  @override
  Future<void> recordDecoherenceMeasurement({
    required String userId,
    required double decoherenceFactor,
  }) async {
    if (shouldThrow) {
      throw Exception('Test error');
    }
  }

  @override
  Future<DecoherencePattern?> getPattern(String userId) async {
    if (shouldThrow) {
      throw Exception('Test error');
    }
    return patterns[userId];
  }

  @override
  Future<BehaviorPhase?> getBehaviorPhase(String userId) async {
    if (shouldThrow) {
      throw Exception('Test error');
    }
    final pattern = patterns[userId];
    return pattern?.behaviorPhase;
  }
}

