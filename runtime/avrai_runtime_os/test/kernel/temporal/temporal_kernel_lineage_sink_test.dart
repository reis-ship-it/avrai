import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel_lineage_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  test('lineage sink persists events into temporal kernel history', () async {
    final kernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
    );
    final sink = TemporalKernelLineageSink(temporalKernel: kernel);

    await sink.record(
      TemporalLineageEvent(
        eventId: 'evt-1',
        stage: TemporalLineageStage.ordered,
        occurredAt: DateTime.utc(2026, 3, 6, 11),
        source: 'ai2ai_protocol',
        eventType: 'heartbeat',
        peerId: 'peer-1',
        sequenceNumber: 7,
      ),
    );

    final stored = await kernel.getRuntimeEvent('evt-1');

    expect(stored, isNotNull);
    expect(stored!.event.eventId, 'evt-1');
    expect(stored.event.stage, RuntimeTemporalEventStage.ordered);
  });
}
