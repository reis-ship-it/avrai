import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';

class SpatialFeatureReplaySourceAdapter extends BhamReplaySourceAdapter {
  const SpatialFeatureReplaySourceAdapter();

  @override
  String get adapterId => 'spatial_feature_replay_source_adapter';

  @override
  bool supports(ReplayIngestionSourcePlan plan) {
    final sourceType = plan.source.sourceType.toLowerCase();
    final replayRole = plan.source.replayRole.toLowerCase();
    final isHistoricalArchive =
        sourceType.contains('historical') ||
        sourceType.contains('archive') ||
        replayRole.contains('historical') ||
        replayRole.contains('memory');
    if (isHistoricalArchive) {
      return false;
    }

    const supportedTargets = <String>{
      'locality',
      'venue',
      'community',
      'club',
    };
    if (plan.normalizationTargetTypes.contains('event')) {
      if (!sourceType.contains('spatial') &&
          !sourceType.contains('gis') &&
          !sourceType.contains('map') &&
          !sourceType.contains('civic')) {
        return false;
      }
    }
    return plan.normalizationTargetTypes.any(supportedTargets.contains);
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
          rawRecord['feature_id']?.toString() ??
          '${plan.source.sourceName}:${rawRecords.indexOf(rawRecord)}';
      final rawEntityType =
          rawRecord['entity_type']?.toString() ??
          rawRecord['feature_type']?.toString() ??
          _defaultEntityTypeFor(plan);
      final subjectId =
          rawRecord['entity_id']?.toString() ??
          rawRecord['feature_id']?.toString() ??
          recordId;
      return ReplaySourceRecord(
        recordId: recordId,
        sourceName: plan.source.sourceName,
        replayYear: plan.replayYear,
        rawEntityId: subjectId,
        rawEntityType: rawEntityType,
        canonicalEntityHint: rawEntityType,
        localityHint:
            rawRecord['locality']?.toString() ??
            rawRecord['neighborhood']?.toString() ??
            rawRecord['district']?.toString(),
        replayEnvelope: _buildEnvelope(
          recordId: recordId,
          subjectId: subjectId,
          sourceName: plan.source.sourceName,
          rawRecord: rawRecord,
          fallbackInstant: fallbackInstant,
        ),
        payload: <String, dynamic>{
          'name':
              rawRecord['name']?.toString() ??
              rawRecord['label']?.toString() ??
              rawEntityType,
          'lat': rawRecord['lat'],
          'lng': rawRecord['lng'],
          'geometry': rawRecord['geometry'],
          ...rawRecord,
        },
        metadata: <String, dynamic>{
          'adapter_id': adapterId,
          'source_type': plan.source.sourceType,
        },
      );
    }).toList(growable: false);
  }

  String _defaultEntityTypeFor(ReplayIngestionSourcePlan plan) {
    if (plan.normalizationTargetTypes.contains('locality')) {
      return 'locality';
    }
    if (plan.normalizationTargetTypes.contains('community')) {
      return 'community';
    }
    if (plan.normalizationTargetTypes.contains('club')) {
      return 'club';
    }
    return 'venue';
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
    return ReplayTemporalEnvelope(
      envelopeId: 'env:$recordId',
      subjectId: subjectId,
      observedAt: observedAt,
      publishedAt: _readOptionalInstant(
        rawRecord['published_at'],
        sourceName: sourceName,
      ),
      validFrom: _readOptionalInstant(
        rawRecord['valid_from'],
        sourceName: sourceName,
      ),
      validTo: _readOptionalInstant(
        rawRecord['valid_to'],
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
    final confidence = (rawRecord['confidence'] as num?)?.toDouble() ?? 0.92;
    final minutes = (rawRecord['uncertainty_minutes'] as num?)?.toInt() ?? 10;
    return TemporalUncertainty(
      window: Duration(minutes: minutes),
      confidence: confidence,
    );
  }
}
