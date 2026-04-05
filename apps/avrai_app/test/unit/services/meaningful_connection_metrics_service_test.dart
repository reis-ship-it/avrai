// Meaningful Connection Metrics Service Tests
//
// Tests for Phase 19 Section 19.7: Meaningful Connection Metrics System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/enums/user_enums.dart' as core_enums;
import 'package:avrai_core/models/user.dart' as core_user;
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'meaningful_connection_metrics_service_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  QuantumEntanglementService,
  PersonalityLearning,
  UserVibeAnalyzer,
  SupabaseService,
  AgentIdService,
  KnotEvolutionStringService,
  KnotWorldsheetService,
  KnotFabricService,
  KnotStorageService,
])
void main() {
  group('MeaningfulConnectionMetricsService', () {
    late MeaningfulConnectionMetricsService service;
    late MockAtomicClockService mockAtomicClock;
    late MockQuantumEntanglementService mockEntanglementService;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockSupabaseService mockSupabaseService;
    late MockAgentIdService mockAgentIdService;
    late MockKnotEvolutionStringService mockStringService;
    late MockKnotWorldsheetService mockWorldsheetService;
    late MockKnotFabricService mockFabricService;
    late MockKnotStorageService mockKnotStorage;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockEntanglementService = MockQuantumEntanglementService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockSupabaseService = MockSupabaseService();
      mockAgentIdService = MockAgentIdService();
      mockStringService = MockKnotEvolutionStringService();
      mockWorldsheetService = MockKnotWorldsheetService();
      mockFabricService = MockKnotFabricService();
      mockKnotStorage = MockKnotStorageService();

      service = MeaningfulConnectionMetricsService(
        atomicClock: mockAtomicClock,
        entanglementService: mockEntanglementService,
        personalityLearning: mockPersonalityLearning,
        vibeAnalyzer: mockVibeAnalyzer,
        agentIdService: mockAgentIdService,
        supabaseService: mockSupabaseService,
        stringService: mockStringService,
        worldsheetService: mockWorldsheetService,
        fabricService: mockFabricService,
        knotStorage: mockKnotStorage,
      );
    });

    group('calculateMetrics', () {
      test('should calculate meaningful connection metrics correctly',
          () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final host = UnifiedUser(
          id: 'host-1',
          email: 'host@example.com',
          displayName: 'Host User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: host,
          attendeeIds: const ['user-1', 'user-2'],
          attendeeCount: 2,
          maxAttendees: 20,
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 9)),
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 9)),
        );

        final attendees = <core_user.User>[
          core_user.User(
            id: 'user-1',
            email: 'user1@example.com',
            name: 'User 1',
            role: core_enums.UserRole.follower,
            createdAt: now,
            updatedAt: now,
          ),
          core_user.User(
            id: 'user-2',
            email: 'user2@example.com',
            name: 'User 2',
            role: core_enums.UserRole.follower,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Mock agent ID service
        when(mockAgentIdService.getUserAgentId('user-1'))
            .thenAnswer((_) async => 'agent-1');
        when(mockAgentIdService.getUserAgentId('user-2'))
            .thenAnswer((_) async => 'agent-2');

        // Mock Supabase service to return null (will use placeholder logic)
        // In real tests, would mock the client properly

        // Mock personality learning
        final personalityProfile = PersonalityProfile(
          userId: 'user-1',
          agentId: 'agent-1',
          dimensions: {'dim1': 0.5, 'dim2': 0.6},
          dimensionConfidence: {'dim1': 0.8, 'dim2': 0.7},
          archetype: 'developing',
          authenticity: 0.5,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality('user-1'))
            .thenAnswer((_) async => personalityProfile);
        when(mockPersonalityLearning.getCurrentPersonality('user-2'))
            .thenAnswer((_) async => personalityProfile);

        // Mock vibe analyzer
        final userVibe = UserVibe.fromPersonalityProfile(
            'user-1', personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe('user-1', personalityProfile))
            .thenAnswer((_) async => userVibe);
        when(mockVibeAnalyzer.compileUserVibe('user-2', personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Act
        final result = await service.calculateMetrics(
          event: event,
          attendees: attendees,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.meaningfulConnectionScore, greaterThanOrEqualTo(0.0));
        expect(result.meaningfulConnectionScore, lessThanOrEqualTo(1.0));
        expect(result.repeatingInteractionsRate, greaterThanOrEqualTo(0.0));
        expect(result.repeatingInteractionsRate, lessThanOrEqualTo(1.0));
        expect(result.eventContinuationRate, greaterThanOrEqualTo(0.0));
        expect(result.eventContinuationRate, lessThanOrEqualTo(1.0));
        expect(result.vibeEvolutionScore, greaterThanOrEqualTo(0.0));
        expect(result.vibeEvolutionScore, lessThanOrEqualTo(1.0));
        expect(result.connectionPersistenceRate, greaterThanOrEqualTo(0.0));
        expect(result.connectionPersistenceRate, lessThanOrEqualTo(1.0));
        expect(result.transformativeImpactScore, greaterThanOrEqualTo(0.0));
        expect(result.transformativeImpactScore, lessThanOrEqualTo(1.0));
        expect(result.timestamp, equals(tAtomic));
      });

      test('should handle empty attendees list', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final host = UnifiedUser(
          id: 'host-1',
          email: 'host@example.com',
          displayName: 'Host User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: host,
          attendeeIds: const [],
          attendeeCount: 0,
          maxAttendees: 20,
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 9)),
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 9)),
        );

        // Act
        final result = await service.calculateMetrics(
          event: event,
          attendees: [],
        );

        // Assert
        expect(result, isNotNull);
        expect(result.meaningfulConnectionScore, equals(0.0));
        expect(result.repeatingInteractionsRate, equals(0.0));
        expect(result.eventContinuationRate, equals(0.0));
        expect(result.vibeEvolutionScore, equals(0.0));
        expect(result.connectionPersistenceRate, equals(0.0));
        expect(result.transformativeImpactScore, equals(0.0));
      });

      test('should handle errors gracefully', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final host = UnifiedUser(
          id: 'host-1',
          email: 'host@example.com',
          displayName: 'Host User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: host,
          attendeeIds: const ['user-1'],
          attendeeCount: 1,
          maxAttendees: 20,
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 9)),
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 9)),
        );

        final attendees = <core_user.User>[
          core_user.User(
            id: 'user-1',
            email: 'user1@example.com',
            name: 'User 1',
            role: core_enums.UserRole.follower,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Mock agent ID service to throw error
        when(mockAgentIdService.getUserAgentId('user-1'))
            .thenThrow(Exception('Service error'));

        // Act
        final result = await service.calculateMetrics(
          event: event,
          attendees: attendees,
        );

        // Assert
        expect(result, isNotNull);
        // Should return default metrics (all zeros) on error
        expect(result.meaningfulConnectionScore, equals(0.0));
      });
    });
  });
}
