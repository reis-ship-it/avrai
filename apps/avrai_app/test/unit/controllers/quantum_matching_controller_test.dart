// Quantum Matching Controller Unit Tests
//
// Tests controller orchestration logic with mocked dependencies
// Part of Phase 19 Section 19.5: Quantum Matching Controller

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_core/models/quantum/matching_input.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/quantum_entity_state.dart'
    show QuantumEntityState, EntityTimingQuantumState;
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/user/preferences_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'quantum_matching_controller_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  QuantumEntanglementService,
  LocationTimingQuantumStateService,
  PersonalityLearning,
  UserVibeAnalyzer,
  AgentIdService,
  PreferencesProfileService,
  IntegratedKnotRecommendationEngine,
  CrossEntityCompatibilityService,
])
void main() {
  group('QuantumMatchingController', () {
    late QuantumMatchingController controller;
    late MockAtomicClockService mockAtomicClock;
    late MockQuantumEntanglementService mockEntanglementService;
    late MockLocationTimingQuantumStateService mockLocationTimingService;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockAgentIdService mockAgentIdService;
    late MockPreferencesProfileService mockPreferencesProfileService;
    late MockIntegratedKnotRecommendationEngine mockKnotEngine;
    late MockCrossEntityCompatibilityService mockKnotCompatibilityService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockEntanglementService = MockQuantumEntanglementService();
      mockLocationTimingService = MockLocationTimingQuantumStateService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockAgentIdService = MockAgentIdService();
      mockPreferencesProfileService = MockPreferencesProfileService();
      mockKnotEngine = MockIntegratedKnotRecommendationEngine();
      mockKnotCompatibilityService = MockCrossEntityCompatibilityService();

      controller = QuantumMatchingController(
        atomicClock: mockAtomicClock,
        entanglementService: mockEntanglementService,
        locationTimingService: mockLocationTimingService,
        personalityLearning: mockPersonalityLearning,
        vibeAnalyzer: mockVibeAnalyzer,
        agentIdService: mockAgentIdService,
        preferencesProfileService: mockPreferencesProfileService,
        knotEngine: mockKnotEngine,
        knotCompatibilityService: mockKnotCompatibilityService,
      );
    });

    group('validate', () {
      test('should return valid result for valid input with event', () {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: user,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.fieldErrors, isEmpty);
        expect(result.generalErrors, isEmpty);
      });

      test('should return valid result for valid input with spot', () {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final spot = Spot(
          id: 'spot-1',
          name: 'Coffee Shop',
          description: 'A great coffee shop',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'Coffee',
          rating: 4.5,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final input = MatchingInput(
          user: user,
          spot: spot,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty user ID', () {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: '',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: user,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );
        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors, contains('User ID is required'));
      });

      test('should return invalid result when no entities provided', () {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final input = MatchingInput(
          user: user,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(
            result.generalErrors,
            contains(
                'At least one entity (event, spot, business, etc.) is required'));
      });
    });

    group('execute', () {
      test('should successfully perform matching with event', () async {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          location: 'New York, NY',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: user,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final input = MatchingInput(
          user: user,
          event: event,
        );

        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        // Mock atomic clock
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        // Mock personality learning
        final personalityProfile = PersonalityProfile(
          agentId: 'agent-user-1',
          dimensions: {'dimension1': 0.5},
          dimensionConfidence: {'dimension1': 0.8},
          archetype: 'explorer',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );
        when(mockPersonalityLearning.getCurrentPersonality(user.id))
            .thenAnswer((_) async => personalityProfile);

        // Mock vibe analyzer
        final userVibe = UserVibe.fromPersonalityProfile(
          user.id,
          personalityProfile.dimensions,
        );
        when(mockVibeAnalyzer.compileUserVibe(user.id, personalityProfile))
            .thenAnswer((_) async => userVibe);

        // Mock agent ID service
        when(mockAgentIdService.getUserAgentId(user.id))
            .thenAnswer((_) async => 'agent-user-1');

        // Mock preferences profile service
        final preferencesProfile = PreferencesProfile(
          agentId: 'agent-user-1',
          categoryPreferences: const {'Coffee': 0.8},
          localityPreferences: const {},
          eventTypePreferences: const {},
          scopePreferences: const {},
          localExpertPreferenceWeight: 0.5,
          explorationWillingness: 0.7,
          lastUpdated: DateTime.now(),
        );
        when(mockPreferencesProfileService
                .getPreferencesProfile('agent-user-1'))
            .thenAnswer((_) async => preferencesProfile);

        when(mockLocationTimingService.createTimingQuantumStateFromIntuitive(
          timeOfDayHour: anyNamed('timeOfDayHour'),
          dayOfWeek: anyNamed('dayOfWeek'),
          frequencyPreference: anyNamed('frequencyPreference'),
          durationPreference: anyNamed('durationPreference'),
        )).thenAnswer((_) async => EntityTimingQuantumState(
              timeOfDayPreference: 0.5,
              dayOfWeekPreference: 0.5,
              frequencyPreference: 0.5,
              durationPreference: 0.5,
              timingVibeMatch: 0.5,
            ));

        when(mockLocationTimingService.createTimingQuantumStateFromDateTime(
          preferredTime: anyNamed('preferredTime'),
          frequencyPreference: anyNamed('frequencyPreference'),
          durationPreference: anyNamed('durationPreference'),
        )).thenAnswer((_) async => EntityTimingQuantumState(
              timeOfDayPreference: 0.5,
              dayOfWeekPreference: 0.5,
              frequencyPreference: 0.5,
              durationPreference: 0.5,
              timingVibeMatch: 0.5,
            ));

        // Mock entanglement service - returns EntangledQuantumState
        final entangledState = EntangledQuantumState(
          entityStates: [
            QuantumEntityState(
              entityId: user.id,
              entityType: QuantumEntityType.user,
              personalityState: {'dimension1': 0.5},
              quantumVibeAnalysis: {'vibe1': 0.6},
              entityCharacteristics: {'type': 'user'},
              tAtomic: tAtomic,
            ),
            QuantumEntityState(
              entityId: event.id,
              entityType: QuantumEntityType.event,
              personalityState: {'dimension1': 0.7},
              quantumVibeAnalysis: {'vibe1': 0.8},
              entityCharacteristics: {'type': 'event'},
              tAtomic: tAtomic,
            ),
          ],
          coefficients: [0.5, 0.5],
          entangledVector: [0.5, 0.5, 0.5, 0.5],
          tAtomic: tAtomic,
        );
        when(mockEntanglementService.createEntangledState(
          entityStates: anyNamed('entityStates'),
        )).thenAnswer((_) async => entangledState);

        when(mockEntanglementService.calculateFidelity(
          any,
          any,
        )).thenAnswer((_) async => 0.75);

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
        expect(result.matchingResult!.compatibility, lessThanOrEqualTo(1.0));
        // QuantumMatchingController now computes quantumCompatibility as the
        // average cosine similarity between the user's state vector and each
        // target entity's state vector (clamped to [0,1]).
        expect(result.matchingResult!.quantumCompatibility,
            inInclusiveRange(0.0, 1.0));
        expect(result.matchingResult!.quantumCompatibility, greaterThan(0.7));
        expect(result.matchingResult!.entities.length, greaterThanOrEqualTo(1));
        expect(result.matchingResult!.timestamp, equals(tAtomic));
      });

      test('should handle validation errors gracefully', () async {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: '',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final input = MatchingInput(
          user: user,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('VALIDATION_ERROR'));
        expect(result.matchingResult, isNull);
      });

      test('should handle service errors gracefully', () async {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: user,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
        );
        final input = MatchingInput(
          user: user,
          event: event,
        );

        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        // Mock atomic clock
        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => tAtomic);

        // Mock personality learning to throw error
        when(mockPersonalityLearning.getCurrentPersonality(user.id))
            .thenThrow(Exception('Service error'));

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isFalse);
        // Error code may vary depending on where the error occurs
        expect(result.errorCode, isNotNull);
        expect(result.error, isNotEmpty);
      });
    });
  });
}
