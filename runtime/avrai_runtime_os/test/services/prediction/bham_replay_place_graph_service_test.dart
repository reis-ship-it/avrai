import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_place_graph_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant instant(DateTime time) => TemporalInstant(
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

  ReplayNormalizedObservation observation({
    required String id,
    required String entityId,
    required String entityType,
    required String canonicalName,
    required String locality,
    required Map<String, dynamic> normalizedFields,
  }) {
    return ReplayNormalizedObservation(
      observationId: id,
      subjectIdentity: ReplayEntityIdentity(
        normalizedEntityId: entityId,
        entityType: entityType,
        canonicalName: canonicalName,
        localityAnchor: locality,
      ),
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-$id',
        subjectId: entityId,
        observedAt: instant(DateTime.utc(2023, 1, 10)),
        eventStartAt: instant(DateTime.utc(2023, 2, 10)),
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'test',
        ),
        uncertainty: const TemporalUncertainty.zero(),
        temporalAuthoritySource: 'when_kernel',
      ),
      status: ReplayNormalizationStatus.normalized,
      sourceRefs: const <String>['Source A'],
      normalizedFields: normalizedFields,
    );
  }

  Map<String, dynamic> buildConsolidatedArtifact() {
    return <String, dynamic>{
      'ingestion': <String, dynamic>{
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'observations': <Map<String, dynamic>>[
              observation(
                id: 'obs-venue',
                entityId: 'venue:alabama-theatre',
                entityType: 'venue',
                canonicalName: 'Alabama Theatre',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'venue_name': 'Alabama Theatre',
                  'poi_type': 'theatre',
                  'category': 'arts',
                },
              ).toJson(),
              observation(
                id: 'obs-event',
                entityId: 'event:music-night',
                entityType: 'event',
                canonicalName: 'Music Night',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'venue_name': 'Alabama Theatre',
                  'source_page_title': 'Music Night Celebration',
                  'organization_name': 'Arts Org',
                },
              ).toJson(),
              observation(
                id: 'obs-event-missing-venue',
                entityId: 'event:community-jam',
                entityType: 'event',
                canonicalName: 'Community Jam',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'venue_name': 'Carver Hall',
                  'source_page_title': 'Community Jam Festival',
                  'organization_name': 'Community Hosts',
                },
              ).toJson(),
              observation(
                id: 'obs-community',
                entityId: 'community:arts-downtown',
                entityType: 'community',
                canonicalName: 'Downtown Arts Community',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'category': 'arts',
                  'community_name': 'Downtown Arts Community',
                },
              ).toJson(),
            ],
          },
        ],
      },
    };
  }

  ReplayVirtualWorldEnvironment buildEnvironment() {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-1',
        seed: 2023,
        divergencePolicy: 'none',
      ),
      isolationBoundary: const ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36', '37', '39'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 3,
      observationCount: 3,
      forecastEvaluatedCount: 3,
      sourceCounts: const <String, int>{'Source A': 3},
      entityTypeCounts: const <String, int>{
        'venue': 1,
        'event': 1,
        'community': 1,
      },
      localityCounts: const <String, int>{'Downtown': 3},
      forecastDispositionCounts: const <String, int>{'admitted': 3},
      nodes: const <ReplayVirtualWorldNode>[],
      metadata: const <String, dynamic>{},
    );
  }

  test('builds a canonical Birmingham place graph from replay truth', () {
    final graph = const BhamReplayPlaceGraphService().buildGraph(
      consolidatedArtifact: buildConsolidatedArtifact(),
      environment: buildEnvironment(),
    );

    expect(graph.nodeCount, greaterThanOrEqualTo(3));
    expect(graph.venueProfiles, isNotEmpty);
    expect(graph.communityProfiles, isNotEmpty);
    expect(graph.eventProfiles, isNotEmpty);
    expect(graph.clubProfiles, isNotEmpty);
    expect(graph.venueCategoryCounts['theatre'], 1);
    expect(graph.organizationProfiles, isNotEmpty);
    expect(graph.nodes.first.localityAnchor, 'Downtown');
    expect(graph.metadata['graphKind'], 'canonical_bham_truth_year_place_graph');
    expect(
      graph.venueProfiles.any(
        (profile) => profile.identity.normalizedEntityId == 'venue:carver-hall',
      ),
      isTrue,
    );
  });
}
