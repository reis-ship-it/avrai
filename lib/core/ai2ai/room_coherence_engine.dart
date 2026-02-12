import 'dart:math';

import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

/// Computes a broadcast-safe “room coherence” signal from nearby AI frames.
///
/// This implements the Event Mode coherence primitives described in:
/// `docs/agents/reference/EVENT_MODE_POLICY.md`
///
/// **Core math (Patent #1 primitives, real-only broadcast-safe form):**
/// - Per-node state: \( |\psi_i\\rangle = normalize( sqrt(p_k) ) \)
/// - Room state: \( |\\Psi\\rangle = normalize( \\sum_i |\\psi_i\\rangle ) \)
/// - Coherence score: \( mean_i |\\langle \\psi_i | \\Psi \\rangle|^2 \)
/// - Stability: Bures distance \( D_B = \\sqrt{2(1-|\\langle\\Psi_t|\\Psi_{t-1}\\rangle|)} \)
class RoomCoherenceEngine {
  static const int defaultMinNodesForCoherence = 12;
  static const double defaultCoherenceScoreMin = 0.70;
  static const double defaultBuresDistanceMax = 0.30;
  static const double defaultCoherenceDeltaMax = 0.08;
  static const int defaultRequiredConsecutiveWindows = 3;
  static const Duration defaultWindowHorizon = Duration(minutes: 10);

  // Stage-1 dwell defaults (policy v1).
  static const Duration defaultLingerMinSpan = Duration(minutes: 3);
  static const int defaultLingerMinWindows = 3;
  static const int defaultUniqueNodesPer10MinMin = 25;
  static const double defaultOverlapRatioMedianMin = 0.30;
  static const double defaultNewNodeRateMaxPerSec = 10.0;

  final int minNodesForCoherence;
  final double coherenceScoreMin;
  final double buresDistanceMax;
  final double coherenceDeltaMax;
  final int requiredConsecutiveWindows;
  final Duration windowHorizon;

  final Duration lingerMinSpan;
  final int lingerMinWindows;
  final int uniqueNodesPer10MinMin;
  final double overlapRatioMedianMin;
  final double newNodeRateMaxPerSec;

  List<double>? _prevRoomPsi;
  double? _prevCoherenceScore;
  int _coherentStreak = 0;

  final List<_WindowSample> _samples = <_WindowSample>[];

  RoomCoherenceEngine({
    this.minNodesForCoherence = defaultMinNodesForCoherence,
    this.coherenceScoreMin = defaultCoherenceScoreMin,
    this.buresDistanceMax = defaultBuresDistanceMax,
    this.coherenceDeltaMax = defaultCoherenceDeltaMax,
    this.requiredConsecutiveWindows = defaultRequiredConsecutiveWindows,
    this.windowHorizon = defaultWindowHorizon,
    this.lingerMinSpan = defaultLingerMinSpan,
    this.lingerMinWindows = defaultLingerMinWindows,
    this.uniqueNodesPer10MinMin = defaultUniqueNodesPer10MinMin,
    this.overlapRatioMedianMin = defaultOverlapRatioMedianMin,
    this.newNodeRateMaxPerSec = defaultNewNodeRateMaxPerSec,
  });

  RoomCoherenceWindowResult observeWindow({
    required DateTime observedAt,
    required List<SpotsBroadcastFrameV1Decoded> frames,
  }) {
    return observeWindowFrames(
      observedAt: observedAt,
      frames: frames
          .map(
            (f) => RoomCoherenceFrame(
              nodeTag: f.nodeTag,
              dimsQ: f.dimsQ,
            ),
          )
          .toList(growable: false),
    );
  }

  RoomCoherenceWindowResult observeWindowFrames({
    required DateTime observedAt,
    required List<RoomCoherenceFrame> frames,
  }) {
    _pruneSamples(observedAt);

    // Deduplicate by node_tag (4 bytes) to prevent double counting.
    final byNodeTag = <String, RoomCoherenceFrame>{};
    for (final f in frames) {
      byNodeTag[_nodeTagKey(f.nodeTag)] = f;
    }

    final n = byNodeTag.length;

    // Dwell/linger stats (computed even if coherence is ineligible).
    final nodeKeys = byNodeTag.keys.toSet();
    final prev = _samples.isNotEmpty ? _samples.last : null;
    final overlapRatio = prev == null ? null : _jaccard(prev.nodeKeys, nodeKeys);
    final windowSeconds = prev == null
        ? null
        : max(
            1.0,
            observedAt.difference(prev.observedAt).inMilliseconds / 1000.0,
          );
    final newNodesCount =
        prev == null ? null : nodeKeys.difference(prev.nodeKeys).length;
    final newNodeRatePerSec =
        (newNodesCount == null || windowSeconds == null)
            ? null
            : newNodesCount / windowSeconds;

    _samples.add(_WindowSample(
      observedAt: observedAt,
      nodeKeys: nodeKeys,
      overlapRatio: overlapRatio,
      newNodeRatePerSec: newNodeRatePerSec,
    ));
    _pruneSamples(observedAt);

    final uniqueNodesPer10Min = _uniqueNodesInHorizon(observedAt);
    final overlapMedian = _median(_samples
        .where((s) => s.overlapRatio != null)
        .map((s) => s.overlapRatio!)
        .toList());
    final newNodeRateMedian = _median(_samples
        .where((s) => s.newNodeRatePerSec != null)
        .map((s) => s.newNodeRatePerSec!)
        .toList());

    final linger = _computeLinger(
      observedAt: observedAt,
      uniqueNodesPer10Min: uniqueNodesPer10Min,
      overlapRatioMedian: overlapMedian,
      newNodeRateMedian: newNodeRateMedian,
    );

    if (n < minNodesForCoherence) {
      _coherentStreak = 0;
      return RoomCoherenceWindowResult.ineligible(
        observedAt: observedAt,
        nodeCount: n,
        uniqueNodesPer10Min: uniqueNodesPer10Min,
        overlapRatioMedian: overlapMedian,
        newNodeRateMedianPerSec: newNodeRateMedian,
        linger: linger,
      );
    }

    final psis = <List<double>>[];
    for (final f in byNodeTag.values) {
      psis.add(f.psiVector());
    }

    final roomPsi = _normalize(_sumVectors(psis));

    // coherenceScore = mean_i dot(psi_i, roomPsi)^2 (real-only inner product).
    var acc = 0.0;
    for (final psi in psis) {
      final ip = _dot(psi, roomPsi);
      var c = ip * ip;
      if (c < 0.0) c = 0.0;
      if (c > 1.0) c = 1.0;
      acc += c;
    }
    final coherenceScore = acc / n.toDouble();
    final dispersionScore = (1.0 - coherenceScore).clamp(0.0, 1.0);

    double? buresDistance;
    if (_prevRoomPsi != null) {
      var overlap = _dot(roomPsi, _prevRoomPsi!);
      overlap = overlap.abs().clamp(0.0, 1.0);
      buresDistance = sqrt(2.0 * (1.0 - overlap));
    }

    final coherenceDelta = _prevCoherenceScore == null
        ? null
        : (coherenceScore - _prevCoherenceScore!).abs();

    final meetsCoherence = coherenceScore >= coherenceScoreMin &&
        (buresDistance == null || buresDistance <= buresDistanceMax) &&
        (coherenceDelta == null || coherenceDelta <= coherenceDeltaMax);

    _coherentStreak = meetsCoherence ? (_coherentStreak + 1) : 0;
    _prevRoomPsi = roomPsi;
    _prevCoherenceScore = coherenceScore;

    final coherentLinger =
        linger && _coherentStreak >= requiredConsecutiveWindows;
    final densityClass = _classify(
      uniqueNodesPer10Min: uniqueNodesPer10Min,
      overlapRatioMedian: overlapMedian,
      coherentLinger: coherentLinger,
    );

    return RoomCoherenceWindowResult.eligible(
      observedAt: observedAt,
      nodeCount: n,
      roomPsi: roomPsi,
      coherenceScore: coherenceScore,
      dispersionScore: dispersionScore,
      buresDistance: buresDistance,
      coherenceDelta: coherenceDelta,
      coherentStreak: _coherentStreak,
      coherentLinger: coherentLinger,
      uniqueNodesPer10Min: uniqueNodesPer10Min,
      overlapRatioMedian: overlapMedian,
      newNodeRateMedianPerSec: newNodeRateMedian,
      linger: linger,
      densityClass: densityClass,
    );
  }

  static String _nodeTagKey(List<int> nodeTag) {
    // nodeTag is 4 bytes.
    if (nodeTag.length < 4) return nodeTag.join(',');
    return '${nodeTag[0]}-${nodeTag[1]}-${nodeTag[2]}-${nodeTag[3]}';
  }

  void _pruneSamples(DateTime now) {
    final cutoff = now.subtract(windowHorizon);
    while (_samples.isNotEmpty && _samples.first.observedAt.isBefore(cutoff)) {
      _samples.removeAt(0);
    }
  }

  int _uniqueNodesInHorizon(DateTime now) {
    final cutoff = now.subtract(windowHorizon);
    final set = <String>{};
    for (final s in _samples) {
      if (s.observedAt.isBefore(cutoff)) continue;
      set.addAll(s.nodeKeys);
    }
    return set.length;
  }

  bool _computeLinger({
    required DateTime observedAt,
    required int uniqueNodesPer10Min,
    required double? overlapRatioMedian,
    required double? newNodeRateMedian,
  }) {
    if (uniqueNodesPer10Min < uniqueNodesPer10MinMin) return false;

    final cutoff = observedAt.subtract(lingerMinSpan);
    final recent = _samples.where((s) => !s.observedAt.isBefore(cutoff)).toList();
    if (recent.length < lingerMinWindows) return false;

    final span = recent.last.observedAt.difference(recent.first.observedAt);
    if (span < lingerMinSpan) return false;

    if (overlapRatioMedian == null || overlapRatioMedian < overlapRatioMedianMin) {
      return false;
    }
    if (newNodeRateMedian != null && newNodeRateMedian > newNodeRateMaxPerSec) {
      return false;
    }
    return true;
  }

  RoomDensityClass _classify({
    required int uniqueNodesPer10Min,
    required double? overlapRatioMedian,
    required bool coherentLinger,
  }) {
    if (coherentLinger) return RoomDensityClass.eventLikeDense;

    final overlap = overlapRatioMedian ?? 0.0;
    if (uniqueNodesPer10Min >= 50 && overlap < 0.15) {
      return RoomDensityClass.ambientDense;
    }
    if (uniqueNodesPer10Min >= 25 && overlap >= 0.30) {
      return RoomDensityClass.stickyCrowd;
    }
    if (uniqueNodesPer10Min >= 25) return RoomDensityClass.dense;
    return RoomDensityClass.low;
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final inter = a.intersection(b).length;
    final uni = a.union(b).length;
    if (uni <= 0) return 0.0;
    return inter / uni;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    values.sort();
    final mid = values.length ~/ 2;
    if (values.length.isOdd) return values[mid];
    return (values[mid - 1] + values[mid]) / 2.0;
  }

  static List<double> _sumVectors(List<List<double>> vectors) {
    if (vectors.isEmpty) return List<double>.filled(12, 0.0);
    final k = vectors.first.length;
    final sum = List<double>.filled(k, 0.0);
    for (final v in vectors) {
      for (var i = 0; i < k; i++) {
        sum[i] += v[i];
      }
    }
    return sum;
  }

  static double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  static List<double> _normalize(List<double> v) {
    var sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    final n = sqrt(sumSq);
    if (n <= 0.0) {
      final u = 1.0 / sqrt(v.length.toDouble());
      return List<double>.filled(v.length, u);
    }
    for (var i = 0; i < v.length; i++) {
      v[i] = v[i] / n;
    }
    return v;
  }
}

/// Minimal coherence input extracted from the broadcast frame v1.
class RoomCoherenceFrame {
  final List<int> nodeTag; // 4 bytes
  final List<int> dimsQ; // 12 bytes (0..255)

  RoomCoherenceFrame({
    required this.nodeTag,
    required this.dimsQ,
  });

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

class RoomCoherenceWindowResult {
  final bool eligible;
  final DateTime observedAt;
  final int nodeCount;

  /// Normalized room state vector (length 12), only present when eligible.
  final List<double>? roomPsi;

  /// 0..1, only present when eligible.
  final double? coherenceScore;

  /// 0..1, only present when eligible.
  final double? dispersionScore;

  /// 0..sqrt(2), only present when eligible and a previous room exists.
  final double? buresDistance;

  /// |ΔcoherenceScore|, only present when eligible and a previous coherence exists.
  final double? coherenceDelta;

  /// Count of consecutive coherent windows.
  final int coherentStreak;

  /// True when coherentStreak >= requiredConsecutiveWindows.
  final bool coherentLinger;

  /// Stage 1 dwell (linger) flag (see policy).
  final bool linger;

  /// Approx unique nodes observed in the last ~10 minutes.
  final int uniqueNodesPer10Min;

  /// Median overlap ratio (Jaccard) across recent windows (when available).
  final double? overlapRatioMedian;

  /// Median new-node rate per second across recent windows (when available).
  final double? newNodeRateMedianPerSec;

  final RoomDensityClass densityClass;

  const RoomCoherenceWindowResult._({
    required this.eligible,
    required this.observedAt,
    required this.nodeCount,
    required this.roomPsi,
    required this.coherenceScore,
    required this.dispersionScore,
    required this.buresDistance,
    required this.coherenceDelta,
    required this.coherentStreak,
    required this.coherentLinger,
    required this.linger,
    required this.uniqueNodesPer10Min,
    required this.overlapRatioMedian,
    required this.newNodeRateMedianPerSec,
    required this.densityClass,
  });

  factory RoomCoherenceWindowResult.ineligible({
    required DateTime observedAt,
    required int nodeCount,
    required int uniqueNodesPer10Min,
    required double? overlapRatioMedian,
    required double? newNodeRateMedianPerSec,
    required bool linger,
  }) {
    return RoomCoherenceWindowResult._(
      eligible: false,
      observedAt: observedAt,
      nodeCount: nodeCount,
      roomPsi: null,
      coherenceScore: null,
      dispersionScore: null,
      buresDistance: null,
      coherenceDelta: null,
      coherentStreak: 0,
      coherentLinger: false,
      linger: linger,
      uniqueNodesPer10Min: uniqueNodesPer10Min,
      overlapRatioMedian: overlapRatioMedian,
      newNodeRateMedianPerSec: newNodeRateMedianPerSec,
      densityClass: RoomDensityClass.low,
    );
  }

  factory RoomCoherenceWindowResult.eligible({
    required DateTime observedAt,
    required int nodeCount,
    required List<double> roomPsi,
    required double coherenceScore,
    required double dispersionScore,
    required double? buresDistance,
    required double? coherenceDelta,
    required int coherentStreak,
    required bool coherentLinger,
    required int uniqueNodesPer10Min,
    required double? overlapRatioMedian,
    required double? newNodeRateMedianPerSec,
    required bool linger,
    required RoomDensityClass densityClass,
  }) {
    return RoomCoherenceWindowResult._(
      eligible: true,
      observedAt: observedAt,
      nodeCount: nodeCount,
      roomPsi: roomPsi,
      coherenceScore: coherenceScore,
      dispersionScore: dispersionScore,
      buresDistance: buresDistance,
      coherenceDelta: coherenceDelta,
      coherentStreak: coherentStreak,
      coherentLinger: coherentLinger,
      linger: linger,
      uniqueNodesPer10Min: uniqueNodesPer10Min,
      overlapRatioMedian: overlapRatioMedian,
      newNodeRateMedianPerSec: newNodeRateMedianPerSec,
      densityClass: densityClass,
    );
  }
}

enum RoomDensityClass {
  low,
  dense,
  stickyCrowd,
  ambientDense,
  eventLikeDense,
}

class _WindowSample {
  final DateTime observedAt;
  final Set<String> nodeKeys;
  final double? overlapRatio;
  final double? newNodeRatePerSec;

  _WindowSample({
    required this.observedAt,
    required this.nodeKeys,
    required this.overlapRatio,
    required this.newNodeRatePerSec,
  });
}

