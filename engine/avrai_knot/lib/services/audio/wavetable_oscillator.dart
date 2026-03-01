// Wavetable Oscillator
//
// Core synthesis engine that reads through wavetables to produce audio.
// Maintains phase accumulator, supports frequency modulation and detuning.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;

import 'package:avrai_knot/models/audio/wavetable.dart';

/// A wavetable oscillator that produces audio by reading through wavetables.
///
/// The oscillator maintains a phase accumulator that advances based on the
/// frequency. It can morph between multiple wavetables for evolving timbres.
///
/// **Usage:**
/// ```dart
/// final osc = WavetableOscillator(wavetableSet);
///
/// // Generate samples at 440Hz
/// for (var i = 0; i < numSamples; i++) {
///   final sample = osc.sample(
///     frequency: 440.0,
///     morphPosition: 0.5,
///     sampleRate: 44100,
///   );
///   buffer[i] = sample;
/// }
/// ```
class WavetableOscillator {
  /// The wavetable set to read from.
  final WavetableSet wavetables;

  /// Current phase position (0.0 to 1.0).
  double _phase = 0.0;

  /// Optional detuning in cents (100 cents = 1 semitone).
  double detuneCents;

  /// Vibrato frequency in Hz (0 = disabled).
  double vibratoFrequency;

  /// Vibrato depth as a ratio of the base frequency.
  double vibratoDepth;

  /// Internal vibrato phase.
  double _vibratoPhase = 0.0;

  /// Creates a wavetable oscillator.
  ///
  /// [wavetables] is the set of wavetables to morph between.
  /// [detuneCents] adds slight pitch variation (0 = no detune).
  /// [vibratoFrequency] is the vibrato rate in Hz (0 = disabled).
  /// [vibratoDepth] is the vibrato amount (0.01 = 1% of frequency).
  WavetableOscillator(
    this.wavetables, {
    this.detuneCents = 0.0,
    this.vibratoFrequency = 0.0,
    this.vibratoDepth = 0.0,
  });

  /// Gets the current phase position.
  double get phase => _phase;

  /// Sets the phase position (0.0 to 1.0).
  set phase(double value) {
    _phase = value % 1.0;
    if (_phase < 0) _phase += 1.0;
  }

  /// Resets the oscillator phase to zero.
  void reset() {
    _phase = 0.0;
    _vibratoPhase = 0.0;
  }

  /// Generates a single sample at the given frequency.
  ///
  /// [frequency] is the pitch in Hz.
  /// [morphPosition] determines which wavetables to blend (0.0 to 1.0).
  /// [sampleRate] is the audio sample rate (typically 44100).
  ///
  /// Returns a sample value in the range -1.0 to 1.0.
  double sample({
    required double frequency,
    required double morphPosition,
    required int sampleRate,
  }) {
    // Apply detuning
    var effectiveFrequency = frequency;
    if (detuneCents != 0.0) {
      // Convert cents to frequency ratio: 2^(cents/1200)
      final detuneRatio = math.pow(2.0, detuneCents / 1200.0);
      effectiveFrequency *= detuneRatio;
    }

    // Apply vibrato
    if (vibratoFrequency > 0.0 && vibratoDepth > 0.0) {
      // Advance vibrato phase
      _vibratoPhase += vibratoFrequency / sampleRate;
      _vibratoPhase %= 1.0;

      // Calculate vibrato modulation
      final vibratoMod = math.sin(_vibratoPhase * 2.0 * math.pi) * vibratoDepth;
      effectiveFrequency *= (1.0 + vibratoMod);
    }

    // Read from wavetable at current phase
    final sampleValue = wavetables.readMorphed(
      phase: _phase,
      morphPosition: morphPosition,
    );

    // Advance phase
    final phaseIncrement = effectiveFrequency / sampleRate;
    _phase += phaseIncrement;
    _phase %= 1.0;

    return sampleValue;
  }

  /// Generates a single sample with frequency modulation.
  ///
  /// [frequency] is the base frequency in Hz.
  /// [morphPosition] determines wavetable blend.
  /// [fmAmount] is the modulation depth (0 = no modulation).
  /// [modulator] is the modulator oscillator's current output (-1 to 1).
  /// [sampleRate] is the audio sample rate.
  double sampleWithFM({
    required double frequency,
    required double morphPosition,
    required double fmAmount,
    required double modulator,
    required int sampleRate,
  }) {
    // Apply FM: carrier frequency is modulated by the modulator
    final fmOffset = modulator * fmAmount * frequency;
    final modulatedFrequency = frequency + fmOffset;

    return sample(
      frequency: modulatedFrequency.clamp(20.0, 20000.0),
      morphPosition: morphPosition,
      sampleRate: sampleRate,
    );
  }

  @override
  String toString() =>
      'WavetableOscillator(${wavetables.name ?? wavetables.personalitySignature})';
}

/// A bank of multiple oscillators for polyphonic synthesis.
///
/// Manages multiple oscillators that can play simultaneously,
/// useful for chords and layered sounds.
class OscillatorBank {
  /// The oscillators in this bank.
  final List<WavetableOscillator> oscillators;

  /// Number of active oscillators.
  int get count => oscillators.length;

  /// Creates an oscillator bank with the specified number of oscillators.
  ///
  /// All oscillators share the same wavetable set but can have
  /// different detune values for a richer sound.
  factory OscillatorBank.create({
    required WavetableSet wavetables,
    required int oscillatorCount,
    double detuneSpread = 0.0,
    double vibratoFrequency = 0.0,
    double vibratoDepth = 0.0,
  }) {
    final oscillators = <WavetableOscillator>[];

    for (var i = 0; i < oscillatorCount; i++) {
      // Spread detune across oscillators
      double detune = 0.0;
      if (detuneSpread > 0 && oscillatorCount > 1) {
        // Distribute detune from -spread/2 to +spread/2
        final normalizedPos = i / (oscillatorCount - 1); // 0 to 1
        detune = (normalizedPos - 0.5) * detuneSpread;
      }

      oscillators.add(
        WavetableOscillator(
          wavetables,
          detuneCents: detune,
          vibratoFrequency: vibratoFrequency,
          vibratoDepth: vibratoDepth,
        ),
      );
    }

    return OscillatorBank._(oscillators);
  }

  OscillatorBank._(this.oscillators);

  /// Resets all oscillators in the bank.
  void reset() {
    for (final osc in oscillators) {
      osc.reset();
    }
  }

  /// Generates a mixed sample from all oscillators playing a chord.
  ///
  /// [frequencies] is a list of frequencies, one per oscillator.
  /// If fewer frequencies than oscillators, extra oscillators are silent.
  /// [morphPosition] determines wavetable blend for all oscillators.
  /// [sampleRate] is the audio sample rate.
  ///
  /// Returns the mixed sample (sum of all oscillators, normalized).
  double sampleChord({
    required List<double> frequencies,
    required double morphPosition,
    required int sampleRate,
  }) {
    var mixedSample = 0.0;
    final activeCount = math.min(frequencies.length, oscillators.length);

    for (var i = 0; i < activeCount; i++) {
      mixedSample += oscillators[i].sample(
        frequency: frequencies[i],
        morphPosition: morphPosition,
        sampleRate: sampleRate,
      );
    }

    // Normalize to prevent clipping
    if (activeCount > 0) {
      mixedSample /= math.sqrt(activeCount.toDouble());
    }

    return mixedSample.clamp(-1.0, 1.0);
  }

  /// Generates samples with each oscillator at a different morph position.
  ///
  /// Useful for creating evolving textures where different voices
  /// have different timbres.
  double sampleWithMorphSpread({
    required List<double> frequencies,
    required double baseMorphPosition,
    required double morphSpread,
    required int sampleRate,
  }) {
    var mixedSample = 0.0;
    final activeCount = math.min(frequencies.length, oscillators.length);

    for (var i = 0; i < activeCount; i++) {
      // Calculate morph position for this oscillator
      double morphPos = baseMorphPosition;
      if (morphSpread > 0 && activeCount > 1) {
        final normalizedPos = i / (activeCount - 1);
        morphPos += (normalizedPos - 0.5) * morphSpread;
      }
      morphPos = morphPos.clamp(0.0, 1.0);

      mixedSample += oscillators[i].sample(
        frequency: frequencies[i],
        morphPosition: morphPos,
        sampleRate: sampleRate,
      );
    }

    // Normalize
    if (activeCount > 0) {
      mixedSample /= math.sqrt(activeCount.toDouble());
    }

    return mixedSample.clamp(-1.0, 1.0);
  }

  /// Sets vibrato parameters for all oscillators.
  void setVibrato({required double frequency, required double depth}) {
    for (final osc in oscillators) {
      osc.vibratoFrequency = frequency;
      osc.vibratoDepth = depth;
    }
  }
}

/// Configuration for a single voice in a polyphonic synthesizer.
class VoiceConfig {
  /// The frequency of this voice in Hz.
  final double frequency;

  /// Volume of this voice (0.0 to 1.0).
  final double volume;

  /// Stereo pan position (-1.0 = left, 0.0 = center, 1.0 = right).
  final double pan;

  /// Morph position for this voice (0.0 to 1.0).
  final double morphPosition;

  /// Detune in cents for this voice.
  final double detuneCents;

  const VoiceConfig({
    required this.frequency,
    this.volume = 1.0,
    this.pan = 0.0,
    this.morphPosition = 0.0,
    this.detuneCents = 0.0,
  });

  /// Creates a copy with modified values.
  VoiceConfig copyWith({
    double? frequency,
    double? volume,
    double? pan,
    double? morphPosition,
    double? detuneCents,
  }) {
    return VoiceConfig(
      frequency: frequency ?? this.frequency,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      morphPosition: morphPosition ?? this.morphPosition,
      detuneCents: detuneCents ?? this.detuneCents,
    );
  }
}
