import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

class TemporalKernelLineageSink implements TemporalLineageSink {
  TemporalKernelLineageSink({
    required TemporalKernel temporalKernel,
  }) : _temporalKernel = temporalKernel;

  final TemporalKernel _temporalKernel;

  @override
  Future<void> record(TemporalLineageEvent event) async {
    final runtimeEvent = RuntimeTemporalEvent(
      eventId: event.eventId,
      occurredAt: event.occurredAt,
      source: event.source,
      eventType: event.eventType,
      stage: RuntimeTemporalEventStage.values.firstWhere(
        (value) => value.name == event.stage.name,
        orElse: () => RuntimeTemporalEventStage.ordered,
      ),
      peerId: event.peerId,
      sequenceNumber: event.sequenceNumber,
      metadata: event.metadata,
      provenance: TemporalProvenance(
        authority: TemporalAuthority.inferred,
        source: event.source,
      ),
    );
    await _temporalKernel.recordRuntimeEvent(runtimeEvent);
  }
}
