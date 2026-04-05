import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/governed_forecast_runtime_service.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

class BhamReplayForecastBatchItem {
  const BhamReplayForecastBatchItem({
    required this.sequenceNumber,
    required this.observationId,
    required this.subjectId,
    required this.entityType,
    required this.primarySourceName,
    required this.disposition,
    required this.predictedOutcome,
    required this.confidence,
    required this.actionabilityScore,
    required this.governanceReasons,
  });

  final int sequenceNumber;
  final String observationId;
  final String subjectId;
  final String entityType;
  final String primarySourceName;
  final ForecastGovernanceDisposition disposition;
  final String predictedOutcome;
  final double confidence;
  final double actionabilityScore;
  final List<String> governanceReasons;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sequenceNumber': sequenceNumber,
      'observationId': observationId,
      'subjectId': subjectId,
      'entityType': entityType,
      'primarySourceName': primarySourceName,
      'disposition': disposition.name,
      'predictedOutcome': predictedOutcome,
      'confidence': confidence,
      'actionabilityScore': actionabilityScore,
      'governanceReasons': governanceReasons,
    };
  }

  factory BhamReplayForecastBatchItem.fromJson(Map<String, dynamic> json) {
    return BhamReplayForecastBatchItem(
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt() ?? 0,
      observationId: json['observationId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'unknown',
      primarySourceName: json['primarySourceName'] as String? ?? 'unknown',
      disposition: ForecastGovernanceDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => ForecastGovernanceDisposition.admittedWithCaution,
      ),
      predictedOutcome: json['predictedOutcome'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      actionabilityScore:
          (json['actionabilityScore'] as num?)?.toDouble() ?? 0.0,
      governanceReasons: (json['governanceReasons'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
    );
  }
}

class BhamReplayForecastBatchResult {
  const BhamReplayForecastBatchResult({
    required this.runContext,
    required this.evaluatedCount,
    required this.dispositionCounts,
    required this.entityTypeCounts,
    required this.sourceCounts,
    required this.items,
    this.metadata = const <String, dynamic>{},
  });

  final MonteCarloRunContext runContext;
  final int evaluatedCount;
  final Map<String, int> dispositionCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> sourceCounts;
  final List<BhamReplayForecastBatchItem> items;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'runContext': runContext.toJson(),
      'evaluatedCount': evaluatedCount,
      'dispositionCounts': dispositionCounts,
      'entityTypeCounts': entityTypeCounts,
      'sourceCounts': sourceCounts,
      'items': items.map((item) => item.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory BhamReplayForecastBatchResult.fromJson(Map<String, dynamic> json) {
    Map<String, int> readCounts(Object? raw) {
      return (raw as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{};
    }

    return BhamReplayForecastBatchResult(
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
      dispositionCounts: readCounts(json['dispositionCounts']),
      entityTypeCounts: readCounts(json['entityTypeCounts']),
      sourceCounts: readCounts(json['sourceCounts']),
      items: (json['items'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => BhamReplayForecastBatchItem.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <BhamReplayForecastBatchItem>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class BhamReplayForecastBatchService {
  const BhamReplayForecastBatchService({
    required this.governedForecastRuntimeService,
    this.replayClockSource,
  });

  final GovernedForecastRuntimeService governedForecastRuntimeService;
  final FixedClockSource? replayClockSource;

  Future<BhamReplayForecastBatchResult> evaluatePlan({
    required BhamReplayExecutionPlan plan,
    required Map<String, dynamic> artifact,
    int maxPerEntityType = 20,
  }) async {
    final sourceDescriptors = _sourceDescriptorsFromArtifact(artifact);
    final selectedEntries = _selectEntries(
      plan.entries,
      maxPerEntityType: maxPerEntityType,
    );

    final items = <BhamReplayForecastBatchItem>[];
    final dispositionCounts = <String, int>{};
    final entityTypeCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final forecastKernelCounts = <String, int>{};
    final forecastKernelModeCounts = <String, int>{};

    for (final entry in selectedEntries) {
      replayClockSource?.setInstant(entry.executionInstant);
      final request = _buildRequest(entry, plan.runContext);
      final result = await governedForecastRuntimeService.evaluateBhamForecast(
        request: request,
        candidateYears: <int>[plan.replayYear],
        sources: sourceDescriptors,
      );

      final item = BhamReplayForecastBatchItem(
        sequenceNumber: entry.sequenceNumber,
        observationId: entry.observation.observationId,
        subjectId: entry.observation.subjectIdentity.normalizedEntityId,
        entityType: entry.observation.subjectIdentity.entityType,
        primarySourceName: entry.primarySourceName,
        disposition: result.projection.disposition,
        predictedOutcome: result.projection.result.predictedOutcome,
        confidence: result.projection.result.confidence,
        actionabilityScore: result.projection.actionabilityScore,
        governanceReasons: result.projection.governanceReasons,
      );
      items.add(item);

      dispositionCounts[item.disposition.name] =
          (dispositionCounts[item.disposition.name] ?? 0) + 1;
      entityTypeCounts[item.entityType] =
          (entityTypeCounts[item.entityType] ?? 0) + 1;
      sourceCounts[item.primarySourceName] =
          (sourceCounts[item.primarySourceName] ?? 0) + 1;
      final resultMetadata = result.projection.result.metadata;
      final forecastKernelId =
          resultMetadata['forecast_kernel_id']?.toString() ??
              result.projection.result.claim.modelVersion;
      if (forecastKernelId.isNotEmpty) {
        forecastKernelCounts[forecastKernelId] =
            (forecastKernelCounts[forecastKernelId] ?? 0) + 1;
      }
      final forecastKernelMode =
          resultMetadata['forecast_kernel_execution_mode']?.toString();
      if (forecastKernelMode != null && forecastKernelMode.isNotEmpty) {
        forecastKernelModeCounts[forecastKernelMode] =
            (forecastKernelModeCounts[forecastKernelMode] ?? 0) + 1;
      }
    }

    return BhamReplayForecastBatchResult(
      runContext: plan.runContext,
      evaluatedCount: items.length,
      dispositionCounts: _sortedCounts(dispositionCounts),
      entityTypeCounts: _sortedCounts(entityTypeCounts),
      sourceCounts: _sortedCounts(sourceCounts),
      items: items,
      metadata: <String, dynamic>{
        'forecast_kernel_counts': _sortedCounts(forecastKernelCounts),
        'forecast_kernel_execution_mode_counts':
            _sortedCounts(forecastKernelModeCounts),
        if (forecastKernelCounts.length == 1)
          'selected_forecast_kernel_id': forecastKernelCounts.keys.single,
        if (forecastKernelModeCounts.length == 1)
          'selected_forecast_kernel_execution_mode':
              forecastKernelModeCounts.keys.single,
      },
    );
  }

  List<ReplaySourceDescriptor> _sourceDescriptorsFromArtifact(
    Map<String, dynamic> artifact,
  ) {
    final ingestion = Map<String, dynamic>.from(
      artifact['ingestion'] as Map? ?? const {},
    );
    final results = (ingestion['results'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final descriptors = <String, ReplaySourceDescriptor>{};
    for (final result in results) {
      final sourcePlan = Map<String, dynamic>.from(
        result['sourcePlan'] as Map? ?? const {},
      );
      final source = Map<String, dynamic>.from(
        sourcePlan['source'] as Map? ?? const {},
      );
      final descriptor = ReplaySourceDescriptor.fromJson(source);
      descriptors[descriptor.sourceName] = descriptor;
    }
    return descriptors.values.toList(growable: false);
  }

  List<BhamReplayExecutionEntry> _selectEntries(
    List<BhamReplayExecutionEntry> entries, {
    required int maxPerEntityType,
  }) {
    final selected = <BhamReplayExecutionEntry>[];
    final counts = <String, int>{};
    for (final entry in entries) {
      if (!_isForecastEligible(entry.observation.subjectIdentity.entityType)) {
        continue;
      }
      final entityType = entry.observation.subjectIdentity.entityType;
      if ((counts[entityType] ?? 0) >= maxPerEntityType) {
        continue;
      }
      counts[entityType] = (counts[entityType] ?? 0) + 1;
      selected.add(entry);
    }
    return selected;
  }

  bool _isForecastEligible(String entityType) {
    return switch (entityType) {
      'event' => true,
      'venue' => true,
      'community' => true,
      'club' => true,
      'movement_flow' => true,
      'economic_signal' => true,
      _ => false,
    };
  }

  ForecastKernelRequest _buildRequest(
    BhamReplayExecutionEntry entry,
    MonteCarloRunContext runContext,
  ) {
    final observation = entry.observation;
    final envelope = observation.replayEnvelope;
    final adjustedEnvelope = ReplayTemporalEnvelope(
      envelopeId: envelope.envelopeId,
      subjectId: envelope.subjectId,
      observedAt: entry.executionInstant,
      publishedAt: envelope.publishedAt,
      validFrom: envelope.validFrom,
      validTo: envelope.validTo,
      eventStartAt: envelope.eventStartAt ?? entry.executionInstant,
      eventEndAt: envelope.eventEndAt,
      lastVerifiedAt: envelope.lastVerifiedAt,
      semanticBand: envelope.semanticBand,
      provenance: envelope.provenance,
      uncertainty: envelope.uncertainty,
      temporalAuthoritySource: envelope.temporalAuthoritySource,
      branchId: runContext.branchId,
      runId: runContext.runId,
      metadata: envelope.metadata,
    );

    final targetStart = adjustedEnvelope.eventStartAt ?? entry.executionInstant;
    final targetEnd = _targetEndFor(adjustedEnvelope, targetStart);
    final evidenceStart = adjustedEnvelope.validFrom ??
        adjustedEnvelope.publishedAt ??
        targetStart;

    return ForecastKernelRequest(
      forecastId: '${entry.observation.observationId}:forecast',
      subjectId: observation.subjectIdentity.normalizedEntityId,
      replayEnvelope: adjustedEnvelope,
      runContext: runContext,
      targetWindow: TemporalInterval(start: targetStart, end: targetEnd),
      evidenceWindow: TemporalInterval(
        start: evidenceStart,
        end: targetStart,
      ),
      metadata: <String, dynamic>{
        'source_refs': observation.sourceRefs,
        'entity_type': observation.subjectIdentity.entityType,
        'day_key': entry.dayKey,
        'month_key': entry.monthKey,
      },
    );
  }

  TemporalInstant _targetEndFor(
    ReplayTemporalEnvelope envelope,
    TemporalInstant start,
  ) {
    final candidate = envelope.eventEndAt ?? envelope.validTo ?? start;
    if (candidate.referenceTime.isBefore(start.referenceTime)) {
      return start;
    }
    return candidate;
  }

  Map<String, int> _sortedCounts(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }
}
