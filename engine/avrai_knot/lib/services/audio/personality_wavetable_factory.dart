// Personality Wavetable Factory
//
// Generates wavetables shaped by personality dimensions.
// Creates unique timbres for each user's personality profile.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avrai_knot/models/audio/personality_audio_params.dart';
import 'package:avrai_knot/models/audio/wavetable.dart';

/// Factory for generating wavetables based on personality.
///
/// Creates a set of 16 wavetables that can be morphed between,
/// with each wavetable's harmonic content shaped by the user's
/// personality dimensions.
///
/// **Usage:**
/// ```dart
/// final factory = PersonalityWavetableFactory();
/// final wavetables = factory.createWavetableSet(dimensions);
/// ```
class PersonalityWavetableFactory {
  static const String _logName = 'PersonalityWavetableFactory';

  /// Number of samples per wavetable.
  static const int wavetableSize = 2048;

  /// Number of wavetables in a set (for morphing).
  static const int wavetableCount = 16;

  /// Cache of generated wavetable sets.
  final Map<String, WavetableSet> _cache = {};

  /// Maximum cache size before cleanup.
  static const int maxCacheSize = 10;

  /// Creates a wavetable set from personality dimensions.
  ///
  /// Returns a cached set if one exists for this personality signature.
  WavetableSet createWavetableSet(Map<String, double> dimensions) {
    final signature = PersonalityAudioParams.createSignature(dimensions);

    // Check cache
    if (_cache.containsKey(signature)) {
      developer.log('Using cached wavetables for $signature', name: _logName);
      return _cache[signature]!;
    }

    developer.log('Generating new wavetables for personality', name: _logName);

    // Generate new wavetable set
    final params = PersonalityAudioParams.fromDimensions(dimensions);
    final tables = _generateWavetables(params);

    final wavetableSet = WavetableSet(
      tables: tables,
      personalitySignature: signature,
      name: 'personality_${signature.hashCode}',
    );

    // Cache the result
    _addToCache(signature, wavetableSet);

    return wavetableSet;
  }

  /// Generates a list of wavetables based on audio parameters.
  List<Wavetable> _generateWavetables(PersonalityAudioParams params) {
    final tables = <Wavetable>[];

    for (var i = 0; i < wavetableCount; i++) {
      // Morph progress from 0 to 1
      final morphProgress = i / (wavetableCount - 1);

      final table = _generateSingleWavetable(
        params: params,
        morphProgress: morphProgress,
        index: i,
      );

      tables.add(table);
    }

    return tables;
  }

  /// Generates a single wavetable at the given morph position.
  Wavetable _generateSingleWavetable({
    required PersonalityAudioParams params,
    required double morphProgress,
    required int index,
  }) {
    final samples = Float64List(wavetableSize);
    final twoPi = 2.0 * math.pi;

    // Calculate harmonic content based on personality and morph position
    final harmonics = _calculateHarmonics(params, morphProgress);

    // Generate the waveform
    for (var sampleIndex = 0; sampleIndex < wavetableSize; sampleIndex++) {
      final phase = sampleIndex / wavetableSize;
      var sample = 0.0;

      // Add each harmonic
      for (var h = 0; h < harmonics.length; h++) {
        final harmonicNumber = h + 1;
        final amplitude = harmonics[h];

        if (amplitude.abs() < 0.001) continue;

        // Calculate phase offset for this harmonic
        final phaseOffset = _calculatePhaseOffset(
          harmonicNumber: harmonicNumber,
          params: params,
          morphProgress: morphProgress,
        );

        sample +=
            amplitude * math.sin(phase * twoPi * harmonicNumber + phaseOffset);
      }

      samples[sampleIndex] = sample;
    }

    // Normalize
    var maxAmp = 0.0;
    for (var i = 0; i < wavetableSize; i++) {
      maxAmp = math.max(maxAmp, samples[i].abs());
    }
    if (maxAmp > 0.99) {
      final normFactor = 0.99 / maxAmp;
      for (var i = 0; i < wavetableSize; i++) {
        samples[i] *= normFactor;
      }
    }

    return Wavetable(
      samples: samples,
      name: 'morph_${(morphProgress * 100).round()}',
    );
  }

  /// Calculates harmonic amplitudes based on personality.
  List<double> _calculateHarmonics(
    PersonalityAudioParams params,
    double morphProgress,
  ) {
    final harmonics = <double>[];

    // Number of harmonics varies with value orientation (richness)
    // and morphProgress (evolution)
    final harmonicCount = (4 + params.harmonicCount * morphProgress)
        .round()
        .clamp(4, 32);

    for (var h = 0; h < harmonicCount; h++) {
      final harmonicNumber = h + 1;

      // Base amplitude with rolloff
      var amplitude = 1.0 / math.pow(harmonicNumber, params.harmonicRolloff);

      // Odd/even balance (authenticity)
      final isEven = harmonicNumber % 2 == 0;
      if (isEven) {
        amplitude *= params.oddEvenBalance;
      } else {
        amplitude *= 1.0 - params.oddEvenBalance * 0.3;
      }

      // Add variation based on morph progress
      // Early morph = simpler, later = more complex
      if (harmonicNumber > 4) {
        amplitude *= morphProgress;
      }

      // Add slight randomness for organic feel (deterministic based on harmonic)
      final organicVariation = _deterministicRandom(
        seed: harmonicNumber * 42,
        scale: params.oddEvenBalance * 0.2,
      );
      amplitude *= 1.0 + organicVariation;

      harmonics.add(amplitude.clamp(0.0, 1.0));
    }

    return harmonics;
  }

  /// Calculates phase offset for a harmonic.
  double _calculatePhaseOffset({
    required int harmonicNumber,
    required PersonalityAudioParams params,
    required double morphProgress,
  }) {
    // Phase offset creates timbral variation
    // Higher authenticity = less phase distortion
    final maxPhaseOffset = (1.0 - params.oddEvenBalance) * 0.3;

    // Deterministic phase based on harmonic number
    final basePhase = _deterministicRandom(
      seed: harmonicNumber * 17,
      scale: maxPhaseOffset,
    );

    // Add morph-based variation
    final morphVariation = morphProgress * math.pi * 0.1;

    return basePhase + morphVariation;
  }

  /// Generates a deterministic "random" value.
  double _deterministicRandom({required int seed, required double scale}) {
    // Use sine-based hash for deterministic randomness
    final hash = math.sin(seed * 12.9898 + 78.233) * 43758.5453;
    return (hash - hash.floor()) * scale;
  }

  /// Adds a wavetable set to the cache, evicting old entries if necessary.
  void _addToCache(String signature, WavetableSet set) {
    // Evict oldest if cache is full
    if (_cache.length >= maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      developer.log('Evicted cached wavetables: $oldestKey', name: _logName);
    }

    _cache[signature] = set;
  }

  /// Clears the wavetable cache.
  void clearCache() {
    _cache.clear();
    developer.log('Wavetable cache cleared', name: _logName);
  }

  /// Gets the current cache size.
  int get cacheSize => _cache.length;

  /// Creates a simple wavetable set for testing.
  ///
  /// Uses default personality (all dimensions at 0.5).
  WavetableSet createDefaultWavetableSet() {
    return createWavetableSet(const {});
  }

  /// Creates wavetables for a specific personality preset.
  WavetableSet createFromPreset(Map<String, double> preset) {
    return createWavetableSet(preset);
  }
}

/// Pre-built wavetable factory configurations for common use cases.
class WavetablePresets {
  WavetablePresets._();

  /// Creates wavetables for the birth harmony experience.
  ///
  /// Optimized for the 60-second birth experience with
  /// smooth transitions between chaos and harmony.
  static WavetableSet createBirthHarmonySet(
    PersonalityWavetableFactory factory,
    Map<String, double> dimensions,
  ) {
    // Birth harmony uses a specific personality variation
    // that emphasizes the evolution from chaos to order
    final birthDimensions = Map<String, double>.from(dimensions);

    // Slightly increase authenticity for warmer sound
    final currentAuth = birthDimensions['authenticity_preference'] ?? 0.5;
    birthDimensions['authenticity_preference'] = (currentAuth + 0.7) / 2;

    // Slightly increase value orientation for richer harmonics
    final currentValue = birthDimensions['value_orientation'] ?? 0.5;
    birthDimensions['value_orientation'] = (currentValue + 0.8) / 2;

    return factory.createWavetableSet(birthDimensions);
  }

  /// Creates wavetables for the formation sound.
  ///
  /// Optimized for the 8-second formation experience.
  static WavetableSet createFormationSet(
    PersonalityWavetableFactory factory,
    Map<String, double> dimensions,
  ) {
    // Formation uses a slightly more chaotic starting point
    final formationDimensions = Map<String, double>.from(dimensions);

    // Lower initial trust for more tension that resolves
    final currentTrust = formationDimensions['trust_network_reliance'] ?? 0.5;
    formationDimensions['trust_network_reliance'] = currentTrust * 0.8;

    return factory.createWavetableSet(formationDimensions);
  }

  /// Creates wavetables for loading sounds.
  ///
  /// Optimized for short, ambient loading sounds.
  static WavetableSet createLoadingSet(
    PersonalityWavetableFactory factory,
    Map<String, double> dimensions,
  ) {
    // Loading sounds are shorter, more ambient
    final loadingDimensions = Map<String, double>.from(dimensions);

    // Reduce energy for calmer loading experience
    final currentEnergy = loadingDimensions['energy_preference'] ?? 0.5;
    loadingDimensions['energy_preference'] = currentEnergy * 0.6;

    // Increase authenticity for warmth
    final currentAuth = loadingDimensions['authenticity_preference'] ?? 0.5;
    loadingDimensions['authenticity_preference'] = (currentAuth + 0.6) / 2;

    return factory.createWavetableSet(loadingDimensions);
  }
}
