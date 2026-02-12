// Quantum Entanglement Service Tests
//
// Tests for Phase 19 Section 19.1: N-Way Quantum Entanglement Framework
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/quantum_state_knot_service.dart';

void main() {
  group('QuantumEntanglementService', () {
    late QuantumEntanglementService service;
    late AtomicClockService atomicClock;

    setUp(() {
      atomicClock = AtomicClockService();
      service = QuantumEntanglementService(
        atomicClock: atomicClock,
        knotEngine: null, // Optional, graceful degradation
        knotCompatibilityService: null, // Optional, graceful degradation
      );
    });

    test('should create entangled state from multiple entity states', () async {
      // Initialize atomic clock
      await atomicClock.initialize();

      // Create test entity states
      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

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

      // Create entangled state
      final entangled = await service.createEntangledState(
        entityStates: [entity1, entity2],
      );

      // Verify results
      expect(entangled.entityStates.length, equals(2));
      expect(entangled.coefficients.length, equals(2));
      expect(entangled.entangledVector.length, greaterThan(0));
      expect(entangled.isNormalized, isTrue);
      expect(entangled.tAtomic, isNotNull);
    });

    test('should normalize entity states before entanglement', () async {
      await atomicClock.initialize();

      final tAtomic = await atomicClock.getAtomicTimestamp();
      final entity = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.5, 'dim2': 0.3},
        quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.4},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic,
      );

      // Entity should be normalized after normalization
      final normalized = entity.normalized();
      expect(normalized.isNormalized, isTrue);
    });

    test('should calculate fidelity between two entangled states', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

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

      final entangled1 = await service.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final entangled2 = await service.createEntangledState(
        entityStates: [entity1, entity2],
      );

      final fidelity = await service.calculateFidelity(entangled1, entangled2);
      expect(fidelity, greaterThanOrEqualTo(0.0));
      expect(fidelity, lessThanOrEqualTo(1.0));
    });

    test('should handle empty entity states with error', () async {
      await atomicClock.initialize();

      expect(
        () => service.createEntangledState(entityStates: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should use atomic timestamps for entanglement', () async {
      await atomicClock.initialize();

      final tAtomic = await atomicClock.getAtomicTimestamp();
      final entity = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic,
      );

      final entangled = await service.createEntangledState(
        entityStates: [entity],
      );

      // Verify atomic timestamp is used
      expect(entangled.tAtomic, isNotNull);
      expect(entangled.tAtomic.isSynchronized, isA<bool>());
    });

    test('should gracefully degrade when knot services unavailable', () async {
      await atomicClock.initialize();

      final tAtomic = await atomicClock.getAtomicTimestamp();
      final entity = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic,
      );

      // Service should work without knot services
      final knotBonus = await service.calculateKnotCompatibilityBonus([entity]);
      expect(knotBonus, equals(0.0)); // Graceful degradation
    });

    test('should return non-zero knot bonus when knot services available', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      final entity1 = QuantumEntityState(
        entityId: 'entity1',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.2, 'dim2': 0.8},
        quantumVibeAnalysis: {'vibe1': 0.6, 'vibe2': 0.4},
        entityCharacteristics: const {'type': 'user'},
        tAtomic: tAtomic1,
      );

      final entity2 = QuantumEntityState(
        entityId: 'entity2',
        entityType: QuantumEntityType.event,
        personalityState: {'dim1': 0.25, 'dim2': 0.75},
        quantumVibeAnalysis: {'vibe1': 0.55, 'vibe2': 0.45},
        entityCharacteristics: const {'type': 'event'},
        tAtomic: tAtomic2,
      );

      final svc = QuantumEntanglementService(
        atomicClock: atomicClock,
        knotCompatibilityService: CrossEntityCompatibilityService(),
        quantumStateKnotService: QuantumStateKnotService(),
      );

      final bonus = await svc.calculateKnotCompatibilityBonus([entity1, entity2]);
      expect(bonus, greaterThan(0.0));
      expect(bonus, lessThanOrEqualTo(1.0));
    });
  });

  group('QuantumEntityState', () {
    test('should normalize state correctly', () async {
      final atomicClock = AtomicClockService();
      await atomicClock.initialize();
      final tAtomic = await atomicClock.getAtomicTimestamp();

      final state = QuantumEntityState(
        entityId: 'test',
        entityType: QuantumEntityType.user,
        personalityState: {'dim1': 0.5, 'dim2': 0.3},
        quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.4},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic,
      );

      final normalized = state.normalized();
      expect(normalized.isNormalized, isTrue);
    });

    test('should serialize and deserialize correctly', () async {
      final atomicClock = AtomicClockService();
      await atomicClock.initialize();
      final tAtomic = await atomicClock.getAtomicTimestamp();

      final original = QuantumEntityState(
        entityId: 'test',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic,
      );

      final json = original.toJson();
      final restored = QuantumEntityState.fromJson(json);

      expect(restored.entityId, equals(original.entityId));
      expect(restored.entityType, equals(original.entityType));
    });
  });
}
