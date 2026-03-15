import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/replay_record_normalization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'America/Chicago',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  test('normalizes replay source record into canonical observation', () async {
    final temporalKernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
    );
    final service = ReplayRecordNormalizationService(
      temporalKernel: temporalKernel,
    );

    final record = ReplaySourceRecord(
      recordId: 'rec-1',
      sourceName: 'City Events',
      replayYear: 2023,
      rawEntityId: 'evt-123',
      rawEntityType: 'event',
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'event:raw',
        observedAt: buildInstant(DateTime.utc(2023, 6, 1, 18)),
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'city_events',
        ),
        uncertainty: const TemporalUncertainty(
          window: Duration(minutes: 15),
          confidence: 0.9,
        ),
        temporalAuthoritySource: 'when_kernel',
      ),
      localityHint: 'Avondale',
      payload: const <String, dynamic>{
        'name': 'Saturn Concert',
        'venue_name': 'Saturn',
      },
    );

    const sourceDescriptor = ReplaySourceDescriptor(
      sourceName: 'City Events',
      sourceType: 'official_calendar',
      accessMethod: ReplaySourceAccessMethod.api,
      trustTier: ReplaySourceTrustTier.tier1,
      status: ReplaySourceStatus.approved,
      entityCoverage: <String>['events', 'venues', 'communities'],
      temporalStartYear: 2023,
      temporalEndYear: 2025,
      replayRole: 'event_truth',
      legalStatus: 'allowed',
    );

    final observation = await service.normalize(
      record: record,
      sourceDescriptor: sourceDescriptor,
    );

    expect(observation.status, ReplayNormalizationStatus.normalized);
    expect(observation.subjectIdentity.entityType, 'event');
    expect(observation.subjectIdentity.canonicalName, 'Saturn Concert');
    expect(observation.subjectIdentity.localityAnchor, 'Avondale');
    expect(observation.subjectIdentity.normalizedEntityId, 'event:saturn-concert');
    expect(observation.truthResolution?.outcome, ReplayTruthResolutionOutcome.merged);
  });
}
