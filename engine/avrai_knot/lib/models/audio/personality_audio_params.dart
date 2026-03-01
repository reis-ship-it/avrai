// Personality Audio Parameters
//
// Maps the 12 avrai personality dimensions to audio synthesis parameters.
// Each dimension influences specific aspects of the generated sound.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'package:avrai_core/utils/vibe_constants.dart';

/// Audio parameters derived from personality dimensions.
///
/// Maps all 12 avrai personality dimensions to specific audio characteristics:
///
/// | Dimension                | Audio Effect                          |
/// |--------------------------|---------------------------------------|
/// | exploration_eagerness    | Frequency range / melodic spread      |
/// | community_orientation    | Voice count (polyphony)               |
/// | authenticity_preference  | Harmonic balance + vibrato            |
/// | social_discovery_style   | Echo amount / call-response           |
/// | temporal_flexibility     | Rubato (timing variation)             |
/// | location_adventurousness | Pitch register extremes               |
/// | curation_tendency        | Ornamentation density                 |
/// | trust_network_reliance   | Consonance/dissonance ratio           |
/// | energy_preference        | Tempo, attack speed, note density     |
/// | novelty_seeking          | Melodic unpredictability              |
/// | value_orientation        | Harmonic richness, reverb             |
/// | crowd_tolerance          | Texture density, dynamics             |
///
/// **Usage:**
/// ```dart
/// final params = PersonalityAudioParams.fromDimensions(dimensions);
/// final voiceCount = params.voiceCount;
/// final tempo = params.tempo;
/// ```
class PersonalityAudioParams {
  // ===== Frequency and Pitch =====

  /// Frequency range in Hz (200-1000).
  /// Higher exploration = wider melodic range.
  final double frequencyRange;

  /// Base frequency in Hz (110-440).
  final double baseFrequency;

  /// Maximum interval in semitones (3-12).
  /// Higher location adventurousness = larger leaps.
  final int maxIntervalSemitones;

  /// Pitch register offset (-12 to +12 semitones).
  final double pitchRegisterOffset;

  // ===== Polyphony and Voices =====

  /// Number of simultaneous voices (1-6).
  /// Higher community orientation = more voices.
  final int voiceCount;

  /// Detune spread between voices in cents (0-30).
  final double detuneSpread;

  // ===== Timbre and Harmonics =====

  /// Number of harmonics (4-24).
  /// Higher value orientation = richer harmonics.
  final int harmonicCount;

  /// Balance between odd and even harmonics (0-1).
  /// 0 = only odd (hollow), 1 = all harmonics (warm).
  /// Controlled by authenticity_preference.
  final double oddEvenBalance;

  /// Harmonic rolloff rate (1.0-2.5).
  /// Higher = faster rolloff = darker sound.
  final double harmonicRolloff;

  // ===== Vibrato and Modulation =====

  /// Vibrato frequency in Hz (0-8).
  /// Higher authenticity = more natural vibrato.
  final double vibratoFrequency;

  /// Vibrato depth as ratio (0-0.03).
  final double vibratoDepth;

  // ===== Rhythm and Tempo =====

  /// Tempo in BPM (60-180).
  /// Higher energy = faster tempo.
  final double tempo;

  /// Notes per beat (1-4).
  final int notesPerBeat;

  /// Timing variation / rubato (0-0.15).
  /// Higher temporal flexibility = more rubato.
  final double rubatoAmount;

  // ===== Effects =====

  /// Reverb mix (0-0.6).
  /// Higher value orientation = more reverb.
  final double reverbMix;

  /// Reverb room size (0.3-0.9).
  final double reverbRoomSize;

  /// Echo/delay amount (0-0.4).
  /// Higher social discovery = more echo.
  final double echoAmount;

  // ===== Dynamics and Texture =====

  /// Dynamic range (0.2-0.8).
  /// Lower crowd tolerance = wider dynamics.
  final double dynamicRange;

  /// Texture density (0.3-1.0).
  /// Higher crowd tolerance = denser texture.
  final double textureDensity;

  /// Stereo width (0-0.8).
  /// Higher community orientation = wider stereo.
  final double stereoWidth;

  /// Pan movement amount (0-0.5).
  /// Higher exploration = more pan movement.
  final double panMovement;

  // ===== Melodic Character =====

  /// Ornamentation density (0-0.5).
  /// Higher curation = more ornaments.
  final double ornamentDensity;

  /// Melodic surprise probability (0-0.4).
  /// Higher novelty seeking = more surprising notes.
  final double surpriseProbability;

  /// Note repetition probability (0-0.5).
  /// Lower novelty seeking = more repetition.
  final double repetitionProbability;

  // ===== Harmony =====

  /// Consonance ratio (0.5-0.9).
  /// Higher trust = more consonant.
  final double consonanceRatio;

  const PersonalityAudioParams({
    required this.frequencyRange,
    required this.baseFrequency,
    required this.maxIntervalSemitones,
    required this.pitchRegisterOffset,
    required this.voiceCount,
    required this.detuneSpread,
    required this.harmonicCount,
    required this.oddEvenBalance,
    required this.harmonicRolloff,
    required this.vibratoFrequency,
    required this.vibratoDepth,
    required this.tempo,
    required this.notesPerBeat,
    required this.rubatoAmount,
    required this.reverbMix,
    required this.reverbRoomSize,
    required this.echoAmount,
    required this.dynamicRange,
    required this.textureDensity,
    required this.stereoWidth,
    required this.panMovement,
    required this.ornamentDensity,
    required this.surpriseProbability,
    required this.repetitionProbability,
    required this.consonanceRatio,
  });

  /// Creates audio parameters from personality dimensions.
  ///
  /// [dimensions] is a map of dimension names to values (0.0 to 1.0).
  /// Missing dimensions default to 0.5.
  factory PersonalityAudioParams.fromDimensions(
    Map<String, double> dimensions,
  ) {
    // Extract dimensions with defaults
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final community = dimensions['community_orientation'] ?? 0.5;
    final authenticity = dimensions['authenticity_preference'] ?? 0.5;
    final social = dimensions['social_discovery_style'] ?? 0.5;
    final temporal = dimensions['temporal_flexibility'] ?? 0.5;
    final location = dimensions['location_adventurousness'] ?? 0.5;
    final curation = dimensions['curation_tendency'] ?? 0.5;
    final trust = dimensions['trust_network_reliance'] ?? 0.5;
    final energy = dimensions['energy_preference'] ?? 0.5;
    final novelty = dimensions['novelty_seeking'] ?? 0.5;
    final value = dimensions['value_orientation'] ?? 0.5;
    final crowd = dimensions['crowd_tolerance'] ?? 0.5;

    return PersonalityAudioParams(
      // Frequency and Pitch
      frequencyRange: 200 + exploration * 800, // 200-1000Hz
      baseFrequency: 110 + value * 110, // 110-220Hz (A2-A3)
      maxIntervalSemitones: (3 + location * 9).round(), // 3-12 semitones
      pitchRegisterOffset: (location - 0.5) * 24, // -12 to +12 semitones
      // Polyphony and Voices
      voiceCount: (1 + community * 5).round(), // 1-6 voices
      detuneSpread: community * 30, // 0-30 cents
      // Timbre and Harmonics
      harmonicCount: (4 + value * 20).round(), // 4-24 harmonics
      oddEvenBalance: authenticity, // 0-1 (authentic = warmer)
      harmonicRolloff: 1.0 + (1.0 - value) * 1.5, // 1.0-2.5
      // Vibrato and Modulation
      vibratoFrequency: authenticity > 0.3
          ? 4.0 + authenticity * 4
          : 0, // 0-8Hz
      vibratoDepth: authenticity * 0.02, // 0-2%
      // Rhythm and Tempo
      tempo: 60 + energy * 120, // 60-180 BPM
      notesPerBeat: (1 + energy * 3).round(), // 1-4 notes per beat
      rubatoAmount: temporal * 0.15, // 0-15% timing variation
      // Effects
      reverbMix: 0.1 + value * 0.5, // 10-60%
      reverbRoomSize: 0.3 + value * 0.6, // 0.3-0.9
      echoAmount: social * 0.4, // 0-40%
      // Dynamics and Texture
      dynamicRange: 0.2 + (1.0 - crowd) * 0.6, // 0.2-0.8
      textureDensity: 0.3 + crowd * 0.7, // 0.3-1.0
      stereoWidth: community * 0.8, // 0-80%
      panMovement: exploration * 0.5, // 0-50%
      // Melodic Character
      ornamentDensity: curation * 0.5, // 0-50%
      surpriseProbability: novelty * 0.4, // 0-40%
      repetitionProbability: (1.0 - novelty) * 0.5, // 0-50%
      // Harmony
      consonanceRatio: 0.5 + trust * 0.4, // 0.5-0.9
    );
  }

  /// Creates default audio parameters (all dimensions at 0.5).
  factory PersonalityAudioParams.defaults() {
    return PersonalityAudioParams.fromDimensions(const {});
  }

  /// Gets the attack time in seconds based on energy.
  ///
  /// Higher energy = faster attack.
  double get attackTime {
    // Derived from energy_preference (inverse relationship)
    // tempo is 60-180, normalized: (tempo - 60) / 120 = 0-1
    final energyNormalized = (tempo - 60) / 120;
    return 0.01 + (1.0 - energyNormalized) * 0.2; // 0.01-0.21 seconds
  }

  /// Gets the decay time in seconds.
  double get decayTime {
    final energyNormalized = (tempo - 60) / 120;
    return 0.1 + (1.0 - energyNormalized) * 0.4; // 0.1-0.5 seconds
  }

  /// Gets the sustain level (0-1).
  double get sustainLevel {
    // Authenticity affects sustain (warmer = higher sustain)
    return 0.4 + oddEvenBalance * 0.4; // 0.4-0.8
  }

  /// Gets the release time in seconds.
  double get releaseTime {
    final energyNormalized = (tempo - 60) / 120;
    return 0.1 + (1.0 - energyNormalized) * 0.5; // 0.1-0.6 seconds
  }

  /// Creates a personality signature string for caching.
  ///
  /// Rounds dimension values to reduce cache fragmentation.
  static String createSignature(Map<String, double> dimensions) {
    final entries = <String>[];
    for (final dim in VibeConstants.coreDimensions) {
      final value = dimensions[dim] ?? 0.5;
      // Round to nearest 0.1 for caching
      final rounded = (value * 10).round();
      entries.add('$dim:$rounded');
    }
    return entries.join('|');
  }

  @override
  String toString() {
    return 'PersonalityAudioParams('
        'voices: $voiceCount, '
        'tempo: ${tempo.toStringAsFixed(0)}bpm, '
        'harmonics: $harmonicCount, '
        'stereoWidth: ${(stereoWidth * 100).toStringAsFixed(0)}%)';
  }
}

/// Audio parameter presets for testing and demonstration.
class PersonalityAudioPresets {
  PersonalityAudioPresets._();

  /// High-energy, social personality.
  static final Map<String, double> energeticSocial = {
    'exploration_eagerness': 0.8,
    'community_orientation': 0.9,
    'authenticity_preference': 0.6,
    'social_discovery_style': 0.8,
    'temporal_flexibility': 0.7,
    'location_adventurousness': 0.7,
    'curation_tendency': 0.5,
    'trust_network_reliance': 0.8,
    'energy_preference': 0.9,
    'novelty_seeking': 0.7,
    'value_orientation': 0.6,
    'crowd_tolerance': 0.9,
  };

  /// Calm, introspective personality.
  static final Map<String, double> calmIntrospective = {
    'exploration_eagerness': 0.4,
    'community_orientation': 0.3,
    'authenticity_preference': 0.9,
    'social_discovery_style': 0.3,
    'temporal_flexibility': 0.4,
    'location_adventurousness': 0.3,
    'curation_tendency': 0.6,
    'trust_network_reliance': 0.5,
    'energy_preference': 0.2,
    'novelty_seeking': 0.3,
    'value_orientation': 0.7,
    'crowd_tolerance': 0.2,
  };

  /// Adventurous, novelty-seeking personality.
  static final Map<String, double> adventurousExplorer = {
    'exploration_eagerness': 0.95,
    'community_orientation': 0.6,
    'authenticity_preference': 0.7,
    'social_discovery_style': 0.6,
    'temporal_flexibility': 0.9,
    'location_adventurousness': 0.95,
    'curation_tendency': 0.4,
    'trust_network_reliance': 0.5,
    'energy_preference': 0.7,
    'novelty_seeking': 0.95,
    'value_orientation': 0.5,
    'crowd_tolerance': 0.6,
  };

  /// Balanced, neutral personality (all at 0.5).
  static final Map<String, double> balanced = {
    'exploration_eagerness': 0.5,
    'community_orientation': 0.5,
    'authenticity_preference': 0.5,
    'social_discovery_style': 0.5,
    'temporal_flexibility': 0.5,
    'location_adventurousness': 0.5,
    'curation_tendency': 0.5,
    'trust_network_reliance': 0.5,
    'energy_preference': 0.5,
    'novelty_seeking': 0.5,
    'value_orientation': 0.5,
    'crowd_tolerance': 0.5,
  };
}
