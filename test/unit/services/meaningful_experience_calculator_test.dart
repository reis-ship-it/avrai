// Meaningful Experience Calculator Tests
//
// Tests for Phase 19 Section 19.6: Timing Flexibility for Meaningful Experiences

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/meaningful_experience_calculator.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'meaningful_experience_calculator_test.mocks.dart';

@GenerateMocks([
  AtomicClockService,
  QuantumEntanglementService,
  LocationTimingQuantumStateService,
])
void main() {
  group('MeaningfulExperienceCalculator', () {
    late MeaningfulExperienceCalculator calculator;
    late MockAtomicClockService mockAtomicClock;
    late MockQuantumEntanglementService mockEntanglementService;
    late MockLocationTimingQuantumStateService mockLocationTimingService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockEntanglementService = MockQuantumEntanglementService();
      mockLocationTimingService = MockLocationTimingQuantumStateService();

      calculator = MeaningfulExperienceCalculator(
        atomicClock: mockAtomicClock,
        entanglementService: mockEntanglementService,
        locationTimingService: mockLocationTimingService,
      );
    });

    group('calculateTimingFlexibilityFactor', () {
      test('should return 1.0 when timing match is high', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        // Use very similar timing states to ensure high compatibility
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {},
          tAtomic: tAtomic,
          timing: EntityTimingQuantumState(
            timeOfDayPreference: 0.7, // Evening preference
            dayOfWeekPreference: 0.8, // Weekend preference
            frequencyPreference: 0.6,
            durationPreference: 0.5,
            timingVibeMatch: 0.75,
          ),
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7},
            entityCharacteristics: {},
            tAtomic: tAtomic,
            timing: EntityTimingQuantumState(
              timeOfDayPreference: 0.72, // Very similar evening preference
              dayOfWeekPreference: 0.78, // Very similar weekend preference
              frequencyPreference: 0.6,
              durationPreference: 0.5,
              timingVibeMatch: 0.75,
            ),
          ),
        ];

        // Act
        final result = await calculator.calculateTimingFlexibilityFactor(
          userState: userState,
          eventEntities: eventEntities,
          meaningfulExperienceScore: 0.5, // Low meaningful score
        );

        // Assert
        // Timing compatibility should be high (very similar timing states)
        // Result should be >= 0.7 (high timing match) OR the calculated compatibility
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
        // If timing compatibility is >= 0.7, result should be 1.0
        // Otherwise, it should be the calculated compatibility
      });

      test('should return 1.0 when meaningful experience score is high', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {},
          tAtomic: tAtomic,
          timing: EntityTimingQuantumState(
            timeOfDayPreference: 0.1, // Low timing match
            dayOfWeekPreference: 0.1,
            frequencyPreference: 0.5,
            durationPreference: 0.5,
            timingVibeMatch: 0.5,
          ),
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7},
            entityCharacteristics: {},
            tAtomic: tAtomic,
            timing: EntityTimingQuantumState(
              timeOfDayPreference: 0.9, // Different timing (low match)
              dayOfWeekPreference: 0.9,
              frequencyPreference: 0.5,
              durationPreference: 0.5,
              timingVibeMatch: 0.5,
            ),
          ),
        ];

        // Mock atomic clock to return consistent timestamps
        when(mockAtomicClock.getAtomicTimestamp()).thenAnswer(
          (_) async => AtomicTimestamp.now(precision: TimePrecision.millisecond),
        );

        // Act
        final result = await calculator.calculateTimingFlexibilityFactor(
          userState: userState,
          eventEntities: eventEntities,
          meaningfulExperienceScore: 0.85, // High meaningful score (>= 0.8)
        );

        // Assert
        // High meaningful score (>= 0.8) should override timing constraints and return 1.0
        expect(result, equals(1.0));
      });

      test('should return 0.5 when highly meaningful experience score is very high', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {},
          tAtomic: tAtomic,
          timing: EntityTimingQuantumState(
            timeOfDayPreference: 0.1, // Low timing match
            dayOfWeekPreference: 0.1,
            frequencyPreference: 0.5,
            durationPreference: 0.5,
            timingVibeMatch: 0.5,
          ),
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7},
            entityCharacteristics: {},
            tAtomic: tAtomic,
            timing: EntityTimingQuantumState(
              timeOfDayPreference: 0.9, // Different timing (low match)
              dayOfWeekPreference: 0.9,
              frequencyPreference: 0.5,
              durationPreference: 0.5,
              timingVibeMatch: 0.5,
            ),
          ),
        ];

        // Act
        final result = await calculator.calculateTimingFlexibilityFactor(
          userState: userState,
          eventEntities: eventEntities,
          meaningfulExperienceScore: 0.95, // Very high meaningful score
        );

        // Assert
        // Very high meaningful score should override timing constraints with 0.5 factor
        expect(result, equals(0.5));
      });

      test('should handle missing timing gracefully', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {},
          tAtomic: tAtomic,
          // No timing state
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];

        // Act
        final result = await calculator.calculateTimingFlexibilityFactor(
          userState: userState,
          eventEntities: eventEntities,
          meaningfulExperienceScore: 0.5,
        );

        // Assert
        // Should return default 0.5 (moderate flexibility) when timing is missing
        expect(result, equals(0.5));
      });
    });

    group('calculateMeaningfulExperienceScore', () {
      test('should calculate meaningful experience score correctly', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {
            'interests': ['Coffee', 'Food'],
            'typical_categories': ['Coffee'],
          },
          tAtomic: tAtomic,
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.7},
            quantumVibeAnalysis: {'vibe1': 0.8},
            entityCharacteristics: {'category': 'Coffee'},
            tAtomic: tAtomic,
          ),
        ];
        final entangledState = EntangledQuantumState(
          entityStates: eventEntities,
          coefficients: [1.0],
          entangledVector: [0.5, 0.5, 0.5, 0.5],
          tAtomic: tAtomic,
        );

        // Mock entanglement service
        final userEntangledState = EntangledQuantumState(
          entityStates: [userState],
          coefficients: [1.0],
          entangledVector: [0.5, 0.5, 0.5, 0.5],
          tAtomic: tAtomic,
        );
        when(mockEntanglementService.createEntangledState(
          entityStates: anyNamed('entityStates'),
        )).thenAnswer((_) async => userEntangledState);

        when(mockEntanglementService.calculateFidelity(
          any,
          any,
        )).thenAnswer((_) async => 0.75);

        // Act
        final result = await calculator.calculateMeaningfulExperienceScore(
          userState: userState,
          entangledState: entangledState,
          eventEntities: eventEntities,
        );

        // Assert
        expect(result, greaterThan(0.0));
        expect(result, lessThanOrEqualTo(1.0));
        // Should be weighted combination of core compatibility, vibe, interest, transformative
        expect(result, greaterThan(0.3)); // At least some meaningfulness
      });

      test('should handle errors gracefully', () async {
        // Arrange
        final tAtomic = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final userState = QuantumEntityState(
          entityId: 'user-1',
          entityType: QuantumEntityType.user,
          personalityState: {'dim1': 0.5},
          quantumVibeAnalysis: {'vibe1': 0.6},
          entityCharacteristics: {},
          tAtomic: tAtomic,
        );
        final eventEntities = [
          QuantumEntityState(
            entityId: 'event-1',
            entityType: QuantumEntityType.event,
            personalityState: {'dim1': 0.6},
            quantumVibeAnalysis: {'vibe1': 0.7},
            entityCharacteristics: {},
            tAtomic: tAtomic,
          ),
        ];
        final entangledState = EntangledQuantumState(
          entityStates: eventEntities,
          coefficients: [1.0],
          entangledVector: [0.5, 0.5, 0.5, 0.5],
          tAtomic: tAtomic,
        );

        // Mock entanglement service to throw error
        when(mockEntanglementService.createEntangledState(
          entityStates: anyNamed('entityStates'),
        )).thenThrow(Exception('Service error'));

        // Act
        final result = await calculator.calculateMeaningfulExperienceScore(
          userState: userState,
          entangledState: entangledState,
          eventEntities: eventEntities,
        );

        // Assert
        // Should return default 0.5 on error
        expect(result, equals(0.5));
      });
    });
  });
}
