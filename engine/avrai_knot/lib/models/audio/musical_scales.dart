// Musical Scales
//
// Modal scale system for personality-driven harmony.
// Different modes create different emotional colors.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;

/// Musical mode intervals (semitones from root).
///
/// Each mode has a distinct emotional character:
/// - **Lydian**: Dreamy, ethereal, floating
/// - **Ionian**: Happy, resolved, stable (major scale)
/// - **Mixolydian**: Bluesy, driving, upbeat
/// - **Dorian**: Cool, jazzy, sophisticated
/// - **Aeolian**: Sad, introspective (natural minor)
/// - **Phrygian**: Exotic, mysterious, Spanish
/// - **Locrian**: Unstable, searching, unresolved
enum MusicalMode {
  /// C D E F# G A B - Dreamy, floating (raised 4th)
  lydian,

  /// C D E F G A B - Happy, resolved (major scale)
  ionian,

  /// C D E F G A Bb - Bluesy, driving (lowered 7th)
  mixolydian,

  /// C D Eb F G A Bb - Cool, jazzy (raised 6th of minor)
  dorian,

  /// C D Eb F G Ab Bb - Sad, natural minor
  aeolian,

  /// C Db Eb F G Ab Bb - Exotic, Spanish feel
  phrygian,

  /// C Db Eb F Gb Ab Bb - Unstable, diminished
  locrian,
}

/// Musical scale utilities for personality-driven harmony.
class MusicalScales {
  MusicalScales._();

  /// Semitone intervals for each mode (from root).
  static const Map<MusicalMode, List<int>> modeIntervals = {
    MusicalMode.lydian: [0, 2, 4, 6, 7, 9, 11],
    MusicalMode.ionian: [0, 2, 4, 5, 7, 9, 11],
    MusicalMode.mixolydian: [0, 2, 4, 5, 7, 9, 10],
    MusicalMode.dorian: [0, 2, 3, 5, 7, 9, 10],
    MusicalMode.aeolian: [0, 2, 3, 5, 7, 8, 10],
    MusicalMode.phrygian: [0, 1, 3, 5, 7, 8, 10],
    MusicalMode.locrian: [0, 1, 3, 5, 6, 8, 10],
  };

  /// Emotional characteristics of each mode.
  static const Map<MusicalMode, String> modeCharacters = {
    MusicalMode.lydian: 'dreamy, floating, ethereal',
    MusicalMode.ionian: 'happy, resolved, stable',
    MusicalMode.mixolydian: 'bluesy, driving, upbeat',
    MusicalMode.dorian: 'cool, jazzy, sophisticated',
    MusicalMode.aeolian: 'sad, introspective, melancholic',
    MusicalMode.phrygian: 'exotic, mysterious, Spanish',
    MusicalMode.locrian: 'unstable, searching, unresolved',
  };

  /// Selects a musical mode based on personality dimensions.
  ///
  /// Uses a weighted decision based on key personality traits:
  /// - High exploration + adventure → Lydian (dreamy)
  /// - High energy → Mixolydian (driving)
  /// - High trust → Ionian (resolved)
  /// - Low trust → Aeolian (melancholic)
  /// - High novelty → Phrygian (exotic)
  /// - Low trust + high novelty → Locrian (unstable)
  /// - Balanced → Dorian (cool)
  static MusicalMode selectMode(Map<String, double> dimensions) {
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final trust = dimensions['trust_network_reliance'] ?? 0.5;
    final energy = dimensions['energy_preference'] ?? 0.5;
    final novelty = dimensions['novelty_seeking'] ?? 0.5;
    final location = dimensions['location_adventurousness'] ?? 0.5;

    // High novelty + low trust = unstable, searching
    if (novelty > 0.8 && trust < 0.3) {
      return MusicalMode.locrian;
    }

    // High novelty = exotic, mysterious
    if (novelty > 0.7) {
      return MusicalMode.phrygian;
    }

    // High exploration + adventure = dreamy, floating
    if (exploration > 0.7 && location > 0.6) {
      return MusicalMode.lydian;
    }

    // High energy = driving, upbeat
    if (energy > 0.7) {
      return MusicalMode.mixolydian;
    }

    // High trust = resolved, stable
    if (trust > 0.7) {
      return MusicalMode.ionian;
    }

    // Low trust = melancholic
    if (trust < 0.3) {
      return MusicalMode.aeolian;
    }

    // Balanced = cool, sophisticated
    return MusicalMode.dorian;
  }

  /// Gets the frequency ratios for a chord in the selected mode.
  ///
  /// [mode] is the musical mode.
  /// [chordType] is 'major', 'minor', 'seventh', or 'extended'.
  /// [rootRatio] is the ratio of the root to the base frequency (default 1.0).
  ///
  /// Returns a list of frequency ratios relative to the root.
  static List<double> getChordRatios({
    required MusicalMode mode,
    String chordType = 'triad',
    double rootRatio = 1.0,
  }) {
    final intervals = modeIntervals[mode]!;

    switch (chordType) {
      case 'triad':
        // Root, third, fifth
        return [
          rootRatio,
          rootRatio * _semitoneToRatio(intervals[2]), // 3rd
          rootRatio * _semitoneToRatio(intervals[4]), // 5th
        ];

      case 'seventh':
        // Root, third, fifth, seventh
        return [
          rootRatio,
          rootRatio * _semitoneToRatio(intervals[2]), // 3rd
          rootRatio * _semitoneToRatio(intervals[4]), // 5th
          rootRatio * _semitoneToRatio(intervals[6]), // 7th
        ];

      case 'extended':
        // Root, third, fifth, seventh, ninth
        return [
          rootRatio,
          rootRatio * _semitoneToRatio(intervals[2]), // 3rd
          rootRatio * _semitoneToRatio(intervals[4]), // 5th
          rootRatio * _semitoneToRatio(intervals[6]), // 7th
          rootRatio * _semitoneToRatio(intervals[1] + 12), // 9th (2nd + octave)
        ];

      case 'power':
        // Root and fifth only (neutral harmony)
        return [
          rootRatio,
          rootRatio * _semitoneToRatio(intervals[4]), // 5th
        ];

      default:
        return [rootRatio];
    }
  }

  /// Converts semitones to frequency ratio.
  ///
  /// Uses equal temperament: ratio = 2^(semitones/12)
  static double _semitoneToRatio(int semitones) {
    return math.pow(2.0, semitones / 12.0).toDouble();
  }

  /// Gets consonant intervals for the mode.
  ///
  /// Returns intervals that sound stable and resolved.
  static List<int> getConsonantIntervals(MusicalMode mode) {
    final intervals = modeIntervals[mode]!;
    // Root, third, fifth are generally consonant
    return [intervals[0], intervals[2], intervals[4]];
  }

  /// Gets dissonant intervals for the mode.
  ///
  /// Returns intervals that create tension.
  static List<int> getDissonantIntervals(MusicalMode mode) {
    final intervals = modeIntervals[mode]!;
    // Second, fourth, seventh tend to be more tense
    return [intervals[1], intervals[3], intervals[6]];
  }

  /// Generates a frequency for a scale degree.
  ///
  /// [baseFrequency] is the root frequency in Hz.
  /// [degree] is the scale degree (0-6 for one octave).
  /// [mode] is the musical mode.
  /// [octaveOffset] shifts the pitch by octaves.
  static double degreeToFrequency({
    required double baseFrequency,
    required int degree,
    required MusicalMode mode,
    int octaveOffset = 0,
  }) {
    final intervals = modeIntervals[mode]!;
    final normalizedDegree = degree % 7;
    final extraOctaves = degree ~/ 7;

    final semitones =
        intervals[normalizedDegree] + (octaveOffset + extraOctaves) * 12;
    return baseFrequency * _semitoneToRatio(semitones);
  }

  /// Generates frequencies for a complete scale.
  ///
  /// [baseFrequency] is the root frequency in Hz.
  /// [mode] is the musical mode.
  /// [octaves] is how many octaves to generate.
  static List<double> generateScale({
    required double baseFrequency,
    required MusicalMode mode,
    int octaves = 1,
  }) {
    final frequencies = <double>[];
    final intervals = modeIntervals[mode]!;

    for (var octave = 0; octave < octaves; octave++) {
      for (final interval in intervals) {
        final semitones = interval + octave * 12;
        frequencies.add(baseFrequency * _semitoneToRatio(semitones));
      }
    }

    // Add the final octave
    frequencies.add(baseFrequency * math.pow(2.0, octaves).toDouble());

    return frequencies;
  }
}

/// Chord builder for creating harmonies.
class ChordBuilder {
  /// Base frequency in Hz.
  final double baseFrequency;

  /// Selected musical mode.
  final MusicalMode mode;

  /// Personality-derived consonance ratio (0.5-0.9).
  final double consonanceRatio;

  ChordBuilder({
    required this.baseFrequency,
    required this.mode,
    this.consonanceRatio = 0.7,
  });

  /// Creates from personality dimensions.
  factory ChordBuilder.fromDimensions(
    Map<String, double> dimensions, {
    required double baseFrequency,
  }) {
    final mode = MusicalScales.selectMode(dimensions);
    final trust = dimensions['trust_network_reliance'] ?? 0.5;
    final consonance = 0.5 + trust * 0.4;

    return ChordBuilder(
      baseFrequency: baseFrequency,
      mode: mode,
      consonanceRatio: consonance,
    );
  }

  /// Builds a chord with the specified number of voices.
  ///
  /// [voiceCount] is how many frequencies to generate.
  /// Returns a list of frequencies in Hz.
  List<double> buildChord(int voiceCount) {
    if (voiceCount <= 0) return [];
    if (voiceCount == 1) return [baseFrequency];

    final frequencies = <double>[];
    final intervals = MusicalScales.modeIntervals[mode]!;

    // Always start with root
    frequencies.add(baseFrequency);

    // Add voices based on consonance preference
    final consonantDegrees = [2, 4]; // Third and fifth
    final tensionDegrees = [1, 3, 5, 6]; // Second, fourth, sixth, seventh

    var degreesToUse = <int>[];

    // Mix consonant and tension degrees based on consonance ratio
    for (var i = 0; i < voiceCount - 1; i++) {
      final useConsonant =
          math.Random().nextDouble() < consonanceRatio || i < 2;

      if (useConsonant && consonantDegrees.isNotEmpty) {
        final degreeIndex = i % consonantDegrees.length;
        degreesToUse.add(consonantDegrees[degreeIndex]);
      } else if (tensionDegrees.isNotEmpty) {
        final degreeIndex = i % tensionDegrees.length;
        degreesToUse.add(tensionDegrees[degreeIndex]);
      }
    }

    // Sort and convert to frequencies
    degreesToUse.sort();
    for (final degree in degreesToUse) {
      if (frequencies.length >= voiceCount) break;

      final semitones = intervals[degree % intervals.length];
      final octave = degree ~/ intervals.length;
      final freq =
          baseFrequency *
          MusicalScales._semitoneToRatio(semitones + octave * 12);
      frequencies.add(freq);
    }

    return frequencies;
  }

  /// Builds a deterministic chord (no randomness).
  ///
  /// Useful for reproducible audio generation.
  List<double> buildDeterministicChord(int voiceCount) {
    if (voiceCount <= 0) return [];
    if (voiceCount == 1) return [baseFrequency];

    // Standard chord voicing based on voice count
    switch (voiceCount) {
      case 2:
        // Power chord: root + fifth
        return MusicalScales.getChordRatios(
          mode: mode,
          chordType: 'power',
        ).map((r) => baseFrequency * r).toList();

      case 3:
        // Triad: root + third + fifth
        return MusicalScales.getChordRatios(
          mode: mode,
          chordType: 'triad',
        ).map((r) => baseFrequency * r).toList();

      case 4:
        // Seventh chord
        return MusicalScales.getChordRatios(
          mode: mode,
          chordType: 'seventh',
        ).map((r) => baseFrequency * r).toList();

      default:
        // Extended chord for 5+ voices
        final extended = MusicalScales.getChordRatios(
          mode: mode,
          chordType: 'extended',
        ).map((r) => baseFrequency * r).toList();

        // Add octave doublings if needed
        while (extended.length < voiceCount) {
          extended.add(extended[extended.length - 5] * 2); // Octave up
        }

        return extended.take(voiceCount).toList();
    }
  }
}
