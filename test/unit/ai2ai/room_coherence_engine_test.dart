/// RoomCoherenceEngine tests
///
/// Purpose: ensure coherence math + thresholds are deterministic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

void main() {
  test('ineligible when nodeCount < minNodesForCoherence', () {
    final engine = RoomCoherenceEngine(minNodesForCoherence: 12);
    final now = DateTime.utc(2026, 1, 2, 0, 0, 0);
    final frames = <SpotsBroadcastFrameV1Decoded>[];

    for (var i = 0; i < 11; i++) {
      final bytes = SpotsBroadcastFrameV1.encode(
        utcMillis: now.millisecondsSinceEpoch,
        nodeId: 'node-$i',
        dims: {
          for (final d in SpotsBroadcastFrameV1.dimensionOrder) d: 1.0,
        },
        eventModeEnabled: false,
        connectOk: false,
        brownout: false,
      );
      frames.add(SpotsBroadcastFrameV1.decode(bytes)!);
    }

    final res = engine.observeWindow(observedAt: now, frames: frames);
    expect(res.eligible, isFalse);
    expect(res.coherentLinger, isFalse);
  });

  test('coherent linger triggers after required consecutive windows', () {
    final engine = RoomCoherenceEngine(
      minNodesForCoherence: 12,
      coherenceScoreMin: 0.70,
      buresDistanceMax: 0.30,
      coherenceDeltaMax: 0.08,
      requiredConsecutiveWindows: 3,
    );

    List<SpotsBroadcastFrameV1Decoded> makeFrames(DateTime t) {
      final frames = <SpotsBroadcastFrameV1Decoded>[];
      for (var i = 0; i < 25; i++) {
        final bytes = SpotsBroadcastFrameV1.encode(
          utcMillis: t.millisecondsSinceEpoch,
          nodeId: 'node-$i',
          dims: {
            for (final d in SpotsBroadcastFrameV1.dimensionOrder) d: 1.0,
          },
          eventModeEnabled: true,
          connectOk: false,
          brownout: false,
        );
        frames.add(SpotsBroadcastFrameV1.decode(bytes)!);
      }
      return frames;
    }

    final t0 = DateTime.utc(2026, 1, 2, 0, 0, 0);
    final r0 = engine.observeWindow(observedAt: t0, frames: makeFrames(t0));
    expect(r0.eligible, isTrue);
    expect(r0.linger, isFalse);
    expect(r0.coherentLinger, isFalse);

    final t1 = t0.add(const Duration(seconds: 90));
    final r1 = engine.observeWindow(observedAt: t1, frames: makeFrames(t1));
    expect(r1.eligible, isTrue);
    expect(r1.coherentLinger, isFalse);

    final t2 = t0.add(const Duration(seconds: 180));
    final r2 = engine.observeWindow(observedAt: t2, frames: makeFrames(t2));
    expect(r2.eligible, isTrue);
    expect(r2.linger, isTrue);
    expect(r2.coherentLinger, isTrue);
  });
}

