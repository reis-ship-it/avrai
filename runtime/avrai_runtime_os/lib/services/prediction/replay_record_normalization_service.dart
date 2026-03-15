import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

class ReplayRecordNormalizationService {
  const ReplayRecordNormalizationService({
    required this.temporalKernel,
  });

  final TemporalKernel temporalKernel;

  Future<ReplayNormalizedObservation> normalize({
    required ReplaySourceRecord record,
    ReplaySourceDescriptor? sourceDescriptor,
  }) async {
    final now = await temporalKernel.nowCivil();
    final canonicalName = _canonicalNameFor(record);
    final entityType = _canonicalEntityTypeFor(record);
    final sourceRefs = {
      record.sourceName,
      if (sourceDescriptor != null) sourceDescriptor.sourceName,
    }.toList();

    final subjectIdentity = ReplayEntityIdentity(
      normalizedEntityId: _normalizedEntityIdFor(
        entityType: entityType,
        canonicalName: canonicalName,
        fallbackId: record.rawEntityId,
      ),
      entityType: entityType,
      canonicalName: canonicalName,
      sourceAliases: [
        record.rawEntityId,
        if (record.payload['name'] != null) record.payload['name'].toString(),
        if (record.payload['title'] != null) record.payload['title'].toString(),
      ].where((entry) => entry.isNotEmpty).toSet().toList(),
      sourceRefs: sourceRefs,
      dedupeKeys: <String, String>{
        'raw_entity_id': record.rawEntityId,
        if (record.localityHint != null) 'locality': record.localityHint!,
      },
      localityAnchor: record.localityHint ??
          record.payload['locality']?.toString() ??
          record.payload['neighborhood']?.toString(),
      metadata: <String, dynamic>{
        'source_type': sourceDescriptor?.sourceType ?? 'unknown',
        'replay_year': record.replayYear,
      },
    );

    final truthResolution = ReplayTruthResolution(
      resolutionId: 'resolution:${record.recordId}',
      subjectId: subjectIdentity.normalizedEntityId,
      outcome: ReplayTruthResolutionOutcome.merged,
      confidence: _confidenceFor(sourceDescriptor),
      rationale: 'normalized from replay source record into canonical observation',
      resolvedAt: now,
      contributingSources: sourceRefs,
      metadata: <String, dynamic>{
        'record_id': record.recordId,
        'raw_entity_type': record.rawEntityType,
      },
    );

    return ReplayNormalizedObservation(
      observationId: 'obs:${record.recordId}',
      subjectIdentity: subjectIdentity,
      replayEnvelope: record.replayEnvelope,
      status: ReplayNormalizationStatus.normalized,
      sourceRefs: sourceRefs,
      normalizedFields: <String, dynamic>{
        'canonical_name': canonicalName,
        'entity_type': entityType,
        'locality_anchor': subjectIdentity.localityAnchor,
        ...record.payload,
      },
      truthResolution: truthResolution,
      metadata: <String, dynamic>{
        'raw_record_id': record.recordId,
      },
    );
  }

  String _canonicalNameFor(ReplaySourceRecord record) {
    final fromPayload = <dynamic>[
      record.payload['name'],
      record.payload['title'],
      record.payload['venue_name'],
      record.payload['event_name'],
    ].whereType<Object>().map((entry) => entry.toString().trim()).firstWhere(
          (entry) => entry.isNotEmpty,
          orElse: () => record.rawEntityId,
        );
    return fromPayload;
  }

  String _canonicalEntityTypeFor(ReplaySourceRecord record) {
    final hint = (record.canonicalEntityHint ?? record.rawEntityType).toLowerCase();
    if (hint.contains('event')) {
      return 'event';
    }
    if (hint.contains('club')) {
      return 'club';
    }
    if (hint.contains('communit')) {
      return 'community';
    }
    if (hint.contains('localit') || hint.contains('neighborhood')) {
      return 'locality';
    }
    if (hint.contains('movement') || hint.contains('route') || hint.contains('traffic')) {
      return 'movement_flow';
    }
    if (hint.contains('population') || hint.contains('household') || hint.contains('cohort')) {
      return 'population_cohort';
    }
    if (hint.contains('housing')) {
      return 'housing_signal';
    }
    if (hint.contains('economic') || hint.contains('income') || hint.contains('wallet')) {
      return 'economic_signal';
    }
    if (hint.contains('environment') || hint.contains('weather') || hint.contains('climate')) {
      return 'environmental_signal';
    }
    return 'venue';
  }

  String _normalizedEntityIdFor({
    required String entityType,
    required String canonicalName,
    required String fallbackId,
  }) {
    final slug = canonicalName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      return '$entityType:$fallbackId';
    }
    return '$entityType:$slug';
  }

  double _confidenceFor(ReplaySourceDescriptor? sourceDescriptor) {
    if (sourceDescriptor == null) {
      return 0.6;
    }
    return switch (sourceDescriptor.trustTier) {
      ReplaySourceTrustTier.tier1 => 0.95,
      ReplaySourceTrustTier.tier2 => 0.88,
      ReplaySourceTrustTier.tier3 => 0.78,
      ReplaySourceTrustTier.tier4 => 0.66,
      ReplaySourceTrustTier.tier5 => 0.55,
    };
  }
}
