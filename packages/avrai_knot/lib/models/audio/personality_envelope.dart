// Personality Envelope
//
// ADSR envelope generator shaped by personality dimensions.
// Controls the volume contour of each note.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;

import 'package:avrai_knot/models/audio/personality_audio_params.dart';

/// ADSR envelope generator shaped by personality.
///
/// The envelope controls how a note's volume changes over time:
/// - **Attack**: Time to reach peak volume
/// - **Decay**: Time from peak to sustain level
/// - **Sustain**: Volume level while note is held
/// - **Release**: Time to fade to silence after note ends
///
/// Personality affects the envelope:
/// - High energy = fast attack, short decay
/// - Low energy = slow attack, long release
/// - High authenticity = natural sustain curve
/// - High temporal flexibility = more variation
///
/// **Usage:**
/// ```dart
/// final env = PersonalityEnvelope.fromParams(params);
/// final amplitude = env.valueAt(time, noteLength);
/// ```
class PersonalityEnvelope {
  /// Time to reach peak (in seconds).
  final double attack;

  /// Time from peak to sustain level (in seconds).
  final double decay;

  /// Level during sustain phase (0.0 to 1.0).
  final double sustain;

  /// Time to fade to silence after note ends (in seconds).
  final double release;

  /// Optional curve exponent for attack (1.0 = linear).
  final double attackCurve;

  /// Optional curve exponent for decay (1.0 = linear).
  final double decayCurve;

  /// Optional curve exponent for release (1.0 = linear).
  final double releaseCurve;

  const PersonalityEnvelope({
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    this.attackCurve = 0.5, // Faster curve (exponential-like)
    this.decayCurve = 1.0, // Linear
    this.releaseCurve = 2.0, // Slower curve (holds longer)
  });

  /// Creates an envelope from personality audio parameters.
  factory PersonalityEnvelope.fromParams(PersonalityAudioParams params) {
    return PersonalityEnvelope(
      attack: params.attackTime,
      decay: params.decayTime,
      sustain: params.sustainLevel,
      release: params.releaseTime,
      // Shape curves based on authenticity (more organic curves)
      attackCurve: 0.3 + params.oddEvenBalance * 0.4, // 0.3-0.7
      decayCurve: 0.8 + params.oddEvenBalance * 0.4, // 0.8-1.2
      releaseCurve: 1.5 + params.oddEvenBalance * 1.0, // 1.5-2.5
    );
  }

  /// Creates an envelope from personality dimensions directly.
  factory PersonalityEnvelope.fromDimensions(Map<String, double> dimensions) {
    final params = PersonalityAudioParams.fromDimensions(dimensions);
    return PersonalityEnvelope.fromParams(params);
  }

  /// Creates a default envelope (balanced personality).
  factory PersonalityEnvelope.defaults() {
    return PersonalityEnvelope.fromParams(PersonalityAudioParams.defaults());
  }

  /// Creates a fast, punchy envelope (high energy).
  factory PersonalityEnvelope.punchy() {
    return const PersonalityEnvelope(
      attack: 0.01,
      decay: 0.1,
      sustain: 0.3,
      release: 0.1,
      attackCurve: 0.3,
      decayCurve: 0.8,
      releaseCurve: 1.5,
    );
  }

  /// Creates a slow, pad-like envelope (low energy).
  factory PersonalityEnvelope.pad() {
    return const PersonalityEnvelope(
      attack: 0.3,
      decay: 0.5,
      sustain: 0.7,
      release: 1.0,
      attackCurve: 0.7,
      decayCurve: 1.2,
      releaseCurve: 2.5,
    );
  }

  /// Total duration of attack + decay phases.
  double get attackDecayTime => attack + decay;

  /// Calculates the envelope value at a given time.
  ///
  /// [time] is the elapsed time since note start (in seconds).
  /// [noteLength] is the total note duration (in seconds).
  ///
  /// Returns amplitude value from 0.0 to 1.0.
  double valueAt(double time, double noteLength) {
    if (time < 0) return 0.0;

    // Attack phase
    if (time < attack) {
      final progress = time / attack;
      return _curve(progress, attackCurve);
    }

    // Decay phase
    if (time < attack + decay) {
      final decayTime = time - attack;
      final decayProgress = decayTime / decay;
      final decayAmount = (1.0 - sustain) * _curve(decayProgress, decayCurve);
      return 1.0 - decayAmount;
    }

    // Sustain phase
    final releaseStart = noteLength - release;
    if (time < releaseStart) {
      return sustain;
    }

    // Release phase
    if (time < noteLength) {
      final releaseTime = time - releaseStart;
      final releaseProgress = releaseTime / release;
      return sustain * (1.0 - _curve(releaseProgress, releaseCurve));
    }

    // After note ends
    return 0.0;
  }

  /// Applies curve shaping to a linear progress value.
  ///
  /// [progress] is 0.0 to 1.0.
  /// [exponent] shapes the curve:
  ///   - < 1.0: Fast start, slow finish (exponential decay-like)
  ///   - 1.0: Linear
  ///   - > 1.0: Slow start, fast finish (exponential rise-like)
  double _curve(double progress, double exponent) {
    return math.pow(progress.clamp(0.0, 1.0), exponent).toDouble();
  }

  /// Calculates envelope value for a note that's being held indefinitely.
  ///
  /// Use this when the note length is unknown (e.g., sustained notes).
  /// Returns the envelope value without release phase.
  double valueAtSustained(double time) {
    if (time < 0) return 0.0;

    // Attack phase
    if (time < attack) {
      final progress = time / attack;
      return _curve(progress, attackCurve);
    }

    // Decay phase
    if (time < attack + decay) {
      final decayTime = time - attack;
      final decayProgress = decayTime / decay;
      final decayAmount = (1.0 - sustain) * _curve(decayProgress, decayCurve);
      return 1.0 - decayAmount;
    }

    // Sustain phase (indefinite)
    return sustain;
  }

  /// Calculates the release envelope given a time since release started.
  ///
  /// [releasedTime] is time since the note was released.
  /// [sustainValue] is the amplitude when release started.
  ///
  /// Returns the fading amplitude.
  double releaseValueAt(double releasedTime, double sustainValue) {
    if (releasedTime < 0) return sustainValue;
    if (releasedTime >= release) return 0.0;

    final releaseProgress = releasedTime / release;
    return sustainValue * (1.0 - _curve(releaseProgress, releaseCurve));
  }

  @override
  String toString() {
    return 'PersonalityEnvelope('
        'A: ${(attack * 1000).toStringAsFixed(0)}ms, '
        'D: ${(decay * 1000).toStringAsFixed(0)}ms, '
        'S: ${(sustain * 100).toStringAsFixed(0)}%, '
        'R: ${(release * 1000).toStringAsFixed(0)}ms)';
  }
}

/// Multi-stage envelope for complex sounds.
///
/// Supports multiple segments with different targets and curves,
/// useful for birth harmony phases and evolving sounds.
class MultiStageEnvelope {
  /// List of envelope stages.
  final List<EnvelopeStage> stages;

  /// Total duration of all stages.
  final double totalDuration;

  const MultiStageEnvelope({
    required this.stages,
    required this.totalDuration,
  });

  /// Creates a birth harmony envelope with 5 phases.
  ///
  /// - Transition (0-5s): Build from silence
  /// - Void (5-10s): Single tone emerges
  /// - Emergence (10-25s): Harmonics appear
  /// - Formation (25-45s): Chord builds
  /// - Harmony (45-60s): Full resolution
  factory MultiStageEnvelope.birthHarmony() {
    return const MultiStageEnvelope(
      stages: [
        EnvelopeStage(
          name: 'transition',
          startTime: 0.0,
          endTime: 5.0,
          startLevel: 0.0,
          endLevel: 0.2,
          curve: 0.5,
        ),
        EnvelopeStage(
          name: 'void',
          startTime: 5.0,
          endTime: 10.0,
          startLevel: 0.2,
          endLevel: 0.4,
          curve: 1.0,
        ),
        EnvelopeStage(
          name: 'emergence',
          startTime: 10.0,
          endTime: 25.0,
          startLevel: 0.4,
          endLevel: 0.7,
          curve: 0.8,
        ),
        EnvelopeStage(
          name: 'formation',
          startTime: 25.0,
          endTime: 45.0,
          startLevel: 0.7,
          endLevel: 0.9,
          curve: 0.6,
        ),
        EnvelopeStage(
          name: 'harmony',
          startTime: 45.0,
          endTime: 60.0,
          startLevel: 0.9,
          endLevel: 0.0,
          curve: 2.0, // Slow fade out
        ),
      ],
      totalDuration: 60.0,
    );
  }

  /// Creates a formation sound envelope (8 seconds).
  factory MultiStageEnvelope.formation() {
    return const MultiStageEnvelope(
      stages: [
        EnvelopeStage(
          name: 'chaos',
          startTime: 0.0,
          endTime: 2.0,
          startLevel: 0.0,
          endLevel: 0.5,
          curve: 0.5,
        ),
        EnvelopeStage(
          name: 'emerging',
          startTime: 2.0,
          endTime: 4.0,
          startLevel: 0.5,
          endLevel: 0.7,
          curve: 0.8,
        ),
        EnvelopeStage(
          name: 'forming',
          startTime: 4.0,
          endTime: 6.0,
          startLevel: 0.7,
          endLevel: 0.9,
          curve: 1.0,
        ),
        EnvelopeStage(
          name: 'resolved',
          startTime: 6.0,
          endTime: 8.0,
          startLevel: 0.9,
          endLevel: 0.0,
          curve: 2.0,
        ),
      ],
      totalDuration: 8.0,
    );
  }

  /// Gets the envelope value at the given time.
  double valueAt(double time) {
    if (time < 0) return 0.0;
    if (time >= totalDuration) return 0.0;

    // Find the current stage
    for (final stage in stages) {
      if (time >= stage.startTime && time < stage.endTime) {
        return stage.valueAt(time);
      }
    }

    return 0.0;
  }

  /// Gets the current stage name at the given time.
  String? stageNameAt(double time) {
    for (final stage in stages) {
      if (time >= stage.startTime && time < stage.endTime) {
        return stage.name;
      }
    }
    return null;
  }

  /// Gets the morph position (0-1) corresponding to the current time.
  ///
  /// Useful for wavetable morphing synchronized with envelope.
  double morphPositionAt(double time) {
    return (time / totalDuration).clamp(0.0, 1.0);
  }
}

/// A single stage in a multi-stage envelope.
class EnvelopeStage {
  /// Name of this stage (for debugging).
  final String name;

  /// Start time in seconds.
  final double startTime;

  /// End time in seconds.
  final double endTime;

  /// Amplitude level at start (0.0 to 1.0).
  final double startLevel;

  /// Amplitude level at end (0.0 to 1.0).
  final double endLevel;

  /// Curve exponent (see PersonalityEnvelope._curve).
  final double curve;

  const EnvelopeStage({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.startLevel,
    required this.endLevel,
    this.curve = 1.0,
  });

  /// Duration of this stage in seconds.
  double get duration => endTime - startTime;

  /// Gets the envelope value at the given time.
  double valueAt(double time) {
    if (time < startTime) return startLevel;
    if (time >= endTime) return endLevel;

    final progress = (time - startTime) / duration;
    final curvedProgress = math.pow(progress, curve);
    return startLevel + (endLevel - startLevel) * curvedProgress;
  }
}
