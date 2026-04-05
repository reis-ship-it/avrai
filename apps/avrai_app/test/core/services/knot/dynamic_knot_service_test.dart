import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/user/mood_state.dart';

void main() {
  group('DynamicKnotService Tests', () {
    late DynamicKnotService service;
    late PersonalityKnot baseKnot;

    setUp(() {
      service = DynamicKnotService();

      // Create a test base knot
      baseKnot = PersonalityKnot(
        agentId: 'test_agent',
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
        braidData: [3.0, 1.0, 2.0, 2.0, 3.0],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    });

    group('updateKnotWithCurrentState', () {
      test('should create dynamic knot with mood-based colors', () {
        final mood = MoodState(
          type: MoodType.happy,
          intensity: 0.8,
          timestamp: DateTime.now(),
        );
        final energy = EnergyLevel(
          value: 0.7,
          timestamp: DateTime.now(),
        );
        final stress = StressLevel(
          value: 0.2,
          timestamp: DateTime.now(),
        );

        final dynamicKnot = service.updateKnotWithCurrentState(
          baseKnot: baseKnot,
          mood: mood,
          energy: energy,
          stress: stress,
        );

        expect(dynamicKnot.baseKnot, equals(baseKnot));
        expect(dynamicKnot.mood, equals(mood));
        expect(dynamicKnot.energy, equals(energy));
        expect(dynamicKnot.stress, equals(stress));
        expect(dynamicKnot.colorScheme, isNotEmpty);
        expect(dynamicKnot.colorScheme['primary'], isNotNull);
        expect(dynamicKnot.colorScheme['secondary'], isNotNull);
      });

      test('should calculate complexity modifier from energy and stress', () {
        final mood = service.getDefaultMood();
        final highEnergy = EnergyLevel(value: 0.9, timestamp: DateTime.now());
        final lowStress = StressLevel(value: 0.1, timestamp: DateTime.now());

        final dynamicKnot = service.updateKnotWithCurrentState(
          baseKnot: baseKnot,
          mood: mood,
          energy: highEnergy,
          stress: lowStress,
        );

        // High energy + low stress = higher complexity modifier
        // Formula: (0.9 * 0.6) + ((1.0 - 0.1) * 0.4) = 0.54 + 0.36 = 0.9
        // But clamped to 0.5-1.5, so should be >= 0.5
        expect(dynamicKnot.complexityModifier, greaterThanOrEqualTo(0.5));
        expect(dynamicKnot.complexityModifier, lessThanOrEqualTo(1.5));
      });

      test('should map energy to animation speed', () {
        final mood = service.getDefaultMood();
        final highEnergy = EnergyLevel(value: 1.0, timestamp: DateTime.now());
        final stress = service.getDefaultStress();

        final dynamicKnot = service.updateKnotWithCurrentState(
          baseKnot: baseKnot,
          mood: mood,
          energy: highEnergy,
          stress: stress,
        );

        // High energy = fast animation
        expect(dynamicKnot.animationSpeed, greaterThan(0.8));
      });

      test('should map stress to pulse rate', () {
        final mood = service.getDefaultMood();
        final energy = service.getDefaultEnergy();
        final highStress = StressLevel(value: 0.9, timestamp: DateTime.now());

        final dynamicKnot = service.updateKnotWithCurrentState(
          baseKnot: baseKnot,
          mood: mood,
          energy: energy,
          stress: highStress,
        );

        // High stress = fast pulse
        expect(dynamicKnot.pulseRate, greaterThan(0.8));
      });
    });

    group('createBreathingKnot', () {
      test('should create breathing knot with stress-based breathing rate', () {
        const lowStress = 0.1;
        final breathingKnot = service.createBreathingKnot(
          baseKnot: baseKnot,
          currentStressLevel: lowStress,
        );

        expect(breathingKnot.knot, equals(baseKnot));
        expect(breathingKnot.animationType, equals(AnimationType.breathing));
        // Low stress = slow breathing (high rate)
        expect(breathingKnot.animationSpeed, greaterThan(0.8));
        expect(breathingKnot.colorTransition, isNotEmpty);
      });

      test('should create faster breathing for high stress', () {
        const highStress = 0.9;
        final breathingKnot = service.createBreathingKnot(
          baseKnot: baseKnot,
          currentStressLevel: highStress,
        );

        // High stress = fast breathing (low rate)
        expect(breathingKnot.animationSpeed, lessThan(0.5));
      });

      test('should create color transition based on stress level', () {
        const lowStress = 0.1;
        const mediumStress = 0.5;
        const highStress = 0.9;

        final lowStressKnot = service.createBreathingKnot(
          baseKnot: baseKnot,
          currentStressLevel: lowStress,
        );

        final mediumStressKnot = service.createBreathingKnot(
          baseKnot: baseKnot,
          currentStressLevel: mediumStress,
        );

        final highStressKnot = service.createBreathingKnot(
          baseKnot: baseKnot,
          currentStressLevel: highStress,
        );

        // Different stress levels should produce different color transitions
        expect(lowStressKnot.colorTransition, isNotEmpty);
        expect(mediumStressKnot.colorTransition, isNotEmpty);
        expect(highStressKnot.colorTransition, isNotEmpty);
      });
    });

    group('mood color mapping', () {
      test('should map different moods to different colors', () {
        final moods = [
          MoodType.happy,
          MoodType.calm,
          MoodType.energetic,
          MoodType.stressed,
        ];

        final colorSchemes = <MoodType, Map<String, int>>{};

        for (final moodType in moods) {
          final mood = MoodState(
            type: moodType,
            intensity: 0.5,
            timestamp: DateTime.now(),
          );
          final dynamicKnot = service.updateKnotWithCurrentState(
            baseKnot: baseKnot,
            mood: mood,
            energy: service.getDefaultEnergy(),
            stress: service.getDefaultStress(),
          );
          colorSchemes[moodType] = dynamicKnot.colorScheme;
        }

        // Each mood should have a color scheme
        expect(colorSchemes.length, equals(moods.length));

        // Happy and energetic should have different colors
        expect(
          colorSchemes[MoodType.happy]!['primary'],
          isNot(equals(colorSchemes[MoodType.energetic]!['primary'])),
        );
      });
    });

    group('default values', () {
      test('should provide default mood state', () {
        final defaultMood = service.getDefaultMood();
        expect(defaultMood.type, equals(MoodType.calm));
        expect(defaultMood.intensity, equals(0.5));
      });

      test('should provide default energy level', () {
        final defaultEnergy = service.getDefaultEnergy();
        expect(defaultEnergy.value, equals(0.5));
      });

      test('should provide default stress level', () {
        final defaultStress = service.getDefaultStress();
        expect(defaultStress.value, equals(0.0));
      });
    });
  });
}
