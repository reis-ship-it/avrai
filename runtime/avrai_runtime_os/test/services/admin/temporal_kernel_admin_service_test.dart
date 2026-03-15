import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
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

  test('builds runtime snapshot with stage and peer summaries', () async {
    final kernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
    );
    final service = TemporalKernelAdminService(
      temporalKernel: kernel,
      nowProvider: () => DateTime.utc(2026, 3, 6, 12),
    );

    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-1',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 59),
        source: 'ai2ai_protocol',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.ordered,
        peerId: 'peer-a',
      ),
    );
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-2',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 58),
        source: 'ai2ai_protocol',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.buffered,
        peerId: 'peer-a',
      ),
    );
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-3',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 57),
        source: 'ai2ai_protocol',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.encoded,
        peerId: 'peer-b',
      ),
    );
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-4',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 56),
        source: 'other_source',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.decoded,
        peerId: 'peer-c',
      ),
    );

    final snapshot = await service.getRuntimeEventSnapshot(
      lookbackWindow: const Duration(minutes: 15),
    );

    expect(snapshot.totalEvents, 3);
    expect(snapshot.orderedCount, 1);
    expect(snapshot.bufferedCount, 1);
    expect(snapshot.encodedCount, 1);
    expect(snapshot.decodedCount, 0);
    expect(snapshot.uniquePeerCount, 2);
    expect(snapshot.latestOccurredAt, DateTime.utc(2026, 3, 6, 11, 59));
    expect(snapshot.topPeers.first.peerId, 'peer-a');
    expect(snapshot.topPeers.first.eventCount, 2);
  });

  test('filters runtime snapshot to a specific peer', () async {
    final kernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
    );
    final service = TemporalKernelAdminService(
      temporalKernel: kernel,
      nowProvider: () => DateTime.utc(2026, 3, 6, 12),
    );

    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-1',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 59),
        source: 'ai2ai_protocol',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.ordered,
        peerId: 'peer-a',
      ),
    );
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'evt-2',
        occurredAt: DateTime.utc(2026, 3, 6, 11, 58),
        source: 'ai2ai_protocol',
        eventType: 'message',
        stage: RuntimeTemporalEventStage.buffered,
        peerId: 'peer-b',
      ),
    );

    final snapshot = await service.getRuntimeEventSnapshot(
      peerId: 'peer-a',
      lookbackWindow: const Duration(minutes: 15),
    );

    expect(snapshot.totalEvents, 1);
    expect(snapshot.uniquePeerCount, 1);
    expect(snapshot.topPeers.single.peerId, 'peer-a');
    expect(snapshot.recentEvents.single.event.eventId, 'evt-1');
  });
}
