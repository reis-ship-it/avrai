import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';

class CalendarEventReplaySourceAdapter extends BhamReplaySourceAdapter {
  const CalendarEventReplaySourceAdapter();

  @override
  String get adapterId => 'calendar_event_replay_source_adapter';

  @override
  bool supports(ReplayIngestionSourcePlan plan) {
    final sourceType = plan.source.sourceType.toLowerCase();
    final sourceName = plan.source.sourceName.toLowerCase();
    final hasEventCoverage = plan.normalizationTargetTypes.contains('event');
    final isCalendarLike =
        sourceType.contains('calendar') ||
        sourceType.contains('civic') ||
        sourceType.contains('tourism') ||
        sourceType.contains('event') ||
        plan.source.accessMethod == ReplaySourceAccessMethod.ics ||
        sourceName.contains('calendar');
    return isCalendarLike && hasEventCoverage;
  }

  @override
  Future<List<ReplaySourceRecord>> adapt({
    required ReplayIngestionSourcePlan plan,
    required List<Map<String, dynamic>> rawRecords,
    required TemporalKernel temporalKernel,
  }) async {
    final fallbackInstant = await temporalKernel.nowCivil();
    return rawRecords.map((rawRecord) {
      final recordId =
          rawRecord['record_id']?.toString() ??
          rawRecord['event_id']?.toString() ??
          '${plan.source.sourceName}:${rawRecords.indexOf(rawRecord)}';
      final title =
          rawRecord['title']?.toString() ??
          rawRecord['name']?.toString() ??
          rawRecord['event_name']?.toString() ??
          recordId;
      final explicitEntityType =
          rawRecord['entity_type']?.toString() ??
          rawRecord['raw_entity_type']?.toString();
      final historicalAdmissibility =
          rawRecord['historical_admissibility']?.toString() ?? '';
      final isHistoricalizedStructuralRow =
          (historicalAdmissibility == 'year_valid_structural_snapshot' ||
              rawRecord.containsKey('historical_validation_note') ||
              rawRecord.containsKey('historical_capture_method')) &&
          explicitEntityType != null &&
          explicitEntityType.isNotEmpty &&
          explicitEntityType != 'event';
      final locality =
          rawRecord['locality']?.toString() ??
          rawRecord['neighborhood']?.toString();
      final rawEntityType =
          isHistoricalizedStructuralRow ? explicitEntityType : 'event';
      return ReplaySourceRecord(
        recordId: recordId,
        sourceName: plan.source.sourceName,
        replayYear: plan.replayYear,
        rawEntityId:
            rawRecord['event_id']?.toString() ??
            rawRecord['entity_id']?.toString() ??
            recordId,
        rawEntityType: rawEntityType,
        canonicalEntityHint: rawEntityType,
        localityHint: locality,
        replayEnvelope: _buildEnvelope(
          recordId: recordId,
          subjectId:
              rawRecord['event_id']?.toString() ??
              rawRecord['entity_id']?.toString() ??
              recordId,
          sourceName: plan.source.sourceName,
          rawRecord: rawRecord,
          fallbackInstant: fallbackInstant,
        ),
        payload: <String, dynamic>{
          'name': title,
          'venue_name': rawRecord['venue_name'],
          'community_name': rawRecord['community_name'],
          'starts_at': rawRecord['starts_at'],
          'ends_at': rawRecord['ends_at'],
          ...rawRecord,
        },
        metadata: <String, dynamic>{
          'adapter_id': adapterId,
          'source_type': plan.source.sourceType,
        },
      );
    }).toList(growable: false);
  }

  ReplayTemporalEnvelope _buildEnvelope({
    required String recordId,
    required String subjectId,
    required String sourceName,
    required Map<String, dynamic> rawRecord,
    required TemporalInstant fallbackInstant,
  }) {
    final observedAt = _readInstant(
      rawRecord['observed_at'] ?? rawRecord['published_at'] ?? rawRecord['starts_at'],
      sourceName: sourceName,
      fallback: fallbackInstant,
    );
    return ReplayTemporalEnvelope(
      envelopeId: 'env:$recordId',
      subjectId: subjectId,
      observedAt: observedAt,
      publishedAt: _readOptionalInstant(
        rawRecord['published_at'],
        sourceName: sourceName,
      ),
      validFrom: _readOptionalInstant(
        rawRecord['valid_from'] ?? rawRecord['starts_at'],
        sourceName: sourceName,
      ),
      validTo: _readOptionalInstant(
        rawRecord['valid_to'] ?? rawRecord['ends_at'],
        sourceName: sourceName,
      ),
      eventStartAt: _readOptionalInstant(
        rawRecord['starts_at'],
        sourceName: sourceName,
      ),
      eventEndAt: _readOptionalInstant(
        rawRecord['ends_at'],
        sourceName: sourceName,
      ),
      lastVerifiedAt: _readOptionalInstant(
        rawRecord['last_verified_at'],
        sourceName: sourceName,
      ),
      provenance: TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: sourceName,
      ),
      uncertainty: _readUncertainty(rawRecord),
      temporalAuthoritySource: 'when_kernel',
      metadata: <String, dynamic>{
        'adapter_id': adapterId,
      },
    );
  }

  TemporalInstant _readInstant(
    Object? raw, {
    required String sourceName,
    required TemporalInstant fallback,
  }) {
    if (raw == null) {
      return fallback;
    }
    final parsed = DateTime.tryParse(raw.toString())?.toUtc();
    if (parsed == null) {
      return fallback;
    }
    return TemporalInstant(
      referenceTime: parsed,
      civilTime: parsed,
      timezoneId: 'America/Chicago',
      provenance: TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: sourceName,
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: parsed.microsecondsSinceEpoch,
    );
  }

  TemporalInstant? _readOptionalInstant(
    Object? raw, {
    required String sourceName,
  }) {
    if (raw == null) {
      return null;
    }
    final parsed = DateTime.tryParse(raw.toString())?.toUtc();
    if (parsed == null) {
      return null;
    }
    return TemporalInstant(
      referenceTime: parsed,
      civilTime: parsed,
      timezoneId: 'America/Chicago',
      provenance: TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: sourceName,
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: parsed.microsecondsSinceEpoch,
    );
  }

  TemporalUncertainty _readUncertainty(Map<String, dynamic> rawRecord) {
    final confidence = (rawRecord['confidence'] as num?)?.toDouble() ?? 0.94;
    final minutes = (rawRecord['uncertainty_minutes'] as num?)?.toInt() ?? 5;
    return TemporalUncertainty(
      window: Duration(minutes: minutes),
      confidence: confidence,
    );
  }
}
