import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// AVRA BLE broadcast frame (v1).
///
/// This is a **24-byte** service-data payload designed to be:
/// - deterministic across platforms (iOS/Android)
/// - stable to parse in scanners (no JSON parsing required)
/// - compatible with the Event Mode coherence math in
///   `docs/agents/reference/EVENT_MODE_POLICY.md`
///
/// **Frame layout (v1):**
/// - `magic[4]`: ASCII `"AVRA"`
/// - `ver[1]`: `1`
/// - `flags[1]`: bitfield
///   - bit0: event_mode_enabled
///   - bit1: connect_ok
///   - bit2: brownout
/// - `epoch[2]`: little-endian `floor(utcMillis / EPOCH_MS) mod 65536`
/// - `node_tag[4]`: first 4 bytes of sha256(node_id_utf8)
/// - `dims_q[12]`: quantized dimensions (0..255) in canonical order
///
/// Total: 24 bytes.
class SpotsBroadcastFrameV1 {
  static const int byteLength = 24;
  static const int dimensionsCount = 12;

  static const int version = 1;
  static const int epochMs = 5 * 60 * 1000; // 5-minute buckets

  static const List<int> _magic = <int>[
    0x53, // S
    0x50, // P
    0x54, // T
    0x53, // S
  ];

  /// Canonical dimension ordering for dims_q.
  ///
  /// Must remain stable for v1.
  static const List<String> dimensionOrder = <String>[
    'exploration_eagerness',
    'community_orientation',
    'authenticity_preference',
    'social_discovery_style',
    'temporal_flexibility',
    'location_adventurousness',
    'curation_tendency',
    'trust_network_reliance',
    'energy_preference',
    'novelty_seeking',
    'value_orientation',
    'crowd_tolerance',
  ];

  /// Returns `true` if bytes look like a v1 frame (cheap check).
  static bool looksLikeFrame(Uint8List bytes) {
    if (bytes.length != byteLength) return false;
    if (bytes[0] != _magic[0] ||
        bytes[1] != _magic[1] ||
        bytes[2] != _magic[2] ||
        bytes[3] != _magic[3]) {
      return false;
    }
    return bytes[4] == version;
  }

  /// Encode a frame v1.
  ///
  /// The caller is responsible for ensuring `dims` contains values in 0..1.
  /// Missing dimensions default to 0.5.
  static Uint8List encode({
    required int utcMillis,
    required String nodeId,
    required Map<String, double> dims,
    required bool eventModeEnabled,
    required bool connectOk,
    required bool brownout,
  }) {
    final epoch = ((utcMillis ~/ epochMs) % 65536).clamp(0, 65535);

    var flags = 0;
    if (eventModeEnabled) flags |= 0x01;
    if (connectOk) flags |= 0x02;
    if (brownout) flags |= 0x04;

    final nodeTag = _sha256First4(nodeId);

    final out = Uint8List(byteLength);
    out.setRange(0, 4, _magic);
    out[4] = version;
    out[5] = flags & 0xFF;
    out[6] = epoch & 0xFF;
    out[7] = (epoch >> 8) & 0xFF;
    out.setRange(8, 12, nodeTag);

    for (var i = 0; i < dimensionsCount; i++) {
      final name = dimensionOrder[i];
      final p = dims[name] ?? 0.5;
      out[12 + i] = _quantizeByte(p);
    }

    return out;
  }

  /// Decode a frame v1. Returns null if invalid.
  static SpotsBroadcastFrameV1Decoded? decode(Uint8List bytes) {
    if (!looksLikeFrame(bytes)) return null;
    if (bytes.length != byteLength) return null;

    final flags = bytes[5];
    final epoch = bytes[6] | (bytes[7] << 8);
    final nodeTag = Uint8List.sublistView(bytes, 8, 12);
    final dimsQ = Uint8List.sublistView(bytes, 12, 24);

    return SpotsBroadcastFrameV1Decoded._(
      flags: flags,
      epoch: epoch,
      nodeTag: Uint8List.fromList(nodeTag),
      dimsQ: Uint8List.fromList(dimsQ),
    );
  }

  static Uint8List _sha256First4(String nodeId) {
    final digest = sha256.convert(utf8.encode(nodeId));
    // Digest.bytes is 32 bytes.
    return Uint8List.fromList(digest.bytes.sublist(0, 4));
  }

  static double _clamp01(double x) => x < 0.0
      ? 0.0
      : (x > 1.0 ? 1.0 : x);

  /// Quantize a probability into a byte using the required rounding:
  /// `q = floor(clamp(p,0,1)*255 + 0.5)`.
  static int _quantizeByte(double p) {
    final scaled = _clamp01(p) * 255.0;
    final q = (scaled + 0.5).floor();
    return q.clamp(0, 255);
  }
}

class SpotsBroadcastFrameV1Decoded {
  final int flags;
  final int epoch;
  final Uint8List nodeTag; // 4 bytes
  final Uint8List dimsQ; // 12 bytes

  const SpotsBroadcastFrameV1Decoded._({
    required this.flags,
    required this.epoch,
    required this.nodeTag,
    required this.dimsQ,
  });

  bool get eventModeEnabled => (flags & 0x01) != 0;
  bool get connectOk => (flags & 0x02) != 0;
  bool get brownout => (flags & 0x04) != 0;

  /// Dequantize `dims_q` bytes to probabilities.
  List<double> dequantizeProbabilities() =>
      dimsQ.map((q) => q / 255.0).toList(growable: false);

  /// Convert `dims_q` into a normalized (real-only) quantum state vector.
  ///
  /// This follows the Event Mode policy:
  /// 1) p = q/255
  /// 2) a_k = sqrt(p_k)
  /// 3) normalize by L2 norm
  List<double> psiVector() {
    final amps = List<double>.filled(SpotsBroadcastFrameV1.dimensionsCount, 0.0);
    for (var i = 0; i < amps.length; i++) {
      amps[i] = sqrt(dimsQ[i] / 255.0);
    }

    final norm = _l2Norm(amps);
    if (norm <= 0.0) {
      final u = 1.0 / sqrt(amps.length.toDouble());
      return List<double>.filled(amps.length, u);
    }
    for (var i = 0; i < amps.length; i++) {
      amps[i] = amps[i] / norm;
    }
    return amps;
  }

  static double _l2Norm(List<double> v) {
    var sum = 0.0;
    for (final x in v) {
      sum += x * x;
    }
    return sqrt(sum);
  }
}

