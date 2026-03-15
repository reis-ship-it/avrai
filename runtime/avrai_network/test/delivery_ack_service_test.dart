import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/network/delivery_ack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(int micros) {
    final time = DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
    return TemporalInstant(
      referenceTime: time,
      civilTime: time.toLocal(),
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: micros,
    );
  }

  test('ack timeout follows shared clock progression', () async {
    final clock = FixedClockSource(buildInstant(0));
    final service = DeliveryAckService(
      clockSource: clock,
      ackTimeout: const Duration(milliseconds: 20),
      deadlineCheckFloor: const Duration(milliseconds: 1),
    );

    final future = service.waitForAck('msg-1');
    clock.setInstant(buildInstant(const Duration(seconds: 6).inMicroseconds));

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(await future, isFalse);
  });
}
