// Prediction API Service Tests
//
// Tests for Phase 19 Section 19.14: Prediction API for Business Intelligence

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/quantum/prediction_api_service.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai_runtime_os/services/quantum/user_journey_tracking_service.dart';
import 'package:avrai_runtime_os/services/quantum/user_event_prediction_matching_service.dart';
import 'package:avrai_runtime_os/services/quantum/third_party_data_privacy_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_core/models/user/personality_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'prediction_api_service_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  MeaningfulConnectionMetricsService,
  UserJourneyTrackingService,
  UserEventPredictionMatchingService,
  ThirdPartyDataPrivacyService,
  AgentIdService,
  ExpertiseEventService,
  PersonalityLearning,
  UserVibeAnalyzer,
  KnotEvolutionStringService,
  KnotFabricService,
  KnotWorldsheetService,
  HybridEncryptionService,
  AnonymousCommunicationProtocol,
])
void main() {
  group('PredictionAPIService', () {
    late PredictionAPIService service;
    late MockAtomicClockService mockAtomicClock;
    late MockMeaningfulConnectionMetricsService mockMetricsService;
    late MockUserJourneyTrackingService mockJourneyService;
    late MockUserEventPredictionMatchingService mockHypotheticalService;
    late MockThirdPartyDataPrivacyService mockPrivacyService;
    late MockAgentIdService mockAgentIdService;
    late MockExpertiseEventService mockEventService;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockKnotEvolutionStringService? mockStringService;
    late MockKnotFabricService? mockFabricService;
    late MockKnotWorldsheetService? mockWorldsheetService;
    late MockHybridEncryptionService? mockEncryptionService;
    late MockAnonymousCommunicationProtocol? mockAi2aiProtocol;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockMetricsService = MockMeaningfulConnectionMetricsService();
      mockJourneyService = MockUserJourneyTrackingService();
      mockHypotheticalService = MockUserEventPredictionMatchingService();
      mockPrivacyService = MockThirdPartyDataPrivacyService();
      mockAgentIdService = MockAgentIdService();
      mockEventService = MockExpertiseEventService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockStringService = MockKnotEvolutionStringService();
      mockFabricService = MockKnotFabricService();
      mockWorldsheetService = MockKnotWorldsheetService();
      mockEncryptionService = MockHybridEncryptionService();
      mockAi2aiProtocol = MockAnonymousCommunicationProtocol();

      service = PredictionAPIService(
        atomicClock: mockAtomicClock,
        metricsService: mockMetricsService,
        journeyService: mockJourneyService,
        hypotheticalService: mockHypotheticalService,
        privacyService: mockPrivacyService,
        agentIdService: mockAgentIdService,
        eventService: mockEventService,
        personalityLearning: mockPersonalityLearning,
        vibeAnalyzer: mockVibeAnalyzer,
        stringService: mockStringService,
        fabricService: mockFabricService,
        worldsheetService: mockWorldsheetService,
        encryptionService: mockEncryptionService,
        ai2aiProtocol: mockAi2aiProtocol,
      );
    });

    group('getMeaningfulConnectionPredictions', () {
      test('should return meaningful connection predictions for an event',
          () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
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
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event-1'))
            .thenAnswer((_) async => event);
        when(mockAgentIdService.getUserAgentId('user-1'))
            .thenAnswer((_) async => 'agent-1');
        when(mockAgentIdService.getUserAgentId('user-2'))
            .thenAnswer((_) async => 'agent-2');

        // Mock metrics service
        final metrics = MeaningfulConnectionMetrics(
          repeatingInteractionsRate: 0.75,
          eventContinuationRate: 0.80,
          vibeEvolutionScore: 0.70,
          connectionPersistenceRate: 0.85,
          transformativeImpactScore: 0.78,
          meaningfulConnectionScore: 0.77,
          timestamp: tAtomic,
        );
        when(mockMetricsService.calculateMetrics(
          event: anyNamed('event'),
          attendees: anyNamed('attendees'),
        )).thenAnswer((_) async => metrics);

        // Act
        final result = await service.getMeaningfulConnectionPredictions(
          eventId: 'event-1',
          maxPredictions: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.eventId, equals('event-1'));
        expect(result.predictedConnections.length, equals(2));
        expect(result.totalPredictedConnections, equals(2));
        expect(result.predictionTimestamp, equals(tAtomic));

        final connection1 = result.predictedConnections
            .firstWhere((c) => c.agentId == 'agent-1');
        expect(connection1.meaningfulConnectionScore, equals(0.77));
        expect(connection1.predictedInteractions, equals(0.75));
        expect(connection1.predictedEventContinuation, equals(0.80));
        expect(connection1.predictedVibeEvolution, equals(0.70));
        expect(connection1.transformativePotential, equals(0.78));
        expect(connection1.timestamp, equals(tAtomic));
      });

      test('should throw ArgumentError when event not found', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);
        when(mockEventService.getEventById('non-existent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getMeaningfulConnectionPredictions(
              eventId: 'non-existent'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty attendee list gracefully', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
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
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event-1'))
            .thenAnswer((_) async => event);

        // Act
        final result = await service.getMeaningfulConnectionPredictions(
          eventId: 'event-1',
          maxPredictions: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.predictedConnections, isEmpty);
        expect(result.totalPredictedConnections, equals(0));
      });

      test('should handle errors when converting userId to agentId gracefully',
          () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
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
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event-1'))
            .thenAnswer((_) async => event);
        when(mockAgentIdService.getUserAgentId('user-1'))
            .thenThrow(Exception('Service error'));
        when(mockAgentIdService.getUserAgentId('user-2'))
            .thenAnswer((_) async => 'agent-2');

        // Mock metrics service
        final metrics = MeaningfulConnectionMetrics(
          repeatingInteractionsRate: 0.75,
          eventContinuationRate: 0.80,
          vibeEvolutionScore: 0.70,
          connectionPersistenceRate: 0.85,
          transformativeImpactScore: 0.78,
          meaningfulConnectionScore: 0.77,
          timestamp: tAtomic,
        );
        when(mockMetricsService.calculateMetrics(
          event: anyNamed('event'),
          attendees: anyNamed('attendees'),
        )).thenAnswer((_) async => metrics);

        // Act
        final result = await service.getMeaningfulConnectionPredictions(
          eventId: 'event-1',
          maxPredictions: 10,
        );

        // Assert - should continue with user-2 despite error with user-1
        expect(result, isNotNull);
        expect(result.predictedConnections.length, equals(1));
        expect(result.predictedConnections.first.agentId, equals('agent-2'));
      });
    });

    group('getVibeEvolutionPredictions', () {
      test('should return vibe evolution predictions for a user', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final agentId = 'agent-123';
        // Note: Service uses agentId as userId (placeholder - requires reverse lookup)
        final userId = agentId;

        // Mock personality profile
        final personalityProfile = PersonalityProfile(
          userId: userId,
          agentId: agentId,
          dimensions: {'dim1': 0.5, 'dim2': 0.6},
          dimensionConfidence: {'dim1': 0.8, 'dim2': 0.7},
          archetype: 'developing',
          authenticity: 0.5,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);

        // Mock vibe analyzer
        final userVibe = UserVibe.fromPersonalityProfile(
            userId, personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Mock upcoming events
        final event1 = ExpertiseEvent(
          id: 'event-1',
          title: 'Event 1',
          description: 'Description 1',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: UnifiedUser(
            id: 'host-1',
            email: 'host@example.com',
            createdAt: now,
            updatedAt: now,
          ),
          attendeeIds: const [],
          attendeeCount: 0,
          maxAttendees: 20,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );
        when(mockEventService.searchEvents(
          startDate: anyNamed('startDate'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [event1]);

        // Mock prediction service
        final prediction = UserEventPrediction(
          userId: userId,
          eventId: 'event-1',
          predictionScore: 0.85,
          quantumCompatibility: 0.80,
          knotStringPrediction: 0.75,
          fabricStability: 0.70,
          overlapScore: 0.82,
          behaviorSimilarity: 0.78,
          reasoning: 'High compatibility',
          tAtomic: tAtomic,
        );
        when(mockHypotheticalService.predictUserEventCompatibility(
          userId: userId,
          eventId: 'event-1',
        )).thenAnswer((_) async => prediction);

        // Act
        final result = await service.getVibeEvolutionPredictions(
          agentId: agentId,
          maxEvents: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.agentId, equals(agentId));
        expect(result.currentVibe, isNotEmpty);
        expect(result.predictedVibeAfterEvents.length, equals(1));
        expect(result.predictionTimestamp, equals(tAtomic));

        final vibeEvolution = result.predictedVibeAfterEvents.first;
        expect(vibeEvolution.eventId, equals('event-1'));
        expect(vibeEvolution.vibeEvolutionScore, equals(0.85));
        expect(vibeEvolution.predictedVibe, isNotEmpty);
        expect(vibeEvolution.predictionTimestamp, equals(tAtomic));
      });

      test('should throw ArgumentError when personality profile not found',
          () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);
        // Note: Service uses agentId as userId (placeholder)
        final agentId = 'agent-123';
        when(mockPersonalityLearning.getCurrentPersonality(agentId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getVibeEvolutionPredictions(agentId: agentId),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty upcoming events list', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final agentId = 'agent-123';
        // Note: Service uses agentId as userId (placeholder)
        final userId = agentId;

        // Mock personality profile
        final personalityProfile = PersonalityProfile(
          userId: userId,
          agentId: agentId,
          dimensions: {'dim1': 0.5},
          dimensionConfidence: {'dim1': 0.8},
          archetype: 'developing',
          authenticity: 0.5,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);

        // Mock vibe analyzer
        final userVibe = UserVibe.fromPersonalityProfile(
            userId, personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Mock empty upcoming events
        when(mockEventService.searchEvents(
          startDate: anyNamed('startDate'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await service.getVibeEvolutionPredictions(
          agentId: agentId,
          maxEvents: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.predictedVibeAfterEvents, isEmpty);
      });

      test('should integrate knot string predictions when available', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final agentId = 'agent-123';
        // Note: Service uses agentId as userId (placeholder)
        final userId = agentId;

        // Mock personality profile
        final personalityProfile = PersonalityProfile(
          userId: userId,
          agentId: agentId,
          dimensions: {'dim1': 0.5},
          dimensionConfidence: {'dim1': 0.8},
          archetype: 'developing',
          authenticity: 0.5,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);

        // Mock vibe analyzer
        final userVibe = UserVibe.fromPersonalityProfile(
            userId, personalityProfile.dimensions);
        when(mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Mock upcoming event
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Event 1',
          description: 'Description 1',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: UnifiedUser(
            id: 'host-1',
            email: 'host@example.com',
            createdAt: now,
            updatedAt: now,
          ),
          attendeeIds: const [],
          attendeeCount: 0,
          maxAttendees: 20,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );
        when(mockEventService.searchEvents(
          startDate: anyNamed('startDate'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [event]);

        // Mock prediction service
        final prediction = UserEventPrediction(
          userId: userId,
          eventId: 'event-1',
          predictionScore: 0.85,
          quantumCompatibility: 0.80,
          knotStringPrediction: 0.75,
          fabricStability: 0.70,
          overlapScore: 0.82,
          behaviorSimilarity: 0.78,
          reasoning: 'High compatibility',
          tAtomic: tAtomic,
        );
        when(mockHypotheticalService.predictUserEventCompatibility(
          userId: userId,
          eventId: 'event-1',
        )).thenAnswer((_) async => prediction);

        // Mock knot string service (integration test)
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        final futureKnot = PersonalityKnot(
          agentId: agentId,
          braidData: [],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: now,
          lastUpdated: now,
        );
        when(mockStringService!.predictFutureKnot(agentId, event.startTime))
            .thenAnswer((_) async => futureKnot);

        // Note: This tests knot string integration - the service will call predictFutureKnot
        // if stringService is available, which it is in this test setup

        // Act
        final result = await service.getVibeEvolutionPredictions(
          agentId: agentId,
          maxEvents: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.predictedVibeAfterEvents.length, equals(1));
        // Verify knot string service was called
        verify(mockStringService!.predictFutureKnot(agentId, event.startTime))
            .called(1);
      });
    });

    group('getUserJourneyPredictions', () {
      test('should return user journey predictions', () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        final now = DateTime.now();
        final agentId = 'agent-123';
        // Note: Service uses agentId as userId (placeholder)
        final userId = agentId;

        // Mock personality profile
        final personalityProfile = PersonalityProfile(
          userId: userId,
          agentId: agentId,
          dimensions: {'dim1': 0.5, 'dim2': 0.6},
          dimensionConfidence: {'dim1': 0.8, 'dim2': 0.7},
          archetype: 'developing',
          authenticity: 0.5,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);

        // Mock upcoming event
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Event 1',
          description: 'Description 1',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: UnifiedUser(
            id: 'host-1',
            email: 'host@example.com',
            createdAt: now,
            updatedAt: now,
          ),
          attendeeIds: const [],
          attendeeCount: 0,
          maxAttendees: 20,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );
        when(mockEventService.searchEvents(
          startDate: anyNamed('startDate'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [event]);

        // Mock prediction service
        final prediction = UserEventPrediction(
          userId: userId,
          eventId: 'event-1',
          predictionScore: 0.85,
          quantumCompatibility: 0.80,
          knotStringPrediction: 0.75,
          fabricStability: 0.70,
          overlapScore: 0.82,
          behaviorSimilarity: 0.78,
          reasoning: 'High compatibility',
          tAtomic: tAtomic,
        );
        when(mockHypotheticalService.predictUserEventCompatibility(
          userId: userId,
          eventId: 'event-1',
        )).thenAnswer((_) async => prediction);

        // Act
        final result = await service.getUserJourneyPredictions(
          agentId: agentId,
          maxEvents: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.agentId, equals(agentId));
        expect(result.currentJourneyState, isNotEmpty);
        expect(result.predictedTrajectory.length, equals(1));
        expect(result.predictionTimestamp, equals(tAtomic));

        final journeyStep = result.predictedTrajectory.first;
        expect(journeyStep.eventId, equals('event-1'));
        expect(journeyStep.predictedConnections, greaterThanOrEqualTo(0));
        expect(journeyStep.predictedContinuationRate, equals(0.85));
        expect(journeyStep.predictedTransformativeImpact,
            equals(0.68)); // 0.85 * 0.8
        expect(journeyStep.predictionTimestamp, equals(tAtomic));
      });

      test('should throw ArgumentError when personality profile not found',
          () async {
        // Arrange
        final tAtomic =
            AtomicTimestamp.now(precision: TimePrecision.millisecond);
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);
        // Note: Service uses agentId as userId (placeholder)
        final agentId = 'agent-123';
        when(mockPersonalityLearning.getCurrentPersonality(agentId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getUserJourneyPredictions(agentId: agentId),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('encryptAndTransmitPrediction', () {
      test(
          'should encrypt and transmit prediction via Signal Protocol + AI2AI mesh',
          () async {
        // Arrange
        final predictionData = {
          'event_id': 'event-1',
          'agent_id': 'agent-123',
          'prediction_score': 0.85,
        };
        final recipientAgentId = 'recipient-agent-456';

        // Mock encryption and transmission (privacy validation happens inside encryptAndTransmit)
        final transmissionResult = EncryptedTransmissionResult(
          success: true,
          encryptionType: EncryptionType.aes256gcm,
          meshTransmitted: true,
          recipientAgentId: recipientAgentId,
        );
        when(mockPrivacyService.encryptAndTransmit(
          anonymizedData: anyNamed('anonymizedData'),
          recipientAgentId: recipientAgentId,
          messageType: anyNamed('messageType'),
        )).thenAnswer((_) async => transmissionResult);

        // Act
        final result = await service.encryptAndTransmitPrediction(
          predictionData: predictionData,
          recipientAgentId: recipientAgentId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result['success'], isTrue);
        expect(result['encryption_type'], isNotNull);
        expect(result['mesh_transmitted'], isTrue);
        expect(result['recipient_agent_id'], equals(recipientAgentId));

        // Verify privacy service was called with correct parameters
        verify(mockPrivacyService.encryptAndTransmit(
          anonymizedData: predictionData,
          recipientAgentId: recipientAgentId,
          messageType: MessageType.recommendationShare,
        )).called(1);
      });

      test('should handle encryption and transmission failure', () async {
        // Arrange
        final predictionData = {
          'event_id': 'event-1',
          'agent_id': 'agent-123',
        };
        final recipientAgentId = 'recipient-agent-456';

        // Mock encryption and transmission failure (privacy validation fails inside)
        when(mockPrivacyService.encryptAndTransmit(
          anonymizedData: anyNamed('anonymizedData'),
          recipientAgentId: recipientAgentId,
          messageType: anyNamed('messageType'),
        )).thenThrow(Exception('Privacy validation failed: Missing agentId'));

        // Act & Assert
        expect(
          () => service.encryptAndTransmitPrediction(
            predictionData: predictionData,
            recipientAgentId: recipientAgentId,
          ),
          throwsException,
        );

        // Verify encryption was attempted
        verify(mockPrivacyService.encryptAndTransmit(
          anonymizedData: predictionData,
          recipientAgentId: recipientAgentId,
          messageType: MessageType.recommendationShare,
        )).called(1);
      });
    });
  });
}
