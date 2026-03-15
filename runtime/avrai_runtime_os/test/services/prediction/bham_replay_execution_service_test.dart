import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'America/Chicago',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  Map<String, dynamic> buildArtifact() {
    return <String, dynamic>{
      'pack': ReplaySourcePack(
        packId: 'bham-consolidated-replay-2023',
        replayYear: 2023,
        generatedAtUtc: DateTime.utc(2026, 3, 12),
      ).toJson(),
      'ingestion': <String, dynamic>{
        'manifest': const <String, dynamic>{},
        'skippedSources': <String>['Source C'],
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'sourcePlan': <String, dynamic>{
              'source': const <String, dynamic>{'sourceName': 'Source A'},
            },
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-2',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'event:late',
                  entityType: 'event',
                  canonicalName: 'Late Event',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-2',
                  subjectId: 'event:late',
                  observedAt: buildInstant(DateTime.utc(2023, 4, 2, 10)),
                  eventStartAt: buildInstant(DateTime.utc(2023, 4, 2, 18)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty.zero(),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
                sourceRefs: const <String>['Source A'],
              ).toJson(),
            ],
          },
          <String, dynamic>{
            'sourcePlan': <String, dynamic>{
              'source': const <String, dynamic>{'sourceName': 'Source B'},
            },
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-1',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'venue:early',
                  entityType: 'venue',
                  canonicalName: 'Early Venue',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-1',
                  subjectId: 'venue:early',
                  observedAt: buildInstant(DateTime.utc(2023, 4, 1, 9)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty.zero(),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
                sourceRefs: const <String>['Source B'],
              ).toJson(),
            ],
          },
        ],
      },
    };
  }

  test('builds an ordered replay execution plan from consolidated artifact',
      () {
    final service = BhamReplayExecutionService(
      temporalKernel: SystemTemporalKernel(
        clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 12))),
      ),
    );
    const runContext = MonteCarloRunContext(
      canonicalReplayYear: 2023,
      replayYear: 2023,
      branchId: 'canonical',
      runId: 'run-1',
      seed: 2023,
      divergencePolicy: 'none',
    );

    final plan = service.buildPlanFromConsolidatedArtifact(
      artifact: buildArtifact(),
      runContext: runContext,
    );

    expect(plan.entries.length, 2);
    expect(plan.entries.first.observation.observationId, 'obs-1');
    expect(plan.entries.last.observation.observationId, 'obs-2');
    expect(plan.sourceCounts['Source A'], 1);
    expect(plan.sourceCounts['Source B'], 1);
    expect(plan.entityTypeCounts['event'], 1);
    expect(plan.entityTypeCounts['venue'], 1);
    expect(plan.skippedSources, contains('Source C'));
    expect(
      plan.runContext.metadata.containsKey('mesh_runtime_state_summary'),
      isFalse,
    );
    expect(
      plan.runContext.metadata.containsKey('ai2ai_runtime_state_summary'),
      isFalse,
    );
  });

  test('executes replay plan into ordered runtime events', () async {
    final fixedClock = FixedClockSource(buildInstant(DateTime.utc(2023, 1, 1)));
    final kernel = SystemTemporalKernel(clockSource: fixedClock);
    final service = BhamReplayExecutionService(
      temporalKernel: kernel,
      replayClockSource: fixedClock,
    );

    final plan = service.buildPlanFromConsolidatedArtifact(
      artifact: buildArtifact(),
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-2',
        seed: 2023,
        divergencePolicy: 'none',
      ),
    );

    final result = await service.executePlan(plan: plan);
    final stored = await kernel.queryRuntimeEvents(
      const RuntimeTemporalEventQuery(
          source: 'bham_replay_execution', limit: 10),
    );

    expect(result.executedEventIds.length, 2);
    expect(result.executedSourceCounts['Source A'], 1);
    expect(result.executedSourceCounts['Source B'], 1);
    expect(stored.length, 2);
    expect(stored.first.event.eventId, contains('run-2'));
  });

  test('clamps out-of-year structural priors into the replay year', () {
    final service = BhamReplayExecutionService(
      temporalKernel: SystemTemporalKernel(
        clockSource: FixedClockSource(buildInstant(DateTime.utc(2026, 3, 12))),
      ),
    );

    final artifact = <String, dynamic>{
      'pack': ReplaySourcePack(
        packId: 'bham-consolidated-replay-2023',
        replayYear: 2023,
        generatedAtUtc: DateTime.utc(2026, 3, 12),
      ).toJson(),
      'ingestion': <String, dynamic>{
        'manifest': const <String, dynamic>{},
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'sourcePlan': <String, dynamic>{
              'source': const <String, dynamic>{
                'sourceName': 'Historical Source'
              },
            },
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-historical',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'venue:historic-anchor',
                  entityType: 'venue',
                  canonicalName: 'Historic Anchor',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-historical',
                  subjectId: 'venue:historic-anchor',
                  observedAt: buildInstant(DateTime.utc(1988, 1, 1)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty.zero(),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
              ).toJson(),
            ],
          },
        ],
      },
    };

    final plan = service.buildPlanFromConsolidatedArtifact(
      artifact: artifact,
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-3',
        seed: 2023,
        divergencePolicy: 'none',
      ),
    );

    expect(plan.entries.single.executionInstant.referenceTime,
        DateTime.utc(2023, 1, 1));
  });
}
