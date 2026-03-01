// Wavetable Model
//
// Core data structures for wavetable synthesis.
// A wavetable is a single-cycle waveform that can be read at different
// speeds to produce different pitches.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;
import 'dart:typed_data';

/// A single-cycle waveform for wavetable synthesis.
///
/// Contains a buffer of samples (typically 256-2048) representing
/// one complete cycle of a waveform. The oscillator reads through
/// this buffer at different speeds to produce different pitches.
///
/// **Usage:**
/// ```dart
/// final table = Wavetable.sine(size: 2048);
/// final sample = table.read(0.25); // Read at 25% through the cycle
/// ```
class Wavetable {
  /// The waveform samples (normalized to -1.0 to 1.0).
  final Float64List samples;

  /// Number of samples in the wavetable.
  final int size;

  /// Human-readable name for this wavetable.
  final String name;

  /// Creates a wavetable from pre-computed samples.
  ///
  /// [samples] should be normalized to the range -1.0 to 1.0.
  /// [name] is an optional identifier for debugging/caching.
  Wavetable({required this.samples, required this.name})
    : size = samples.length {
    if (samples.isEmpty) {
      throw ArgumentError('Wavetable samples cannot be empty');
    }
  }

  /// Creates a pure sine wave wavetable.
  ///
  /// [size] determines the resolution (higher = smoother, more memory).
  /// Typical values: 256, 512, 1024, 2048.
  factory Wavetable.sine({int size = 2048, String? name}) {
    final samples = Float64List(size);
    final twoPi = 2.0 * math.pi;

    for (var i = 0; i < size; i++) {
      final phase = i / size;
      samples[i] = math.sin(phase * twoPi);
    }

    return Wavetable(samples: samples, name: name ?? 'sine');
  }

  /// Creates a sawtooth wave wavetable.
  ///
  /// Bright, harmonically rich waveform containing all harmonics.
  factory Wavetable.sawtooth({int size = 2048, String? name}) {
    final samples = Float64List(size);

    for (var i = 0; i < size; i++) {
      final phase = i / size;
      // Sawtooth: rises linearly from -1 to 1
      samples[i] = 2.0 * phase - 1.0;
    }

    return Wavetable(samples: samples, name: name ?? 'sawtooth');
  }

  /// Creates a square wave wavetable.
  ///
  /// Contains only odd harmonics, hollow sound.
  factory Wavetable.square({int size = 2048, String? name}) {
    final samples = Float64List(size);

    for (var i = 0; i < size; i++) {
      final phase = i / size;
      // Square: +1 for first half, -1 for second half
      samples[i] = phase < 0.5 ? 1.0 : -1.0;
    }

    return Wavetable(samples: samples, name: name ?? 'square');
  }

  /// Creates a triangle wave wavetable.
  ///
  /// Softer than sawtooth, contains only odd harmonics with fast rolloff.
  factory Wavetable.triangle({int size = 2048, String? name}) {
    final samples = Float64List(size);

    for (var i = 0; i < size; i++) {
      final phase = i / size;
      // Triangle: rises to 1, then falls to -1, then rises to 0
      if (phase < 0.25) {
        samples[i] = 4.0 * phase;
      } else if (phase < 0.75) {
        samples[i] = 2.0 - 4.0 * phase;
      } else {
        samples[i] = 4.0 * phase - 4.0;
      }
    }

    return Wavetable(samples: samples, name: name ?? 'triangle');
  }

  /// Creates a wavetable with custom harmonic content.
  ///
  /// [harmonics] is a list of amplitudes for each harmonic.
  /// Index 0 = fundamental, index 1 = 2nd harmonic, etc.
  ///
  /// **Example:**
  /// ```dart
  /// // Create a wavetable with fundamental + 3rd + 5th harmonics
  /// final table = Wavetable.fromHarmonics(
  ///   harmonics: [1.0, 0.0, 0.5, 0.0, 0.25],
  ///   size: 2048,
  /// );
  /// ```
  factory Wavetable.fromHarmonics({
    required List<double> harmonics,
    int size = 2048,
    String? name,
  }) {
    final samples = Float64List(size);
    final twoPi = 2.0 * math.pi;

    for (var i = 0; i < size; i++) {
      final phase = i / size;
      var sample = 0.0;

      for (var h = 0; h < harmonics.length; h++) {
        final harmonicNumber = h + 1;
        final amplitude = harmonics[h];
        sample += amplitude * math.sin(phase * twoPi * harmonicNumber);
      }

      samples[i] = sample;
    }

    // Normalize to prevent clipping
    var maxAmp = 0.0;
    for (var i = 0; i < size; i++) {
      maxAmp = math.max(maxAmp, samples[i].abs());
    }
    if (maxAmp > 1.0) {
      for (var i = 0; i < size; i++) {
        samples[i] /= maxAmp;
      }
    }

    return Wavetable(samples: samples, name: name ?? 'harmonics');
  }

  /// Reads a sample at the given phase position with linear interpolation.
  ///
  /// [phase] should be in the range 0.0 to 1.0 (wraps automatically).
  /// Returns an interpolated sample value in the range -1.0 to 1.0.
  ///
  /// Linear interpolation smooths the output when reading between samples,
  /// reducing aliasing artifacts.
  double read(double phase) {
    // Wrap phase to 0.0-1.0 range
    phase = phase % 1.0;
    if (phase < 0) phase += 1.0;

    // Calculate position in sample buffer
    final pos = phase * size;
    final index = pos.floor();
    final frac = pos - index;

    // Get the two samples to interpolate between
    final sample1 = samples[index % size];
    final sample2 = samples[(index + 1) % size];

    // Linear interpolation
    return sample1 + frac * (sample2 - sample1);
  }

  /// Reads a sample at the given phase with cubic interpolation.
  ///
  /// Higher quality than linear interpolation, smoother output.
  /// Slightly more CPU intensive.
  double readCubic(double phase) {
    // Wrap phase to 0.0-1.0 range
    phase = phase % 1.0;
    if (phase < 0) phase += 1.0;

    // Calculate position in sample buffer
    final pos = phase * size;
    final index = pos.floor();
    final frac = pos - index;

    // Get four samples for cubic interpolation
    final y0 = samples[(index - 1 + size) % size];
    final y1 = samples[index % size];
    final y2 = samples[(index + 1) % size];
    final y3 = samples[(index + 2) % size];

    // Cubic interpolation (Catmull-Rom spline)
    final a0 = -0.5 * y0 + 1.5 * y1 - 1.5 * y2 + 0.5 * y3;
    final a1 = y0 - 2.5 * y1 + 2.0 * y2 - 0.5 * y3;
    final a2 = -0.5 * y0 + 0.5 * y2;
    final a3 = y1;

    return a0 * frac * frac * frac + a1 * frac * frac + a2 * frac + a3;
  }

  @override
  String toString() => 'Wavetable($name, $size samples)';
}

/// A collection of wavetables for morphing/blending.
///
/// Contains multiple wavetables that can be smoothly interpolated
/// between based on a morph position. This allows for evolving
/// timbres that change over time.
///
/// **Usage:**
/// ```dart
/// final set = WavetableSet(
///   tables: [
///     Wavetable.sine(),
///     Wavetable.sawtooth(),
///   ],
///   personalitySignature: 'user_123',
/// );
///
/// // Read at 25% through the cycle, morphing 50% between tables
/// final sample = set.readMorphed(phase: 0.25, morphPosition: 0.5);
/// ```
class WavetableSet {
  /// The wavetables to morph between.
  final List<Wavetable> tables;

  /// Cache key based on personality dimensions.
  final String personalitySignature;

  /// Optional name for debugging.
  final String? name;

  /// Creates a wavetable set from a list of wavetables.
  ///
  /// [tables] must contain at least 2 wavetables.
  /// [personalitySignature] is used for caching.
  WavetableSet({
    required this.tables,
    required this.personalitySignature,
    this.name,
  }) {
    if (tables.length < 2) {
      throw ArgumentError('WavetableSet requires at least 2 wavetables');
    }
  }

  /// Number of wavetables in this set.
  int get tableCount => tables.length;

  /// Reads a sample with morphing between adjacent wavetables.
  ///
  /// [phase] is the position within the waveform cycle (0.0 to 1.0).
  /// [morphPosition] determines which wavetables to blend (0.0 to 1.0):
  ///   - 0.0 = first wavetable only
  ///   - 0.5 = blend between middle wavetables
  ///   - 1.0 = last wavetable only
  ///
  /// Returns an interpolated sample in the range -1.0 to 1.0.
  double readMorphed({required double phase, required double morphPosition}) {
    // Clamp morph position to valid range
    morphPosition = morphPosition.clamp(0.0, 1.0);

    // Calculate which two tables to blend between
    final tablePos = morphPosition * (tables.length - 1);
    final tableIndex = tablePos.floor().clamp(0, tables.length - 2);
    final tableFrac = tablePos - tableIndex;

    // Read from both tables
    final sample1 = tables[tableIndex].read(phase);
    final sample2 = tables[tableIndex + 1].read(phase);

    // Linear interpolation between tables
    return sample1 * (1.0 - tableFrac) + sample2 * tableFrac;
  }

  /// Reads a sample with morphing using cubic interpolation for higher quality.
  double readMorphedCubic({
    required double phase,
    required double morphPosition,
  }) {
    // Clamp morph position to valid range
    morphPosition = morphPosition.clamp(0.0, 1.0);

    // Calculate which two tables to blend between
    final tablePos = morphPosition * (tables.length - 1);
    final tableIndex = tablePos.floor().clamp(0, tables.length - 2);
    final tableFrac = tablePos - tableIndex;

    // Read from both tables using cubic interpolation
    final sample1 = tables[tableIndex].readCubic(phase);
    final sample2 = tables[tableIndex + 1].readCubic(phase);

    // Linear interpolation between tables
    return sample1 * (1.0 - tableFrac) + sample2 * tableFrac;
  }

  /// Gets a specific wavetable by index.
  Wavetable operator [](int index) => tables[index];

  @override
  String toString() =>
      'WavetableSet(${name ?? personalitySignature}, ${tables.length} tables)';
}
