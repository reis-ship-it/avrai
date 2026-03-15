import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/aggregate_metric_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/bham_priority_replay_ingestion_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/calendar_event_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/historical_entity_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/replay_record_normalization_service.dart';
import 'package:avrai_runtime_os/services/prediction/spatial_feature_replay_source_adapter.dart';
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

  test('ingests ready 2023 replay sources through adapters and normalization', () async {
    final temporalKernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
    );

    final manifest = ReplayIngestionManifest(
      manifestId: 'manifest-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 10, 18),
      selectedScore: const ReplayYearCompletenessScore(
        year: 2023,
        eventCoverage: 0.7,
        venueCoverage: 0.65,
        communityCoverage: 0.72,
        recurrenceFidelity: 0.81,
        temporalCertainty: 0.82,
        trustQuality: 0.7,
        overallScore: 0.717,
      ),
      sourcePlans: const <ReplayIngestionSourcePlan>[
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'U.S. Census ACS',
            sourceType: 'demographic_reality',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['population', 'housing'],
            temporalStartYear: 2020,
            temporalEndYear: 2024,
            replayRole: 'population_priors',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['population_cohort', 'housing_signal'],
          dedupeKeys: <String>['tract_id', 'year'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'City of Birmingham OpenGov',
            sourceType: 'civic_spatial_truth',
            accessMethod: ReplaySourceAccessMethod.openData,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['localities', 'communities'],
            temporalStartYear: 2015,
            temporalEndYear: 2026,
            replayRole: 'locality_truth',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['locality', 'community'],
          dedupeKeys: <String>['dataset_id', 'neighborhood_name'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'UAB Academic, Clinical, and Event Calendars',
            sourceType: 'institutional_calendar',
            accessMethod: ReplaySourceAccessMethod.ics,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['events', 'venues', 'communities'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'institutional_gravity_well',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 2,
          normalizationTargetTypes: <String>['event', 'venue', 'community'],
          dedupeKeys: <String>['calendar_uid', 'event_start'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'Resy / OpenTable / Venue Reservation Exports',
            sourceType: 'reservation_demand',
            accessMethod: ReplaySourceAccessMethod.partnerExport,
            trustTier: ReplaySourceTrustTier.tier3,
            status: ReplaySourceStatus.candidate,
            entityCoverage: <String>['venues'],
            temporalStartYear: 2023,
            temporalEndYear: 2026,
            replayRole: 'occupancy_and_booking_pressure',
            legalStatus: 'review_required',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.pendingReview,
          ingestPriority: 3,
          normalizationTargetTypes: <String>['venue'],
          dedupeKeys: <String>['venue_name', 'service_date'],
        ),
      ],
      canonicalEntityTypes: const <String>['population_cohort', 'housing_signal', 'locality', 'community', 'event', 'venue'],
    );

    final service = BhamPriorityReplayIngestionService(
      adapters: const <BhamReplaySourceAdapter>[
        AggregateMetricReplaySourceAdapter(),
        HistoricalEntityReplaySourceAdapter(),
        CalendarEventReplaySourceAdapter(),
        SpatialFeatureReplaySourceAdapter(),
      ],
      normalizationService: ReplayRecordNormalizationService(
        temporalKernel: temporalKernel,
      ),
      temporalKernel: temporalKernel,
    );

    final result = await service.ingestManifest(
      manifest: manifest,
      rawRecordsBySourceName: <String, List<Map<String, dynamic>>>{
        'U.S. Census ACS': <Map<String, dynamic>>[
          <String, dynamic>{
            'record_id': 'acs-1',
            'series_key': 'population_total',
            'name': 'Southside Population',
            'entity_id': 'tract:110100',
            'entity_type': 'population_cohort',
            'locality': 'Southside',
            'metric_value': 12000,
            'observed_at': '2023-07-01T00:00:00Z',
            'published_at': '2023-12-15T00:00:00Z',
          },
        ],
        'City of Birmingham OpenGov': <Map<String, dynamic>>[
          <String, dynamic>{
            'record_id': 'opengov-1',
            'feature_id': 'neighborhood-avondale',
            'name': 'Avondale',
            'entity_type': 'locality',
            'locality': 'Avondale',
            'lat': 33.5245,
            'lng': -86.7743,
            'published_at': '2023-02-01T00:00:00Z',
          },
        ],
        'UAB Academic, Clinical, and Event Calendars': <Map<String, dynamic>>[
          <String, dynamic>{
            'record_id': 'uab-1',
            'event_id': 'event-uab-spring-concert',
            'title': 'UAB Spring Concert',
            'venue_name': 'UAB Green',
            'community_name': 'UAB Students',
            'locality': 'Southside',
            'published_at': '2023-03-01T10:00:00Z',
            'starts_at': '2023-04-10T18:00:00Z',
            'ends_at': '2023-04-10T20:00:00Z',
          },
        ],
      },
    );

    expect(result.results.length, 3);
    expect(result.skippedSources, contains('Resy / OpenTable / Venue Reservation Exports'));

    final calendarResult = result.results.firstWhere(
      (entry) => entry.sourcePlan.source.sourceName == 'UAB Academic, Clinical, and Event Calendars',
    );
    expect(calendarResult.adapterId, 'calendar_event_replay_source_adapter');
    expect(calendarResult.observations.single.subjectIdentity.entityType, 'event');

    final spatialResult = result.results.firstWhere(
      (entry) => entry.sourcePlan.source.sourceName == 'City of Birmingham OpenGov',
    );
    expect(spatialResult.adapterId, 'spatial_feature_replay_source_adapter');
    expect(spatialResult.observations.single.subjectIdentity.localityAnchor, 'Avondale');

    final aggregateResult = result.results.firstWhere(
      (entry) => entry.sourcePlan.source.sourceName == 'U.S. Census ACS',
    );
    expect(aggregateResult.adapterId, 'aggregate_metric_replay_source_adapter');
    expect(
      aggregateResult.observations.single.subjectIdentity.entityType,
      'population_cohort',
    );
  });

  test('ingests historical archive rows through the historical entity adapter',
      () async {
    final temporalKernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 11, 12))),
    );

    final manifest = ReplayIngestionManifest(
      manifestId: 'historical-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 11, 18),
      selectedScore: const ReplayYearCompletenessScore(
        year: 2023,
        eventCoverage: 0.7,
        venueCoverage: 0.68,
        communityCoverage: 0.72,
        recurrenceFidelity: 0.8,
        temporalCertainty: 0.8,
        trustQuality: 0.74,
        overallScore: 0.726,
      ),
      sourcePlans: const <ReplayIngestionSourcePlan>[
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'Bhamwiki',
            sourceType: 'historical_entity_archive',
            accessMethod: ReplaySourceAccessMethod.archive,
            trustTier: ReplaySourceTrustTier.tier3,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['venues', 'communities', 'localities'],
            temporalStartYear: 2006,
            temporalEndYear: 2026,
            replayRole: 'historical_entity_memory',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 5,
          normalizationTargetTypes: <String>['venue', 'community', 'locality'],
          dedupeKeys: <String>['page_title', 'normalized_entity'],
        ),
      ],
      canonicalEntityTypes: const <String>['venue', 'community', 'locality'],
    );

    final service = BhamPriorityReplayIngestionService(
      adapters: const <BhamReplaySourceAdapter>[
        AggregateMetricReplaySourceAdapter(),
        HistoricalEntityReplaySourceAdapter(),
        CalendarEventReplaySourceAdapter(),
        SpatialFeatureReplaySourceAdapter(),
      ],
      normalizationService: ReplayRecordNormalizationService(
        temporalKernel: temporalKernel,
      ),
      temporalKernel: temporalKernel,
    );

    final result = await service.ingestManifest(
      manifest: manifest,
      rawRecordsBySourceName: <String, List<Map<String, dynamic>>>{
        'Bhamwiki': <Map<String, dynamic>>[
          <String, dynamic>{
            'record_id': 'bhamwiki-saturn-history',
            'entity_type': 'club',
            'entity_id': 'saturn_birmingham',
            'name': 'Saturn',
            'locality': 'bham_avondale',
            'observed_at': '2023-12-31T00:00:00Z',
            'published_at': '2026-03-11T22:20:00Z',
            'valid_from': '2015-05-01T00:00:00Z',
            'entity_history': 'Opened in Avondale in 2015 as a live music venue and cultural anchor.',
            'opening_closure_history': 'Open throughout 2023.',
            'neighborhood_links': ['Avondale', '41st Street South'],
          },
        ],
      },
    );

    expect(result.results.length, 1);
    expect(result.results.single.adapterId, 'historical_entity_replay_source_adapter');
    expect(result.results.single.observations.single.subjectIdentity.entityType, 'club');
    expect(
      result.results.single.observations.single.metadata['raw_record_id'],
      'bhamwiki-saturn-history',
    );
  });

  test('allows historicalized structural tourism rows to remain communities', () async {
    final temporalKernel = SystemTemporalKernel(
      clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 12, 12))),
    );

    final manifest = ReplayIngestionManifest(
      manifestId: 'historicalized-public-catalog-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12, 18),
      selectedScore: const ReplayYearCompletenessScore(
        year: 2023,
        eventCoverage: 0.74,
        venueCoverage: 0.72,
        communityCoverage: 0.8,
        recurrenceFidelity: 0.76,
        temporalCertainty: 0.78,
        trustQuality: 0.73,
        overallScore: 0.755,
      ),
      sourcePlans: const <ReplayIngestionSourcePlan>[
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'IN Birmingham (CVB Calendar)',
            sourceType: 'tourism_calendar',
            accessMethod: ReplaySourceAccessMethod.scrape,
            trustTier: ReplaySourceTrustTier.tier3,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['community', 'event', 'locality', 'venue'],
            temporalStartYear: 2023,
            temporalEndYear: 2026,
            replayRole: 'official_tourism_event_truth',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 4,
          normalizationTargetTypes: <String>['community', 'event', 'locality', 'venue'],
          dedupeKeys: <String>['name', 'locality'],
        ),
      ],
      canonicalEntityTypes: const <String>['community', 'event', 'locality', 'venue'],
    );

    final service = BhamPriorityReplayIngestionService(
      adapters: const <BhamReplaySourceAdapter>[
        AggregateMetricReplaySourceAdapter(),
        HistoricalEntityReplaySourceAdapter(),
        CalendarEventReplaySourceAdapter(),
        SpatialFeatureReplaySourceAdapter(),
      ],
      normalizationService: ReplayRecordNormalizationService(
        temporalKernel: temporalKernel,
      ),
      temporalKernel: temporalKernel,
    );

    final result = await service.ingestManifest(
      manifest: manifest,
      rawRecordsBySourceName: <String, List<Map<String, dynamic>>>{
        'IN Birmingham (CVB Calendar)': <Map<String, dynamic>>[
          <String, dynamic>{
            'record_id': 'inbham-hist-downtown-2023',
            'entity_type': 'community',
            'entity_id': 'community:bham_downtown',
            'title': 'Downtown',
            'name': 'Downtown',
            'community_name': 'Downtown',
            'locality': 'bham_downtown',
            'observed_at': '2023-01-01T00:00:00Z',
            'published_at': '2023-01-01T00:00:00Z',
            'valid_from': '2023-01-01T00:00:00Z',
            'valid_to': '2023-12-31T23:59:59Z',
            'historical_admissibility': 'year_valid_structural_snapshot',
            'historical_validation_note':
                'Promoted as a stable destination-community anchor representing downtown Birmingham throughout 2023.',
          },
        ],
      },
    );

    expect(result.results.single.adapterId, 'calendar_event_replay_source_adapter');
    expect(result.results.single.observations.single.subjectIdentity.entityType, 'community');
    expect(
      result.results.single.observations.single.subjectIdentity.localityAnchor,
      'bham_downtown',
    );
  });
}
