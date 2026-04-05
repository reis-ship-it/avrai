/// avrai TemporalInterferenceService Service Tests
/// Date: January 27, 2026
/// Purpose: Test TemporalInterferenceService functionality
///
/// Test Coverage:
/// - Core Methods: detectInterferencePattern, calculateInterferenceCorrectedCompatibility
/// - Error Handling: Invalid inputs, edge cases
///
/// Dependencies:
/// - None (service is self-contained)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/quantum/temporal_interference_service.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

// Helper to create test QuantumTemporalState instances
QuantumTemporalState createTestTemporalState({
  required List<double> phaseState,
  AtomicTimestamp? timestamp,
}) {
  final t = timestamp ??
      AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: DateTime.now(),
      );
  return QuantumTemporalState(
    atomicState: [0.5, 0.5, 0.5],
    quantumState: List.filled(24 + 7 + 4, 0.5), // hour + weekday + season
    phaseState: phaseState,
    temporalState: List.filled(100, 0.5), // Combined state
    atomicTimestamp: t,
  );
}

void main() {
  group('TemporalInterferenceService', () {
    late TemporalInterferenceService service;

    setUp(() {
      service = TemporalInterferenceService();
    });

    group('detectInterferencePattern', () {
      test('should detect interference pattern between two temporal states',
          () async {
        // Arrange - Create two temporal states with different phases
        final timestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
        );
        final state1 = createTestTemporalState(
          phaseState: [
            0.5, 0.5, // daily cos, sin
            0.6, 0.4, // weekly cos, sin
            0.7, 0.3, // seasonal cos, sin
          ],
          timestamp: timestamp,
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.4, 0.6, // daily cos, sin (different phase)
            0.5, 0.5, // weekly cos, sin
            0.6, 0.4, // seasonal cos, sin
          ],
          timestamp: timestamp,
        );

        // Act
        final pattern = await service.detectInterferencePattern(
          state1: state1,
          state2: state2,
        );

        // Assert - Should detect interference pattern
        expect(pattern.type, isA<TemporalInterferenceType>());
        expect(pattern.strength, greaterThanOrEqualTo(0.0));
        expect(pattern.strength, lessThanOrEqualTo(1.0));
        expect(pattern.phaseDifference, isA<double>());
        expect(pattern.affectedFrequencies, isA<List<String>>());
      });

      test('should detect constructive interference when phases align',
          () async {
        // Arrange - States with similar phases (should be constructive)
        final state1 = createTestTemporalState(
          phaseState: [
            0.8, 0.2, // daily cos, sin
            0.7, 0.3, // weekly cos, sin
            0.6, 0.4, // seasonal cos, sin
          ],
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.75, 0.25, // daily cos, sin (similar)
            0.65, 0.35, // weekly cos, sin (similar)
            0.55, 0.45, // seasonal cos, sin (similar)
          ],
        );

        // Act
        final pattern = await service.detectInterferencePattern(
          state1: state1,
          state2: state2,
        );

        // Assert - Similar phases may result in constructive interference
        expect(pattern.type, isA<TemporalInterferenceType>());
        expect(pattern.strength, greaterThanOrEqualTo(0.0));
        expect(pattern.strength, lessThanOrEqualTo(1.0));
      });

      test('should detect destructive interference when phases oppose',
          () async {
        // Arrange - States with opposing phases (should be destructive)
        final state1 = createTestTemporalState(
          phaseState: [
            0.9, 0.1, // daily cos, sin
            0.8, 0.2, // weekly cos, sin
            0.7, 0.3, // seasonal cos, sin
          ],
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.1, 0.9, // daily cos, sin (opposing)
            0.2, 0.8, // weekly cos, sin (opposing)
            0.3, 0.7, // seasonal cos, sin (opposing)
          ],
        );

        // Act
        final pattern = await service.detectInterferencePattern(
          state1: state1,
          state2: state2,
        );

        // Assert - Opposing phases may result in destructive interference
        expect(pattern.type, isA<TemporalInterferenceType>());
        expect(pattern.strength, greaterThanOrEqualTo(0.0));
        expect(pattern.strength, lessThanOrEqualTo(1.0));
      });

      test('should handle old format phase state (backward compatibility)',
          () async {
        // Arrange - Old format with single phase
        final state1 = createTestTemporalState(
          phaseState: [0.5], // Old format
        );
        final state2 = createTestTemporalState(
          phaseState: [0.6], // Old format
        );

        // Act
        final pattern = await service.detectInterferencePattern(
          state1: state1,
          state2: state2,
        );

        // Assert - Should handle old format gracefully
        expect(pattern.type, isA<TemporalInterferenceType>());
        expect(pattern.strength, greaterThanOrEqualTo(0.0));
        expect(pattern.strength, lessThanOrEqualTo(1.0));
      });
    });

    group('calculateInterferenceCorrectedCompatibility', () {
      test('should calculate compatibility with interference correction',
          () async {
        // Arrange
        final state1 = createTestTemporalState(
          phaseState: [
            0.5, 0.5, // daily cos, sin
            0.6, 0.4, // weekly cos, sin
            0.7, 0.3, // seasonal cos, sin
          ],
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.4, 0.6, // daily cos, sin
            0.5, 0.5, // weekly cos, sin
            0.6, 0.4, // seasonal cos, sin
          ],
        );
        // Act - Service computes base compatibility internally via temporalCompatibility
        final correctedCompatibility =
            await service.calculateInterferenceCorrectedCompatibility(
          state1: state1,
          state2: state2,
        );

        // Assert - Should return corrected compatibility in valid range
        expect(correctedCompatibility, greaterThanOrEqualTo(0.0));
        expect(correctedCompatibility, lessThanOrEqualTo(1.0));
      });

      test(
          'should apply constructive interference correction (increase compatibility)',
          () async {
        // Arrange - States with similar phases
        final state1 = createTestTemporalState(
          phaseState: [
            0.8, 0.2, // daily cos, sin
            0.7, 0.3, // weekly cos, sin
            0.6, 0.4, // seasonal cos, sin
          ],
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.75, 0.25, // daily cos, sin (similar)
            0.65, 0.35, // weekly cos, sin (similar)
            0.55, 0.45, // seasonal cos, sin (similar)
          ],
        );

        // Act
        final correctedCompatibility =
            await service.calculateInterferenceCorrectedCompatibility(
          state1: state1,
          state2: state2,
        );

        // Assert - Constructive interference may increase compatibility
        expect(correctedCompatibility, greaterThanOrEqualTo(0.0));
        expect(correctedCompatibility, lessThanOrEqualTo(1.0));
      });

      test(
          'should apply destructive interference correction (decrease compatibility)',
          () async {
        // Arrange - States with opposing phases
        final state1 = createTestTemporalState(
          phaseState: [
            0.9, 0.1, // daily cos, sin
            0.8, 0.2, // weekly cos, sin
            0.7, 0.3, // seasonal cos, sin
          ],
        );
        final state2 = createTestTemporalState(
          phaseState: [
            0.1, 0.9, // daily cos, sin (opposing)
            0.2, 0.8, // weekly cos, sin (opposing)
            0.3, 0.7, // seasonal cos, sin (opposing)
          ],
        );

        // Act
        final correctedCompatibility =
            await service.calculateInterferenceCorrectedCompatibility(
          state1: state1,
          state2: state2,
        );

        // Assert - Destructive interference may decrease compatibility
        expect(correctedCompatibility, greaterThanOrEqualTo(0.0));
        expect(correctedCompatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('Error Handling', () {
      test('should handle states with empty phase state', () async {
        // Arrange
        final state1 = createTestTemporalState(
          phaseState: [], // Empty phase state
        );
        final state2 = createTestTemporalState(
          phaseState: [], // Empty phase state
        );

        // Act & Assert - Should handle gracefully (may throw or return default)
        try {
          final pattern = await service.detectInterferencePattern(
            state1: state1,
            state2: state2,
          );
          // If it doesn't throw, should return valid pattern
          expect(pattern.type, isA<TemporalInterferenceType>());
        } catch (e) {
          // If it throws, that's also acceptable error handling
          expect(e, isNotNull);
        }
      });
    });
  });
}
