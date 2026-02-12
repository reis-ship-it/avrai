// Quantum Outcome-Based Learning Service Tests
//
// Tests for Phase 19 Section 19.9: Quantum Outcome-Based Learning System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/quantum_outcome_learning_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/events/event_success_analysis_service.dart';
import 'package:avrai/core/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai/core/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_success_metrics.dart';
import 'package:avrai/core/models/events/event_success_level.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'quantum_outcome_learning_service_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  EventSuccessAnalysisService,
  MeaningfulConnectionMetricsService,
  QuantumEntanglementService,
  LocationTimingQuantumStateService,
  KnotEvolutionStringService,
  KnotWorldsheetService,
  KnotStorageService,
  AgentIdService,
])
void main() {
  group('QuantumOutcomeLearningService', () {
    late QuantumOutcomeLearningService service;
    late MockAtomicClockService mockAtomicClock;
    late MockEventSuccessAnalysisService mockSuccessAnalysisService;
    late MockMeaningfulConnectionMetricsService mockMeaningfulMetricsService;
    late MockQuantumEntanglementService mockEntanglementService;
    late MockLocationTimingQuantumStateService mockLocationTimingService;
    late MockKnotEvolutionStringService mockStringService;
    late MockKnotWorldsheetService mockWorldsheetService;
    late MockKnotStorageService mockKnotStorage;
    late MockAgentIdService mockAgentIdService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockSuccessAnalysisService = MockEventSuccessAnalysisService();
      mockMeaningfulMetricsService = MockMeaningfulConnectionMetricsService();
      mockEntanglementService = MockQuantumEntanglementService();
      mockLocationTimingService = MockLocationTimingQuantumStateService();
      mockStringService = MockKnotEvolutionStringService();
      mockWorldsheetService = MockKnotWorldsheetService();
      mockKnotStorage = MockKnotStorageService();
      mockAgentIdService = MockAgentIdService();

      service = QuantumOutcomeLearningService(
        atomicClock: mockAtomicClock,
        successAnalysisService: mockSuccessAnalysisService,
        meaningfulMetricsService: mockMeaningfulMetricsService,
        entanglementService: mockEntanglementService,
        locationTimingService: mockLocationTimingService,
        stringService: mockStringService,
        worldsheetService: mockWorldsheetService,
        knotStorage: mockKnotStorage,
        agentIdService: mockAgentIdService,
      );
    });

    group('learnFromOutcome', () {
      test('should learn from successful event outcome', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

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
          attendeeIds: const ['user-1', 'user-2'],
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final successMetrics = EventSuccessMetrics(
          eventId: 'event-1',
          ticketsSold: 50,
          actualAttendance: 45,
          attendanceRate: 0.9,
          grossRevenue: 1000.0,
          netRevenue: 900.0,
          revenueVsProjected: 1.0,
          profitMargin: 0.1,
          averageRating: 4.5,
          nps: 70.0,
          fiveStarCount: 30,
          fourStarCount: 15,
          threeStarCount: 0,
          twoStarCount: 0,
          oneStarCount: 0,
          feedbackResponseRate: 0.9,
          attendeesWhoWouldReturn: 40,
          attendeesWhoWouldRecommend: 42,
          partnerSatisfaction: const {'partner-1': 0.9},
          partnersWouldCollaborateAgain: true,
          successLevel: EventSuccessLevel.high,
          successFactors: const ['Great atmosphere'],
          improvementAreas: const [],
          calculatedAt: now,
        );

        when(mockSuccessAnalysisService.analyzeEventSuccess('event-1'))
            .thenAnswer((_) async => successMetrics);

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
        final result = await service.learnFromOutcome(
          eventId: 'event-1',
          event: event,
          entities: entities,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.successScore, greaterThan(0.0));
        expect(result.successScore, lessThanOrEqualTo(1.0));
        expect(result.learningRate, greaterThan(0.0));
        expect(result.learningRate, lessThanOrEqualTo(0.1));
        expect(result.successLevel, isA<SuccessLevel>());
        expect(result.timestamp, equals(tAtomic));
      });

      test('should handle low success score correctly', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

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
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final successMetrics = EventSuccessMetrics(
          eventId: 'event-1',
          ticketsSold: 50,
          actualAttendance: 20,
          attendanceRate: 0.4,
          grossRevenue: 500.0,
          netRevenue: 400.0,
          revenueVsProjected: 0.5,
          profitMargin: 0.05,
          averageRating: 2.5,
          nps: -50.0,
          fiveStarCount: 0,
          fourStarCount: 5,
          threeStarCount: 10,
          twoStarCount: 5,
          oneStarCount: 0,
          feedbackResponseRate: 0.4,
          attendeesWhoWouldReturn: 5,
          attendeesWhoWouldRecommend: 3,
          partnerSatisfaction: const {'partner-1': 0.3},
          partnersWouldCollaborateAgain: false,
          successLevel: EventSuccessLevel.low,
          successFactors: const [],
          improvementAreas: const ['Low attendance', 'Poor ratings'],
          calculatedAt: now,
        );

        when(mockSuccessAnalysisService.analyzeEventSuccess('event-1'))
            .thenAnswer((_) async => successMetrics);

        final entities = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.3, 'dim2': 0.4},
            quantumVibeAnalysis: {'vibe1': 0.2, 'vibe2': 0.3},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        // Act
        final result = await service.learnFromOutcome(
          eventId: 'event-1',
          event: event,
          entities: entities,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.successScore, lessThan(0.6)); // Low success
        expect(result.successLevel, equals(SuccessLevel.low));
        expect(result.extractedState, isNull); // Should not extract state for low success
      });
    });

    group('detectPreferenceDrift', () {
      test('should detect no drift for new ideal state', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

        // Act
        final result = await service.detectPreferenceDrift(
          idealStateKey: 'new-key',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.driftScore, equals(1.0));
        expect(result.significantDrift, isFalse);
        expect(result.explorationRate, greaterThanOrEqualTo(0.0));
      });

      test('should detect drift for old ideal state', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final oldTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        var callCount = 0;
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? oldTimestamp : tAtomic;
        });

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

        final successMetrics = EventSuccessMetrics(
          eventId: 'event-1',
          ticketsSold: 50,
          actualAttendance: 45,
          attendanceRate: 0.9,
          grossRevenue: 1000.0,
          netRevenue: 900.0,
          revenueVsProjected: 1.0,
          profitMargin: 0.1,
          averageRating: 4.5,
          nps: 70.0,
          fiveStarCount: 30,
          fourStarCount: 15,
          threeStarCount: 0,
          twoStarCount: 0,
          oneStarCount: 0,
          feedbackResponseRate: 0.9,
          attendeesWhoWouldReturn: 40,
          attendeesWhoWouldRecommend: 42,
          partnerSatisfaction: const {'partner-1': 0.9},
          partnersWouldCollaborateAgain: true,
          successLevel: EventSuccessLevel.high,
          successFactors: const ['Great atmosphere'],
          improvementAreas: const [],
          calculatedAt: now,
        );

        when(mockSuccessAnalysisService.analyzeEventSuccess('event-1'))
            .thenAnswer((_) async => successMetrics);

        final entities = [
          QuantumEntityState(
            entityId: 'entity-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.5, 'dim2': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7, 'vibe2': 0.8},
            entityCharacteristics: {},
            tAtomic: oldTimestamp,
          ),
        ];

        // Create ideal state first
        await service.learnFromOutcome(
          eventId: 'event-1',
          event: event,
          entities: entities,
        );

        // Wait a bit (simulate time passing)
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = await service.detectPreferenceDrift(
          idealStateKey: 'tour:Coffee',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.driftScore, greaterThanOrEqualTo(0.0));
        expect(result.driftScore, lessThanOrEqualTo(1.0));
      });
    });

    group('getIdealState', () {
      test('should return null for non-existent ideal state', () async {
        // Act
        final result = await service.getIdealState(
          idealStateKey: 'non-existent',
        );

        // Assert
        expect(result, isNull);
      });

      test('should return ideal state after learning', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

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

        final successMetrics = EventSuccessMetrics(
          eventId: 'event-1',
          ticketsSold: 50,
          actualAttendance: 45,
          attendanceRate: 0.9,
          grossRevenue: 1000.0,
          netRevenue: 900.0,
          revenueVsProjected: 1.0,
          profitMargin: 0.1,
          averageRating: 4.5,
          nps: 70.0,
          fiveStarCount: 30,
          fourStarCount: 15,
          threeStarCount: 0,
          twoStarCount: 0,
          oneStarCount: 0,
          feedbackResponseRate: 0.9,
          attendeesWhoWouldReturn: 40,
          attendeesWhoWouldRecommend: 42,
          partnerSatisfaction: const {'partner-1': 0.9},
          partnersWouldCollaborateAgain: true,
          successLevel: EventSuccessLevel.high,
          successFactors: const ['Great atmosphere'],
          improvementAreas: const [],
          calculatedAt: now,
        );

        when(mockSuccessAnalysisService.analyzeEventSuccess('event-1'))
            .thenAnswer((_) async => successMetrics);

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

        // Learn from outcome to create ideal state
        await service.learnFromOutcome(
          eventId: 'event-1',
          event: event,
          entities: entities,
        );

        // Act
        final result = await service.getIdealState(
          idealStateKey: 'tour:Coffee',
        );

        // Assert
        expect(result, isNotNull);
        expect(result?.idealState, isNotEmpty);
        expect(result?.matchCount, equals(1));
      });
    });
  });
}
