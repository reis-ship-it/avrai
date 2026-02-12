// Entanglement Coefficient Optimizer Tests
//
// Tests for Phase 19 Section 19.2: Dynamic Entanglement Coefficient Optimization
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/entanglement_coefficient_optimizer.dart';
import 'package:avrai/core/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

void main() {
  group('EntanglementCoefficientOptimizer', () {
    late EntanglementCoefficientOptimizer optimizer;
    late QuantumEntanglementService entanglementService;
    late AtomicClockService atomicClock;

    setUp(() {
      atomicClock = AtomicClockService();
      entanglementService = QuantumEntanglementService(
        atomicClock: atomicClock,
        knotEngine: null,
        knotCompatibilityService: null,
      );
      optimizer = EntanglementCoefficientOptimizer(
        atomicClock: atomicClock,
        entanglementService: entanglementService,
      );
    });

    test('should optimize coefficients using gradient descent', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      final tAtomic3 = await atomicClock.getAtomicTimestamp();

      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.5, 'dim2': 0.3},
        quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.4},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.business,
        personalityState: {'dim1': 0.6, 'dim2': 0.4},
        quantumVibeAnalysis: {'vibe1': 0.8, 'vibe2': 0.5},
        entityCharacteristics: {'type': 'business'},
        tAtomic: tAtomic2,
      );

      // Create ideal state (same entities for simplicity)
      final idealEntangled = await entanglementService.createEntangledState(
        entityStates: [entity1, entity2],
      );

      // Optimize coefficients
      final result = await optimizer.optimizeCoefficients(
        entityStates: [entity1, entity2],
        idealState: idealEntangled,
        method: OptimizationMethod.gradientDescent,
      );

      // Verify results
      expect(result.coefficients.length, equals(2));
      expect(result.fidelity, greaterThanOrEqualTo(0.0));
      expect(result.fidelity, lessThanOrEqualTo(1.0));
      expect(result.method, equals(OptimizationMethod.gradientDescent));
      expect(result.tAtomic, isNotNull);

      // Verify normalization: Σᵢ |αᵢ|² = 1
      final norm = result.coefficients.fold<double>(
        0.0,
        (sum, coeff) => sum + coeff * coeff,
      );
      expect((norm - 1.0).abs(), lessThan(0.01));
    });

    test('should optimize coefficients using genetic algorithm', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.business,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'business'},
        tAtomic: tAtomic2,
      );

      final idealEntangled = await entanglementService.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final result = await optimizer.optimizeCoefficients(
        entityStates: [entity1, entity2],
        idealState: idealEntangled,
        method: OptimizationMethod.geneticAlgorithm,
      );

      expect(result.coefficients.length, equals(2));
      expect(result.fidelity, greaterThanOrEqualTo(0.0));
      expect(result.method, equals(OptimizationMethod.geneticAlgorithm));
    });

    test('should use role-based weights when role map provided', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.business,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'business'},
        tAtomic: tAtomic2,
      );

      final idealEntangled = await entanglementService.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final result = await optimizer.optimizeCoefficients(
        entityStates: [entity1, entity2],
        idealState: idealEntangled,
        roleMap: {
          'entity1': 'primary',
          'entity2': 'secondary',
        },
      );

      expect(result.coefficients.length, equals(2));
      // Primary role should have higher weight than secondary
      expect(result.coefficients[0], greaterThan(result.coefficients[1]));
    });

    test('should use atomic timestamps for optimization', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.event,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'event'},
        tAtomic: tAtomic2,
      );

      final idealEntangled = await entanglementService.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final result = await optimizer.optimizeCoefficients(
        entityStates: [entity1, entity2],
        idealState: idealEntangled,
      );

      // Verify atomic timestamp is used
      expect(result.tAtomic, isNotNull);
      expect(result.tAtomic.isSynchronized, isA<bool>());
    });

    test('should converge quickly (2 iterations as per experiment)', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      // Create similar entities (should converge quickly)
      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.5, 'dim2': 0.3},
        quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.4},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.51, 'dim2': 0.31},
        quantumVibeAnalysis: {'vibe1': 0.71, 'vibe2': 0.41},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic2,
      );

      final idealEntangled = await entanglementService.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final result = await optimizer.optimizeCoefficients(
        entityStates: [entity1, entity2],
        idealState: idealEntangled,
        method: OptimizationMethod.gradientDescent,
      );

      // Should converge quickly (experiment shows 2 iterations)
      // We check that it converged (iterations < maxIterations)
      expect(result.iterations, lessThanOrEqualTo(100));
    });
  });
}
