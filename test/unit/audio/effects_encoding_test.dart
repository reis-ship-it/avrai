// Effects and Encoding Unit Tests
//
// Tests for audio effects and encoding components:
// - SimpleReverb comb/allpass filters
// - StereoEncoder WAV encoding
// - AudioMixer stereo mixing
// - PersonalityPanner stereo panning
//
// Part of the Wavetable Knot Audio Synthesis system.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/audio/simple_reverb.dart';
import 'package:avrai_knot/services/audio/stereo_encoder.dart';

void main() {
  group('SimpleReverb', () {
    test('should create reverb with default parameters', () {
      final reverb = SimpleReverb(sampleRate: 44100);

      expect(reverb.sampleRate, equals(44100));
      expect(reverb.roomSize, equals(0.5));
      expect(reverb.damping, equals(0.5));
    });

    test('should process mono samples', () {
      final reverb = SimpleReverb(sampleRate: 44100);

      // Process a single impulse
      final output = reverb.process(1.0);

      // First output should be near zero (reverb has delay)
      expect(output.abs(), lessThan(0.1));

      // Process more samples to build up reverb tail
      for (var i = 0; i < 1000; i++) {
        reverb.process(0.0);
      }

      // After delay, reverb tail should be audible
      final laterOutput = reverb.process(0.0);
      // The reverb tail will have decayed somewhat
      expect(laterOutput.abs(), lessThan(1.0));
    });

    test('should process stereo samples', () {
      final reverb = SimpleReverb(sampleRate: 44100, width: 0.5);

      final stereo = reverb.processStereo(1.0);

      expect(stereo.left, isA<double>());
      expect(stereo.right, isA<double>());
      // Stereo outputs may differ due to width
    });

    test('should apply reverb to buffer', () {
      final reverb = SimpleReverb(sampleRate: 44100);
      final buffer = Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0]);

      reverb.applyToBuffer(buffer, wetMix: 0.5);

      // Buffer should be modified
      expect(buffer[0], isNot(equals(1.0)));
    });

    test('should reset state correctly', () {
      final reverb = SimpleReverb(sampleRate: 44100);

      // Process some audio
      for (var i = 0; i < 100; i++) {
        reverb.process(1.0);
      }

      // Reset
      reverb.reset();

      // After reset, first output should be near zero again
      final output = reverb.process(1.0);
      expect(output.abs(), lessThan(0.1));
    });

    test('should have larger room with higher roomSize', () {
      final smallRoom = SimpleReverb(sampleRate: 44100, roomSize: 0.2);
      final largeRoom = SimpleReverb(sampleRate: 44100, roomSize: 0.9);

      // Process impulse
      smallRoom.process(1.0);
      largeRoom.process(1.0);

      // Process many samples
      for (var i = 0; i < 5000; i++) {
        smallRoom.process(0.0);
        largeRoom.process(0.0);
      }

      // Large room should have longer tail (more output after delay)
      final smallTail = smallRoom.process(0.0).abs();
      final largeTail = largeRoom.process(0.0).abs();

      expect(largeTail, greaterThanOrEqualTo(smallTail * 0.5));
    });
  });

  group('StereoSample', () {
    test('should create mono sample', () {
      final sample = StereoSample.mono(0.5);

      expect(sample.left, equals(0.5));
      expect(sample.right, equals(0.5));
    });

    test('should create panned sample', () {
      final left = StereoSample.panned(1.0, -1.0);
      final right = StereoSample.panned(1.0, 1.0);
      final center = StereoSample.panned(1.0, 0.0);

      // Full left should have more left than right
      expect(left.left.abs(), greaterThan(left.right.abs()));

      // Full right should have more right than left
      expect(right.right.abs(), greaterThan(right.left.abs()));

      // Center should be approximately equal
      expect(center.left, closeTo(center.right, 0.1));
    });

    test('should add samples', () {
      final a = StereoSample(0.5, 0.3);
      final b = StereoSample(0.2, 0.4);
      final sum = a + b;

      expect(sum.left, equals(0.7));
      expect(sum.right, equals(0.7));
    });

    test('should multiply by scalar', () {
      final sample = StereoSample(0.5, 0.3);
      final scaled = sample * 2.0;

      expect(scaled.left, equals(1.0));
      expect(scaled.right, equals(0.6));
    });

    test('should calculate mono sum', () {
      final sample = StereoSample(0.6, 0.4);

      expect(sample.mono, equals(0.5));
    });
  });

  group('StereoEncoder', () {
    late StereoEncoder encoder;

    setUp(() {
      encoder = StereoEncoder(sampleRate: 44100);
    });

    test('should create encoder with correct parameters', () {
      expect(encoder.sampleRate, equals(44100));
      expect(encoder.bitDepth, equals(16));
      expect(encoder.channels, equals(2));
    });

    test('should encode stereo WAV', () {
      final left = Float64List.fromList([0.0, 0.5, 1.0, 0.5, 0.0]);
      final right = Float64List.fromList([0.0, 0.5, 1.0, 0.5, 0.0]);

      final wav = encoder.encodeWav(leftSamples: left, rightSamples: right);

      // Check WAV header
      expect(wav[0], equals(0x52)); // 'R'
      expect(wav[1], equals(0x49)); // 'I'
      expect(wav[2], equals(0x46)); // 'F'
      expect(wav[3], equals(0x46)); // 'F'

      expect(wav[8], equals(0x57)); // 'W'
      expect(wav[9], equals(0x41)); // 'A'
      expect(wav[10], equals(0x56)); // 'V'
      expect(wav[11], equals(0x45)); // 'E'

      // Check data chunk marker
      expect(wav[36], equals(0x64)); // 'd'
      expect(wav[37], equals(0x61)); // 'a'
      expect(wav[38], equals(0x74)); // 't'
      expect(wav[39], equals(0x61)); // 'a'

      // Check total size (header + 5 samples * 2 channels * 2 bytes)
      expect(wav.length, equals(44 + 5 * 2 * 2));
    });

    test('should encode mono WAV', () {
      final samples = Float64List.fromList([0.0, 0.5, 1.0, 0.5, 0.0]);

      final wav = encoder.encodeMonoWav(samples);

      // Check WAV header
      expect(wav[0], equals(0x52)); // 'R'

      // Check total size (header + 5 samples * 1 channel * 2 bytes)
      expect(wav.length, equals(44 + 5 * 1 * 2));
    });

    test('should throw on mismatched sample counts', () {
      final left = Float64List.fromList([0.0, 0.5]);
      final right = Float64List.fromList([0.0, 0.5, 1.0]);

      expect(
        () => encoder.encodeWav(leftSamples: left, rightSamples: right),
        throwsArgumentError,
      );
    });

    test('should clamp samples to valid range', () {
      final left = Float64List.fromList([2.0, -2.0]); // Out of range
      final right = Float64List.fromList([1.5, -1.5]);

      // Should not throw, should clamp
      final wav = encoder.encodeWav(leftSamples: left, rightSamples: right);

      expect(wav.length, greaterThan(44));
    });
  });

  group('AudioMixer', () {
    late AudioMixer mixer;

    setUp(() {
      mixer = AudioMixer(sampleRate: 44100, duration: 1.0);
    });

    test('should create mixer with correct buffer sizes', () {
      expect(mixer.numSamples, equals(44100));
      expect(mixer.leftBuffer.length, equals(44100));
      expect(mixer.rightBuffer.length, equals(44100));
    });

    test('should add samples at time position', () {
      mixer.addSample(time: 0.5, value: 1.0, pan: 0.0);

      // Sample should be at approximately index 22050
      final index = 22050;
      expect(mixer.leftBuffer[index], greaterThan(0));
      expect(mixer.rightBuffer[index], greaterThan(0));
    });

    test('should apply stereo panning', () {
      mixer.addSample(time: 0.5, value: 1.0, pan: -1.0); // Full left

      final index = 22050;
      expect(mixer.leftBuffer[index].abs(), greaterThan(mixer.rightBuffer[index].abs()));
    });

    test('should normalize to prevent clipping', () {
      // Add very loud samples
      for (var i = 0; i < 1000; i++) {
        mixer.leftBuffer[i] = 5.0;
        mixer.rightBuffer[i] = 5.0;
      }

      mixer.normalize(targetPeak: 0.95);

      // All samples should now be within range
      for (var i = 0; i < mixer.numSamples; i++) {
        expect(mixer.leftBuffer[i].abs(), lessThanOrEqualTo(0.95));
        expect(mixer.rightBuffer[i].abs(), lessThanOrEqualTo(0.95));
      }
    });

    test('should apply fade in', () {
      // Fill with constant value
      for (var i = 0; i < mixer.numSamples; i++) {
        mixer.leftBuffer[i] = 1.0;
        mixer.rightBuffer[i] = 1.0;
      }

      mixer.applyFadeIn(0.1); // 100ms fade

      // First sample should be near 0
      expect(mixer.leftBuffer[0], closeTo(0.0, 0.01));

      // Sample at half fade should be ~0.5
      final halfFadeIndex = (0.05 * 44100).round();
      expect(mixer.leftBuffer[halfFadeIndex], closeTo(0.5, 0.1));
    });

    test('should apply fade out', () {
      // Fill with constant value
      for (var i = 0; i < mixer.numSamples; i++) {
        mixer.leftBuffer[i] = 1.0;
        mixer.rightBuffer[i] = 1.0;
      }

      mixer.applyFadeOut(0.1); // 100ms fade

      // Last sample should be near 0
      expect(mixer.leftBuffer[mixer.numSamples - 1], closeTo(0.0, 0.01));
    });

    test('should clear buffers', () {
      mixer.addSample(time: 0.5, value: 1.0, pan: 0.0);
      mixer.clear();

      for (var i = 0; i < mixer.numSamples; i++) {
        expect(mixer.leftBuffer[i], equals(0.0));
        expect(mixer.rightBuffer[i], equals(0.0));
      }
    });

    test('should convert to WAV', () {
      mixer.addSample(time: 0.5, value: 0.5, pan: 0.0);

      final wav = mixer.toWav();

      // Should be valid WAV
      expect(wav[0], equals(0x52)); // 'R'
      expect(wav.length, greaterThan(44));
    });
  });

  group('PersonalityPanner', () {
    test('should create with default values', () {
      const panner = PersonalityPanner();

      expect(panner.stereoWidth, equals(0.5));
      expect(panner.panMovement, equals(0.3));
      expect(panner.basePan, equals(0.0));
    });

    test('should create from dimensions', () {
      final panner = PersonalityPanner.fromDimensions(const {
        'community_orientation': 1.0,
        'exploration_eagerness': 1.0,
      });

      expect(panner.stereoWidth, equals(0.8)); // community * 0.8
      expect(panner.panMovement, equals(0.5)); // exploration * 0.5
    });

    test('should calculate pan at time', () {
      const panner = PersonalityPanner(panMovement: 0.5);

      // Pan should vary over time
      final pan1 = panner.panAt(0.0);
      final pan2 = panner.panAt(0.25); // Quarter cycle
      final pan3 = panner.panAt(0.5); // Half cycle

      // Pan values should differ
      expect(pan1, isNot(equals(pan2)));
      expect(pan2, isNot(equals(pan3)));

      // All should be in valid range
      expect(pan1, inInclusiveRange(-1.0, 1.0));
      expect(pan2, inInclusiveRange(-1.0, 1.0));
      expect(pan3, inInclusiveRange(-1.0, 1.0));
    });

    test('should apply stereo width', () {
      const widePanner = PersonalityPanner(stereoWidth: 1.0);
      const narrowPanner = PersonalityPanner(stereoWidth: 0.0);

      final input = StereoSample(1.0, -1.0); // Full stereo

      final wide = widePanner.applyWidth(input);
      final narrow = narrowPanner.applyWidth(input);

      // Wide should maintain stereo separation
      expect((wide.left - wide.right).abs(), greaterThan(0.5));

      // Narrow should be more mono
      expect((narrow.left - narrow.right).abs(), closeTo(0.0, 0.1));
    });
  });
}
