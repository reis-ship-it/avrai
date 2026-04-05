// Wavetable Knot Audio Service Unit Tests
//
// Tests for wavetable synthesis components that don't require
// the full service (avoiding platform dependencies).
//
// Part of the Wavetable Knot Audio Synthesis system.

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

void main() {
  group('Wavetable Audio Service Components', () {
    group('Wavetable Generation Quality', () {
      test('factory should create 16 wavetables', () {
        final factory = PersonalityWavetableFactory();
        final wavetables = factory.createDefaultWavetableSet();

        expect(wavetables.tableCount, equals(16));
        expect(wavetables.tables[0].size, equals(2048));
      });

      test('personality presets should create distinct wavetables', () {
        final factory = PersonalityWavetableFactory();

        final calmSet = factory.createWavetableSet({
          'energy_preference': 0.1,
          'community_orientation': 0.2,
        });

        factory.clearCache();

        final energeticSet = factory.createWavetableSet({
          'energy_preference': 0.9,
          'community_orientation': 0.9,
        });

        expect(calmSet.personalitySignature,
            isNot(equals(energeticSet.personalitySignature)));
      });

      test('wavetables should have valid samples', () {
        final factory = PersonalityWavetableFactory();
        final wavetables = factory.createDefaultWavetableSet();

        for (final table in wavetables.tables) {
          for (var i = 0; i < table.size; i++) {
            expect(table.samples[i], inInclusiveRange(-1.0, 1.0));
          }
        }
      });
    });

    group('Audio Params for all 12 Dimensions', () {
      test('should create params for all dimension combinations', () {
        // Test with all 12 dimensions set
        final fullDimensions = {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
          'authenticity_preference': 0.8,
          'social_discovery_style': 0.5,
          'temporal_flexibility': 0.4,
          'location_adventurousness': 0.9,
          'curation_tendency': 0.3,
          'trust_network_reliance': 0.7,
          'energy_preference': 0.6,
          'novelty_seeking': 0.8,
          'value_orientation': 0.5,
          'crowd_tolerance': 0.4,
        };

        final params = PersonalityAudioParams.fromDimensions(fullDimensions);

        expect(params.voiceCount, greaterThan(0));
        expect(params.tempo, greaterThan(0));
        expect(params.harmonicCount, greaterThan(0));
        expect(params.frequencyRange, greaterThan(0));
      });
    });

    group('Birth Harmony Envelope', () {
      test('should have 5 phases', () {
        final envelope = MultiStageEnvelope.birthHarmony();

        expect(envelope.stages.length, equals(5));
        expect(envelope.totalDuration, equals(60.0));
      });

      test('phases should cover full duration', () {
        final envelope = MultiStageEnvelope.birthHarmony();

        expect(envelope.stages.first.startTime, equals(0.0));
        expect(envelope.stages.last.endTime, equals(60.0));
      });

      test('morph position should progress linearly', () {
        final envelope = MultiStageEnvelope.birthHarmony();

        expect(envelope.morphPositionAt(0), equals(0.0));
        expect(envelope.morphPositionAt(30), equals(0.5));
        expect(envelope.morphPositionAt(60), equals(1.0));
      });
    });

    group('Mode Selection', () {
      test('should select appropriate modes for different personalities', () {
        // Test various personality profiles
        final explorerMode = MusicalScales.selectMode({
          'exploration_eagerness': 0.9,
          'location_adventurousness': 0.8,
        });
        expect(explorerMode, equals(MusicalMode.lydian));

        final trustingMode = MusicalScales.selectMode({
          'trust_network_reliance': 0.9,
        });
        expect(trustingMode, equals(MusicalMode.ionian));

        final energeticMode = MusicalScales.selectMode({
          'energy_preference': 0.9,
        });
        expect(energeticMode, equals(MusicalMode.mixolydian));
      });
    });

    group('Audio Encoding', () {
      test('should encode valid WAV header', () {
        final mixer = AudioMixer(sampleRate: 44100, duration: 1.0);

        // Add some test samples
        mixer.addSample(time: 0.5, value: 0.5, pan: 0.0);

        final wav = mixer.toWav();

        // Check RIFF header
        expect(wav[0], equals(0x52)); // 'R'
        expect(wav[1], equals(0x49)); // 'I'
        expect(wav[2], equals(0x46)); // 'F'
        expect(wav[3], equals(0x46)); // 'F'

        // Check WAVE format
        expect(wav[8], equals(0x57)); // 'W'
        expect(wav[9], equals(0x41)); // 'A'
        expect(wav[10], equals(0x56)); // 'V'
        expect(wav[11], equals(0x45)); // 'E'
      });
    });

    group('Preset Wavetables', () {
      test('should create birth harmony set', () {
        final factory = PersonalityWavetableFactory();
        final set = WavetablePresets.createBirthHarmonySet(factory, const {});
        expect(set.tableCount, equals(16));
      });

      test('should create formation set', () {
        final factory = PersonalityWavetableFactory();
        final set = WavetablePresets.createFormationSet(factory, const {});
        expect(set.tableCount, equals(16));
      });

      test('should create loading set', () {
        final factory = PersonalityWavetableFactory();
        final set = WavetablePresets.createLoadingSet(factory, const {});
        expect(set.tableCount, equals(16));
      });
    });
  });
}
