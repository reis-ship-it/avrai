import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';

class BhamReplayIngestionManifestService {
  const BhamReplayIngestionManifestService();

  ReplayIngestionManifest buildManifest({
    required BhamReplaySourceRegistry registry,
    required AuthoritativeReplayYearSelection selection,
  }) {
    final replayYear = selection.selectedScore.year;
    final sourcePlans = registry.sources
        .where((source) => source.coversYear(replayYear))
        .map((source) => _buildSourcePlan(source: source, replayYear: replayYear))
        .toList()
      ..sort((left, right) {
        final priorityCompare = left.ingestPriority.compareTo(right.ingestPriority);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return left.source.sourceName.compareTo(right.source.sourceName);
      });

    final canonicalEntityTypes = sourcePlans
        .expand((plan) => plan.normalizationTargetTypes)
        .toSet()
        .toList()
      ..sort();

    final statusCounts = <String, int>{};
    for (final plan in sourcePlans) {
      statusCounts.update(
        plan.source.status.name,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final readyCount = sourcePlans
        .where((plan) => plan.readiness == ReplayIngestionReadiness.ready)
        .length;
    final reviewCount = sourcePlans
        .where((plan) => plan.readiness == ReplayIngestionReadiness.pendingReview)
        .length;
    final blockedCount = sourcePlans
        .where((plan) => plan.readiness == ReplayIngestionReadiness.blocked)
        .length;

    return ReplayIngestionManifest(
      manifestId: 'bham-replay-ingestion-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      selectedScore: selection.selectedScore,
      sourcePlans: sourcePlans,
      canonicalEntityTypes: canonicalEntityTypes,
      sourceStatusCounts: statusCounts,
      notes: <String>[
        'Manifest generated from governed BHAM replay source registry ${registry.registryVersion}.',
        '$readyCount sources are ready for replay-year intake.',
        if (reviewCount > 0)
          '$reviewCount sources remain pending review before full replay-year authority.',
        if (blockedCount > 0)
          '$blockedCount sources are blocked and excluded from immediate ingestion.',
        'Normalization targets are canonical entity types derived from source coverage and replay role.',
      ],
    );
  }

  ReplayIngestionSourcePlan _buildSourcePlan({
    required ReplaySourceDescriptor source,
    required int replayYear,
  }) {
    final metadata = source.metadata;
    final dedupeKeys = (metadata['dedupeKeys'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        (metadata['dedupeKeys'] as Map?)
                ?.keys
                .map((entry) => entry.toString())
                .toList() ??
            const <String>[];

    final legalStatus = source.legalStatus.toLowerCase();
    final readiness = switch (source.status) {
      ReplaySourceStatus.blocked => ReplayIngestionReadiness.blocked,
      ReplaySourceStatus.deferred => ReplayIngestionReadiness.blocked,
      ReplaySourceStatus.legacy => ReplayIngestionReadiness.pendingReview,
      ReplaySourceStatus.candidate => ReplayIngestionReadiness.pendingReview,
      ReplaySourceStatus.approved || ReplaySourceStatus.ingested =>
        legalStatus.contains('review') || legalStatus.contains('blocked')
            ? ReplayIngestionReadiness.pendingReview
            : ReplayIngestionReadiness.ready,
    };

    final normalizationTargetTypes =
        _normalizationTargetTypesFor(source).toSet().toList()..sort();
    final notes = <String>[
      if (readiness == ReplayIngestionReadiness.pendingReview)
        'Requires review or final approval before authoritative replay ingest.',
      if (source.seedingEligible)
        'Eligible to seed governed replay/entity priors.',
      if (!source.seedingEligible)
        'Use as enrichment or verification layer after base entity normalization.',
      if ((source.ageSafetyNotes ?? '').isNotEmpty) source.ageSafetyNotes!,
    ];

    return ReplayIngestionSourcePlan(
      source: source,
      replayYear: replayYear,
      readiness: readiness,
      ingestPriority: (metadata['ingestPriority'] as num?)?.toInt() ?? 99,
      normalizationTargetTypes: normalizationTargetTypes,
      dedupeKeys: dedupeKeys,
      notes: notes,
      metadata: <String, dynamic>{
        'registryTier': metadata['registryTier'],
        'legalUsageNotes': metadata['legalUsageNotes'],
        'plannedIngestFields': metadata['plannedIngestFields'],
      }..removeWhere((key, value) => value == null),
    );
  }

  Iterable<String> _normalizationTargetTypesFor(ReplaySourceDescriptor source) {
    final targets = <String>{};
    for (final rawCoverage in source.entityCoverage) {
      final coverage = rawCoverage.toLowerCase();
      if (coverage.contains('event') || coverage.contains('calendar')) {
        targets.add('event');
      }
      if (coverage.contains('venue') ||
          coverage.contains('restaurant') ||
          coverage.contains('spot') ||
          coverage.contains('place')) {
        targets.add('venue');
      }
      if (coverage.contains('communit')) {
        targets.add('community');
      }
      if (coverage.contains('club')) {
        targets.add('club');
      }
      if (coverage.contains('localit') ||
          coverage.contains('neighborhood') ||
          coverage.contains('district')) {
        targets.add('locality');
      }
      if (coverage.contains('route') ||
          coverage.contains('traffic') ||
          coverage.contains('commute') ||
          coverage.contains('movement')) {
        targets.add('movement_flow');
      }
      if (coverage.contains('population') ||
          coverage.contains('family') ||
          coverage.contains('household')) {
        targets.add('population_cohort');
      }
      if (coverage.contains('econom') ||
          coverage.contains('income') ||
          coverage.contains('wallet')) {
        targets.add('economic_signal');
      }
      if (coverage.contains('weather') || coverage.contains('environment')) {
        targets.add('environmental_signal');
      }
      if (coverage.contains('housing')) {
        targets.add('housing_signal');
      }
    }

    if (targets.isEmpty) {
      targets.add('generic_replay_signal');
    }
    return targets;
  }
}
