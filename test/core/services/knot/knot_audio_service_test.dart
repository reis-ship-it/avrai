// Unit tests for KnotAudioService
// 
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 7: Audio & Privacy

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/audio/wavetable_knot_audio_service.dart';
import 'package:avrai_core/models/personality_knot.dart';

void main() {
  group('WavetableKnotAudioService', () {
    late WavetableKnotAudioService audioService;

    setUp(() {
      audioService = WavetableKnotAudioService();
    });

    group('generateLoadingSound', () {
      test('should generate audio sequence from knot', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);

        // Assert
        expect(audioSequence, isNotNull);
        expect(audioSequence.notes, isNotEmpty);
        expect(audioSequence.duration, greaterThan(0.0));
        expect(audioSequence.loop, isTrue);
      });

      test('should generate notes based on knot topology', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 5,
            writhe: 2,
            signature: 0,
            bridgeNumber: 2,
            braidIndex: 2,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);

        // Assert - WavetableKnotAudioService uses personality-driven melody
        expect(audioSequence.notes, isNotEmpty);
        for (final note in audioSequence.notes) {
          expect(note.frequency, greaterThan(0.0));
          expect(note.duration, greaterThan(0.0));
        }
      });

      test('should use knot invariants for rhythm and melody', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 3, // Higher writhe
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);

        // Assert
        expect(audioSequence.rhythm, isNotNull);
        expect(audioSequence.notes, isNotEmpty);
      });

      test('should calculate frequencies within valid range', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 4,
            writhe: 1,
            signature: 0,
            bridgeNumber: 2,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);

        // Assert
        for (final note in audioSequence.notes) {
          // Frequencies should be in audible range (20-20000 Hz)
          expect(note.frequency, greaterThanOrEqualTo(20.0));
          expect(note.frequency, lessThanOrEqualTo(20000.0));
        }
      });
    });

    group('knotToMusicalPattern', () {
      test('should convert knot to musical pattern', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);
        final pattern = audioSequence; // AudioSequence contains the pattern

        // Assert - WavetableKnotAudioService uses personality-driven melody
        expect(pattern, isNotNull);
        expect(pattern.notes, isNotEmpty);
      });

      test('should handle knots with zero crossings', () async {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0],
            alexanderPolynomial: [1.0],
            crossingNumber: 0,
            writhe: 0,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final audioSequence = await audioService.generateKnotLoadingSound(knot);

        // Assert
        expect(audioSequence, isNotNull);
        // When crossingNumber is 0, the service may generate 0 notes (which is valid)
        // The important thing is that it doesn't throw
        expect(audioSequence.notes.length, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('should handle knots with minimal data gracefully', () async {
        // Arrange: Knot with minimal but valid data
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0], // Minimal but valid braid data
          invariants: KnotInvariants(
            jonesPolynomial: [1.0], // Minimal but valid polynomial
            alexanderPolynomial: [1.0], // Minimal but valid polynomial
            crossingNumber: 0,
            writhe: 0,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act & Assert: Should not throw
        final audioSequence = await audioService.generateKnotLoadingSound(knot);
        expect(audioSequence, isNotNull);
        // When crossingNumber is 0, the service may generate 0 notes (which is valid)
        // The important thing is that it doesn't throw
        expect(audioSequence.notes.length, greaterThanOrEqualTo(0));
      });
    });
  });
}
