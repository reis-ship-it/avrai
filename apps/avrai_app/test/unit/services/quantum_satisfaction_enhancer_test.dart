import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_satisfaction_enhancer.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_satisfaction_feature_extractor.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai_runtime_os/ai/quantum/location_quantum_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum/quantum_satisfaction_features.dart';
import 'package:avrai_core/models/user/unified_models.dart' as unified_models;
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([QuantumSatisfactionFeatureExtractor])
import 'quantum_satisfaction_enhancer_test.mocks.dart';

void main() {
  // Test-only feature flags: always enable quantum satisfaction enhancement so we
  // exercise the quantum path (otherwise the enhancer returns baseSatisfaction).
  final alwaysOnFeatureFlags = _AlwaysOnFeatureFlagService();

  group('QuantumSatisfactionEnhancer', () {
    late MockQuantumSatisfactionFeatureExtractor mockFeatureExtractor;
    late QuantumSatisfactionEnhancer enhancer;

    setUp(() {
      mockFeatureExtractor = MockQuantumSatisfactionFeatureExtractor();
      enhancer = QuantumSatisfactionEnhancer(
        featureExtractor: mockFeatureExtractor,
        featureFlags: alwaysOnFeatureFlags,
      );
    });

    test('should enhance satisfaction with quantum features', () async {
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
      final userTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);

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

      // Mock feature extraction
      final mockFeatures = QuantumSatisfactionFeatures(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
        quantumVibeMatch: 0.75,
        entanglementCompatibility: 0.65,
        interferenceEffect: 0.5,
        decoherenceOptimization: 0.1,
        phaseAlignment: 0.8,
        locationQuantumMatch: 0.7,
        timingQuantumMatch: 0.85,
      );

      when(mockFeatureExtractor.extractFeatures(
        userId: anyNamed('userId'),
        userVibeDimensions: anyNamed('userVibeDimensions'),
        eventVibeDimensions: anyNamed('eventVibeDimensions'),
        userTemporalState: anyNamed('userTemporalState'),
        eventTemporalState: anyNamed('eventTemporalState'),
        userLocationState: anyNamed('userLocationState'),
        eventLocationState: anyNamed('eventLocationState'),
        contextMatch: anyNamed('contextMatch'),
        preferenceAlignment: anyNamed('preferenceAlignment'),
        noveltyScore: anyNamed('noveltyScore'),
      )).thenAnswer((_) async => mockFeatures);

      // Enhance satisfaction
      const baseSatisfaction = 0.5;
      final enhancedSatisfaction = await enhancer.enhanceSatisfaction(
        baseSatisfaction: baseSatisfaction,
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

      // Verify enhancement
      expect(enhancedSatisfaction, greaterThan(baseSatisfaction));
      expect(enhancedSatisfaction, greaterThanOrEqualTo(0.0));
      expect(enhancedSatisfaction, lessThanOrEqualTo(1.0));

      // Verify feature extractor was called
      verify(mockFeatureExtractor.extractFeatures(
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
      )).called(1);
    });

    test('should return base satisfaction on error', () async {
      // Mock feature extraction to throw error
      when(mockFeatureExtractor.extractFeatures(
        userId: anyNamed('userId'),
        userVibeDimensions: anyNamed('userVibeDimensions'),
        eventVibeDimensions: anyNamed('eventVibeDimensions'),
        userTemporalState: anyNamed('userTemporalState'),
        eventTemporalState: anyNamed('eventTemporalState'),
        userLocationState: anyNamed('userLocationState'),
        eventLocationState: anyNamed('eventLocationState'),
        contextMatch: anyNamed('contextMatch'),
        preferenceAlignment: anyNamed('preferenceAlignment'),
        noveltyScore: anyNamed('noveltyScore'),
      )).thenThrow(Exception('Test error'));

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);

      // Enhance satisfaction (should return base on error)
      const baseSatisfaction = 0.5;
      final enhancedSatisfaction = await enhancer.enhanceSatisfaction(
        baseSatisfaction: baseSatisfaction,
        userId: 'user_1',
        userVibeDimensions: {},
        eventVibeDimensions: {},
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        userLocationState: null,
        eventLocationState: null,
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      // Should return base satisfaction on error
      expect(enhancedSatisfaction, equals(baseSatisfaction));
    });

    test('should clamp satisfaction to valid range', () async {
      // Mock features that would result in out-of-range satisfaction
      final mockFeatures = QuantumSatisfactionFeatures(
        contextMatch: 1.0,
        preferenceAlignment: 1.0,
        noveltyScore: 1.0,
        quantumVibeMatch: 1.0,
        entanglementCompatibility: 1.0,
        interferenceEffect: 1.0,
        decoherenceOptimization: 0.5, // Large optimization
        phaseAlignment: 1.0,
        locationQuantumMatch: 1.0,
        timingQuantumMatch: 1.0,
      );

      when(mockFeatureExtractor.extractFeatures(
        userId: anyNamed('userId'),
        userVibeDimensions: anyNamed('userVibeDimensions'),
        eventVibeDimensions: anyNamed('eventVibeDimensions'),
        userTemporalState: anyNamed('userTemporalState'),
        eventTemporalState: anyNamed('eventTemporalState'),
        userLocationState: anyNamed('userLocationState'),
        eventLocationState: anyNamed('eventLocationState'),
        contextMatch: anyNamed('contextMatch'),
        preferenceAlignment: anyNamed('preferenceAlignment'),
        noveltyScore: anyNamed('noveltyScore'),
      )).thenAnswer((_) async => mockFeatures);

      final timestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final userTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);
      final eventTemporalState =
          QuantumTemporalStateGenerator.generate(timestamp);

      final enhancedSatisfaction = await enhancer.enhanceSatisfaction(
        baseSatisfaction: 0.5,
        userId: 'user_1',
        userVibeDimensions: {},
        eventVibeDimensions: {},
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        userLocationState: null,
        eventLocationState: null,
        contextMatch: 1.0,
        preferenceAlignment: 1.0,
        noveltyScore: 1.0,
      );

      // Should be clamped to [0.0, 1.0]
      expect(enhancedSatisfaction, greaterThanOrEqualTo(0.0));
      expect(enhancedSatisfaction, lessThanOrEqualTo(1.0));
    });

    test('should return feature importance map', () {
      final importance = enhancer.getFeatureImportance();

      expect(importance, isA<Map<String, double>>());
      expect(importance['contextMatch'], equals(0.25));
      expect(importance['preferenceAlignment'], equals(0.25));
      expect(importance['noveltyScore'], equals(0.15));
      expect(importance['quantumVibeMatch'], equals(0.15));
      expect(importance['entanglementCompatibility'], equals(0.10));
      expect(importance['interferenceEffect'], equals(0.05));
      expect(importance['locationQuantumMatch'], equals(0.03));
      expect(importance['timingQuantumMatch'], equals(0.02));
    });
  });
}

final class _AlwaysOnFeatureFlagService extends FeatureFlagService {
  _AlwaysOnFeatureFlagService() : super(storage: StorageService.instance);

  @override
  Future<bool> isEnabled(
    String featureName, {
    String? userId,
    bool defaultValue = false,
  }) async {
    return true;
  }
}
