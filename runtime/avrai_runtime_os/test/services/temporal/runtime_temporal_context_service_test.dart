import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/temporal/runtime_temporal_context_service.dart';
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

  test('builds temporal context summary from runtime events', () async {
    final kernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
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

    final adminService = TemporalKernelAdminService(
      temporalKernel: kernel,
      nowProvider: () => DateTime.utc(2026, 3, 6, 12),
    );
    final service = RuntimeTemporalContextService(
      temporalKernelAdminService: adminService,
    );

    final context = await service.buildContext();

    expect(context.totalEvents, 2);
    expect(context.orderedCount, 1);
    expect(context.bufferedCount, 1);
    expect(context.topPeerId, 'peer-a');
    expect(context.summary, contains('2 events'));
    expect(context.summary, contains('top peer is peer-a'));
  });
}
