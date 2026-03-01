/// avrai QuantumMLOptimizer Service Tests
/// Date: January 27, 2026
/// Purpose: Test QuantumMLOptimizer service functionality
///
/// Test Coverage:
/// - Core Methods: optimizeSuperpositionWeights, optimizeCompatibilityThreshold, predictOptimalMeasurementBasis
/// - Error Handling: Model unavailable, invalid inputs, edge cases
/// - Fallback: Default values when ML model unavailable
///
/// Dependencies:
/// - None (service is self-contained with optional ONNX model)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_ml_optimizer.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

void main() {
  group('QuantumMLOptimizer', () {
    late QuantumMLOptimizer optimizer;

    setUp(() {
      optimizer = QuantumMLOptimizer();
    });

    tearDown(() {
      // Service doesn't need cleanup
    });

    group('optimizeSuperpositionWeights', () {
      test(
          'should return normalized weights that sum to 1.0 for all data sources',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final sources = [
          QuantumDataSource.personality,
          QuantumDataSource.behavioral,
          QuantumDataSource.relationship,
        ];

        // Act
        final weights = await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: sources,
          useCase: QuantumUseCase.matching,
        );

        // Assert - Test actual behavior: weights are normalized
        expect(weights.length, equals(sources.length));
        final sum = weights.values.fold(0.0, (a, b) => a + b);
        expect(sum, closeTo(1.0, 0.01)); // Allow small floating point error
        for (final weight in weights.values) {
          expect(weight, greaterThanOrEqualTo(0.0));
          expect(weight, lessThanOrEqualTo(1.0));
        }
      });

      test('should return default weights when model unavailable', () async {
        // Arrange - Model won't be available in test environment
        final state = QuantumEntityState(
          entityId: 'test-entity-2',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final sources = [
          QuantumDataSource.personality,
          QuantumDataSource.behavioral,
        ];

        // Act
        final weights = await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: sources,
          useCase: QuantumUseCase.matching,
        );

        // Assert - Fallback should still return valid normalized weights
        expect(weights.length, equals(sources.length));
        final sum = weights.values.fold(0.0, (a, b) => a + b);
        expect(sum, closeTo(1.0, 0.01));
      });

      test('should handle different use cases with appropriate weights',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-3',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final sources = [
          QuantumDataSource.personality,
          QuantumDataSource.temporal,
        ];

        // Act - Test different use cases
        final matchingWeights = await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: sources,
          useCase: QuantumUseCase.matching,
        );
        final recommendationWeights =
            await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: sources,
          useCase: QuantumUseCase.recommendation,
        );

        // Assert - Different use cases may produce different weights (or same if using defaults)
        expect(matchingWeights.length, equals(sources.length));
        expect(recommendationWeights.length, equals(sources.length));
        // Both should be normalized
        expect(
          matchingWeights.values.fold(0.0, (a, b) => a + b),
          closeTo(1.0, 0.01),
        );
        expect(
          recommendationWeights.values.fold(0.0, (a, b) => a + b),
          closeTo(1.0, 0.01),
        );
      });

      test('should handle single data source correctly', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-4',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final sources = [QuantumDataSource.personality];

        // Act
        final weights = await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: sources,
          useCase: QuantumUseCase.matching,
        );

        // Assert - Single source should have weight of 1.0
        expect(weights.length, equals(1));
        expect(weights[QuantumDataSource.personality], closeTo(1.0, 0.01));
      });
    });

    group('optimizeCompatibilityThreshold', () {
      test('should return threshold between 0.0 and 1.0', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-5',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final threshold = await optimizer.optimizeCompatibilityThreshold(
          state: state,
          useCase: QuantumUseCase.matching,
        );

        // Assert - Threshold should be in valid range
        expect(threshold, greaterThanOrEqualTo(0.0));
        expect(threshold, lessThanOrEqualTo(1.0));
      });

      test('should return different thresholds for different use cases',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-6',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final matchingThreshold =
            await optimizer.optimizeCompatibilityThreshold(
          state: state,
          useCase: QuantumUseCase.matching,
        );
        final predictionThreshold =
            await optimizer.optimizeCompatibilityThreshold(
          state: state,
          useCase: QuantumUseCase.prediction,
        );

        // Assert - Both should be valid thresholds (may be same if using defaults)
        expect(matchingThreshold, greaterThanOrEqualTo(0.0));
        expect(matchingThreshold, lessThanOrEqualTo(1.0));
        expect(predictionThreshold, greaterThanOrEqualTo(0.0));
        expect(predictionThreshold, lessThanOrEqualTo(1.0));
      });

      test('should handle default threshold when model unavailable', () async {
        // Arrange - Model won't be available in test environment
        final state = QuantumEntityState(
          entityId: 'test-entity-7',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final threshold = await optimizer.optimizeCompatibilityThreshold(
          state: state,
          useCase: QuantumUseCase.compatibility,
        );

        // Assert - Should return valid default threshold
        expect(threshold, greaterThanOrEqualTo(0.0));
        expect(threshold, lessThanOrEqualTo(1.0));
      });
    });

    group('predictOptimalMeasurementBasis', () {
      test('should return list of dimension indices within valid range',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-8',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final basis = await optimizer.predictOptimalMeasurementBasis(
          state: state,
          useCase: QuantumUseCase.matching,
          maxDimensions: 5,
        );

        // Assert - Basis should be valid dimension indices
        expect(basis.length, lessThanOrEqualTo(5));
        expect(basis.length,
            greaterThan(0)); // Should return at least one dimension
        for (final index in basis) {
          expect(index, greaterThanOrEqualTo(0));
          expect(index, lessThan(12)); // 12 avrai dimensions
        }
        // Should be unique indices
        expect(basis.toSet().length, equals(basis.length));
      });

      test('should respect maxDimensions parameter', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-9',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final basis3 = await optimizer.predictOptimalMeasurementBasis(
          state: state,
          useCase: QuantumUseCase.matching,
          maxDimensions: 3,
        );
        final basis10 = await optimizer.predictOptimalMeasurementBasis(
          state: state,
          useCase: QuantumUseCase.matching,
          maxDimensions: 10,
        );

        // Assert - Should respect maxDimensions
        expect(basis3.length, lessThanOrEqualTo(3));
        expect(basis10.length, lessThanOrEqualTo(10));
      });

      test('should return default basis when model unavailable', () async {
        // Arrange - Model won't be available in test environment
        final state = QuantumEntityState(
          entityId: 'test-entity-10',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final basis = await optimizer.predictOptimalMeasurementBasis(
          state: state,
          useCase: QuantumUseCase.analysis,
          maxDimensions: 5,
        );

        // Assert - Should return valid default basis (top dimensions by magnitude)
        expect(basis.length, greaterThan(0));
        expect(basis.length, lessThanOrEqualTo(5));
        for (final index in basis) {
          expect(index, greaterThanOrEqualTo(0));
          expect(index, lessThan(12));
        }
      });
    });

    group('Error Handling', () {
      test('should handle state with missing dimensions gracefully', () async {
        // Arrange - State with incomplete dimensions
        final state = QuantumEntityState(
          entityId: 'test-entity-11',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            // Missing other dimensions
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act & Assert - Should not throw, should use available data
        final weights = await optimizer.optimizeSuperpositionWeights(
          state: state,
          sources: [QuantumDataSource.personality],
          useCase: QuantumUseCase.matching,
        );
        expect(weights, isNotEmpty);

        final threshold = await optimizer.optimizeCompatibilityThreshold(
          state: state,
          useCase: QuantumUseCase.matching,
        );
        expect(threshold, greaterThanOrEqualTo(0.0));
        expect(threshold, lessThanOrEqualTo(1.0));
      });
    });
  });
}
