/// SPOTS Broadcast Frame v1 tests
///
/// Purpose: ensure encoder/decoder is deterministic and cross-platform stable.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

void main() {
  test('encode produces 24-byte frame with correct magic/version', () {
    final frame = SpotsBroadcastFrameV1.encode(
      utcMillis: 0,
      nodeId: 'node-1',
      dims: const <String, double>{},
      eventModeEnabled: false,
      connectOk: false,
      brownout: false,
    );

    expect(frame, isA<Uint8List>());
    expect(frame.length, SpotsBroadcastFrameV1.byteLength);
    expect(frame[0], 0x53); // S
    expect(frame[1], 0x50); // P
    expect(frame[2], 0x54); // T
    expect(frame[3], 0x53); // S
    expect(frame[4], SpotsBroadcastFrameV1.version);
  });

  test('epoch uses 5-minute buckets and is little-endian', () {
    // utcMillis = 300_000 => epoch 1
    final frame = SpotsBroadcastFrameV1.encode(
      utcMillis: 300000,
      nodeId: 'node-1',
      dims: const <String, double>{},
      eventModeEnabled: false,
      connectOk: false,
      brownout: false,
    );

    // epoch bytes are [6]=LSB, [7]=MSB
    expect(frame[6], 1);
    expect(frame[7], 0);
  });

  test('quantization uses floor(x + 0.5) rounding', () {
    // p = 0.5 => 127.5 + 0.5 => floor(128.0) => 128
    final dims = <String, double>{
      for (final d in SpotsBroadcastFrameV1.dimensionOrder) d: 0.5,
    };
    final frame = SpotsBroadcastFrameV1.encode(
      utcMillis: 0,
      nodeId: 'node-1',
      dims: dims,
      eventModeEnabled: false,
      connectOk: false,
      brownout: false,
    );

    for (var i = 0; i < SpotsBroadcastFrameV1.dimensionsCount; i++) {
      expect(frame[12 + i], 128);
    }
  });

  test('decode round-trips flags/node_tag/dimsQ', () {
    final dims = <String, double>{
      for (final d in SpotsBroadcastFrameV1.dimensionOrder) d: 0.123,
    };

    final frame = SpotsBroadcastFrameV1.encode(
      utcMillis: 1234567890,
      nodeId: 'node-xyz',
      dims: dims,
      eventModeEnabled: true,
      connectOk: true,
      brownout: false,
    );

    final decoded = SpotsBroadcastFrameV1.decode(frame);
    expect(decoded, isNotNull);
    expect(decoded!.eventModeEnabled, isTrue);
    expect(decoded.connectOk, isTrue);
    expect(decoded.brownout, isFalse);
    expect(decoded.nodeTag.length, 4);
    expect(decoded.dimsQ.length, 12);
  });

  test('psiVector is normalized and stable', () {
    final dims = <String, double>{
      for (final d in SpotsBroadcastFrameV1.dimensionOrder) d: 1.0,
    };

    final frame = SpotsBroadcastFrameV1.encode(
      utcMillis: 0,
      nodeId: 'node-1',
      dims: dims,
      eventModeEnabled: false,
      connectOk: false,
      brownout: false,
    );
    final decoded = SpotsBroadcastFrameV1.decode(frame)!;
    final psi = decoded.psiVector();

    // Should be unit vector.
    final sumSq = psi.fold<double>(0.0, (acc, x) => acc + x * x);
    expect(sumSq, closeTo(1.0, 1e-9));
  });
}

