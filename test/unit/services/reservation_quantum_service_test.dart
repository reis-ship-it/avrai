/// SPOTS Reservation Quantum Service Tests
/// Date: January 1, 2026
/// Purpose: Test ReservationQuantumService functionality
/// 
/// Test Coverage:
/// - Core Methods: createReservationQuantumState, calculateReservationCompatibility
/// - Quantum Integration: Quantum vibe, location, timing states
/// - Compatibility Calculation: Full formula with weights
/// 
/// Dependencies:
/// - Mock AtomicClockService: Atomic timestamp generation
/// - Mock QuantumVibeEngine: Quantum vibe compilation
/// - Mock UserVibeAnalyzer: User vibe analysis
/// - Mock PersonalityLearning: Personality profile retrieval
/// - Mock LocationTimingQuantumStateService: Location/timing quantum states
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test business logic, error handling, async operations, side effects
/// ✅ DO: Test service behavior and interactions with dependencies
/// ✅ DO: Consolidate related checks into comprehensive test blocks
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/reservation/reservation_quantum_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/models/user/unified_models.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai_core/models/unified_location_data.dart';

// Mock dependencies
class MockAtomicClockService extends Mock implements AtomicClockService {}
class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}
class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}
class MockPersonalityLearning extends Mock implements PersonalityLearning {}
class MockLocationTimingQuantumStateService extends Mock implements LocationTimingQuantumStateService {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const UnifiedLocation(
      latitude: 0.0,
      longitude: 0.0,
    ));
    registerFallbackValue(const UnifiedLocationData(
      latitude: 0.0,
      longitude: 0.0,
    ));
  });

  group('ReservationQuantumService', () {
    late ReservationQuantumService service;
    late MockAtomicClockService mockAtomicClock;
    late MockQuantumVibeEngine mockQuantumVibeEngine;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockLocationTimingQuantumStateService mockLocationTimingService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockQuantumVibeEngine = MockQuantumVibeEngine();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockPersonalityLearning = MockPersonalityLearning();
      mockLocationTimingService = MockLocationTimingQuantumStateService();

      service = ReservationQuantumService(
        atomicClock: mockAtomicClock,
        quantumVibeEngine: mockQuantumVibeEngine,
        vibeAnalyzer: mockVibeAnalyzer,
        personalityLearning: mockPersonalityLearning,
        locationTimingService: mockLocationTimingService,
      );
    });

    group('createReservationQuantumState', () {
      test('should create reservation quantum state with user personality and vibe', () async {
        // Arrange
        const userId = 'user-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-123',
          dimensions: personalityDimensions,
          dimensionConfidence: personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Create mock user vibe
        final userVibe = UserVibe.fromPersonalityProfile(userId, personalityDimensions);

        // Create mock atomic timestamp
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        // Create mock location quantum state
        final locationState = EntityLocationQuantumState(
          latitudeQuantumState: 0.5,
          longitudeQuantumState: 0.5,
          locationType: 'urban',
          accessibilityScore: 0.7,
          vibeLocationMatch: 0.5,
        );

        // Create mock timing quantum state
        final timingState = EntityTimingQuantumState(
          timeOfDayPreference: 0.5,
          dayOfWeekPreference: 0.5,
          frequencyPreference: 0.5,
          durationPreference: 0.5,
          timingVibeMatch: 0.5,
        );

        // Setup mocks
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async => userVibe);
        when(() => mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockLocationTimingService.createLocationQuantumState(
          location: any(named: 'location'),
          locationType: any(named: 'locationType'),
          accessibilityScore: any(named: 'accessibilityScore'),
          vibeLocationMatch: any(named: 'vibeLocationMatch'),
        )).thenAnswer((_) async => locationState);
        when(() => mockLocationTimingService.createTimingQuantumState(
          timeOfDayPreference: any(named: 'timeOfDayPreference'),
          dayOfWeekPreference: any(named: 'dayOfWeekPreference'),
          frequencyPreference: any(named: 'frequencyPreference'),
          durationPreference: any(named: 'durationPreference'),
          timingVibeMatch: any(named: 'timingVibeMatch'),
        )).thenAnswer((_) async => timingState);

        // Act
        final quantumState = await service.createReservationQuantumState(
          userId: userId,
          eventId: eventId,
          reservationTime: reservationTime,
        );

        // Assert - Test actual behavior
        expect(quantumState, isA<QuantumEntityState>());
        expect(quantumState.entityId, equals(userId));
        expect(quantumState.entityType, equals(QuantumEntityType.user));
        expect(quantumState.personalityState, isNotEmpty);
        expect(quantumState.quantumVibeAnalysis, isNotEmpty);
        expect(quantumState.location, isNotNull);
        expect(quantumState.timing, isNotNull);
        expect(quantumState.tAtomic, equals(atomicTimestamp));
        expect(quantumState.entityCharacteristics['hasEvent'], isTrue);
        expect(quantumState.entityCharacteristics['eventId'], equals(eventId));

        // Verify interactions
        verify(() => mockPersonalityLearning.getCurrentPersonality(userId)).called(1);
        verify(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile)).called(1);
        verify(() => mockAtomicClock.getAtomicTimestamp()).called(1);
      });

      test('should throw exception when personality profile not found', () async {
        // Arrange
        const userId = 'user-123';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        when(() => mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.createReservationQuantumState(
            userId: userId,
            reservationTime: reservationTime,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('calculateReservationCompatibility', () {
      test('should calculate compatibility using weighted formula', () async {
        // Arrange
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final locationState = EntityLocationQuantumState(
          latitudeQuantumState: 0.5,
          longitudeQuantumState: 0.5,
          locationType: 'urban',
          accessibilityScore: 0.7,
          vibeLocationMatch: 0.5,
        );

        final timingState = EntityTimingQuantumState(
          timeOfDayPreference: 0.5,
          dayOfWeekPreference: 0.5,
          frequencyPreference: 0.5,
          durationPreference: 0.5,
          timingVibeMatch: 0.5,
        );

        // Create two similar quantum states (should have high compatibility)
        final state1 = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: personalityDimensions,
          quantumVibeAnalysis: personalityDimensions,
          entityCharacteristics: {},
          location: locationState,
          timing: timingState,
          tAtomic: atomicTimestamp,
        );

        final state2 = QuantumEntityState(
          entityId: 'user-2',
          entityType: QuantumEntityType.user,
          personalityState: personalityDimensions,
          quantumVibeAnalysis: personalityDimensions,
          entityCharacteristics: {},
          location: locationState,
          timing: timingState,
          tAtomic: atomicTimestamp,
        );

        // Act
        final compatibility = await service.calculateReservationCompatibility(
          reservationState: state1,
          idealState: state2,
        );

        // Assert - Test actual behavior
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        // Similar states should have high compatibility (>0.8)
        expect(compatibility, greaterThan(0.8));
      });

      test('should return lower compatibility for dissimilar states', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        // Create dissimilar personality states
        final personality1 = <String, double>{};
        final personality2 = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personality1[dimension] = 0.0; // Minimum values
          personality2[dimension] = 1.0; // Maximum values
        }

        final locationState1 = EntityLocationQuantumState(
          latitudeQuantumState: 0.0,
          longitudeQuantumState: 0.0,
          locationType: 'rural',
          accessibilityScore: 0.0,
          vibeLocationMatch: 0.0,
        );

        final locationState2 = EntityLocationQuantumState(
          latitudeQuantumState: 1.0,
          longitudeQuantumState: 1.0,
          locationType: 'urban',
          accessibilityScore: 1.0,
          vibeLocationMatch: 1.0,
        );

        final timingState1 = EntityTimingQuantumState(
          timeOfDayPreference: 0.0, // Morning
          dayOfWeekPreference: 0.0, // Weekday
          frequencyPreference: 0.0,
          durationPreference: 0.0,
          timingVibeMatch: 0.0,
        );

        final timingState2 = EntityTimingQuantumState(
          timeOfDayPreference: 1.0, // Night
          dayOfWeekPreference: 1.0, // Weekend
          frequencyPreference: 1.0,
          durationPreference: 1.0,
          timingVibeMatch: 1.0,
        );

        final state1 = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: personality1,
          quantumVibeAnalysis: personality1,
          entityCharacteristics: {},
          location: locationState1,
          timing: timingState1,
          tAtomic: atomicTimestamp,
        );

        final state2 = QuantumEntityState(
          entityId: 'user-2',
          entityType: QuantumEntityType.user,
          personalityState: personality2,
          quantumVibeAnalysis: personality2,
          entityCharacteristics: {},
          location: locationState2,
          timing: timingState2,
          tAtomic: atomicTimestamp,
        );

        // Act
        final compatibility = await service.calculateReservationCompatibility(
          reservationState: state1,
          idealState: state2,
        );

        // Assert - Dissimilar states should have lower compatibility
        // Note: Even with maximum difference, compatibility formula may still produce moderate values
        // due to weighted averaging. We test that it's less than similar states (0.8+)
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        expect(compatibility, lessThan(0.8)); // Should be lower than similar states
      });
    });
  });
}
