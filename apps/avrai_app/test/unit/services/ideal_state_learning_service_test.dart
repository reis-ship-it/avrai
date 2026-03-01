// Ideal State Learning Service Tests
//
// Tests for Phase 19 Section 19.10: Ideal State Learning System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/quantum/ideal_state_learning_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_outcome_learning_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'ideal_state_learning_service_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  QuantumEntanglementService,
  QuantumOutcomeLearningService,
])
void main() {
  group('IdealStateLearningService', () {
    late IdealStateLearningService service;
    late MockAtomicClockService mockAtomicClock;
    late MockQuantumEntanglementService mockEntanglementService;
    late MockQuantumOutcomeLearningService mockOutcomeLearningService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockEntanglementService = MockQuantumEntanglementService();
      mockOutcomeLearningService = MockQuantumOutcomeLearningService();

      service = IdealStateLearningService(
        atomicClock: mockAtomicClock,
        entanglementService: mockEntanglementService,
        outcomeLearningService: mockOutcomeLearningService,
      );
    });

    group('getIdealState', () {
      test('should return heuristic ideal state when no historical data',
          () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        // Act
        final result = await service.getIdealState(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event, QuantumEntityType.user},
        );

        // Assert
        expect(result, isNotNull);
        expect(result.idealState, isNotEmpty);
        expect(result.matchCount, equals(0));
        expect(result.averageSuccessScore, equals(0.5));
        expect(result.entityTypes, contains(QuantumEntityType.event));
        expect(result.entityTypes, contains(QuantumEntityType.user));
        expect(result.category, equals('tour:Coffee'));
      });

      test('should return existing ideal state if found', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Test Event',
          description: 'Test Description',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: UnifiedUser(
            id: 'host-1',
            displayName: 'Host',
            email: 'host@test.com',
            createdAt: now,
            updatedAt: now,
          ),
          startTime: now,
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final entities = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.5, 'dim2': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.8},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        // Learn from match first
        await service.learnFromSuccessfulMatch(
          eventId: 'event-1',
          event: event,
          entities: entities,
          successScore: 0.8,
          learningRate: 0.05,
        );

        // Act
        final result = await service.getIdealState(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event},
        );

        // Assert
        expect(result, isNotNull);
        expect(result.matchCount, greaterThan(0));
        expect(result.averageSuccessScore, greaterThan(0.0));
      });
    });

    group('learnFromSuccessfulMatch', () {
      test('should learn from successful match and update ideal state',
          () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Test Event',
          description: 'Test Description',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: UnifiedUser(
            id: 'host-1',
            displayName: 'Host',
            email: 'host@test.com',
            createdAt: now,
            updatedAt: now,
          ),
          startTime: now,
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final entities = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.5, 'dim2': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.8},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        // Act
        await service.learnFromSuccessfulMatch(
          eventId: 'event-1',
          event: event,
          entities: entities,
          successScore: 0.8,
          learningRate: 0.05,
        );

        // Assert - verify ideal state was created/updated
        final idealState = await service.getIdealState(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event},
        );
        expect(idealState.matchCount, equals(1));
        expect(idealState.averageSuccessScore, equals(0.8));
      });

      test('should update existing ideal state with learning rate', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Test Event',
          description: 'Test Description',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: UnifiedUser(
            id: 'host-1',
            displayName: 'Host',
            email: 'host@test.com',
            createdAt: now,
            updatedAt: now,
          ),
          startTime: now,
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final entities1 = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.5, 'dim2': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.8},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        final entities2 = [
          QuantumEntityState(
            entityId: 'entity-2',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6, 'dim2': 0.7},
            quantumVibeAnalysis: {'vibe1': 0.8, 'vibe2': 0.9},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        // Learn from first match
        await service.learnFromSuccessfulMatch(
          eventId: 'event-1',
          event: event,
          entities: entities1,
          successScore: 0.8,
          learningRate: 0.05,
        );

        // Learn from second match
        await service.learnFromSuccessfulMatch(
          eventId: 'event-2',
          event: event,
          entities: entities2,
          successScore: 0.9,
          learningRate: 0.05,
        );

        // Assert
        final idealState = await service.getIdealState(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event},
        );
        expect(idealState.matchCount, equals(2));
        expect(idealState.averageSuccessScore, closeTo(0.85, 0.01));
      });
    });

    group('calculateIdealStateFromHistory', () {
      test('should calculate ideal state from historical matches', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final historicalMatches = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.5, 'dim2': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.8},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
          QuantumEntityState(
            entityId: 'entity-2',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6, 'dim2': 0.7},
            quantumVibeAnalysis: {'vibe1': 0.8, 'vibe2': 0.9},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        final successScores = [0.8, 0.9];
        final timestamps = [tAtomic, tAtomic];

        // Act
        final result = await service.calculateIdealStateFromHistory(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event},
          historicalMatches: historicalMatches,
          successScores: successScores,
          timestamps: timestamps,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.idealState, isNotEmpty);
        expect(result.matchCount, equals(2));
        expect(result.averageSuccessScore, closeTo(0.85, 0.01));
        expect(result.entityTypes, contains(QuantumEntityType.event));
        expect(result.category, equals('tour:Coffee'));
      });

      test('should return heuristic state when no historical matches',
          () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        // Act
        final result = await service.calculateIdealStateFromHistory(
          category: 'tour:Coffee',
          entityTypes: {QuantumEntityType.event},
          historicalMatches: [],
          successScores: [],
          timestamps: [],
        );

        // Assert
        expect(result, isNotNull);
        expect(result.matchCount, equals(0));
        expect(result.averageSuccessScore, equals(0.5));
      });
    });
  });
}
