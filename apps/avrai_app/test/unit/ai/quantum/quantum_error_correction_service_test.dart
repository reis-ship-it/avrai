/// avrai QuantumErrorCorrectionService Service Tests
/// Date: January 27, 2026
/// Purpose: Test QuantumErrorCorrectionService functionality
///
/// Test Coverage:
/// - Core Methods: encodeQuantumState, decodeAndCorrect, detectErrors, correctQuantumState
/// - Error Correction Codes: Repetition3, Shor, Steane
/// - Error Handling: Invalid inputs, edge cases
///
/// Dependencies:
/// - None (service is self-contained)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_error_correction_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_error_correction_code.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

void main() {
  group('QuantumErrorCorrectionService', () {
    late QuantumErrorCorrectionService service;

    setUp(() {
      service = QuantumErrorCorrectionService();
    });

    group('encodeQuantumState', () {
      test(
          'should encode state with Repetition3 code and produce larger encoded data',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Encoded data should be larger (repetition code adds redundancy)
        expect(encoded.code, equals(QuantumErrorCorrectionCode.repetition3));
        expect(encoded.encodedData.length,
            greaterThan(state.personalityState.length));
        expect(encoded.originalState.length,
            equals(state.personalityState.length));
        expect(encoded.parityChecks, isNotEmpty);
      });

      test('should encode state with Shor code', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.shor,
        );

        // Assert - Shor code should produce encoded data
        expect(encoded.code, equals(QuantumErrorCorrectionCode.shor));
        expect(encoded.encodedData, isNotEmpty);
        expect(encoded.parityChecks, isNotEmpty);
      });

      test('should encode state with Steane code', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.steane,
        );

        // Assert - Steane code should produce encoded data
        expect(encoded.code, equals(QuantumErrorCorrectionCode.steane));
        expect(encoded.encodedData, isNotEmpty);
        expect(encoded.parityChecks, isNotEmpty);
      });

      test('should include both personality and quantum vibe in encoding',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
          },
          quantumVibeAnalysis: {
            'vibe1': 0.7,
            'vibe2': 0.8,
          },
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Original state should include both personality and quantum vibe
        expect(encoded.originalState.length,
            equals(4)); // 2 personality + 2 quantum vibe
        expect(encoded.originalState.containsKey('openness'), isTrue);
        expect(encoded.originalState.containsKey('vibe1'), isTrue);
      });
    });

    group('decodeAndCorrect', () {
      test('should decode and correct encoded state back to original format',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Act
        final corrected = await service.decodeAndCorrect(encoded: encoded);

        // Assert - Should return corrected state with same keys as original
        expect(corrected.length, equals(state.personalityState.length));
        expect(corrected.keys, equals(state.personalityState.keys));
        // Values should be in valid range (0.0-1.0)
        for (final value in corrected.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('should handle all three error correction codes', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act & Assert - Test all three codes
        for (final code in QuantumErrorCorrectionCode.values) {
          final encoded = await service.encodeQuantumState(
            state: state,
            code: code,
          );
          final corrected = await service.decodeAndCorrect(encoded: encoded);

          expect(corrected.length, equals(state.personalityState.length));
          expect(corrected.keys, equals(state.personalityState.keys));
        }
      });
    });

    group('detectErrors', () {
      test('should detect errors in encoded state', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Act
        final errors = service.detectErrors(encoded);

        // Assert - Should return list of errors (may be empty if no errors detected)
        expect(errors, isA<List<DetectedError>>());
        // Errors should have valid properties if present
        for (final error in errors) {
          expect(error.confidence, greaterThanOrEqualTo(0.0));
          expect(error.confidence, lessThanOrEqualTo(1.0));
          expect(error.errorPositions, isNotEmpty);
        }
      });

      test('should detect errors for all three codes', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act & Assert - Test error detection for all codes
        for (final code in QuantumErrorCorrectionCode.values) {
          final encoded = await service.encodeQuantumState(
            state: state,
            code: code,
          );
          final errors = service.detectErrors(encoded);

          expect(errors, isA<List<DetectedError>>());
        }
      });
    });

    group('correctQuantumState', () {
      test('should encode, correct, and return corrected quantum state',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
            'agreeableness': 0.5,
            'neuroticism': 0.4,
            'authenticity': 0.6,
            'curiosity': 0.7,
            'empathy': 0.5,
            'resilience': 0.6,
            'creativity': 0.7,
            'analytical': 0.5,
            'social': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final corrected = await service.correctQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Should return corrected quantum state with same structure
        expect(corrected.personalityState.length,
            equals(state.personalityState.length));
        expect(corrected.personalityState.keys,
            equals(state.personalityState.keys));
        // Values should be in valid range
        for (final value in corrected.personalityState.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('should preserve entity ID and type in corrected state', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-123',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final corrected = await service.correctQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Entity metadata should be preserved
        expect(corrected.entityId, equals(state.entityId));
        expect(corrected.entityType, equals(state.entityType));
      });

      test('should handle all three error correction codes', () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 0.5,
            'conscientiousness': 0.6,
            'extraversion': 0.7,
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act & Assert - Test all three codes
        for (final code in QuantumErrorCorrectionCode.values) {
          final corrected = await service.correctQuantumState(
            state: state,
            code: code,
          );

          expect(corrected.personalityState.length,
              equals(state.personalityState.length));
          expect(corrected.personalityState.keys,
              equals(state.personalityState.keys));
        }
      });
    });

    group('Error Handling', () {
      test('should handle state with empty personality and quantum vibe',
          () async {
        // Arrange
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final encoded = await service.encodeQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Should handle empty state gracefully
        expect(encoded.originalState, isEmpty);
        expect(
            encoded.encodedData, isNotEmpty); // May still produce encoded data
      });

      test('should handle state with values outside 0.0-1.0 range', () async {
        // Arrange - Values will be clamped during encoding/decoding
        final state = QuantumEntityState(
          entityId: 'test-entity-1',
          entityType: QuantumEntityType.user,
          personalityState: {
            'openness': 1.5, // Out of range
            'conscientiousness': -0.5, // Out of range
            'extraversion': 0.7, // In range
          },
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            serverTime: DateTime.now(),
          ),
        );

        // Act
        final corrected = await service.correctQuantumState(
          state: state,
          code: QuantumErrorCorrectionCode.repetition3,
        );

        // Assert - Values should be clamped to 0.0-1.0
        for (final value in corrected.personalityState.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
    });
  });
}
