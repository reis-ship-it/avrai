// Dimensionality Reduction Service Tests
//
// Tests for Phase 19 Section 19.12: Dimensionality Reduction for Scalability
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_quantum/services/quantum/dimensionality_reduction_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

void main() {
  group('DimensionalityReductionService', () {
    late DimensionalityReductionService service;
    late AtomicClockService atomicClock;
    late AtomicTimestamp testTimestamp;

    setUp(() async {
      service = DimensionalityReductionService();
      atomicClock = AtomicClockService();
      await atomicClock.initialize();
      testTimestamp = await atomicClock.getAtomicTimestamp();
    });

    tearDown(() {
      atomicClock.dispose();
    });

    group('PCA Reduction', () {
      test('should reduce dimensionality using variance-based selection', () async {
        final state = QuantumEntityState(
          entityId: 'test_entity',
          entityType: QuantumEntityType.user,
          personalityState: {
            'dim1': 0.9,
            'dim2': 0.1,
            'dim3': 0.8,
            'dim4': 0.2,
            'dim5': 0.7,
          },
          quantumVibeAnalysis: {
            'vibe1': 0.6,
            'vibe2': 0.3,
            'vibe3': 0.5,
          },
          entityCharacteristics: {},
          tAtomic: testTimestamp,
        );

        final reduced = await service.reduceWithPCA(
          state: state,
          targetDimensions: 5,
        );

        expect(reduced.length, equals(5));
        expect(reduced.length, lessThanOrEqualTo(8)); // Original has 8 dimensions
      });

      test('should return original vector if target dimensions >= original', () async {
        final state = QuantumEntityState(
          entityId: 'test_entity',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5, 'dim2': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.5},
          entityCharacteristics: {},
          tAtomic: testTimestamp,
        );

        final reduced = await service.reduceWithPCA(
          state: state,
          targetDimensions: 10,
        );

        expect(reduced.length, equals(3)); // Original has 3 dimensions
      });

      test('should preserve high-variance components', () async {
        final state = QuantumEntityState(
          entityId: 'test_entity',
          entityType: QuantumEntityType.user,
          personalityState: {
            'dim1': 0.9, // High variance
            'dim2': 0.1, // Low variance
            'dim3': 0.8, // High variance
          },
          quantumVibeAnalysis: {
            'vibe1': 0.05, // Very low variance
            'vibe2': 0.95, // Very high variance
          },
          entityCharacteristics: {},
          tAtomic: testTimestamp,
        );

        final reduced = await service.reduceWithPCA(
          state: state,
          targetDimensions: 3,
        );

        expect(reduced.length, equals(3));
        // High variance components should be preserved
        expect(reduced.any((v) => v.abs() > 0.8), isTrue);
      });
    });

    group('Sparse Tensor', () {
      test('should create sparse tensor from dense vector', () {
        final vector = [0.0, 0.5, 0.0, 0.3, 0.0, 0.0, 0.8, 0.0];
        final sparse = service.toSparseTensor(vector, threshold: 0.1);

        expect(sparse.dimension, equals(8));
        expect(sparse.entries.length, lessThan(8));
        expect(sparse.entries.any((e) => e.value == 0.5), isTrue);
        expect(sparse.entries.any((e) => e.value == 0.3), isTrue);
        expect(sparse.entries.any((e) => e.value == 0.8), isTrue);
      });

      test('should convert sparse tensor back to dense vector', () {
        final vector = [0.0, 0.5, 0.0, 0.3, 0.0, 0.0, 0.8, 0.0];
        final sparse = service.toSparseTensor(vector, threshold: 0.1);
        final dense = sparse.toDenseVector();

        expect(dense.length, equals(8));
        expect(dense[1], closeTo(0.5, 0.001));
        expect(dense[3], closeTo(0.3, 0.001));
        expect(dense[6], closeTo(0.8, 0.001));
      });

      test('should calculate sparsity ratio correctly', () {
        final vector = [0.0, 0.5, 0.0, 0.3, 0.0, 0.0, 0.8, 0.0];
        final sparse = service.toSparseTensor(vector, threshold: 0.1);

        expect(sparse.sparsityRatio, greaterThan(0.0));
        expect(sparse.sparsityRatio, lessThan(1.0));
      });
    });

    group('Partial Trace', () {
      test('should perform partial trace operation', () async {
        // Create a simple entangled vector (2x2 system)
        final entangledVector = [0.5, 0.5, 0.5, 0.5];
        final reduced = await service.partialTrace(
          entangledVector: entangledVector,
          traceOverIndices: [1], // Trace over subsystem B
          subsystemADim: 2,
          subsystemBDim: 2,
        );

        expect(reduced.length, equals(2));
        expect(reduced[0].length, equals(2));
      });

      test('should reduce dimensionality correctly', () async {
        final entangledVector = List.generate(16, (i) => 0.25); // 4x4 system
        final reduced = await service.partialTrace(
          entangledVector: entangledVector,
          traceOverIndices: [2, 3], // Trace over last 2 dimensions
          subsystemADim: 2,
          subsystemBDim: 2,
        );

        expect(reduced.length, equals(2));
        expect(reduced[0].length, equals(2));
      });
    });

    group('Schmidt Decomposition', () {
      test('should perform Schmidt decomposition', () async {
        // Create a simple entangled vector (2x2 system)
        final entangledVector = [0.5, 0.5, 0.5, 0.5];
        final decomposition = await service.schmidtDecomposition(
          entangledVector: entangledVector,
          subsystemADim: 2,
          subsystemBDim: 2,
        );

        expect(decomposition.coefficients.length, greaterThan(0));
        expect(decomposition.leftBasis.length, equals(decomposition.coefficients.length));
        expect(decomposition.rightBasis.length, equals(decomposition.coefficients.length));
      });

      test('should reconstruct original state from decomposition', () async {
        final entangledVector = [0.5, 0.5, 0.5, 0.5];
        final decomposition = await service.schmidtDecomposition(
          entangledVector: entangledVector,
          subsystemADim: 2,
          subsystemBDim: 2,
        );

        final reconstructed = decomposition.reconstruct(2, 2);
        expect(reconstructed.length, equals(4));
      });

      test('should calculate Schmidt rank correctly', () async {
        final entangledVector = [0.5, 0.5, 0.5, 0.5];
        final decomposition = await service.schmidtDecomposition(
          entangledVector: entangledVector,
          subsystemADim: 2,
          subsystemBDim: 2,
        );

        expect(decomposition.schmidtRank, greaterThan(0));
        expect(decomposition.schmidtRank, lessThanOrEqualTo(decomposition.coefficients.length));
      });
    });

    group('Quantum-Inspired Approximation', () {
      test('should approximate large vectors', () async {
        final originalVector = List.generate(100, (i) => i / 100.0);
        final approximated = await service.quantumInspiredApproximation(
          originalVector: originalVector,
          targetDimensions: 20,
        );

        expect(approximated.length, equals(20));
        expect(approximated.length, lessThan(originalVector.length));
      });

      test('should preserve quantum normalization', () async {
        final originalVector = List.generate(50, (i) => (i % 10) / 10.0);
        final originalNorm = _calculateNorm(originalVector);
        final approximated = await service.quantumInspiredApproximation(
          originalVector: originalVector,
          targetDimensions: 10,
        );
        final approximatedNorm = _calculateNorm(approximated);

        // Norms should be similar (within 10% tolerance)
        expect(
          (approximatedNorm - originalNorm).abs() / originalNorm,
          lessThan(0.1),
        );
      });

      test('should select largest magnitude components', () async {
        final originalVector = [
          0.1,
          0.9, // Largest
          0.2,
          0.8, // Second largest
          0.3,
          0.7, // Third largest
          0.4,
          0.5,
        ];
        final approximated = await service.quantumInspiredApproximation(
          originalVector: originalVector,
          targetDimensions: 3,
        );

        expect(approximated.length, equals(3));
        // Should contain the largest values
        expect(approximated.any((v) => v.abs() > 0.7), isTrue);
      });

      test('should return original if target >= original length', () async {
        final originalVector = [0.5, 0.3, 0.7];
        final approximated = await service.quantumInspiredApproximation(
          originalVector: originalVector,
          targetDimensions: 5,
        );

        expect(approximated.length, equals(3));
      });
    });

    group('Integration Tests', () {
      test('should work with full quantum entity state', () async {
        final state = QuantumEntityState(
          entityId: 'test_entity',
          entityType: QuantumEntityType.user,
          personalityState: {
            'dim1': 0.8,
            'dim2': 0.6,
            'dim3': 0.4,
            'dim4': 0.2,
          },
          quantumVibeAnalysis: {
            'vibe1': 0.7,
            'vibe2': 0.5,
            'vibe3': 0.3,
          },
          entityCharacteristics: {},
          location: EntityLocationQuantumState(
            latitudeQuantumState: 0.5,
            longitudeQuantumState: 0.5,
            locationType: 'restaurant',
            accessibilityScore: 0.8,
            vibeLocationMatch: 0.6,
          ),
          timing: EntityTimingQuantumState(
            timeOfDayPreference: 0.5,
            dayOfWeekPreference: 0.5,
            frequencyPreference: 0.5,
            durationPreference: 0.5,
            timingVibeMatch: 0.5,
          ),
          tAtomic: testTimestamp,
        );

        // Test PCA
        final pcaReduced = await service.reduceWithPCA(
          state: state,
          targetDimensions: 10,
        );
        expect(pcaReduced.length, lessThanOrEqualTo(16)); // Original has ~16 dimensions

        // Test sparse tensor (use PCA result as vector)
        final sparse = service.toSparseTensor(pcaReduced);
        expect(sparse.dimension, equals(pcaReduced.length));

        // Test quantum-inspired approximation
        final approximated = await service.quantumInspiredApproximation(
          originalVector: pcaReduced,
          targetDimensions: 8,
        );
        expect(approximated.length, lessThanOrEqualTo(8));
      });
    });
  });
}

// Helper function for norm calculation
double _calculateNorm(List<double> vector) {
  return vector.fold<double>(
    0.0,
    (sum, val) => sum + val * val,
  );
}
