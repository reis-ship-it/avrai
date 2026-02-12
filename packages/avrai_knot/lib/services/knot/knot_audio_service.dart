// Knot Audio Service
//
// Generates audio from knot topology (especially loading sounds)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 7: Audio & Privacy

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/musical_pattern.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';

/// Service for generating and playing audio from knot topology
///
/// **Audio Playback:** Uses audioplayers for actual audio playback
/// **Note:** Audio synthesis from frequencies requires additional work.
/// For now, uses a simplified approach with tone generation.
///
/// **DEPRECATED:** Use [WavetableKnotAudioService] instead for:
/// - Rich wavetable synthesis instead of sine waves
/// - All 12 personality dimensions shape the audio
/// - Stereo audio with reverb and panning
/// - Smooth wavetable morphing between timbres
///
/// This service is maintained for backward compatibility but will be
/// removed in a future version.
@Deprecated('Use WavetableKnotAudioService instead for richer audio synthesis')
class KnotAudioService {
  static const String _logName = 'KnotAudioService';

  // Musical parameters
  static const double _baseFrequency = 220.0; // A3 note
  static const double _frequencyRange = 880.0; // 4 octaves
  static const double _noteDuration = 0.2; // 200ms per note
  static const double _loadingSoundDuration = 3.0; // 3 seconds
  static const double _fabricHarmonyDuration =
      10.0; // 10 seconds for fabric harmony

  // Audio player
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  File? _currentAudioFile; // Track current temp file for cleanup

  // Audio synthesis parameters
  static const int _sampleRate = 44100; // CD quality
  static const int _bitsPerSample = 16;
  static const int _numChannels = 1; // Mono

  AudioPlayer? _getOrCreateAudioPlayer() {
    if (_audioPlayer != null) return _audioPlayer;
    try {
      _audioPlayer = AudioPlayer();
      return _audioPlayer;
    } catch (e, stackTrace) {
      // In unit-test contexts the audioplayers platform implementation is not
      // available (MissingPluginException). This service still supports
      // generating musical patterns without playback.
      developer.log(
        'AudioPlayer not available; playback disabled',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate loading sound from user's knot
  ///
  /// Converts knot structure to musical pattern suitable for loading sounds
  Future<AudioSequence> generateKnotLoadingSound(PersonalityKnot knot) async {
    developer.log('Generating loading sound from knot', name: _logName);

    // Convert knot structure to musical pattern
    final musicalPattern = _knotToMusicalPattern(knot);

    return AudioSequence(
      notes: musicalPattern.notes,
      rhythm: musicalPattern.rhythm,
      harmony: musicalPattern.harmony,
      duration: _loadingSoundDuration,
      loop: true,
    );
  }

  /// Generate harmony from knot fabric (community/club weave)
  ///
  /// Converts a multi-strand braid fabric into polyphonic harmony where:
  /// - Each strand (user knot) = a voice/harmonic
  /// - Fabric invariants = overall harmony, rhythm, and stability
  /// - All voices play simultaneously = rich community sound
  ///
  /// **Algorithm:**
  /// 1. Each user knot → a voice (set of notes)
  /// 2. Fabric polynomials → chord progressions
  /// 3. Fabric density → rhythm/tempo
  /// 4. Fabric stability → harmony quality (consonant vs dissonant)
  /// 5. Mix all voices into polyphonic harmony
  Future<AudioSequence> generateFabricHarmony(KnotFabric fabric) async {
    developer.log(
      'Generating fabric harmony from ${fabric.userCount} user knots',
      name: _logName,
    );

    try {
      // Step 1: Convert each strand (user knot) to a voice
      final voices = <List<MusicalNote>>[];
      for (final userKnot in fabric.userKnots) {
        final pattern = _knotToMusicalPattern(userKnot);
        voices.add(pattern.notes);
      }

      // Step 2: Calculate fabric-level harmony from invariants
      final fabricHarmony = _calculateFabricHarmony(
        jonesPoly: fabric.invariants.jonesPolynomial.coefficients,
        alexanderPoly: fabric.invariants.alexanderPolynomial.coefficients,
        stability: fabric.invariants.stability,
      );

      // Step 3: Calculate rhythm from fabric density
      final rhythm = _calculateFabricRhythm(fabric.invariants.density);

      // Step 4: Mix all voices into polyphonic harmony
      final mixedNotes = _mixVoicesIntoHarmony(
        voices: voices,
        fabricHarmony: fabricHarmony,
        stability: fabric.invariants.stability,
      );

      developer.log(
        '✅ Generated fabric harmony: ${mixedNotes.length} notes, '
        '${voices.length} voices, ${rhythm.toStringAsFixed(1)}BPM',
        name: _logName,
      );

      return AudioSequence(
        notes: mixedNotes,
        rhythm: rhythm,
        harmony: fabricHarmony,
        duration: _fabricHarmonyDuration,
        loop: true,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to generate fabric harmony: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Fallback to single knot pattern if fabric conversion fails
      if (fabric.userKnots.isNotEmpty) {
        return generateKnotLoadingSound(fabric.userKnots.first);
      }
      rethrow;
    }
  }

  /// Play fabric harmony (community/club weave sound)
  ///
  /// Generates polyphonic harmony from knot fabric and plays it.
  Future<void> playFabricHarmony(KnotFabric fabric) async {
    if (_isPlaying) {
      developer.log('Audio already playing, skipping', name: _logName);
      return;
    }

    developer.log(
      'Playing fabric harmony from ${fabric.userCount} user knots',
      name: _logName,
    );

    try {
      _isPlaying = true;

      // Generate fabric harmony
      final audioSequence = await generateFabricHarmony(fabric);

      // Generate audio data (sine waves from frequencies)
      final audioSamples = await _synthesizeAudio(audioSequence);

      // Encode as WAV file
      final wavBytes = _encodeWav(audioSamples);

      // Save to temporary file
      final tempFile = await _saveToTempFile(wavBytes);

      // Play using audioplayers
      final player = _getOrCreateAudioPlayer();
      if (player != null && tempFile != null) {
        // Clean up previous audio file if any
        await _cleanupAudioFile();
        _currentAudioFile = tempFile;

        // Set release mode for looping
        if (audioSequence.loop) {
          await player.setReleaseMode(ReleaseMode.loop);
        } else {
          await player.setReleaseMode(ReleaseMode.release);
        }

        // Play the audio file
        await player.play(DeviceFileSource(tempFile.path));

        developer.log(
          '✅ Playing fabric harmony: ${audioSequence.notes.length} notes, '
          '${audioSequence.rhythm.toStringAsFixed(1)}BPM, '
          '${(wavBytes.length / 1024).toStringAsFixed(1)}KB, '
          'loop=${audioSequence.loop}',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ Audio player not available or temp file creation failed',
          name: _logName,
        );
        _isPlaying = false;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to play fabric harmony: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    } finally {
      // Note: Don't set _isPlaying = false here - let stopAudio() handle it
      // The audio will continue playing until stopAudio() is called
    }
  }

  /// Convert knot to musical pattern
  ///
  /// **Algorithm:**
  /// - Each crossing = musical note
  /// - Crossing number determines frequency
  /// - Writhe determines rhythm
  /// - Polynomial coefficients determine harmony
  MusicalPattern _knotToMusicalPattern(PersonalityKnot knot) {
    final notes = <MusicalNote>[];

    // Extract knot properties
    final crossingNumber = knot.invariants.crossingNumber;
    final writhe = knot.invariants.writhe;
    final jonesPoly = knot.invariants.jonesPolynomial;
    final alexanderPoly = knot.invariants.alexanderPolynomial;

    // Generate notes from crossings
    // Each crossing contributes a note
    for (int i = 0; i < crossingNumber.clamp(0, 20); i++) {
      // Frequency based on crossing position and polynomial coefficients
      final frequency = _calculateNoteFrequency(
        crossingIndex: i,
        totalCrossings: crossingNumber,
        jonesCoeff: jonesPoly.isNotEmpty
            ? jonesPoly[i % jonesPoly.length]
            : 0.0,
        alexanderCoeff: alexanderPoly.isNotEmpty
            ? alexanderPoly[i % alexanderPoly.length]
            : 0.0,
      );

      // Duration based on writhe (more writhe = faster rhythm)
      final duration = _calculateNoteDuration(writhe);

      // Volume based on polynomial magnitude
      final volume = _calculateNoteVolume(
        jonesCoeff: jonesPoly.isNotEmpty
            ? jonesPoly[i % jonesPoly.length]
            : 0.0,
      );

      notes.add(
        MusicalNote(frequency: frequency, duration: duration, volume: volume),
      );
    }

    // Rhythm based on writhe (beats per minute)
    final rhythm = _calculateRhythm(writhe);

    // Harmony from polynomial coefficients
    final harmony = _calculateHarmony(jonesPoly, alexanderPoly);

    return MusicalPattern(
      notes: notes,
      rhythm: rhythm,
      harmony: harmony,
      duration: _loadingSoundDuration,
      loop: true,
    );
  }

  /// Calculate note frequency from knot properties
  ///
  /// Uses polynomial coefficients to determine pitch
  double _calculateNoteFrequency({
    required int crossingIndex,
    required int totalCrossings,
    required double jonesCoeff,
    required double alexanderCoeff,
  }) {
    // Base frequency with crossing-based variation
    final crossingVariation =
        (crossingIndex / totalCrossings.clamp(1, 20)) * _frequencyRange;

    // Polynomial-based pitch adjustment
    final polyAdjustment = (jonesCoeff + alexanderCoeff) * 100.0;

    // Final frequency
    final frequency = (_baseFrequency + crossingVariation + polyAdjustment)
        .clamp(110.0, 2000.0); // A2 to B6 range

    return frequency;
  }

  /// Calculate note duration from writhe
  ///
  /// Higher writhe = faster rhythm (shorter notes)
  double _calculateNoteDuration(int writhe) {
    // Base duration with writhe adjustment
    final writheFactor = (writhe.abs() / 10.0).clamp(0.0, 1.0);
    final duration = _noteDuration * (1.0 - writheFactor * 0.5);

    return duration.clamp(0.1, 0.5);
  }

  /// Calculate note volume from polynomial coefficient
  ///
  /// Larger coefficients = louder notes
  double _calculateNoteVolume({required double jonesCoeff}) {
    final magnitude = jonesCoeff.abs();
    return (0.3 + magnitude * 0.7).clamp(0.1, 1.0);
  }

  /// Calculate rhythm (beats per minute) from writhe
  ///
  /// Higher writhe = faster tempo
  double _calculateRhythm(int writhe) {
    const baseBPM = 120.0; // Base tempo
    final writheAdjustment = writhe.abs() * 5.0; // 5 BPM per writhe unit
    return (baseBPM + writheAdjustment).clamp(60.0, 180.0);
  }

  /// Calculate harmony (chord progression) from polynomials
  ///
  /// Uses polynomial coefficients to determine chord frequencies
  List<double> _calculateHarmony(
    List<double> jonesPoly,
    List<double> alexanderPoly,
  ) {
    final harmony = <double>[];

    // Use first few coefficients to create chord
    final maxCoeffs = math.min(
      3,
      math.max(jonesPoly.length, alexanderPoly.length),
    );

    for (int i = 0; i < maxCoeffs; i++) {
      final jonesCoeff = i < jonesPoly.length ? jonesPoly[i] : 0.0;
      final alexanderCoeff = i < alexanderPoly.length ? alexanderPoly[i] : 0.0;

      // Chord frequency from coefficients
      final chordFreq =
          _baseFrequency * (1.0 + (jonesCoeff + alexanderCoeff) * 0.5);
      harmony.add(chordFreq.clamp(110.0, 2000.0));
    }

    // If no coefficients, use default chord
    if (harmony.isEmpty) {
      harmony.addAll([
        _baseFrequency,
        _baseFrequency * 1.25,
        _baseFrequency * 1.5,
      ]);
    }

    return harmony;
  }

  /// Calculate fabric-level harmony from fabric invariants
  ///
  /// Uses fabric polynomials and stability to create richer chord progressions
  /// that represent the community's overall harmonic structure.
  List<double> _calculateFabricHarmony({
    required List<double> jonesPoly,
    required List<double> alexanderPoly,
    required double stability,
  }) {
    final harmony = <double>[];

    // Use more coefficients for fabric (richer harmony)
    final maxCoeffs = math.min(
      5,
      math.max(jonesPoly.length, alexanderPoly.length),
    );

    for (int i = 0; i < maxCoeffs; i++) {
      final jonesCoeff = i < jonesPoly.length ? jonesPoly[i] : 0.0;
      final alexanderCoeff = i < alexanderPoly.length ? alexanderPoly[i] : 0.0;

      // Base chord frequency from coefficients
      var chordFreq =
          _baseFrequency * (1.0 + (jonesCoeff + alexanderCoeff) * 0.5);

      // Stability adjustment: high stability = consonant intervals
      // Low stability = more dissonant intervals
      if (stability > 0.7) {
        // High stability: use consonant intervals (major thirds, perfect fifths)
        final intervalRatios = [
          1.0,
          1.25,
          1.5,
          1.875,
          2.0,
        ]; // Root, major third, fifth, major seventh, octave
        if (i < intervalRatios.length) {
          chordFreq = _baseFrequency * intervalRatios[i];
        }
      } else if (stability < 0.3) {
        // Low stability: use more dissonant intervals
        final intervalRatios = [1.0, 1.2, 1.4, 1.7, 1.9]; // More dissonant
        if (i < intervalRatios.length) {
          chordFreq = _baseFrequency * intervalRatios[i];
        }
      }

      harmony.add(chordFreq.clamp(110.0, 2000.0));
    }

    // If no coefficients, use default chord based on stability
    if (harmony.isEmpty) {
      if (stability > 0.7) {
        // Consonant major chord
        harmony.addAll([
          _baseFrequency, // Root
          _baseFrequency * 1.25, // Major third
          _baseFrequency * 1.5, // Perfect fifth
        ]);
      } else if (stability < 0.3) {
        // Dissonant chord
        harmony.addAll([
          _baseFrequency, // Root
          _baseFrequency * 1.2, // Minor third
          _baseFrequency * 1.4, // Tritone
        ]);
      } else {
        // Neutral chord
        harmony.addAll([
          _baseFrequency,
          _baseFrequency * 1.25,
          _baseFrequency * 1.5,
        ]);
      }
    }

    return harmony;
  }

  /// Calculate rhythm from fabric density
  ///
  /// Higher density (more crossings per strand) = faster, more complex rhythm
  double _calculateFabricRhythm(double density) {
    const baseBPM = 100.0; // Base tempo for fabric
    // Density ranges from 0.0 to ~10.0 (crossings per strand)
    // Higher density = faster tempo
    final densityAdjustment = density * 20.0; // 20 BPM per density unit
    return (baseBPM + densityAdjustment).clamp(60.0, 200.0);
  }

  /// Mix multiple voices (strands) into polyphonic harmony
  ///
  /// Combines notes from all user knots into a single harmonious sequence.
  /// Each voice plays simultaneously, creating rich polyphonic texture.
  List<MusicalNote> _mixVoicesIntoHarmony({
    required List<List<MusicalNote>> voices,
    required List<double> fabricHarmony,
    required double stability,
  }) {
    if (voices.isEmpty) {
      return [];
    }

    // Find the maximum number of notes across all voices
    final maxNotes = voices.fold<int>(
      0,
      (max, voice) => math.max(max, voice.length),
    );

    // Mix voices: each position gets notes from all voices
    final mixedNotes = <MusicalNote>[];

    for (int noteIndex = 0; noteIndex < maxNotes; noteIndex++) {
      // Collect notes from all voices at this position
      final notesAtPosition = <MusicalNote>[];

      for (final voice in voices) {
        if (noteIndex < voice.length) {
          notesAtPosition.add(voice[noteIndex]);
        }
      }

      if (notesAtPosition.isEmpty) continue;

      // Mix notes: average frequency, sum durations, weighted volume
      var totalFrequency = 0.0;
      var totalDuration = 0.0;
      var totalVolume = 0.0;
      var count = 0;

      for (final note in notesAtPosition) {
        totalFrequency += note.frequency;
        totalDuration += note.duration;
        totalVolume += note.volume;
        count++;
      }

      // Calculate mixed note properties
      final mixedFreq = totalFrequency / count;
      final mixedDuration = totalDuration / count;

      // Volume: stability affects how voices blend
      // High stability = voices blend smoothly (lower volume per voice)
      // Low stability = voices stand out more (higher volume per voice)
      final volumeMultiplier = stability > 0.7 ? 0.6 : 0.8;
      final mixedVolume = (totalVolume / count * volumeMultiplier).clamp(
        0.1,
        1.0,
      );

      // Add fabric harmony frequencies as additional notes (chord tones)
      for (var i = 0; i < fabricHarmony.length && i < 3; i++) {
        final harmonyFreq = fabricHarmony[i];

        // Only add harmony note if it's different enough from mixed frequency
        if ((harmonyFreq - mixedFreq).abs() > 50.0) {
          mixedNotes.add(
            MusicalNote(
              frequency: harmonyFreq,
              duration: mixedDuration * 1.5, // Harmony notes last longer
              volume: mixedVolume * 0.4, // Lower volume for harmony
            ),
          );
        }
      }

      // Add the main mixed note
      mixedNotes.add(
        MusicalNote(
          frequency: mixedFreq,
          duration: mixedDuration,
          volume: mixedVolume,
        ),
      );
    }

    // Limit total notes to prevent overwhelming audio
    final maxTotalNotes = 50;
    if (mixedNotes.length > maxTotalNotes) {
      // Take evenly spaced notes
      final step = mixedNotes.length / maxTotalNotes;
      final sampledNotes = <MusicalNote>[];
      for (var i = 0; i < maxTotalNotes; i++) {
        final index = (i * step).round();
        if (index < mixedNotes.length) {
          sampledNotes.add(mixedNotes[index]);
        }
      }
      return sampledNotes;
    }

    return mixedNotes;
  }

  /// Play loading sound from knot
  ///
  /// Generates audio from knot topology and plays it using audioplayers.
  /// Audio is synthesized from frequencies using sine waves and saved to a temporary WAV file.
  Future<void> playKnotLoadingSound(PersonalityKnot knot) async {
    if (_isPlaying) {
      developer.log('Audio already playing, skipping', name: _logName);
      return;
    }

    developer.log('Playing loading sound from knot', name: _logName);

    try {
      _isPlaying = true;

      // Generate musical pattern
      final musicalPattern = _knotToMusicalPattern(knot);

      // Create audio sequence
      final audioSequence = AudioSequence(
        notes: musicalPattern.notes,
        rhythm: musicalPattern.rhythm,
        harmony: musicalPattern.harmony,
        duration: _loadingSoundDuration,
        loop: true,
      );

      // Generate audio data (sine waves from frequencies)
      final audioSamples = await _synthesizeAudio(audioSequence);

      // Encode as WAV file
      final wavBytes = _encodeWav(audioSamples);

      // Save to temporary file
      final tempFile = await _saveToTempFile(wavBytes);

      // Play using audioplayers
      final player = _getOrCreateAudioPlayer();
      if (player != null && tempFile != null) {
        // Clean up previous audio file if any
        await _cleanupAudioFile();
        _currentAudioFile = tempFile;

        // Set release mode for looping
        if (audioSequence.loop) {
          await player.setReleaseMode(ReleaseMode.loop);
        } else {
          await player.setReleaseMode(ReleaseMode.release);
        }

        // Play the audio file
        await player.play(DeviceFileSource(tempFile.path));

        developer.log(
          '✅ Playing knot audio: ${audioSequence.notes.length} notes, '
          '${audioSequence.rhythm.toStringAsFixed(1)}BPM, '
          '${(wavBytes.length / 1024).toStringAsFixed(1)}KB, '
          'loop=${audioSequence.loop}',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ Audio player not available or temp file creation failed',
          name: _logName,
        );
        _isPlaying = false;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to play knot loading sound: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    } finally {
      // Note: Don't set _isPlaying = false here - let stopAudio() handle it
      // The audio will continue playing until stopAudio() is called
    }
  }

  /// Stop playing audio
  Future<void> stopAudio() async {
    if (!_isPlaying) return;

    try {
      final player = _getOrCreateAudioPlayer();
      if (player != null) {
        await player.stop();
        await player.setReleaseMode(ReleaseMode.release);
      }
      _isPlaying = false;

      // Clean up temp file
      await _cleanupAudioFile();

      developer.log('Stopped audio playback', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error stopping audio: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _isPlaying = false;
    }
  }

  /// Clean up temporary audio file
  Future<void> _cleanupAudioFile() async {
    if (_currentAudioFile != null) {
      try {
        if (await _currentAudioFile!.exists()) {
          await _currentAudioFile!.delete();
        }
      } catch (e) {
        developer.log('Failed to delete temp audio file: $e', name: _logName);
      }
      _currentAudioFile = null;
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _cleanupAudioFile();
  }

  /// Generate audio data from musical pattern
  ///
  /// Returns audio samples as a list of doubles (normalized to -1.0 to 1.0)
  Future<List<double>> generateAudioData(AudioSequence sequence) async {
    return _synthesizeAudio(sequence);
  }

  /// Synthesize audio from audio sequence
  ///
  /// Generates audio samples by creating sine waves for each note
  /// and mixing them together with proper timing and volume.
  Future<List<double>> _synthesizeAudio(AudioSequence sequence) async {
    if (sequence.notes.isEmpty) {
      // Generate silence
      final silenceSamples = (_sampleRate * sequence.duration).round();
      return List<double>.filled(silenceSamples, 0.0);
    }

    // Calculate total samples needed
    final totalSamples = (_sampleRate * sequence.duration).round();
    final audioBuffer = List<double>.filled(totalSamples, 0.0);

    // Calculate note timing based on rhythm (BPM)
    final beatsPerSecond = sequence.rhythm / 60.0;
    final samplesPerBeat = (_sampleRate / beatsPerSecond).round();

    // Generate each note
    for (var noteIndex = 0; noteIndex < sequence.notes.length; noteIndex++) {
      final note = sequence.notes[noteIndex];

      // Calculate start position (stagger notes based on rhythm)
      final noteStartBeat = noteIndex % (sequence.notes.length);
      final startSample = (noteStartBeat * samplesPerBeat).clamp(
        0,
        totalSamples - 1,
      );

      // Calculate note duration in samples
      final noteSamples = (note.duration * _sampleRate).round();
      final endSample = (startSample + noteSamples).clamp(0, totalSamples);

      // Generate sine wave for this note
      final twoPi = 2.0 * math.pi;
      final phaseIncrement = (note.frequency * twoPi) / _sampleRate;

      for (var i = startSample; i < endSample && i < totalSamples; i++) {
        final phase = (i - startSample) * phaseIncrement;

        // Generate sine wave with volume envelope (fade in/out to avoid clicks)
        final progress = (i - startSample) / noteSamples;
        final envelope = _calculateEnvelope(progress);
        final sample = math.sin(phase) * note.volume * envelope;

        // Mix with existing audio (additive synthesis)
        audioBuffer[i] += sample;
      }
    }

    // Add harmony (chord tones) as background
    if (sequence.harmony.isNotEmpty) {
      final harmonyVolume = 0.3; // Lower volume for harmony
      final harmonyStart = (totalSamples * 0.1).round(); // Start after 10%
      final harmonyEnd = (totalSamples * 0.9).round(); // End before 90%

      for (final harmonyFreq in sequence.harmony) {
        final twoPi = 2.0 * math.pi;
        final phaseIncrement = (harmonyFreq * twoPi) / _sampleRate;

        for (var i = harmonyStart; i < harmonyEnd && i < totalSamples; i++) {
          final phase = (i - harmonyStart) * phaseIncrement;
          final sample = math.sin(phase) * harmonyVolume;
          audioBuffer[i] += sample;
        }
      }
    }

    // Normalize to prevent clipping
    final maxAmplitude = audioBuffer.fold<double>(
      0.0,
      (max, sample) => math.max(max, sample.abs()),
    );

    if (maxAmplitude > 1.0) {
      final normalizationFactor = 1.0 / maxAmplitude;
      for (var i = 0; i < audioBuffer.length; i++) {
        audioBuffer[i] *= normalizationFactor;
      }
    }

    return audioBuffer;
  }

  /// Calculate volume envelope to prevent clicks
  ///
  /// Applies fade in/out at the beginning and end of notes
  double _calculateEnvelope(double progress) {
    if (progress < 0.05) {
      // Fade in (first 5%)
      return progress / 0.05;
    } else if (progress > 0.95) {
      // Fade out (last 5%)
      return (1.0 - progress) / 0.05;
    } else {
      // Full volume
      return 1.0;
    }
  }

  /// Encode audio samples as WAV file
  ///
  /// Converts normalized audio samples (-1.0 to 1.0) to 16-bit PCM WAV format
  Uint8List _encodeWav(List<double> samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * _numChannels * (_bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize; // Header size + data size

    final buffer = ByteData(44 + dataSize); // WAV header is 44 bytes

    // RIFF header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // fmt chunk size
    buffer.setUint16(20, 1, Endian.little); // audio format (1 = PCM)
    buffer.setUint16(22, _numChannels, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(
      28,
      _sampleRate * _numChannels * (_bitsPerSample ~/ 8),
      Endian.little,
    ); // byte rate
    buffer.setUint16(
      32,
      _numChannels * (_bitsPerSample ~/ 8),
      Endian.little,
    ); // block align
    buffer.setUint16(34, _bitsPerSample, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Convert samples to 16-bit PCM
    var offset = 44;
    for (final sample in samples) {
      // Clamp to [-1.0, 1.0] and convert to 16-bit integer
      final clampedSample = sample.clamp(-1.0, 1.0);
      final intSample = (clampedSample * 32767.0).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Save audio bytes to temporary file
  ///
  /// Creates a temporary WAV file that can be played by audioplayers
  Future<File?> _saveToTempFile(Uint8List audioBytes) async {
    try {
      // Use system temp directory
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/knot_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
      );

      await tempFile.writeAsBytes(audioBytes);

      developer.log(
        'Saved audio to temp file: ${tempFile.path}',
        name: _logName,
      );

      return tempFile;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save temp audio file: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  // ============================================================
  // EVOLVING SOUND: Cacophony → Harmony Formation
  // ============================================================

  /// Generate evolving sound that transitions from cacophony to harmony
  ///
  /// **Formation Progress (0.0 to 1.0):**
  /// - 0.0-0.25: Pure cacophony (random frequencies, dissonant)
  /// - 0.25-0.50: Emerging patterns (some harmonics appear)
  /// - 0.50-0.85: Forming harmony (consonant intervals emerge)
  /// - 0.85-1.0: Pure harmony (final knot sound)
  ///
  /// Returns audio samples for the given progress segment
  Future<List<double>> generateEvolvingSound({
    required PersonalityKnot knot,
    required double progress,
    required double segmentDuration,
  }) async {
    developer.log(
      'Generating evolving sound at progress: ${(progress * 100).toStringAsFixed(1)}%',
      name: _logName,
    );

    // Get target harmony from knot
    final targetPattern = _knotToMusicalPattern(knot);

    // Calculate chaos factor (1.0 = pure chaos, 0.0 = pure harmony)
    final chaosFactor = _calculateChaosFactor(progress);

    // Generate audio with chaos/harmony blend
    return _synthesizeEvolvingAudio(
      targetPattern: targetPattern,
      chaosFactor: chaosFactor,
      duration: segmentDuration,
    );
  }

  /// Play evolving formation sound in real-time
  ///
  /// This plays a continuous sound that evolves from cacophony to harmony
  /// as the formation progresses. Call updateFormationProgress() to update.
  Future<void> playFormationSound(PersonalityKnot knot) async {
    if (_isPlaying) {
      developer.log('Audio already playing, skipping', name: _logName);
      return;
    }

    developer.log('Starting formation sound', name: _logName);

    try {
      _isPlaying = true;
      _formationKnot = knot;
      _formationProgress = 0.0;

      // Generate full evolving audio sequence
      final audioSamples = await _generateFullFormationAudio(knot);

      // Encode as WAV
      final wavBytes = _encodeWav(audioSamples);

      // Save to temp file
      final tempFile = await _saveToTempFile(wavBytes);

      // Play using audioplayers
      final player = _getOrCreateAudioPlayer();
      if (player != null && tempFile != null) {
        await _cleanupAudioFile();
        _currentAudioFile = tempFile;

        await player.setReleaseMode(ReleaseMode.release);
        await player.play(DeviceFileSource(tempFile.path));

        developer.log(
          '✅ Playing formation sound: ${(wavBytes.length / 1024).toStringAsFixed(1)}KB',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to play formation sound: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _isPlaying = false;
    }
  }

  // Formation state (used for real-time updates in future)
  // ignore: unused_field
  PersonalityKnot? _formationKnot;
  // ignore: unused_field
  double _formationProgress = 0.0;

  /// Calculate chaos factor based on formation progress
  ///
  /// Returns a value from 0.0 (pure harmony) to 1.0 (pure chaos)
  double _calculateChaosFactor(double progress) {
    if (progress < 0.25) {
      // Phase 1: High chaos (0.8 - 1.0)
      return 1.0 - (progress / 0.25) * 0.2;
    } else if (progress < 0.50) {
      // Phase 2: Transitioning (0.4 - 0.8)
      final phaseProgress = (progress - 0.25) / 0.25;
      return 0.8 - phaseProgress * 0.4;
    } else if (progress < 0.85) {
      // Phase 3: Emerging harmony (0.1 - 0.4)
      final phaseProgress = (progress - 0.50) / 0.35;
      return 0.4 - phaseProgress * 0.3;
    } else {
      // Phase 4: Pure harmony (0.0 - 0.1)
      final phaseProgress = (progress - 0.85) / 0.15;
      return 0.1 - phaseProgress * 0.1;
    }
  }

  /// Generate full formation audio (8 seconds of evolving sound)
  Future<List<double>> _generateFullFormationAudio(PersonalityKnot knot) async {
    const formationDuration = 8.0; // seconds
    final totalSamples = (_sampleRate * formationDuration).round();
    final audioBuffer = List<double>.filled(totalSamples, 0.0);

    // Get target musical pattern from knot
    final targetPattern = _knotToMusicalPattern(knot);

    // Generate audio in segments, each with different chaos level
    const segmentCount = 100;
    final samplesPerSegment = totalSamples ~/ segmentCount;

    for (int segment = 0; segment < segmentCount; segment++) {
      final progress = segment / segmentCount;
      final chaosFactor = _calculateChaosFactor(progress);

      final startSample = segment * samplesPerSegment;
      final endSample = math.min(
        (segment + 1) * samplesPerSegment,
        totalSamples,
      );

      // Generate segment audio
      _generateSegmentAudio(
        buffer: audioBuffer,
        startSample: startSample,
        endSample: endSample,
        targetPattern: targetPattern,
        chaosFactor: chaosFactor,
        segmentIndex: segment,
      );
    }

    // Normalize
    final maxAmplitude = audioBuffer.fold<double>(
      0.0,
      (max, sample) => math.max(max, sample.abs()),
    );

    if (maxAmplitude > 1.0) {
      final factor = 0.9 / maxAmplitude;
      for (var i = 0; i < audioBuffer.length; i++) {
        audioBuffer[i] *= factor;
      }
    }

    return audioBuffer;
  }

  /// Generate a segment of evolving audio
  void _generateSegmentAudio({
    required List<double> buffer,
    required int startSample,
    required int endSample,
    required MusicalPattern targetPattern,
    required double chaosFactor,
    required int segmentIndex,
  }) {
    final random = math.Random(segmentIndex * 42); // Deterministic randomness

    // Blend between chaos frequencies and target harmony
    for (int i = startSample; i < endSample; i++) {
      var sample = 0.0;

      // Add chaos component (random frequencies)
      if (chaosFactor > 0.01) {
        // Generate multiple random frequencies for chaos
        final chaosFreqCount = (chaosFactor * 8).ceil().clamp(1, 8);
        for (int j = 0; j < chaosFreqCount; j++) {
          // Random frequency between 100Hz and 2000Hz
          final chaosFreq = 100 + random.nextDouble() * 1900;
          final phase = (i * chaosFreq * 2 * math.pi) / _sampleRate;
          // Add some frequency modulation for "warbling" chaos
          final fmMod = math.sin(i * 0.001 * (j + 1)) * 0.3;
          sample += math.sin(phase + fmMod) * chaosFactor * 0.15;
        }
      }

      // Add harmony component (target knot frequencies)
      final harmonyFactor = 1.0 - chaosFactor;
      if (harmonyFactor > 0.01 && targetPattern.notes.isNotEmpty) {
        // Play notes from the pattern
        for (int noteIdx = 0; noteIdx < targetPattern.notes.length; noteIdx++) {
          final note = targetPattern.notes[noteIdx];
          final phase = (i * note.frequency * 2 * math.pi) / _sampleRate;
          // Envelope for smooth note
          final noteProgress = (i % (_sampleRate ~/ 2)) / (_sampleRate ~/ 2);
          final envelope = math.sin(noteProgress * math.pi);
          sample +=
              math.sin(phase) * note.volume * harmonyFactor * envelope * 0.2;
        }

        // Add harmony chord tones
        for (
          int chordIdx = 0;
          chordIdx < targetPattern.harmony.length;
          chordIdx++
        ) {
          final harmonyFreq = targetPattern.harmony[chordIdx];
          final phase = (i * harmonyFreq * 2 * math.pi) / _sampleRate;
          sample += math.sin(phase) * harmonyFactor * 0.1;
        }
      }

      // Crossfade to prevent clicks
      if (startSample > 0 && i < startSample + 100) {
        final fadeIn = (i - startSample) / 100.0;
        sample *= fadeIn;
      }
      if (i > endSample - 100) {
        final fadeOut = (endSample - i) / 100.0;
        sample *= fadeOut;
      }

      buffer[i] += sample;
    }
  }

  /// Synthesize audio that blends chaos and harmony
  Future<List<double>> _synthesizeEvolvingAudio({
    required MusicalPattern targetPattern,
    required double chaosFactor,
    required double duration,
  }) async {
    final totalSamples = (_sampleRate * duration).round();
    final audioBuffer = List<double>.filled(totalSamples, 0.0);

    _generateSegmentAudio(
      buffer: audioBuffer,
      startSample: 0,
      endSample: totalSamples,
      targetPattern: targetPattern,
      chaosFactor: chaosFactor,
      segmentIndex: 0,
    );

    return audioBuffer;
  }

  // ============================================================
  // BIRTH HARMONY: Synchronized Audio for Birth Experience
  // ============================================================

  /// Play birth harmony synchronized with birth experience phases
  ///
  /// **Phase Audio:**
  /// - **Transition** (0-5s): Low rumble, building anticipation
  /// - **Void** (5-10s): Single tone derived from knot base frequency
  /// - **Emergence** (10-25s): Harmonics emerge, frequencies swirl
  /// - **Formation** (25-45s): Chord builds from knot invariants
  /// - **Harmony** (45-60s): Full resolution, complete chord
  ///
  /// **Frequency Derivation:**
  /// - Base frequency = 110Hz * 2^(crossingNumber/12) (like musical scale)
  /// - Chord type = major (positive signature) or minor (negative)
  /// - Harmonic richness = |writhe| / 10
  Future<void> playBirthHarmony(PersonalityKnot knot) async {
    if (_isPlaying) {
      developer.log('Audio already playing, skipping birth harmony', name: _logName);
      return;
    }

    developer.log('Starting birth harmony for knot', name: _logName);

    try {
      _isPlaying = true;

      // Generate the complete birth harmony audio (60 seconds)
      final audioSamples = await _generateBirthHarmonyAudio(knot);

      // Encode as WAV
      final wavBytes = _encodeWav(audioSamples);

      // Save to temp file
      final tempFile = await _saveToTempFile(wavBytes);

      // Play using audioplayers
      final player = _getOrCreateAudioPlayer();
      if (player != null && tempFile != null) {
        await _cleanupAudioFile();
        _currentAudioFile = tempFile;

        await player.setReleaseMode(ReleaseMode.release);
        await player.play(DeviceFileSource(tempFile.path));

        developer.log(
          '✅ Playing birth harmony: ${(wavBytes.length / 1024).toStringAsFixed(1)}KB, 60s',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to play birth harmony: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _isPlaying = false;
    }
  }

  /// Generate complete birth harmony audio (60 seconds)
  Future<List<double>> _generateBirthHarmonyAudio(PersonalityKnot knot) async {
    const totalDuration = 60.0; // 60 seconds
    final totalSamples = (_sampleRate * totalDuration).round();
    final audioBuffer = List<double>.filled(totalSamples, 0.0);

    // Extract knot properties for audio
    final crossingNumber = knot.invariants.crossingNumber;
    final writhe = knot.invariants.writhe;
    final signature = knot.invariants.signature;
    final jonesPoly = knot.invariants.jonesPolynomial;

    // Calculate base frequency: 110Hz * 2^(crossingNumber/12)
    // This maps crossing number to musical scale (like MIDI notes)
    final baseFrequency = 110.0 * math.pow(2, crossingNumber.clamp(0, 12) / 12.0);

    // Chord type: major (positive signature) or minor (negative)
    final isMajor = signature >= 0;

    // Harmonic richness based on writhe
    final harmonicRichness = (writhe.abs() / 10.0).clamp(0.0, 1.0);

    // Generate each phase
    _generateTransitionPhase(audioBuffer, 0, 5.0 * _sampleRate, baseFrequency);
    _generateVoidPhase(audioBuffer, 5.0 * _sampleRate, 10.0 * _sampleRate, baseFrequency);
    _generateEmergencePhase(audioBuffer, 10.0 * _sampleRate, 25.0 * _sampleRate, 
        baseFrequency, harmonicRichness, jonesPoly);
    _generateFormationPhase(audioBuffer, 25.0 * _sampleRate, 45.0 * _sampleRate, 
        baseFrequency, isMajor, harmonicRichness);
    _generateHarmonyPhase(audioBuffer, 45.0 * _sampleRate, 60.0 * _sampleRate, 
        baseFrequency, isMajor, harmonicRichness);

    // Normalize
    final maxAmplitude = audioBuffer.fold<double>(
      0.0,
      (max, sample) => math.max(max, sample.abs()),
    );

    if (maxAmplitude > 1.0) {
      final factor = 0.9 / maxAmplitude;
      for (var i = 0; i < audioBuffer.length; i++) {
        audioBuffer[i] *= factor;
      }
    }

    return audioBuffer;
  }

  /// Generate transition phase: low rumble building anticipation
  void _generateTransitionPhase(
    List<double> buffer,
    double startSec,
    double endSec,
    double baseFrequency,
  ) {
    final startSample = (startSec).round();
    final endSample = (endSec).round().clamp(0, buffer.length);

    // Low frequency rumble (around 30-50Hz)
    final rumbleFreq = 35.0;
    final twoPi = 2.0 * math.pi;

    for (int i = startSample; i < endSample; i++) {
      final progress = (i - startSample) / (endSample - startSample);
      
      // Rumble with increasing intensity
      final intensity = progress * 0.3;
      final phase = (i * rumbleFreq * twoPi) / _sampleRate;
      var sample = math.sin(phase) * intensity;
      
      // Add subtle high-frequency shimmer that builds
      if (progress > 0.5) {
        final shimmerProgress = (progress - 0.5) * 2;
        final shimmerFreq = baseFrequency * 0.5;
        final shimmerPhase = (i * shimmerFreq * twoPi) / _sampleRate;
        sample += math.sin(shimmerPhase) * shimmerProgress * 0.05;
      }

      buffer[i] += sample;
    }
  }

  /// Generate void phase: single tone emerges
  void _generateVoidPhase(
    List<double> buffer,
    double startSec,
    double endSec,
    double baseFrequency,
  ) {
    final startSample = (startSec).round();
    final endSample = (endSec).round().clamp(0, buffer.length);

    final twoPi = 2.0 * math.pi;

    for (int i = startSample; i < endSample; i++) {
      final progress = (i - startSample) / (endSample - startSample);
      
      // Single tone fading in
      final intensity = progress * 0.5;
      final phase = (i * baseFrequency * twoPi) / _sampleRate;
      var sample = math.sin(phase) * intensity;
      
      // Gentle pulse (like a heartbeat)
      final pulseEnvelope = 0.8 + 0.2 * math.sin(progress * twoPi * 4);
      sample *= pulseEnvelope;

      buffer[i] += sample;
    }
  }

  /// Generate emergence phase: harmonics emerge, frequencies swirl
  void _generateEmergencePhase(
    List<double> buffer,
    double startSec,
    double endSec,
    double baseFrequency,
    double harmonicRichness,
    List<double> jonesPoly,
  ) {
    final startSample = (startSec).round();
    final endSample = (endSec).round().clamp(0, buffer.length);

    final twoPi = 2.0 * math.pi;

    for (int i = startSample; i < endSample; i++) {
      final progress = (i - startSample) / (endSample - startSample);
      
      var sample = 0.0;
      
      // Base tone continues
      final basePhase = (i * baseFrequency * twoPi) / _sampleRate;
      sample += math.sin(basePhase) * 0.4;
      
      // Harmonics emerge progressively
      final numHarmonics = (progress * 6 * (1 + harmonicRichness)).ceil().clamp(1, 8);
      for (int h = 2; h <= numHarmonics + 1; h++) {
        // Harmonic frequency with slight detuning for "swirling"
        final detune = math.sin(i * 0.0001 * h) * 2;
        final harmonicFreq = baseFrequency * h + detune;
        final harmonicPhase = (i * harmonicFreq * twoPi) / _sampleRate;
        
        // Harmonic intensity decreases with harmonic number
        final harmonicIntensity = 0.2 / h * progress;
        sample += math.sin(harmonicPhase) * harmonicIntensity;
      }
      
      // Use Jones polynomial coefficients for frequency modulation
      if (jonesPoly.isNotEmpty) {
        final modIdx = (progress * jonesPoly.length).floor() % jonesPoly.length;
        final modFreq = baseFrequency * (1 + jonesPoly[modIdx].abs() * 0.1);
        final modPhase = (i * modFreq * twoPi) / _sampleRate;
        sample += math.sin(modPhase) * 0.1 * progress;
      }

      buffer[i] += sample;
    }
  }

  /// Generate formation phase: chord builds and crystallizes
  void _generateFormationPhase(
    List<double> buffer,
    double startSec,
    double endSec,
    double baseFrequency,
    bool isMajor,
    double harmonicRichness,
  ) {
    final startSample = (startSec).round();
    final endSample = (endSec).round().clamp(0, buffer.length);

    final twoPi = 2.0 * math.pi;

    // Chord intervals (major or minor)
    final List<double> chordRatios = isMajor
        ? [1.0, 1.25, 1.5, 2.0] // Major: root, major third, fifth, octave
        : [1.0, 1.2, 1.5, 2.0]; // Minor: root, minor third, fifth, octave

    for (int i = startSample; i < endSample; i++) {
      final progress = (i - startSample) / (endSample - startSample);
      
      var sample = 0.0;
      
      // Chord tones fade in progressively
      for (int c = 0; c < chordRatios.length; c++) {
        final chordProgress = ((progress - c * 0.2) / 0.3).clamp(0.0, 1.0);
        if (chordProgress > 0) {
          final chordFreq = baseFrequency * chordRatios[c];
          final chordPhase = (i * chordFreq * twoPi) / _sampleRate;
          final intensity = chordProgress * 0.3;
          sample += math.sin(chordPhase) * intensity;
          
          // Add harmonics for richness
          if (harmonicRichness > 0.3) {
            final harmFreq = chordFreq * 2;
            final harmPhase = (i * harmFreq * twoPi) / _sampleRate;
            sample += math.sin(harmPhase) * intensity * harmonicRichness * 0.3;
          }
        }
      }
      
      // Subtle "crystallization" effect (high frequency sparkles)
      if (progress > 0.5) {
        final sparkleProgress = (progress - 0.5) * 2;
        final sparkleFreq = baseFrequency * 4 + math.sin(i * 0.001) * 100;
        final sparklePhase = (i * sparkleFreq * twoPi) / _sampleRate;
        sample += math.sin(sparklePhase) * 0.05 * sparkleProgress;
      }

      buffer[i] += sample;
    }
  }

  /// Generate harmony phase: full resolution, complete chord
  void _generateHarmonyPhase(
    List<double> buffer,
    double startSec,
    double endSec,
    double baseFrequency,
    bool isMajor,
    double harmonicRichness,
  ) {
    final startSample = (startSec).round();
    final endSample = (endSec).round().clamp(0, buffer.length);

    final twoPi = 2.0 * math.pi;

    // Full chord with extensions
    final List<double> fullChordRatios = isMajor
        ? [1.0, 1.25, 1.5, 1.875, 2.0, 2.5] // Major 7th extended
        : [1.0, 1.2, 1.5, 1.8, 2.0, 2.4]; // Minor 7th extended

    for (int i = startSample; i < endSample; i++) {
      final progress = (i - startSample) / (endSample - startSample);
      
      var sample = 0.0;
      
      // Full chord with all tones
      for (int c = 0; c < fullChordRatios.length; c++) {
        final chordFreq = baseFrequency * fullChordRatios[c];
        final chordPhase = (i * chordFreq * twoPi) / _sampleRate;
        
        // Intensity varies by chord tone (root and fifth louder)
        var intensity = 0.25;
        if (c == 0 || c == 2 || c == 4) intensity = 0.35;
        
        sample += math.sin(chordPhase) * intensity;
        
        // Rich harmonics
        if (harmonicRichness > 0.2) {
          final harm2 = chordFreq * 2;
          final harm3 = chordFreq * 3;
          sample += math.sin((i * harm2 * twoPi) / _sampleRate) * 0.1 * harmonicRichness;
          sample += math.sin((i * harm3 * twoPi) / _sampleRate) * 0.05 * harmonicRichness;
        }
      }
      
      // Gentle fade out at the end
      if (progress > 0.8) {
        final fadeOut = 1.0 - ((progress - 0.8) / 0.2);
        sample *= fadeOut;
      }
      
      // Gentle vibrato for warmth
      final vibratoFreq = 5.0; // 5Hz vibrato
      final vibratoDepth = 0.02;
      final vibrato = 1.0 + math.sin(i * vibratoFreq * twoPi / _sampleRate) * vibratoDepth;
      sample *= vibrato;

      buffer[i] += sample;
    }
  }
}
