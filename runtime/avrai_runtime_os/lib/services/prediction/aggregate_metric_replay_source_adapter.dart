import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';

class AggregateMetricReplaySourceAdapter extends BhamReplaySourceAdapter {
  const AggregateMetricReplaySourceAdapter();

  @override
  String get adapterId => 'aggregate_metric_replay_source_adapter';

  @override
  bool supports(ReplayIngestionSourcePlan plan) {
    const supportedTargets = <String>{
      'economic_signal',
      'population_cohort',
      'movement_flow',
      'housing_signal',
      'environmental_signal',
    };
    final sourceType = plan.source.sourceType.toLowerCase();
    final isAggregateSourceType =
        sourceType.contains('economic') ||
        sourceType.contains('demographic') ||
        sourceType.contains('traffic') ||
        sourceType.contains('infrastructure') ||
        sourceType.contains('friction') ||
        sourceType.contains('weather') ||
        sourceType.contains('environment') ||
        sourceType.contains('housing') ||
        sourceType.contains('travel_flow') ||
        sourceType.contains('labor') ||
        sourceType.contains('income');
    return isAggregateSourceType &&
        plan.normalizationTargetTypes.any(supportedTargets.contains);
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
          rawRecord['series_key']?.toString() ??
          '${plan.source.sourceName}:${rawRecords.indexOf(rawRecord)}';
      final rawEntityType =
          rawRecord['entity_type']?.toString() ??
          (plan.normalizationTargetTypes.isEmpty
              ? null
              : plan.normalizationTargetTypes.first) ??
          'aggregate_metric';
      return ReplaySourceRecord(
        recordId: recordId,
        sourceName: plan.source.sourceName,
        replayYear: plan.replayYear,
        rawEntityId:
            rawRecord['entity_id']?.toString() ??
            rawRecord['series_key']?.toString() ??
            recordId,
        rawEntityType: rawEntityType,
        canonicalEntityHint: rawEntityType,
        localityHint:
            rawRecord['locality']?.toString() ??
            rawRecord['neighborhood']?.toString(),
        replayEnvelope: _buildEnvelope(
          recordId: recordId,
          subjectId:
              rawRecord['entity_id']?.toString() ??
              rawRecord['series_key']?.toString() ??
              recordId,
          sourceName: plan.source.sourceName,
          rawRecord: rawRecord,
          fallbackInstant: fallbackInstant,
        ),
        payload: <String, dynamic>{
          'name':
              rawRecord['name']?.toString() ??
              rawRecord['series_name']?.toString() ??
              rawEntityType,
          'metric_value': rawRecord['metric_value'],
          'series_key': rawRecord['series_key'],
          'unit': rawRecord['unit'],
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
      rawRecord['observed_at'],
      sourceName: sourceName,
      fallback: fallbackInstant,
    );
    final publishedAt = _readOptionalInstant(
      rawRecord['published_at'],
      sourceName: sourceName,
    );
    final validFrom = _readOptionalInstant(
      rawRecord['valid_from'],
      sourceName: sourceName,
    );
    final validTo = _readOptionalInstant(
      rawRecord['valid_to'],
      sourceName: sourceName,
    );
    return ReplayTemporalEnvelope(
      envelopeId: 'env:$recordId',
      subjectId: subjectId,
      observedAt: observedAt,
      publishedAt: publishedAt,
      validFrom: validFrom,
      validTo: validTo,
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
    final confidence = (rawRecord['confidence'] as num?)?.toDouble() ?? 0.9;
    final minutes = (rawRecord['uncertainty_minutes'] as num?)?.toInt() ?? 15;
    return TemporalUncertainty(
      window: Duration(minutes: minutes),
      confidence: confidence,
    );
  }
}
