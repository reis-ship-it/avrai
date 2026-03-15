import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'Asia/Tokyo',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  test('snapshot assigns semantic time band from civil time', () async {
    final clock = FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 9)));
    final kernel = SystemTemporalKernel(clockSource: clock);

    final snapshot = await kernel.snapshot(const TemporalSnapshotRequest());

    expect(snapshot.semanticBand, SemanticTimeBand.morning);
  });

  test('freshness detects stale snapshots', () async {
    final clock = FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12)));
    final kernel = SystemTemporalKernel(clockSource: clock);
    final oldSnapshot = TemporalSnapshot(
      observedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      recordedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      effectiveAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      semanticBand: SemanticTimeBand.morning,
    );

    final result = await kernel.freshnessOf(
      oldSnapshot,
      const TemporalFreshnessPolicy(maxAge: Duration(minutes: 30)),
    );

    expect(result.isFresh, isFalse);
    expect(result.isFromFuture, isFalse);
    expect(result.age, const Duration(hours: 2));
  });

  test('compare orders snapshots by observed time', () async {
    final clock = FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12)));
    final kernel = SystemTemporalKernel(clockSource: clock);
    final left = TemporalSnapshot(
      observedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      recordedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      effectiveAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      semanticBand: SemanticTimeBand.morning,
    );
    final right = TemporalSnapshot(
      observedAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      recordedAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      effectiveAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      semanticBand: SemanticTimeBand.morning,
    );

    final result = await kernel.compare(left, right);

    expect(result.relation, TemporalOrderingRelation.before);
    expect(result.delta, const Duration(hours: -1));
  });

  test('records and retrieves historical evidence and forecasts', () async {
    final instant = buildInstant(DateTime.utc(2026, 3, 6, 12));
    final clock = FixedClockSource(instant);
    final kernel = SystemTemporalKernel(clockSource: clock);
    final interval = TemporalInterval(start: instant, end: instant);

    final evidence = HistoricalTemporalEvidence(
      evidenceId: 'hist-1',
      interval: interval,
      granularity: HistoricalTemporalGranularity.exact,
      confidence: 0.8,
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: 'test',
      ),
      reconstructionMethod: 'manual',
    );
    final claim = ForecastTemporalClaim(
      claimId: 'forecast-1',
      forecastCreatedAt: DateTime.utc(2026, 3, 6, 12),
      targetWindow: interval,
      evidenceWindow: interval,
      confidence: 0.7,
      modelVersion: 'v1',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.forecast,
        source: 'test',
      ),
    );

    await kernel.recordHistoricalEvidence(evidence);
    await kernel.recordForecast(claim);

    final storedEvidence = await kernel.getHistoricalEvidence('hist-1');
    final storedClaim = await kernel.getForecast('forecast-1');

    expect(storedEvidence?.evidence.evidenceId, 'hist-1');
    expect(storedClaim?.claim.claimId, 'forecast-1');
  });

  test('records and retrieves runtime temporal events', () async {
    final instant = buildInstant(DateTime.utc(2026, 3, 6, 12));
    final kernel = SystemTemporalKernel(clockSource: FixedClockSource(instant));
    final event = RuntimeTemporalEvent(
      eventId: 'runtime-1',
      occurredAt: DateTime.utc(2026, 3, 6, 11),
      source: 'ai2ai_protocol',
      eventType: 'heartbeat',
      stage: RuntimeTemporalEventStage.ordered,
      sequenceNumber: 3,
    );

    await kernel.recordRuntimeEvent(event);
    final stored = await kernel.getRuntimeEvent('runtime-1');

    expect(stored?.event.eventId, 'runtime-1');
    expect(stored?.event.stage, RuntimeTemporalEventStage.ordered);
  });

  test('queries runtime temporal events by source and peer', () async {
    final instant = buildInstant(DateTime.utc(2026, 3, 6, 12));
    final kernel = SystemTemporalKernel(clockSource: FixedClockSource(instant));
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'runtime-a',
        occurredAt: DateTime.utc(2026, 3, 6, 11),
        source: 'ai2ai_protocol',
        eventType: 'heartbeat',
        stage: RuntimeTemporalEventStage.ordered,
        peerId: 'peer-1',
      ),
    );
    await kernel.recordRuntimeEvent(
      RuntimeTemporalEvent(
        eventId: 'runtime-b',
        occurredAt: DateTime.utc(2026, 3, 6, 10),
        source: 'other_source',
        eventType: 'heartbeat',
        stage: RuntimeTemporalEventStage.buffered,
        peerId: 'peer-2',
      ),
    );

    final results = await kernel.queryRuntimeEvents(
      const RuntimeTemporalEventQuery(
        source: 'ai2ai_protocol',
        peerId: 'peer-1',
      ),
    );

    expect(results, hasLength(1));
    expect(results.first.event.eventId, 'runtime-a');
  });
}
