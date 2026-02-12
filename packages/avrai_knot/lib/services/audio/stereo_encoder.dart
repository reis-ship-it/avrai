// Stereo Encoder
//
// Handles stereo panning, mixing, and WAV file encoding.
//
// Part of the Wavetable Knot Audio Synthesis system.
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avrai_knot/services/audio/simple_reverb.dart';

/// Stereo audio encoder with WAV file output.
///
/// Handles:
/// - Stereo panning (equal-power law)
/// - Stereo/mono mixing
/// - WAV file encoding (44.1kHz, 16-bit)
/// - Normalization to prevent clipping
class StereoEncoder {
  /// Sample rate in Hz.
  final int sampleRate;

  /// Bit depth (typically 16).
  final int bitDepth;

  /// Number of channels (1 = mono, 2 = stereo).
  final int channels;

  /// Creates a stereo encoder with default settings.
  ///
  /// [sampleRate] defaults to 44100 (CD quality).
  /// [bitDepth] defaults to 16.
  /// [channels] defaults to 2 (stereo).
  StereoEncoder({
    this.sampleRate = 44100,
    this.bitDepth = 16,
    this.channels = 2,
  });

  /// Encodes interleaved stereo samples to WAV format.
  ///
  /// [leftSamples] and [rightSamples] should be normalized (-1.0 to 1.0).
  /// Returns a complete WAV file as bytes.
  Uint8List encodeWav({
    required Float64List leftSamples,
    required Float64List rightSamples,
  }) {
    if (leftSamples.length != rightSamples.length) {
      throw ArgumentError('Left and right sample counts must match');
    }

    final numSamples = leftSamples.length;
    final bytesPerSample = bitDepth ~/ 8;
    final dataSize = numSamples * channels * bytesPerSample;
    final fileSize = 36 + dataSize; // WAV header is 44 bytes, data at byte 44

    final buffer = ByteData(44 + dataSize);

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
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(
      28,
      sampleRate * channels * bytesPerSample,
      Endian.little,
    ); // byte rate
    buffer.setUint16(
      32,
      channels * bytesPerSample,
      Endian.little,
    ); // block align
    buffer.setUint16(34, bitDepth, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Sample data (interleaved stereo)
    var offset = 44;
    for (var i = 0; i < numSamples; i++) {
      // Left channel
      final leftSample = leftSamples[i].clamp(-1.0, 1.0);
      final leftInt = (leftSample * 32767.0).round().clamp(-32768, 32767);
      buffer.setInt16(offset, leftInt, Endian.little);
      offset += 2;

      // Right channel
      final rightSample = rightSamples[i].clamp(-1.0, 1.0);
      final rightInt = (rightSample * 32767.0).round().clamp(-32768, 32767);
      buffer.setInt16(offset, rightInt, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Encodes mono samples to WAV format.
  Uint8List encodeMonoWav(Float64List samples) {
    final numSamples = samples.length;
    final bytesPerSample = bitDepth ~/ 8;
    final dataSize = numSamples * 1 * bytesPerSample;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

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
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * bytesPerSample, Endian.little);
    buffer.setUint16(32, bytesPerSample, Endian.little);
    buffer.setUint16(34, bitDepth, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Sample data
    var offset = 44;
    for (var i = 0; i < numSamples; i++) {
      final sample = samples[i].clamp(-1.0, 1.0);
      final intSample = (sample * 32767.0).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Saves stereo audio to a WAV file.
  Future<File> saveWav({
    required String path,
    required Float64List leftSamples,
    required Float64List rightSamples,
  }) async {
    final wavBytes = encodeWav(
      leftSamples: leftSamples,
      rightSamples: rightSamples,
    );

    final file = File(path);
    await file.writeAsBytes(wavBytes);
    return file;
  }

  /// Saves mono audio to a WAV file.
  Future<File> saveMonoWav({
    required String path,
    required Float64List samples,
  }) async {
    final wavBytes = encodeMonoWav(samples);
    final file = File(path);
    await file.writeAsBytes(wavBytes);
    return file;
  }

  /// Saves to a temporary WAV file.
  Future<File> saveToTempFile({
    required Float64List leftSamples,
    required Float64List rightSamples,
    String prefix = 'audio',
  }) async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/${prefix}_$timestamp.wav';

    return saveWav(
      path: path,
      leftSamples: leftSamples,
      rightSamples: rightSamples,
    );
  }
}

/// Audio mixer for combining multiple audio sources.
class AudioMixer {
  /// Sample rate in Hz.
  final int sampleRate;

  /// Total duration in seconds.
  final double duration;

  late final Float64List _leftBuffer;
  late final Float64List _rightBuffer;

  /// Creates an audio mixer.
  AudioMixer({
    required this.sampleRate,
    required this.duration,
  }) {
    final numSamples = (sampleRate * duration).round();
    _leftBuffer = Float64List(numSamples);
    _rightBuffer = Float64List(numSamples);
  }

  /// Gets the left channel buffer.
  Float64List get leftBuffer => _leftBuffer;

  /// Gets the right channel buffer.
  Float64List get rightBuffer => _rightBuffer;

  /// Total number of samples.
  int get numSamples => _leftBuffer.length;

  /// Adds a sample at the given time position.
  void addSample({
    required double time,
    required double value,
    double pan = 0.0,
  }) {
    final sampleIndex = (time * sampleRate).round();
    if (sampleIndex < 0 || sampleIndex >= numSamples) return;

    final stereo = _panSample(value, pan);
    _leftBuffer[sampleIndex] += stereo.left;
    _rightBuffer[sampleIndex] += stereo.right;
  }

  /// Adds a mono sample to both channels at the given sample index.
  void addSampleAtIndex({
    required int index,
    required StereoSample stereo,
  }) {
    if (index < 0 || index >= numSamples) return;
    _leftBuffer[index] += stereo.left;
    _rightBuffer[index] += stereo.right;
  }

  /// Mixes another buffer into this mixer.
  void mixBuffer({
    required Float64List buffer,
    double pan = 0.0,
    double volume = 1.0,
    int startIndex = 0,
  }) {
    for (var i = 0; i < buffer.length; i++) {
      final index = startIndex + i;
      if (index >= numSamples) break;

      final sample = buffer[i] * volume;
      final stereo = _panSample(sample, pan);
      _leftBuffer[index] += stereo.left;
      _rightBuffer[index] += stereo.right;
    }
  }

  /// Normalizes the buffers to prevent clipping.
  void normalize({double targetPeak = 0.95}) {
    var maxAmp = 0.0;

    for (var i = 0; i < numSamples; i++) {
      maxAmp = math.max(maxAmp, _leftBuffer[i].abs());
      maxAmp = math.max(maxAmp, _rightBuffer[i].abs());
    }

    if (maxAmp > targetPeak) {
      final factor = targetPeak / maxAmp;
      for (var i = 0; i < numSamples; i++) {
        _leftBuffer[i] *= factor;
        _rightBuffer[i] *= factor;
      }
    }
  }

  /// Applies a fade in at the beginning.
  void applyFadeIn(double fadeTime) {
    final fadeSamples = (fadeTime * sampleRate).round();
    for (var i = 0; i < fadeSamples && i < numSamples; i++) {
      final factor = i / fadeSamples;
      _leftBuffer[i] *= factor;
      _rightBuffer[i] *= factor;
    }
  }

  /// Applies a fade out at the end.
  void applyFadeOut(double fadeTime) {
    final fadeSamples = (fadeTime * sampleRate).round();
    final startIndex = numSamples - fadeSamples;

    for (var i = startIndex; i < numSamples; i++) {
      if (i < 0) continue;
      final factor = (numSamples - i) / fadeSamples;
      _leftBuffer[i] *= factor;
      _rightBuffer[i] *= factor;
    }
  }

  /// Clears the buffers.
  void clear() {
    for (var i = 0; i < numSamples; i++) {
      _leftBuffer[i] = 0.0;
      _rightBuffer[i] = 0.0;
    }
  }

  /// Applies equal-power panning to a sample.
  StereoSample _panSample(double value, double pan) {
    // Equal-power panning law
    // pan: -1.0 = left, 0.0 = center, 1.0 = right
    final angle = (pan + 1) * math.pi / 4; // 0 to π/2
    final left = value * math.cos(angle);
    final right = value * math.sin(angle);
    return StereoSample(left, right);
  }

  /// Encodes the mixed audio to WAV.
  Uint8List toWav({StereoEncoder? encoder}) {
    normalize();

    final enc = encoder ?? StereoEncoder(sampleRate: sampleRate);
    return enc.encodeWav(
      leftSamples: _leftBuffer,
      rightSamples: _rightBuffer,
    );
  }
}

/// Calculates stereo width and panning based on personality.
class PersonalityPanner {
  /// Stereo width (0.0 = mono, 1.0 = full stereo).
  final double stereoWidth;

  /// Pan movement amount (how much panning varies over time).
  final double panMovement;

  /// Base pan position (-1.0 to 1.0).
  final double basePan;

  const PersonalityPanner({
    this.stereoWidth = 0.5,
    this.panMovement = 0.3,
    this.basePan = 0.0,
  });

  /// Creates a panner from personality dimensions.
  factory PersonalityPanner.fromDimensions(Map<String, double> dimensions) {
    final community = dimensions['community_orientation'] ?? 0.5;
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;

    return PersonalityPanner(
      stereoWidth: community * 0.8, // 0-80% stereo width
      panMovement: exploration * 0.5, // 0-50% pan movement
      basePan: 0.0,
    );
  }

  /// Calculates pan position at a given time.
  double panAt(double time, {double frequency = 0.5}) {
    // Slow oscillation for natural movement
    final movement = math.sin(time * frequency * 2 * math.pi) * panMovement;
    return (basePan + movement).clamp(-1.0, 1.0);
  }

  /// Applies stereo width to a stereo sample.
  StereoSample applyWidth(StereoSample input) {
    final mid = (input.left + input.right) * 0.5;
    final side = (input.left - input.right) * 0.5;

    final left = mid + side * stereoWidth;
    final right = mid - side * stereoWidth;

    return StereoSample(left, right);
  }
}
