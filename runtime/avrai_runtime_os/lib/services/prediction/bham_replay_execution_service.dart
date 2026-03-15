import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

class BhamReplayExecutionEntry {
  const BhamReplayExecutionEntry({
    required this.sequenceNumber,
    required this.observation,
    required this.executionInstant,
    required this.primarySourceName,
    required this.dayKey,
    required this.monthKey,
  });

  final int sequenceNumber;
  final ReplayNormalizedObservation observation;
  final TemporalInstant executionInstant;
  final String primarySourceName;
  final String dayKey;
  final String monthKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sequenceNumber': sequenceNumber,
      'observationId': observation.observationId,
      'subjectId': observation.subjectIdentity.normalizedEntityId,
      'entityType': observation.subjectIdentity.entityType,
      'canonicalName': observation.subjectIdentity.canonicalName,
      'primarySourceName': primarySourceName,
      'executionInstant': executionInstant.toJson(),
      'dayKey': dayKey,
      'monthKey': monthKey,
    };
  }

  factory BhamReplayExecutionEntry.fromJson(Map<String, dynamic> json) {
    return BhamReplayExecutionEntry(
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt() ?? 0,
      observation: ReplayNormalizedObservation(
        observationId: json['observationId'] as String? ?? '',
        subjectIdentity: ReplayEntityIdentity(
          normalizedEntityId: json['subjectId'] as String? ?? '',
          entityType: json['entityType'] as String? ?? 'unknown',
          canonicalName: json['canonicalName'] as String? ?? '',
        ),
        replayEnvelope: ReplayTemporalEnvelope(
          envelopeId: 'reconstructed:${json['observationId'] ?? ''}',
          subjectId: json['subjectId'] as String? ?? '',
          observedAt: TemporalInstant.fromJson(
            Map<String, dynamic>.from(
                json['executionInstant'] as Map? ?? const {}),
          ),
          provenance: const TemporalProvenance(
            authority: TemporalAuthority.historicalImport,
            source: 'bham_replay_execution_plan',
          ),
          uncertainty: const TemporalUncertainty.zero(),
          temporalAuthoritySource: 'when_kernel',
        ),
        status: ReplayNormalizationStatus.normalized,
      ),
      executionInstant: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['executionInstant'] as Map? ?? const {}),
      ),
      primarySourceName: json['primarySourceName'] as String? ?? 'unknown',
      dayKey: json['dayKey'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
    );
  }
}

class BhamReplayExecutionPlan {
  const BhamReplayExecutionPlan({
    required this.packId,
    required this.replayYear,
    required this.runContext,
    required this.entries,
    required this.skippedSources,
    required this.sourceCounts,
    required this.entityTypeCounts,
    required this.dayCounts,
    this.firstExecutionAt,
    this.lastExecutionAt,
  });

  final String packId;
  final int replayYear;
  final MonteCarloRunContext runContext;
  final List<BhamReplayExecutionEntry> entries;
  final List<String> skippedSources;
  final Map<String, int> sourceCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> dayCounts;
  final TemporalInstant? firstExecutionAt;
  final TemporalInstant? lastExecutionAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'packId': packId,
      'replayYear': replayYear,
      'runContext': runContext.toJson(),
      'entryCount': entries.length,
      'skippedSources': skippedSources,
      'sourceCounts': sourceCounts,
      'entityTypeCounts': entityTypeCounts,
      'dayCounts': dayCounts,
      'firstExecutionAt': firstExecutionAt?.toJson(),
      'lastExecutionAt': lastExecutionAt?.toJson(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory BhamReplayExecutionPlan.fromJson(Map<String, dynamic> json) {
    return BhamReplayExecutionPlan(
      packId: json['packId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      entries: (json['entries'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => BhamReplayExecutionEntry.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <BhamReplayExecutionEntry>[],
      skippedSources: (json['skippedSources'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceCounts: _readCounts(json['sourceCounts']),
      entityTypeCounts: _readCounts(json['entityTypeCounts']),
      dayCounts: _readCounts(json['dayCounts']),
      firstExecutionAt: _readInstant(json['firstExecutionAt']),
      lastExecutionAt: _readInstant(json['lastExecutionAt']),
    );
  }

  static Map<String, int> _readCounts(Object? raw) {
    return (raw as Map?)?.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        const <String, int>{};
  }

  static TemporalInstant? _readInstant(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return TemporalInstant.fromJson(raw);
    }
    if (raw is Map) {
      return TemporalInstant.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}

class BhamReplayExecutionResult {
  const BhamReplayExecutionResult({
    required this.plan,
    required this.executedEventIds,
    required this.executedSourceCounts,
    required this.executedEntityTypeCounts,
    this.firstExecutedAt,
    this.lastExecutedAt,
  });

  final BhamReplayExecutionPlan plan;
  final List<String> executedEventIds;
  final Map<String, int> executedSourceCounts;
  final Map<String, int> executedEntityTypeCounts;
  final TemporalInstant? firstExecutedAt;
  final TemporalInstant? lastExecutedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'packId': plan.packId,
      'replayYear': plan.replayYear,
      'runContext': plan.runContext.toJson(),
      'executedCount': executedEventIds.length,
      'executedEventIds': executedEventIds,
      'executedSourceCounts': executedSourceCounts,
      'executedEntityTypeCounts': executedEntityTypeCounts,
      'firstExecutedAt': firstExecutedAt?.toJson(),
      'lastExecutedAt': lastExecutedAt?.toJson(),
    };
  }
}

class BhamReplayExecutionService {
  const BhamReplayExecutionService({
    required this.temporalKernel,
    this.replayClockSource,
  });

  final TemporalKernel temporalKernel;
  final FixedClockSource? replayClockSource;

  BhamReplayExecutionPlan buildPlanFromConsolidatedArtifact({
    required Map<String, dynamic> artifact,
    required MonteCarloRunContext runContext,
  }) {
    final pack = ReplaySourcePack.fromJson(
      Map<String, dynamic>.from(artifact['pack'] as Map? ?? const {}),
    );
    final ingestion = Map<String, dynamic>.from(
      artifact['ingestion'] as Map? ?? const {},
    );
    final results = (ingestion['results'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final skippedSources = (ingestion['skippedSources'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        const <String>[];

    final entries = <BhamReplayExecutionEntry>[];
    final sourceCounts = <String, int>{};
    final entityTypeCounts = <String, int>{};
    final dayCounts = <String, int>{};

    for (final result in results) {
      final sourcePlan = Map<String, dynamic>.from(
        result['sourcePlan'] as Map? ?? const {},
      );
      final sourceDescriptor = Map<String, dynamic>.from(
        sourcePlan['source'] as Map? ?? const {},
      );
      final sourceName = sourceDescriptor['sourceName'] as String? ?? 'unknown';
      final observations = (result['observations'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayNormalizedObservation.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayNormalizedObservation>[];

      for (final observation in observations) {
        final executionInstant = _executionInstantFor(
          observation,
          replayYear: pack.replayYear,
        );
        final dayKey = _dayKey(executionInstant.civilTime);
        final monthKey = _monthKey(executionInstant.civilTime);
        final sequenceNumber = entries.length + 1;
        entries.add(
          BhamReplayExecutionEntry(
            sequenceNumber: sequenceNumber,
            observation: observation,
            executionInstant: executionInstant,
            primarySourceName: sourceName,
            dayKey: dayKey,
            monthKey: monthKey,
          ),
        );
      }
    }

    entries.sort((left, right) {
      final timeOrder = left.executionInstant.referenceTime.compareTo(
        right.executionInstant.referenceTime,
      );
      if (timeOrder != 0) {
        return timeOrder;
      }
      final entityOrder = left.observation.subjectIdentity.entityType.compareTo(
        right.observation.subjectIdentity.entityType,
      );
      if (entityOrder != 0) {
        return entityOrder;
      }
      return left.observation.observationId.compareTo(
        right.observation.observationId,
      );
    });

    final sequencedEntries = <BhamReplayExecutionEntry>[];
    for (final entry in entries) {
      final resequenced = BhamReplayExecutionEntry(
        sequenceNumber: sequencedEntries.length + 1,
        observation: entry.observation,
        executionInstant: entry.executionInstant,
        primarySourceName: entry.primarySourceName,
        dayKey: entry.dayKey,
        monthKey: entry.monthKey,
      );
      sequencedEntries.add(resequenced);
      sourceCounts[resequenced.primarySourceName] =
          (sourceCounts[resequenced.primarySourceName] ?? 0) + 1;
      final entityType = resequenced.observation.subjectIdentity.entityType;
      entityTypeCounts[entityType] = (entityTypeCounts[entityType] ?? 0) + 1;
      dayCounts[resequenced.dayKey] = (dayCounts[resequenced.dayKey] ?? 0) + 1;
    }

    return BhamReplayExecutionPlan(
      packId: pack.packId,
      replayYear: pack.replayYear,
      runContext: runContext,
      entries: sequencedEntries,
      skippedSources: skippedSources,
      sourceCounts: _sortedCounts(sourceCounts),
      entityTypeCounts: _sortedCounts(entityTypeCounts),
      dayCounts: _sortedCounts(dayCounts),
      firstExecutionAt: sequencedEntries.isEmpty
          ? null
          : sequencedEntries.first.executionInstant,
      lastExecutionAt: sequencedEntries.isEmpty
          ? null
          : sequencedEntries.last.executionInstant,
    );
  }

  Future<BhamReplayExecutionResult> executePlan({
    required BhamReplayExecutionPlan plan,
  }) async {
    final executedEventIds = <String>[];
    final sourceCounts = <String, int>{};
    final entityTypeCounts = <String, int>{};

    for (final entry in plan.entries) {
      replayClockSource?.setInstant(entry.executionInstant);
      final entityType = entry.observation.subjectIdentity.entityType;
      final event = RuntimeTemporalEvent(
        eventId: 'replay:${plan.runContext.runId}:${entry.sequenceNumber}',
        occurredAt: entry.executionInstant.referenceTime.toUtc(),
        source: 'bham_replay_execution',
        eventType: entityType,
        stage: RuntimeTemporalEventStage.ordered,
        peerId: entry.observation.subjectIdentity.normalizedEntityId,
        sequenceNumber: entry.sequenceNumber,
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'bham_consolidated_replay',
        ),
        metadata: <String, dynamic>{
          'observation_id': entry.observation.observationId,
          'canonical_name': entry.observation.subjectIdentity.canonicalName,
          'primary_source_name': entry.primarySourceName,
          'day_key': entry.dayKey,
          'month_key': entry.monthKey,
          'replay_year': plan.replayYear,
          'branch_id': plan.runContext.branchId,
          'run_id': plan.runContext.runId,
        },
      );
      final receipt = await temporalKernel.recordRuntimeEvent(event);
      executedEventIds.add(receipt.eventId);
      sourceCounts[entry.primarySourceName] =
          (sourceCounts[entry.primarySourceName] ?? 0) + 1;
      entityTypeCounts[entityType] = (entityTypeCounts[entityType] ?? 0) + 1;
    }

    return BhamReplayExecutionResult(
      plan: plan,
      executedEventIds: executedEventIds,
      executedSourceCounts: _sortedCounts(sourceCounts),
      executedEntityTypeCounts: _sortedCounts(entityTypeCounts),
      firstExecutedAt: plan.firstExecutionAt,
      lastExecutedAt: plan.lastExecutionAt,
    );
  }

  TemporalInstant _executionInstantFor(
    ReplayNormalizedObservation observation, {
    required int replayYear,
  }) {
    final envelope = observation.replayEnvelope;
    final candidates = <TemporalInstant?>[
      envelope.eventStartAt,
      envelope.eventEndAt,
      envelope.validFrom,
      envelope.validTo,
      envelope.publishedAt,
      envelope.observedAt,
      envelope.lastVerifiedAt,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.referenceTime.year == replayYear) {
        return candidate;
      }
    }

    if (_isStructuralPriorType(observation.subjectIdentity.entityType)) {
      return _clampToReplayYearStart(envelope.observedAt,
          replayYear: replayYear);
    }

    return _clampToReplayYearEnd(envelope.observedAt, replayYear: replayYear);
  }

  bool _isStructuralPriorType(String entityType) {
    return switch (entityType) {
      'venue' => true,
      'community' => true,
      'club' => true,
      'locality' => true,
      'population_cohort' => true,
      'housing_signal' => true,
      'economic_signal' => true,
      'environmental_signal' => true,
      'movement_flow' => true,
      _ => false,
    };
  }

  TemporalInstant _clampToReplayYearStart(
    TemporalInstant seed, {
    required int replayYear,
  }) {
    final clamped = DateTime.utc(replayYear, 1, 1, 0, 0, 0);
    return TemporalInstant(
      referenceTime: clamped,
      civilTime: clamped,
      timezoneId: seed.timezoneId,
      provenance: seed.provenance,
      uncertainty: seed.uncertainty,
      monotonicTicks: seed.monotonicTicks,
      atomicTimestamp: seed.atomicTimestamp,
    );
  }

  TemporalInstant _clampToReplayYearEnd(
    TemporalInstant seed, {
    required int replayYear,
  }) {
    final clamped = DateTime.utc(replayYear, 12, 31, 23, 59, 59);
    return TemporalInstant(
      referenceTime: clamped,
      civilTime: clamped,
      timezoneId: seed.timezoneId,
      provenance: seed.provenance,
      uncertainty: seed.uncertainty,
      monotonicTicks: seed.monotonicTicks,
      atomicTimestamp: seed.atomicTimestamp,
    );
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

  String _dayKey(DateTime value) {
    final local = value.toUtc();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _monthKey(DateTime value) {
    final local = value.toUtc();
    final month = local.month.toString().padLeft(2, '0');
    return '${local.year}-$month';
  }
}
