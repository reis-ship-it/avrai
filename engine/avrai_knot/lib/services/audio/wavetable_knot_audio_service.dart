// Wavetable Knot Audio Service
//
// Generates harmonically rich audio from personality knots using wavetable synthesis.
// Replaces the sine-wave based KnotAudioService with personality-driven audio.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/audio/musical_scales.dart';
import 'package:avrai_knot/models/audio/personality_audio_params.dart';
import 'package:avrai_knot/models/audio/personality_envelope.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/musical_pattern.dart';
import 'package:avrai_knot/services/audio/personality_wavetable_factory.dart';
import 'package:avrai_knot/services/audio/simple_reverb.dart';
import 'package:avrai_knot/services/audio/stereo_encoder.dart';
import 'package:avrai_knot/services/audio/wavetable_oscillator.dart';

/// Wavetable-based audio service for knot sonification.
///
/// Uses wavetable synthesis to generate harmonically rich, personality-driven
/// audio from knot topology. Each user's audio is uniquely shaped by their
/// 12 avrai personality dimensions.
///
/// **Features:**
/// - All 12 personality dimensions shape the audio
/// - Wavetable morphing for evolving timbres
/// - Stereo audio with personality-driven panning
/// - Reverb for spatial depth
/// - Smooth transitions between phases
///
/// **Usage:**
/// ```dart
/// final service = WavetableKnotAudioService(
///   personalityLearning: personalityLearning,
/// );
///
/// await service.playBirthHarmony(knot);
/// ```
class WavetableKnotAudioService {
  static const String _logName = 'WavetableKnotAudioService';

  // Audio parameters
  static const int _sampleRate = 44100;
  static const double _baseFrequency = 220.0; // A3

  // Duration constants (matching original service)
  static const double _birthHarmonyDuration = 60.0; // 60 seconds
  static const double _formationDuration = 8.0; // 8 seconds
  static const double _loadingDuration = 3.0; // 3 seconds

  /// Callback for looking up personality dimensions.
  /// Takes an agentId and returns a Future with the dimensions map.
  final Future<Map<String, double>> Function(String agentId)?
  _getDimensionsCallback;

  /// Factory for generating wavetables.
  final PersonalityWavetableFactory _wavetableFactory;

  /// Audio player instance.
  AudioPlayer? _audioPlayer;

  /// Whether audio is currently playing.
  bool _isPlaying = false;

  /// Current temporary audio file.
  File? _currentAudioFile;

  /// Creates a wavetable knot audio service.
  ///
  /// [getDimensionsCallback] is a function that returns personality dimensions
  /// for a given agentId. If null, default dimensions (0.5 for all) are used.
  /// [wavetableFactory] is the factory for generating wavetables.
  WavetableKnotAudioService({
    Future<Map<String, double>> Function(String agentId)? getDimensionsCallback,
    PersonalityWavetableFactory? wavetableFactory,
  }) : _getDimensionsCallback = getDimensionsCallback,
       _wavetableFactory = wavetableFactory ?? PersonalityWavetableFactory();

  /// Gets the audio player, creating if necessary.
  AudioPlayer? _getOrCreateAudioPlayer() {
    if (_audioPlayer != null) return _audioPlayer;
    try {
      _audioPlayer = AudioPlayer();
      return _audioPlayer;
    } catch (e, stackTrace) {
      developer.log(
        'AudioPlayer not available; playback disabled',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Retrieves personality dimensions for a knot.
  Future<Map<String, double>> _getDimensions(PersonalityKnot knot) async {
    if (_getDimensionsCallback == null) {
      developer.log('No dimensions callback, using defaults', name: _logName);
      return {};
    }

    try {
      return await _getDimensionsCallback(knot.agentId);
    } catch (e) {
      developer.log(
        'Failed to get personality dimensions',
        name: _logName,
        error: e,
      );
      return {};
    }
  }

  // ============================================
  // Public API (matches KnotAudioService)
  // ============================================

  /// Plays the birth harmony for a personality knot.
  ///
  /// A 60-second audio experience with 5 phases:
  /// - Transition (0-5s): Low rumble, building
  /// - Void (5-10s): Single tone emerges
  /// - Emergence (10-25s): Harmonics appear
  /// - Formation (25-45s): Chord builds
  /// - Harmony (45-60s): Full resolution, fade out
  Future<void> playBirthHarmony(PersonalityKnot knot) async {
    developer.log('Playing birth harmony', name: _logName);

    if (_isPlaying) {
      await stopAudio();
    }

    try {
      final dimensions = await _getDimensions(knot);
      final wavBytes = await _generateBirthHarmony(knot, dimensions);
      await _playWavBytes(wavBytes);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to play birth harmony',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Plays the formation sound for a knot.
  ///
  /// An 8-second sound representing knot formation.
  Future<void> playFormationSound(PersonalityKnot knot) async {
    developer.log('Playing formation sound', name: _logName);

    if (_isPlaying) {
      await stopAudio();
    }

    try {
      final dimensions = await _getDimensions(knot);
      final wavBytes = await _generateFormationSound(knot, dimensions);
      await _playWavBytes(wavBytes);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to play formation sound',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Plays a loading sound for a knot.
  ///
  /// A 3-second looping sound.
  Future<void> playKnotLoadingSound(PersonalityKnot knot) async {
    developer.log('Playing loading sound', name: _logName);

    if (_isPlaying) {
      await stopAudio();
    }

    try {
      final dimensions = await _getDimensions(knot);
      final wavBytes = await _generateLoadingSound(knot, dimensions);
      await _playWavBytes(wavBytes, loop: true);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to play loading sound',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Plays fabric harmony for a knot fabric.
  Future<void> playFabricHarmony(KnotFabric fabric) async {
    developer.log(
      'Playing fabric harmony for ${fabric.userCount} users',
      name: _logName,
    );

    if (_isPlaying) {
      await stopAudio();
    }

    try {
      final wavBytes = await _generateFabricHarmony(fabric);
      await _playWavBytes(wavBytes);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to play fabric harmony',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stops any currently playing audio.
  Future<void> stopAudio() async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
      } catch (e) {
        developer.log('Error stopping audio', name: _logName, error: e);
      }
    }
    _isPlaying = false;

    // Clean up temp file
    if (_currentAudioFile != null) {
      try {
        if (await _currentAudioFile!.exists()) {
          await _currentAudioFile!.delete();
        }
      } catch (e) {
        developer.log('Error deleting temp file', name: _logName, error: e);
      }
      _currentAudioFile = null;
    }
  }

  /// Disposes of resources.
  void dispose() {
    stopAudio();
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    _wavetableFactory.clearCache();
  }

  /// Generates loading sound (for testing).
  Future<AudioSequence> generateKnotLoadingSound(PersonalityKnot knot) async {
    final dimensions = await _getDimensions(knot);
    final params = PersonalityAudioParams.fromDimensions(dimensions);

    return AudioSequence(
      notes: _generateMelody(params, _loadingDuration),
      rhythm: params.tempo,
      harmony: [1.0],
      duration: _loadingDuration,
      loop: true,
    );
  }

  /// Generates fabric harmony (for testing).
  Future<AudioSequence> generateFabricHarmony(KnotFabric fabric) async {
    return AudioSequence(
      notes: [],
      rhythm: 120.0,
      harmony: [1.0],
      duration: 10.0,
      loop: false,
    );
  }

  // ============================================
  // Audio Generation
  // ============================================

  /// Generates birth harmony audio.
  Future<Uint8List> _generateBirthHarmony(
    PersonalityKnot knot,
    Map<String, double> dimensions,
  ) async {
    final params = PersonalityAudioParams.fromDimensions(dimensions);
    final wavetables = WavetablePresets.createBirthHarmonySet(
      _wavetableFactory,
      dimensions,
    );
    final envelope = MultiStageEnvelope.birthHarmony();
    final mode = MusicalScales.selectMode(dimensions);
    final chordBuilder = ChordBuilder(
      baseFrequency: _baseFrequency,
      mode: mode,
    );

    // Create oscillator bank
    final oscillatorBank = OscillatorBank.create(
      wavetables: wavetables,
      oscillatorCount: params.voiceCount,
      detuneSpread: params.detuneSpread,
      vibratoFrequency: params.vibratoFrequency,
      vibratoDepth: params.vibratoDepth,
    );

    // Create mixer
    final mixer = AudioMixer(
      sampleRate: _sampleRate,
      duration: _birthHarmonyDuration,
    );

    // Create reverb
    final reverb = SimpleReverb(
      sampleRate: _sampleRate,
      roomSize: params.reverbRoomSize,
      damping: 1.0 - params.oddEvenBalance,
    );

    // Generate audio sample by sample
    final numSamples = (mixer.numSamples).toInt();
    final frequencies = chordBuilder.buildDeterministicChord(params.voiceCount);

    for (var i = 0; i < numSamples; i++) {
      final time = i / _sampleRate;
      final morphPosition = envelope.morphPositionAt(time);
      final envelopeValue = envelope.valueAt(time);

      // Generate oscillator output
      final sample = oscillatorBank.sampleWithMorphSpread(
        frequencies: frequencies,
        baseMorphPosition: morphPosition,
        morphSpread: 0.2,
        sampleRate: _sampleRate,
      );

      // Apply envelope
      final envelopedSample = sample * envelopeValue;

      // Apply reverb
      final wetSample = reverb.process(envelopedSample);
      final mixedSample =
          envelopedSample * (1 - params.reverbMix) +
          wetSample * params.reverbMix;

      // Calculate pan
      final pan = math.sin(time * 0.1) * params.panMovement;

      // Add to mixer
      mixer.addSampleAtIndex(index: i, stereo: _panSample(mixedSample, pan));
    }

    // Apply fades
    mixer.applyFadeIn(0.5);
    mixer.applyFadeOut(2.0);

    return mixer.toWav();
  }

  /// Generates formation sound audio.
  Future<Uint8List> _generateFormationSound(
    PersonalityKnot knot,
    Map<String, double> dimensions,
  ) async {
    final params = PersonalityAudioParams.fromDimensions(dimensions);
    final wavetables = WavetablePresets.createFormationSet(
      _wavetableFactory,
      dimensions,
    );
    final envelope = MultiStageEnvelope.formation();
    final mode = MusicalScales.selectMode(dimensions);
    final chordBuilder = ChordBuilder(
      baseFrequency: _baseFrequency,
      mode: mode,
    );

    // Create oscillator bank
    final oscillatorBank = OscillatorBank.create(
      wavetables: wavetables,
      oscillatorCount: math.min(params.voiceCount, 4),
      detuneSpread: params.detuneSpread * 0.5,
    );

    // Create mixer
    final mixer = AudioMixer(
      sampleRate: _sampleRate,
      duration: _formationDuration,
    );

    // Create reverb
    final reverb = SimpleReverb(
      sampleRate: _sampleRate,
      roomSize: params.reverbRoomSize * 0.8,
    );

    final numSamples = mixer.numSamples;
    final frequencies = chordBuilder.buildDeterministicChord(
      math.min(params.voiceCount, 4),
    );

    for (var i = 0; i < numSamples; i++) {
      final time = i / _sampleRate;
      final morphPosition = envelope.morphPositionAt(time);
      final envelopeValue = envelope.valueAt(time);

      final sample = oscillatorBank.sampleChord(
        frequencies: frequencies,
        morphPosition: morphPosition,
        sampleRate: _sampleRate,
      );

      final envelopedSample = sample * envelopeValue;
      final wetSample = reverb.process(envelopedSample);
      final mixedSample = envelopedSample * 0.7 + wetSample * 0.3;

      mixer.addSampleAtIndex(index: i, stereo: StereoSample.mono(mixedSample));
    }

    mixer.applyFadeIn(0.2);
    mixer.applyFadeOut(0.5);

    return mixer.toWav();
  }

  /// Generates loading sound audio.
  Future<Uint8List> _generateLoadingSound(
    PersonalityKnot knot,
    Map<String, double> dimensions,
  ) async {
    final params = PersonalityAudioParams.fromDimensions(dimensions);
    final wavetables = WavetablePresets.createLoadingSet(
      _wavetableFactory,
      dimensions,
    );
    final mode = MusicalScales.selectMode(dimensions);

    // Use fewer voices for loading sound
    final oscillatorBank = OscillatorBank.create(
      wavetables: wavetables,
      oscillatorCount: 2,
      detuneSpread: 10.0,
    );

    // Create mixer
    final mixer = AudioMixer(
      sampleRate: _sampleRate,
      duration: _loadingDuration,
    );

    // Use envelope from params for note shaping
    // Note: Currently using simple pulse for loading sound

    final numSamples = mixer.numSamples;
    final baseFreq = MusicalScales.degreeToFrequency(
      baseFrequency: _baseFrequency * 0.5,
      degree: 0,
      mode: mode,
    );
    final fifthFreq = MusicalScales.degreeToFrequency(
      baseFrequency: _baseFrequency * 0.5,
      degree: 4,
      mode: mode,
    );

    for (var i = 0; i < numSamples; i++) {
      final time = i / _sampleRate;
      final morphPosition = (time / _loadingDuration).clamp(0.0, 1.0);

      // Simple pulsing envelope
      final pulseFreq = params.tempo / 60.0;
      final pulse = (math.sin(time * pulseFreq * math.pi * 2) + 1) * 0.25 + 0.5;

      final sample = oscillatorBank.sampleChord(
        frequencies: [baseFreq, fifthFreq],
        morphPosition: morphPosition * 0.5, // Stay in simpler wavetables
        sampleRate: _sampleRate,
      );

      mixer.addSampleAtIndex(
        index: i,
        stereo: StereoSample.mono(sample * pulse * 0.6),
      );
    }

    // Smooth loop points
    mixer.applyFadeIn(0.1);
    mixer.applyFadeOut(0.1);

    return mixer.toWav();
  }

  /// Generates fabric harmony audio.
  Future<Uint8List> _generateFabricHarmony(KnotFabric fabric) async {
    // Use averaged dimensions from all strands
    // For now use defaults - could aggregate from fabric strands
    final wavetables = _wavetableFactory.createDefaultWavetableSet();

    final mixer = AudioMixer(sampleRate: _sampleRate, duration: 10.0);

    final oscillatorBank = OscillatorBank.create(
      wavetables: wavetables,
      oscillatorCount: math.min(fabric.userCount, 6),
      detuneSpread: 20.0,
    );

    final numSamples = mixer.numSamples;
    final frequencies = <double>[];

    // Create chord from fabric size
    for (var i = 0; i < math.min(fabric.userCount, 6); i++) {
      frequencies.add(_baseFrequency * (1 + i * 0.25));
    }

    for (var i = 0; i < numSamples; i++) {
      final time = i / _sampleRate;
      final morphPosition = (time / 10.0).clamp(0.0, 1.0);

      // Fade envelope
      var envelope = 1.0;
      if (time < 1.0) {
        envelope = time;
      } else if (time > 9.0) {
        envelope = 10.0 - time;
      }

      final sample = oscillatorBank.sampleChord(
        frequencies: frequencies,
        morphPosition: morphPosition,
        sampleRate: _sampleRate,
      );

      mixer.addSampleAtIndex(
        index: i,
        stereo: StereoSample.mono(sample * envelope * 0.7),
      );
    }

    return mixer.toWav();
  }

  // ============================================
  // Helpers
  // ============================================

  /// Generates a simple melody.
  List<MusicalNote> _generateMelody(
    PersonalityAudioParams params,
    double duration,
  ) {
    final notes = <MusicalNote>[];
    final noteDuration = 60.0 / params.tempo;
    var time = 0.0;

    while (time < duration) {
      notes.add(
        MusicalNote(
          frequency: _baseFrequency * (1 + math.Random().nextDouble() * 0.5),
          duration: noteDuration,
          volume: 0.7,
        ),
      );
      time += noteDuration;
    }

    return notes;
  }

  /// Pans a sample using equal-power panning.
  StereoSample _panSample(double value, double pan) {
    final angle = (pan + 1) * math.pi / 4;
    final left = value * math.cos(angle);
    final right = value * math.sin(angle);
    return StereoSample(left, right);
  }

  /// Plays WAV bytes through the audio player.
  Future<void> _playWavBytes(Uint8List wavBytes, {bool loop = false}) async {
    final player = _getOrCreateAudioPlayer();
    if (player == null) {
      developer.log('Audio player not available', name: _logName);
      return;
    }

    // Save to temp file
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/knot_audio_$timestamp.wav');
    await tempFile.writeAsBytes(wavBytes);
    _currentAudioFile = tempFile;

    try {
      if (loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.release);
      }

      await player.play(DeviceFileSource(tempFile.path));
      _isPlaying = true;

      developer.log('Audio playback started', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to play audio',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
