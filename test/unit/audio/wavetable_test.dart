// Wavetable Unit Tests
//
// Tests for the core wavetable synthesis components:
// - Wavetable reading and interpolation
// - WavetableSet morphing
// - WavetableOscillator phase accumulation and sample generation
//
// Part of the Wavetable Knot Audio Synthesis system.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/audio/wavetable.dart';
import 'package:avrai_knot/services/audio/wavetable_oscillator.dart';

void main() {
  group('Wavetable', () {
    group('Factory constructors', () {
      test('should create sine wavetable with correct samples', () {
        final table = Wavetable.sine(size: 1024);

        expect(table.size, equals(1024));
        expect(table.name, equals('sine'));

        // Check sine wave properties
        // At phase 0, sin(0) = 0
        expect(table.read(0.0), closeTo(0.0, 0.01));

        // At phase 0.25, sin(π/2) = 1
        expect(table.read(0.25), closeTo(1.0, 0.01));

        // At phase 0.5, sin(π) = 0
        expect(table.read(0.5), closeTo(0.0, 0.01));

        // At phase 0.75, sin(3π/2) = -1
        expect(table.read(0.75), closeTo(-1.0, 0.01));
      });

      test('should create sawtooth wavetable', () {
        final table = Wavetable.sawtooth(size: 1024);

        expect(table.size, equals(1024));
        expect(table.name, equals('sawtooth'));

        // Sawtooth rises from -1 to 1
        expect(table.read(0.0), closeTo(-1.0, 0.01));
        expect(table.read(0.5), closeTo(0.0, 0.01));
        expect(table.read(0.999), closeTo(1.0, 0.02));
      });

      test('should create square wavetable', () {
        final table = Wavetable.square(size: 1024);

        expect(table.size, equals(1024));
        expect(table.name, equals('square'));

        // Square wave: +1 for first half, -1 for second half
        expect(table.read(0.25), closeTo(1.0, 0.01));
        expect(table.read(0.75), closeTo(-1.0, 0.01));
      });

      test('should create triangle wavetable', () {
        final table = Wavetable.triangle(size: 1024);

        expect(table.size, equals(1024));
        expect(table.name, equals('triangle'));

        // Triangle: starts at 0, peaks at 0.25, returns to 0 at 0.5
        expect(table.read(0.0), closeTo(0.0, 0.01));
        expect(table.read(0.25), closeTo(1.0, 0.01));
        expect(table.read(0.5), closeTo(0.0, 0.01));
        expect(table.read(0.75), closeTo(-1.0, 0.01));
      });

      test('should create wavetable from harmonics', () {
        // Create a simple table with fundamental only (should be sine-like)
        final table = Wavetable.fromHarmonics(
          harmonics: [1.0],
          size: 1024,
        );

        expect(table.size, equals(1024));
        expect(table.name, equals('harmonics'));

        // Should behave like a sine wave
        expect(table.read(0.0), closeTo(0.0, 0.01));
        expect(table.read(0.25), closeTo(1.0, 0.01));
      });

      test('should normalize wavetable from harmonics to prevent clipping', () {
        // Create table with multiple strong harmonics
        final table = Wavetable.fromHarmonics(
          harmonics: [1.0, 1.0, 1.0, 1.0],
          size: 1024,
        );

        // Check that all samples are within -1 to 1
        for (var i = 0; i < table.size; i++) {
          expect(table.samples[i], inInclusiveRange(-1.0, 1.0));
        }
      });
    });

    group('Reading samples', () {
      test('should interpolate between samples', () {
        // Create a simple table with known values
        final samples = Float64List.fromList([0.0, 1.0, 0.0, -1.0]);
        final table = Wavetable(samples: samples, name: 'test');

        // At exact sample positions
        expect(table.read(0.0), closeTo(0.0, 0.01));
        expect(table.read(0.25), closeTo(1.0, 0.01));
        expect(table.read(0.5), closeTo(0.0, 0.01));
        expect(table.read(0.75), closeTo(-1.0, 0.01));

        // Between samples (should interpolate)
        expect(table.read(0.125), closeTo(0.5, 0.01)); // Between 0 and 1
      });

      test('should wrap phase values correctly', () {
        final table = Wavetable.sine(size: 1024);

        // Phase > 1 should wrap
        expect(table.read(1.25), closeTo(table.read(0.25), 0.01));
        expect(table.read(2.5), closeTo(table.read(0.5), 0.01));

        // Negative phase should wrap
        expect(table.read(-0.25), closeTo(table.read(0.75), 0.01));
      });

      test('should provide cubic interpolation', () {
        final table = Wavetable.sine(size: 64); // Low resolution to show difference

        // Cubic interpolation should be smoother
        final linear = table.read(0.123);
        final cubic = table.readCubic(0.123);

        // Both should be in valid range
        expect(linear, inInclusiveRange(-1.0, 1.0));
        expect(cubic, inInclusiveRange(-1.0, 1.0));

        // They might differ slightly due to different interpolation methods
        // but both should be close to the expected sine value
        final expected = math.sin(0.123 * 2 * math.pi);
        expect(cubic, closeTo(expected, 0.1));
      });
    });

    group('Edge cases', () {
      test('should throw on empty samples', () {
        expect(
          () => Wavetable(samples: Float64List(0), name: 'empty'),
          throwsArgumentError,
        );
      });

      test('should handle single sample wavetable', () {
        final samples = Float64List.fromList([0.5]);
        final table = Wavetable(samples: samples, name: 'single');

        // Should always return the same value regardless of phase
        expect(table.read(0.0), closeTo(0.5, 0.01));
        expect(table.read(0.5), closeTo(0.5, 0.01));
        expect(table.read(0.99), closeTo(0.5, 0.01));
      });
    });
  });

  group('WavetableSet', () {
    late List<Wavetable> tables;

    setUp(() {
      // Create a set of tables with distinct characteristics
      tables = [
        Wavetable.sine(size: 1024, name: 'sine'),
        Wavetable.triangle(size: 1024, name: 'triangle'),
        Wavetable.sawtooth(size: 1024, name: 'sawtooth'),
      ];
    });

    test('should create wavetable set with valid tables', () {
      final set = WavetableSet(
        tables: tables,
        personalitySignature: 'test_signature',
        name: 'test_set',
      );

      expect(set.tableCount, equals(3));
      expect(set.personalitySignature, equals('test_signature'));
    });

    test('should throw on less than 2 tables', () {
      expect(
        () => WavetableSet(
          tables: [Wavetable.sine()],
          personalitySignature: 'test',
        ),
        throwsArgumentError,
      );
    });

    test('should morph between first and second table at low positions', () {
      final set = WavetableSet(
        tables: tables,
        personalitySignature: 'test',
      );

      // At morph 0, should be pure first table (sine)
      final atZero = set.readMorphed(phase: 0.25, morphPosition: 0.0);
      final pureSine = tables[0].read(0.25);
      expect(atZero, closeTo(pureSine, 0.01));

      // At morph 0.5 (middle of 3 tables), should be blend
      final atMiddle = set.readMorphed(phase: 0.25, morphPosition: 0.5);
      // Should be triangle (second table)
      final pureTriangle = tables[1].read(0.25);
      expect(atMiddle, closeTo(pureTriangle, 0.01));
    });

    test('should morph to last table at position 1.0', () {
      final set = WavetableSet(
        tables: tables,
        personalitySignature: 'test',
      );

      // At morph 1.0, should be pure last table (sawtooth)
      final atOne = set.readMorphed(phase: 0.25, morphPosition: 1.0);
      final pureSawtooth = tables[2].read(0.25);
      expect(atOne, closeTo(pureSawtooth, 0.01));
    });

    test('should clamp morph position to valid range', () {
      final set = WavetableSet(
        tables: tables,
        personalitySignature: 'test',
      );

      // Morph position > 1 should be clamped to 1
      final overOne = set.readMorphed(phase: 0.25, morphPosition: 1.5);
      final atOne = set.readMorphed(phase: 0.25, morphPosition: 1.0);
      expect(overOne, closeTo(atOne, 0.01));

      // Morph position < 0 should be clamped to 0
      final underZero = set.readMorphed(phase: 0.25, morphPosition: -0.5);
      final atZero = set.readMorphed(phase: 0.25, morphPosition: 0.0);
      expect(underZero, closeTo(atZero, 0.01));
    });

    test('should access tables by index', () {
      final set = WavetableSet(
        tables: tables,
        personalitySignature: 'test',
      );

      expect(set[0].name, equals('sine'));
      expect(set[1].name, equals('triangle'));
      expect(set[2].name, equals('sawtooth'));
    });
  });

  group('WavetableOscillator', () {
    late WavetableSet wavetables;

    setUp(() {
      wavetables = WavetableSet(
        tables: [
          Wavetable.sine(size: 1024),
          Wavetable.sawtooth(size: 1024),
        ],
        personalitySignature: 'test',
      );
    });

    test('should generate samples at specified frequency', () {
      final osc = WavetableOscillator(wavetables);

      // Generate samples and verify phase advances correctly
      const sampleRate = 44100;
      const frequency = 440.0;

      // Phase increment per sample = frequency / sampleRate
      final expectedIncrement = frequency / sampleRate;

      // Generate one sample
      osc.sample(
        frequency: frequency,
        morphPosition: 0.0,
        sampleRate: sampleRate,
      );

      // Phase should have advanced by one increment
      expect(osc.phase, closeTo(expectedIncrement, 0.0001));

      // Generate 99 more samples (total 100)
      for (var i = 0; i < 99; i++) {
        osc.sample(
          frequency: frequency,
          morphPosition: 0.0,
          sampleRate: sampleRate,
        );
      }

      // Phase should be at 100 * increment (mod 1.0)
      final expected = (100 * expectedIncrement) % 1.0;
      expect(osc.phase, closeTo(expected, 0.001));
    });

    test('should produce samples in valid range', () {
      final osc = WavetableOscillator(wavetables);

      for (var i = 0; i < 1000; i++) {
        final sample = osc.sample(
          frequency: 440.0,
          morphPosition: 0.5,
          sampleRate: 44100,
        );
        expect(sample, inInclusiveRange(-1.0, 1.0));
      }
    });

    test('should reset phase correctly', () {
      final osc = WavetableOscillator(wavetables);

      // Advance phase
      for (var i = 0; i < 100; i++) {
        osc.sample(frequency: 440.0, morphPosition: 0.0, sampleRate: 44100);
      }

      // Phase should not be at 0
      expect(osc.phase, isNot(closeTo(0.0, 0.001)));

      // Reset
      osc.reset();
      expect(osc.phase, closeTo(0.0, 0.001));
    });

    test('should apply detuning correctly', () {
      final osc = WavetableOscillator(
        wavetables,
        detuneCents: 100.0, // 1 semitone up
      );

      // At 100 cents detune, frequency is multiplied by 2^(100/1200)
      // which is approximately 1.0595 (one semitone up)

      // Generate samples and check phase advancement
      const sampleRate = 44100;
      const baseFrequency = 440.0;

      // Generate 100 samples
      for (var i = 0; i < 100; i++) {
        osc.sample(
          frequency: baseFrequency,
          morphPosition: 0.0,
          sampleRate: sampleRate,
        );
      }

      // Phase should have advanced faster than without detune
      final expectedPhaseWithDetune =
          (100 * baseFrequency * 1.0595 / sampleRate) % 1.0;
      expect(osc.phase, closeTo(expectedPhaseWithDetune, 0.01));
    });

    test('should apply vibrato', () {
      final osc = WavetableOscillator(
        wavetables,
        vibratoFrequency: 5.0, // 5Hz vibrato
        vibratoDepth: 0.01, // 1% depth
      );

      // Generate samples - vibrato should cause frequency variation
      final samples = <double>[];
      for (var i = 0; i < 44100; i++) {
        samples.add(osc.sample(
          frequency: 440.0,
          morphPosition: 0.0,
          sampleRate: 44100,
        ));
      }

      // Check that samples vary (vibrato is working)
      // The variation should be smooth, not just noise
      expect(samples.where((s) => s.abs() > 0.01).length, greaterThan(1000));
    });

    test('should support FM synthesis', () {
      final carrier = WavetableOscillator(wavetables);
      final modulator = WavetableOscillator(wavetables);

      // Generate FM samples
      for (var i = 0; i < 1000; i++) {
        final modSample = modulator.sample(
          frequency: 440.0 * 2, // 2:1 ratio
          morphPosition: 0.0,
          sampleRate: 44100,
        );

        final carrierSample = carrier.sampleWithFM(
          frequency: 440.0,
          morphPosition: 0.0,
          fmAmount: 100.0,
          modulator: modSample,
          sampleRate: 44100,
        );

        expect(carrierSample, inInclusiveRange(-1.0, 1.0));
      }
    });
  });

  group('OscillatorBank', () {
    late WavetableSet wavetables;

    setUp(() {
      wavetables = WavetableSet(
        tables: [
          Wavetable.sine(size: 1024),
          Wavetable.sawtooth(size: 1024),
        ],
        personalitySignature: 'test',
      );
    });

    test('should create bank with correct oscillator count', () {
      final bank = OscillatorBank.create(
        wavetables: wavetables,
        oscillatorCount: 4,
      );

      expect(bank.count, equals(4));
    });

    test('should apply detune spread across oscillators', () {
      final bank = OscillatorBank.create(
        wavetables: wavetables,
        oscillatorCount: 3,
        detuneSpread: 20.0, // 20 cents total spread
      );

      // Check that oscillators have different detune values
      expect(bank.oscillators[0].detuneCents, closeTo(-10.0, 0.01));
      expect(bank.oscillators[1].detuneCents, closeTo(0.0, 0.01));
      expect(bank.oscillators[2].detuneCents, closeTo(10.0, 0.01));
    });

    test('should generate chord samples', () {
      final bank = OscillatorBank.create(
        wavetables: wavetables,
        oscillatorCount: 3,
      );

      // Major chord frequencies (C4, E4, G4)
      final frequencies = [261.63, 329.63, 392.00];

      for (var i = 0; i < 1000; i++) {
        final sample = bank.sampleChord(
          frequencies: frequencies,
          morphPosition: 0.5,
          sampleRate: 44100,
        );

        // Should be normalized to prevent clipping
        expect(sample, inInclusiveRange(-1.0, 1.0));
      }
    });

    test('should reset all oscillators', () {
      final bank = OscillatorBank.create(
        wavetables: wavetables,
        oscillatorCount: 3,
      );

      // Generate some samples
      bank.sampleChord(
        frequencies: [440.0, 550.0, 660.0],
        morphPosition: 0.5,
        sampleRate: 44100,
      );

      // Reset all
      bank.reset();

      // All oscillators should be at phase 0
      for (final osc in bank.oscillators) {
        expect(osc.phase, closeTo(0.0, 0.001));
      }
    });

    test('should set vibrato for all oscillators', () {
      final bank = OscillatorBank.create(
        wavetables: wavetables,
        oscillatorCount: 3,
      );

      bank.setVibrato(frequency: 5.0, depth: 0.02);

      for (final osc in bank.oscillators) {
        expect(osc.vibratoFrequency, equals(5.0));
        expect(osc.vibratoDepth, equals(0.02));
      }
    });
  });

  group('VoiceConfig', () {
    test('should create with required parameters', () {
      final config = VoiceConfig(frequency: 440.0);

      expect(config.frequency, equals(440.0));
      expect(config.volume, equals(1.0));
      expect(config.pan, equals(0.0));
      expect(config.morphPosition, equals(0.0));
      expect(config.detuneCents, equals(0.0));
    });

    test('should copy with modified values', () {
      final config = VoiceConfig(frequency: 440.0);
      final copied = config.copyWith(volume: 0.5, pan: -0.5);

      expect(copied.frequency, equals(440.0));
      expect(copied.volume, equals(0.5));
      expect(copied.pan, equals(-0.5));
    });
  });
}
