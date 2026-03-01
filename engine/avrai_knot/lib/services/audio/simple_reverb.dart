// Simple Reverb
//
// Freeverb-style reverb effect for adding space and depth to audio.
// Based on the Schroeder reverberator architecture.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:typed_data';

/// A simple Freeverb-style reverb effect.
///
/// Uses parallel comb filters followed by series allpass filters
/// to create a natural-sounding reverberation effect.
///
/// **Usage:**
/// ```dart
/// final reverb = SimpleReverb(
///   sampleRate: 44100,
///   roomSize: 0.7,
///   damping: 0.5,
/// );
///
/// for (var i = 0; i < buffer.length; i++) {
///   final wet = reverb.process(buffer[i]);
///   buffer[i] = buffer[i] * (1 - mix) + wet * mix;
/// }
/// ```
class SimpleReverb {
  /// Sample rate in Hz.
  final int sampleRate;

  /// Room size (0.0 = small, 1.0 = large).
  final double roomSize;

  /// Damping amount (0.0 = bright, 1.0 = dark).
  final double damping;

  /// Stereo width (0.0 = mono, 1.0 = wide).
  final double width;

  late final List<_CombFilter> _combFiltersL;
  late final List<_CombFilter> _combFiltersR;
  late final List<_AllpassFilter> _allpassFiltersL;
  late final List<_AllpassFilter> _allpassFiltersR;

  /// Creates a reverb effect.
  ///
  /// [sampleRate] is the audio sample rate (typically 44100).
  /// [roomSize] controls the size of the virtual room (0.0 to 1.0).
  /// [damping] controls high-frequency absorption (0.0 to 1.0).
  /// [width] controls stereo spread (0.0 to 1.0).
  SimpleReverb({
    required this.sampleRate,
    this.roomSize = 0.5,
    this.damping = 0.5,
    this.width = 0.5,
  }) {
    // Scale delay times for sample rate
    final scaleFactor = sampleRate / 44100.0;

    // Comb filter delay times (in samples at 44100Hz)
    // These are tuned to avoid flutter echoes
    final combDelays = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];

    // Allpass filter delay times
    final allpassDelays = [556, 441, 341, 225];

    // Calculate feedback based on room size
    final feedback = 0.84 * (0.28 + roomSize * 0.7);

    // Calculate damping factor
    final damp = damping * 0.4;

    // Create left channel filters
    _combFiltersL = combDelays.map((delay) {
      return _CombFilter(
        size: (delay * scaleFactor).round(),
        feedback: feedback,
        damping: damp,
      );
    }).toList();

    _allpassFiltersL = allpassDelays.map((delay) {
      return _AllpassFilter(size: (delay * scaleFactor).round());
    }).toList();

    // Create right channel filters with slightly different delays for width
    final stereoOffset = (23 * scaleFactor).round();
    _combFiltersR = combDelays.map((delay) {
      return _CombFilter(
        size: (delay * scaleFactor).round() + stereoOffset,
        feedback: feedback,
        damping: damp,
      );
    }).toList();

    _allpassFiltersR = allpassDelays.map((delay) {
      return _AllpassFilter(size: (delay * scaleFactor).round() + stereoOffset);
    }).toList();
  }

  /// Processes a mono sample and returns a stereo pair.
  ///
  /// [input] is the input sample (-1.0 to 1.0).
  /// Returns a [StereoSample] with left and right channels.
  StereoSample processStereo(double input) {
    // Process through parallel comb filters
    var outputL = 0.0;
    var outputR = 0.0;

    for (final comb in _combFiltersL) {
      outputL += comb.process(input);
    }
    for (final comb in _combFiltersR) {
      outputR += comb.process(input);
    }

    // Normalize
    outputL /= _combFiltersL.length;
    outputR /= _combFiltersR.length;

    // Process through series allpass filters
    for (final allpass in _allpassFiltersL) {
      outputL = allpass.process(outputL);
    }
    for (final allpass in _allpassFiltersR) {
      outputR = allpass.process(outputR);
    }

    // Apply stereo width
    final mid = (outputL + outputR) * 0.5;
    final side = (outputL - outputR) * 0.5;

    outputL = mid + side * width;
    outputR = mid - side * width;

    return StereoSample(outputL, outputR);
  }

  /// Processes a mono sample and returns a mono output.
  double process(double input) {
    final stereo = processStereo(input);
    return (stereo.left + stereo.right) * 0.5;
  }

  /// Applies reverb to a buffer in-place.
  ///
  /// [buffer] is the audio buffer to process.
  /// [wetMix] is the amount of reverb (0.0 = dry, 1.0 = wet).
  void applyToBuffer(Float64List buffer, {double wetMix = 0.3}) {
    final dryMix = 1.0 - wetMix;

    for (var i = 0; i < buffer.length; i++) {
      final dry = buffer[i];
      final wet = process(dry);
      buffer[i] = dry * dryMix + wet * wetMix;
    }
  }

  /// Applies stereo reverb to left and right buffers.
  void applyToStereoBuffers(
    Float64List leftBuffer,
    Float64List rightBuffer, {
    double wetMix = 0.3,
  }) {
    final dryMix = 1.0 - wetMix;
    final length = leftBuffer.length < rightBuffer.length
        ? leftBuffer.length
        : rightBuffer.length;

    for (var i = 0; i < length; i++) {
      final input = (leftBuffer[i] + rightBuffer[i]) * 0.5;
      final wet = processStereo(input);

      leftBuffer[i] = leftBuffer[i] * dryMix + wet.left * wetMix;
      rightBuffer[i] = rightBuffer[i] * dryMix + wet.right * wetMix;
    }
  }

  /// Resets the reverb state (clears delay lines).
  void reset() {
    for (final comb in _combFiltersL) {
      comb.reset();
    }
    for (final comb in _combFiltersR) {
      comb.reset();
    }
    for (final allpass in _allpassFiltersL) {
      allpass.reset();
    }
    for (final allpass in _allpassFiltersR) {
      allpass.reset();
    }
  }
}

/// A stereo sample pair.
class StereoSample {
  final double left;
  final double right;

  const StereoSample(this.left, this.right);

  /// Creates a centered (mono) sample.
  factory StereoSample.mono(double value) => StereoSample(value, value);

  /// Creates a panned sample.
  ///
  /// [pan] ranges from -1.0 (left) to 1.0 (right).
  factory StereoSample.panned(double value, double pan) {
    // Equal-power panning
    final angle = (pan + 1) * 0.25 * 3.14159265359;
    final left = value * _cos(angle);
    final right = value * _sin(angle);
    return StereoSample(left, right);
  }

  /// Adds two stereo samples.
  StereoSample operator +(StereoSample other) {
    return StereoSample(left + other.left, right + other.right);
  }

  /// Multiplies by a scalar.
  StereoSample operator *(double scalar) {
    return StereoSample(left * scalar, right * scalar);
  }

  /// Returns the mono sum.
  double get mono => (left + right) * 0.5;

  static double _cos(double x) {
    // Taylor series approximation
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24;
  }

  static double _sin(double x) {
    // Taylor series approximation
    final x2 = x * x;
    return x - x * x2 / 6 + x * x2 * x2 / 120;
  }
}

/// Internal comb filter implementation.
class _CombFilter {
  final Float64List _buffer;
  final double _feedback;
  final double _damping;
  int _index = 0;
  double _filterStore = 0.0;

  _CombFilter({
    required int size,
    required double feedback,
    required double damping,
  }) : _buffer = Float64List(size),
       _feedback = feedback,
       _damping = damping;

  double process(double input) {
    final output = _buffer[_index];

    // Apply damping (low-pass filter on feedback)
    _filterStore = output * (1 - _damping) + _filterStore * _damping;

    // Write to buffer with feedback
    _buffer[_index] = input + _filterStore * _feedback;

    // Advance index
    _index = (_index + 1) % _buffer.length;

    return output;
  }

  void reset() {
    for (var i = 0; i < _buffer.length; i++) {
      _buffer[i] = 0.0;
    }
    _filterStore = 0.0;
    _index = 0;
  }
}

/// Internal allpass filter implementation.
class _AllpassFilter {
  final Float64List _buffer;
  int _index = 0;
  static const double _feedback = 0.5;

  _AllpassFilter({required int size}) : _buffer = Float64List(size);

  double process(double input) {
    final bufferOutput = _buffer[_index];
    final output = bufferOutput - input;

    _buffer[_index] = input + bufferOutput * _feedback;
    _index = (_index + 1) % _buffer.length;

    return output;
  }

  void reset() {
    for (var i = 0; i < _buffer.length; i++) {
      _buffer[i] = 0.0;
    }
    _index = 0;
  }
}
