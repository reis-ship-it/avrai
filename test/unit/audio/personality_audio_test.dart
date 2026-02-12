// Personality Audio Unit Tests
//
// Tests for personality-driven audio components:
// - PersonalityAudioParams dimension mapping
// - PersonalityEnvelope ADSR generation
// - MusicalScales mode selection
// - PersonalityWavetableFactory wavetable generation
//
// Part of the Wavetable Knot Audio Synthesis system.

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/audio/personality_audio_params.dart';
import 'package:avrai_knot/models/audio/personality_envelope.dart';
import 'package:avrai_knot/models/audio/musical_scales.dart';
import 'package:avrai_knot/services/audio/personality_wavetable_factory.dart';

void main() {
  group('PersonalityAudioParams', () {
    group('fromDimensions', () {
      test('should create params from empty dimensions with defaults', () {
        final params = PersonalityAudioParams.fromDimensions(const {});

        // All dimensions default to 0.5
        expect(params.voiceCount, equals(4)); // 1 + 0.5 * 5 = 3.5 → rounds to 4
        expect(params.tempo, equals(120.0)); // 60 + 0.5 * 120 = 120
        expect(params.harmonicCount, equals(14)); // 4 + 0.5 * 20 = 14
      });

      test('should map exploration_eagerness to frequency range', () {
        final lowExploration = PersonalityAudioParams.fromDimensions(
          const {'exploration_eagerness': 0.0},
        );
        final highExploration = PersonalityAudioParams.fromDimensions(
          const {'exploration_eagerness': 1.0},
        );

        expect(lowExploration.frequencyRange, equals(200.0));
        expect(highExploration.frequencyRange, equals(1000.0));
      });

      test('should map community_orientation to voice count', () {
        final lowCommunity = PersonalityAudioParams.fromDimensions(
          const {'community_orientation': 0.0},
        );
        final highCommunity = PersonalityAudioParams.fromDimensions(
          const {'community_orientation': 1.0},
        );

        expect(lowCommunity.voiceCount, equals(1));
        expect(highCommunity.voiceCount, equals(6));
      });

      test('should map energy_preference to tempo', () {
        final lowEnergy = PersonalityAudioParams.fromDimensions(
          const {'energy_preference': 0.0},
        );
        final highEnergy = PersonalityAudioParams.fromDimensions(
          const {'energy_preference': 1.0},
        );

        expect(lowEnergy.tempo, equals(60.0));
        expect(highEnergy.tempo, equals(180.0));
      });

      test('should map value_orientation to harmonic count', () {
        final lowValue = PersonalityAudioParams.fromDimensions(
          const {'value_orientation': 0.0},
        );
        final highValue = PersonalityAudioParams.fromDimensions(
          const {'value_orientation': 1.0},
        );

        expect(lowValue.harmonicCount, equals(4));
        expect(highValue.harmonicCount, equals(24));
      });

      test('should map trust_network_reliance to consonance', () {
        final lowTrust = PersonalityAudioParams.fromDimensions(
          const {'trust_network_reliance': 0.0},
        );
        final highTrust = PersonalityAudioParams.fromDimensions(
          const {'trust_network_reliance': 1.0},
        );

        expect(lowTrust.consonanceRatio, equals(0.5));
        expect(highTrust.consonanceRatio, equals(0.9));
      });

      test('should map authenticity_preference to vibrato', () {
        final lowAuth = PersonalityAudioParams.fromDimensions(
          const {'authenticity_preference': 0.0},
        );
        final highAuth = PersonalityAudioParams.fromDimensions(
          const {'authenticity_preference': 1.0},
        );

        // Low authenticity (< 0.3) disables vibrato
        expect(lowAuth.vibratoFrequency, equals(0.0));
        expect(highAuth.vibratoFrequency, greaterThan(0));
        expect(highAuth.vibratoDepth, greaterThan(0));
      });
    });

    group('Presets', () {
      test('energeticSocial should create high-energy params', () {
        final params = PersonalityAudioParams.fromDimensions(
          PersonalityAudioPresets.energeticSocial,
        );

        expect(params.tempo, greaterThan(150)); // High energy
        expect(params.voiceCount, greaterThan(4)); // High community
      });

      test('calmIntrospective should create low-energy params', () {
        final params = PersonalityAudioParams.fromDimensions(
          PersonalityAudioPresets.calmIntrospective,
        );

        expect(params.tempo, lessThan(90)); // Low energy
        expect(params.voiceCount, lessThanOrEqualTo(3)); // Low community (0.3)
      });
    });

    group('createSignature', () {
      test('should create consistent signature for same dimensions', () {
        final dims = {'exploration_eagerness': 0.7, 'energy_preference': 0.3};
        final sig1 = PersonalityAudioParams.createSignature(dims);
        final sig2 = PersonalityAudioParams.createSignature(dims);

        expect(sig1, equals(sig2));
      });

      test('should create different signatures for different dimensions', () {
        final sig1 = PersonalityAudioParams.createSignature(
          const {'exploration_eagerness': 0.7},
        );
        final sig2 = PersonalityAudioParams.createSignature(
          const {'exploration_eagerness': 0.3},
        );

        expect(sig1, isNot(equals(sig2)));
      });
    });

    group('Derived properties', () {
      test('should calculate attack time from energy', () {
        final lowEnergy = PersonalityAudioParams.fromDimensions(
          const {'energy_preference': 0.0},
        );
        final highEnergy = PersonalityAudioParams.fromDimensions(
          const {'energy_preference': 1.0},
        );

        // Low energy = slow attack
        expect(lowEnergy.attackTime, greaterThan(highEnergy.attackTime));
      });
    });
  });

  group('PersonalityEnvelope', () {
    group('Factory constructors', () {
      test('should create envelope from params', () {
        final params = PersonalityAudioParams.fromDimensions(const {});
        final envelope = PersonalityEnvelope.fromParams(params);

        expect(envelope.attack, greaterThan(0));
        expect(envelope.decay, greaterThan(0));
        expect(envelope.sustain, inInclusiveRange(0.0, 1.0));
        expect(envelope.release, greaterThan(0));
      });

      test('should create punchy envelope', () {
        final envelope = PersonalityEnvelope.punchy();

        expect(envelope.attack, lessThan(0.05));
        expect(envelope.sustain, lessThan(0.5));
      });

      test('should create pad envelope', () {
        final envelope = PersonalityEnvelope.pad();

        expect(envelope.attack, greaterThan(0.2));
        expect(envelope.release, greaterThan(0.5));
      });
    });

    group('valueAt', () {
      test('should return 0 at time 0 (before attack completes)', () {
        final envelope = PersonalityEnvelope.defaults();
        // At time 0, we're at the start of attack
        expect(envelope.valueAt(0, 1.0), equals(0.0));
      });

      test('should peak at end of attack phase', () {
        final envelope = PersonalityEnvelope.defaults();
        // At exactly attack time, should be near peak
        final atAttack = envelope.valueAt(envelope.attack, 1.0);
        expect(atAttack, closeTo(1.0, 0.1));
      });

      test('should reach sustain level after decay', () {
        final envelope = PersonalityEnvelope.defaults();
        final afterDecay = envelope.valueAt(
          envelope.attack + envelope.decay + 0.01,
          2.0, // Long note
        );
        expect(afterDecay, closeTo(envelope.sustain, 0.05));
      });

      test('should fade to 0 at end of note', () {
        final envelope = PersonalityEnvelope.defaults();
        final noteLength = 1.0;
        expect(envelope.valueAt(noteLength, noteLength), closeTo(0.0, 0.1));
      });
    });

    group('valueAtSustained', () {
      test('should hold at sustain level indefinitely', () {
        final envelope = PersonalityEnvelope.defaults();
        final longTime = 100.0;
        final value = envelope.valueAtSustained(longTime);
        expect(value, equals(envelope.sustain));
      });
    });
  });

  group('MultiStageEnvelope', () {
    test('should create birth harmony envelope', () {
      final envelope = MultiStageEnvelope.birthHarmony();

      expect(envelope.totalDuration, equals(60.0));
      expect(envelope.stages.length, equals(5));

      // Check phase timing
      expect(envelope.stages[0].name, equals('transition'));
      expect(envelope.stages[1].name, equals('void'));
      expect(envelope.stages[2].name, equals('emergence'));
      expect(envelope.stages[3].name, equals('formation'));
      expect(envelope.stages[4].name, equals('harmony'));
    });

    test('should return correct value in each phase', () {
      final envelope = MultiStageEnvelope.birthHarmony();

      // Transition phase (0-5s)
      expect(envelope.stageNameAt(2.5), equals('transition'));

      // Void phase (5-10s)
      expect(envelope.stageNameAt(7.5), equals('void'));

      // Emergence phase (10-25s)
      expect(envelope.stageNameAt(17.5), equals('emergence'));

      // Formation phase (25-45s)
      expect(envelope.stageNameAt(35.0), equals('formation'));

      // Harmony phase (45-60s)
      expect(envelope.stageNameAt(52.5), equals('harmony'));
    });

    test('should calculate morph position correctly', () {
      final envelope = MultiStageEnvelope.birthHarmony();

      expect(envelope.morphPositionAt(0), equals(0.0));
      expect(envelope.morphPositionAt(30), equals(0.5));
      expect(envelope.morphPositionAt(60), equals(1.0));
    });
  });

  group('MusicalScales', () {
    group('selectMode', () {
      test('should select lydian for high exploration + adventure', () {
        final mode = MusicalScales.selectMode(const {
          'exploration_eagerness': 0.8,
          'location_adventurousness': 0.8,
        });

        expect(mode, equals(MusicalMode.lydian));
      });

      test('should select mixolydian for high energy', () {
        final mode = MusicalScales.selectMode(const {
          'energy_preference': 0.8,
        });

        expect(mode, equals(MusicalMode.mixolydian));
      });

      test('should select ionian for high trust', () {
        final mode = MusicalScales.selectMode(const {
          'trust_network_reliance': 0.8,
        });

        expect(mode, equals(MusicalMode.ionian));
      });

      test('should select aeolian for low trust', () {
        final mode = MusicalScales.selectMode(const {
          'trust_network_reliance': 0.2,
        });

        expect(mode, equals(MusicalMode.aeolian));
      });

      test('should select phrygian for high novelty', () {
        final mode = MusicalScales.selectMode(const {
          'novelty_seeking': 0.8,
        });

        expect(mode, equals(MusicalMode.phrygian));
      });

      test('should select locrian for high novelty + low trust', () {
        final mode = MusicalScales.selectMode(const {
          'novelty_seeking': 0.9,
          'trust_network_reliance': 0.2,
        });

        expect(mode, equals(MusicalMode.locrian));
      });

      test('should select dorian for balanced personality', () {
        final mode = MusicalScales.selectMode(const {});
        expect(mode, equals(MusicalMode.dorian));
      });
    });

    group('getChordRatios', () {
      test('should return correct triad ratios', () {
        final ratios = MusicalScales.getChordRatios(
          mode: MusicalMode.ionian,
          chordType: 'triad',
        );

        expect(ratios.length, equals(3));
        expect(ratios[0], equals(1.0)); // Root
        expect(ratios[1], closeTo(1.26, 0.01)); // Major third
        expect(ratios[2], closeTo(1.498, 0.01)); // Perfect fifth
      });

      test('should return seventh chord ratios', () {
        final ratios = MusicalScales.getChordRatios(
          mode: MusicalMode.ionian,
          chordType: 'seventh',
        );

        expect(ratios.length, equals(4));
      });

      test('should return power chord ratios', () {
        final ratios = MusicalScales.getChordRatios(
          mode: MusicalMode.ionian,
          chordType: 'power',
        );

        expect(ratios.length, equals(2));
        expect(ratios[0], equals(1.0)); // Root
        expect(ratios[1], closeTo(1.498, 0.01)); // Fifth
      });
    });

    group('degreeToFrequency', () {
      test('should return correct frequencies for scale degrees', () {
        // A3 = 220Hz
        final root = MusicalScales.degreeToFrequency(
          baseFrequency: 220.0,
          degree: 0,
          mode: MusicalMode.ionian,
        );
        expect(root, equals(220.0));

        // Octave = 2x frequency
        final octave = MusicalScales.degreeToFrequency(
          baseFrequency: 220.0,
          degree: 0,
          mode: MusicalMode.ionian,
          octaveOffset: 1,
        );
        expect(octave, equals(440.0));
      });
    });

    group('generateScale', () {
      test('should generate correct number of notes', () {
        final scale = MusicalScales.generateScale(
          baseFrequency: 220.0,
          mode: MusicalMode.ionian,
          octaves: 1,
        );

        expect(scale.length, equals(8)); // 7 notes + octave
      });

      test('should generate ascending frequencies', () {
        final scale = MusicalScales.generateScale(
          baseFrequency: 220.0,
          mode: MusicalMode.ionian,
          octaves: 1,
        );

        for (var i = 1; i < scale.length; i++) {
          expect(scale[i], greaterThan(scale[i - 1]));
        }
      });
    });
  });

  group('ChordBuilder', () {
    test('should build deterministic chords', () {
      final builder = ChordBuilder(
        baseFrequency: 220.0,
        mode: MusicalMode.ionian,
      );

      final triad = builder.buildDeterministicChord(3);
      expect(triad.length, equals(3));
      expect(triad[0], equals(220.0));

      final seventh = builder.buildDeterministicChord(4);
      expect(seventh.length, equals(4));
    });

    test('should create from dimensions', () {
      final builder = ChordBuilder.fromDimensions(
        const {'trust_network_reliance': 0.8},
        baseFrequency: 220.0,
      );

      expect(builder.mode, equals(MusicalMode.ionian));
      expect(builder.consonanceRatio, closeTo(0.82, 0.01));
    });
  });

  group('PersonalityWavetableFactory', () {
    late PersonalityWavetableFactory factory;

    setUp(() {
      factory = PersonalityWavetableFactory();
    });

    tearDown(() {
      factory.clearCache();
    });

    test('should create wavetable set from dimensions', () {
      final set = factory.createWavetableSet(const {});

      expect(set.tableCount, equals(16));
      expect(set.tables[0].size, equals(2048));
    });

    test('should cache wavetable sets', () {
      final dims = {'exploration_eagerness': 0.7};

      final set1 = factory.createWavetableSet(dims);
      final set2 = factory.createWavetableSet(dims);

      // Should be the same cached instance
      expect(identical(set1, set2), isTrue);
      expect(factory.cacheSize, equals(1));
    });

    test('should evict old entries when cache is full', () {
      // Fill the cache
      for (var i = 0; i < 15; i++) {
        factory.createWavetableSet({'exploration_eagerness': i / 20.0});
      }

      // Cache should be limited to maxCacheSize
      expect(factory.cacheSize, lessThanOrEqualTo(10));
    });

    test('should generate wavetables with correct morph progression', () {
      final set = factory.createWavetableSet(const {});

      // Early wavetables should be simpler (fewer harmonics)
      // Later wavetables should be richer
      final earlyTable = set.tables[0];
      final lateTable = set.tables[15];

      // Both should have valid samples
      expect(earlyTable.samples.every((s) => s.abs() <= 1.0), isTrue);
      expect(lateTable.samples.every((s) => s.abs() <= 1.0), isTrue);
    });

    test('should create different wavetables for different personalities', () {
      final calm = factory.createWavetableSet(
        PersonalityAudioPresets.calmIntrospective,
      );
      factory.clearCache(); // Clear to force regeneration
      final energetic = factory.createWavetableSet(
        PersonalityAudioPresets.energeticSocial,
      );

      // Should have different signatures
      expect(calm.personalitySignature, isNot(equals(energetic.personalitySignature)));
    });
  });

  group('WavetablePresets', () {
    late PersonalityWavetableFactory factory;

    setUp(() {
      factory = PersonalityWavetableFactory();
    });

    tearDown(() {
      factory.clearCache();
    });

    test('should create birth harmony set', () {
      final set = WavetablePresets.createBirthHarmonySet(factory, const {});
      expect(set.tableCount, equals(16));
    });

    test('should create formation set', () {
      final set = WavetablePresets.createFormationSet(factory, const {});
      expect(set.tableCount, equals(16));
    });

    test('should create loading set', () {
      final set = WavetablePresets.createLoadingSet(factory, const {});
      expect(set.tableCount, equals(16));
    });
  });
}
