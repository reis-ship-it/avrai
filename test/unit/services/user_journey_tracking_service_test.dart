// User Journey Tracking Service Tests
//
// Tests for Phase 19 Section 19.8: User Journey Tracking

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/user_journey_tracking_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'user_journey_tracking_service_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  PersonalityLearning,
  UserVibeAnalyzer,
  AgentIdService,
  SupabaseService,
])
void main() {
  group('UserJourneyTrackingService', () {
    late UserJourneyTrackingService service;
    late MockAtomicClockService mockAtomicClock;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockAgentIdService mockAgentIdService;
    late MockSupabaseService mockSupabaseService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockAgentIdService = MockAgentIdService();
      mockSupabaseService = MockSupabaseService();

      service = UserJourneyTrackingService(
        atomicClock: mockAtomicClock,
        personalityLearning: mockPersonalityLearning,
        vibeAnalyzer: mockVibeAnalyzer,
        agentIdService: mockAgentIdService,
        supabaseService: mockSupabaseService,
      );
    });

    group('capturePreEventState', () {
      test('should capture pre-event state correctly', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
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

        final userVibe = UserVibe.fromPersonalityProfile('user-1', personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe('user-1', personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Act
        final result = await service.capturePreEventState(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.timestamp, equals(tAtomic));
        expect(result.vibeDimensions, isNotEmpty);
        expect(result.engagementLevel, greaterThanOrEqualTo(0.0));
        expect(result.engagementLevel, lessThanOrEqualTo(1.0));
        expect(result.connectionCount, greaterThanOrEqualTo(0));
      });

      test('should throw error if personality profile not found', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);
        when(mockPersonalityLearning.getCurrentPersonality('user-1'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.capturePreEventState(
            userId: 'user-1',
            eventId: 'event-1',
          ),
          throwsException,
        );
      });
    });

    group('trackEventExperience', () {
      test('should track event experience correctly', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

        // Act
        await service.trackEventExperience(
          userId: 'user-1',
          eventId: 'event-1',
          attended: true,
          interactionCount: 5,
          engagementLevel: 0.8,
        );

        // Assert
        final journey = await service.getUserJourney(
          userId: 'user-1',
          eventId: 'event-1',
        );
        expect(journey, isNotNull);
        expect(journey?.eventExperience, isNotNull);
        expect(journey?.eventExperience?.attended, isTrue);
        expect(journey?.eventExperience?.interactionCount, equals(5));
        expect(journey?.eventExperience?.engagementLevel, equals(0.8));
      });

      test('should track non-attendance correctly', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

        // Act
        await service.trackEventExperience(
          userId: 'user-1',
          eventId: 'event-1',
          attended: false,
        );

        // Assert
        final journey = await service.getUserJourney(
          userId: 'user-1',
          eventId: 'event-1',
        );
        expect(journey, isNotNull);
        expect(journey?.eventExperience, isNotNull);
        expect(journey?.eventExperience?.attended, isFalse);
        expect(journey?.eventExperience?.attendanceTimestamp, isNull);
      });
    });

    group('capturePostEventState', () {
      test('should capture post-event state and calculate evolution', () async {
        // Arrange
        final tAtomicPre = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final tAtomicPost = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        // Mock to return different timestamps on subsequent calls
        var callCount = 0;
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? tAtomicPre : tAtomicPost;
        });

        final now = DateTime.now();
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

        final userVibe = UserVibe.fromPersonalityProfile('user-1', personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe('user-1', personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Capture pre-event state first
        await service.capturePreEventState(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Act
        final result = await service.capturePostEventState(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.timestamp, equals(tAtomicPost));
        expect(result.vibeDimensions, isNotEmpty);

        // Check that evolution was calculated
        final journey = await service.getUserJourney(
          userId: 'user-1',
          eventId: 'event-1',
        );
        expect(journey, isNotNull);
        expect(journey?.evolution, isNotNull);
        expect(journey?.evolution?.journeyImpactScore, greaterThanOrEqualTo(0.0));
        expect(journey?.evolution?.journeyImpactScore, lessThanOrEqualTo(1.0));
      });
    });

    group('getUserJourney', () {
      test('should return null if journey not found', () async {
        // Act
        final result = await service.getUserJourney(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Assert
        expect(result, isNull);
      });

      test('should return journey after capturing pre-event state', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
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

        final userVibe = UserVibe.fromPersonalityProfile('user-1', personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe('user-1', personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Capture pre-event state
        await service.capturePreEventState(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Act
        final journey = await service.getUserJourney(
          userId: 'user-1',
          eventId: 'event-1',
        );

        // Assert
        expect(journey, isNotNull);
        expect(journey?.userId, equals('user-1'));
        expect(journey?.eventId, equals('event-1'));
        expect(journey?.preEventState, isNotNull);
      });
    });
  });
}
