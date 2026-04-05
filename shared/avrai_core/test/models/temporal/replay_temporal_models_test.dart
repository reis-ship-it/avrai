import 'package:avrai_core/avra_core.dart';
import 'package:test/test.dart';

void main() {
  group('Replay temporal contracts', () {
    const provenance = TemporalProvenance(
      authority: TemporalAuthority.historicalImport,
      source: 'bham_registry',
    );
    const uncertainty = TemporalUncertainty(
      window: Duration(minutes: 15),
      confidence: 0.82,
    );
    final instant = TemporalInstant(
      referenceTime: DateTime.utc(2025, 5, 3, 18),
      civilTime: DateTime.utc(2025, 5, 3, 13),
      timezoneId: 'America/Chicago',
      provenance: provenance,
      uncertainty: uncertainty,
      monotonicTicks: 42,
    );

    test('ReplayTemporalEnvelope round-trips', () {
      final envelope = ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'venue:pepper-place',
        observedAt: instant,
        publishedAt: instant,
        validFrom: instant,
        validTo: instant,
        eventStartAt: instant,
        eventEndAt: instant,
        lastVerifiedAt: instant,
        semanticBand: SemanticTimeBand.afternoon,
        provenance: provenance,
        uncertainty: uncertainty,
        temporalAuthoritySource: 'when_kernel',
        branchId: 'branch-a',
        runId: 'run-17',
        metadata: const <String, dynamic>{'source_record': 'rec-3'},
      );

      final decoded = ReplayTemporalEnvelope.fromJson(envelope.toJson());
      expect(decoded.envelopeId, envelope.envelopeId);
      expect(decoded.subjectId, envelope.subjectId);
      expect(decoded.temporalAuthoritySource, 'when_kernel');
      expect(decoded.branchId, 'branch-a');
      expect(decoded.semanticBand, SemanticTimeBand.afternoon);
      expect(decoded.metadata['source_record'], 'rec-3');
    });

    test('MonteCarloRunContext round-trips', () {
      const context = MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-a',
        runId: 'run-17',
        seed: 1234,
        divergencePolicy: 'seasonal_variation',
        branchPurpose: 'attendance_stress',
        parentRunId: 'run-root',
        parentBranchId: 'branch-root',
        metadata: <String, dynamic>{'scenario': 'music-festival'},
      );

      final decoded = MonteCarloRunContext.fromJson(context.toJson());
      expect(decoded.replayYear, 2025);
      expect(decoded.seed, 1234);
      expect(decoded.divergencePolicy, 'seasonal_variation');
      expect(decoded.metadata['scenario'], 'music-festival');
    });

    test('ReplayYearCompletenessScore round-trips', () {
      const score = ReplayYearCompletenessScore(
        year: 2025,
        eventCoverage: 0.91,
        venueCoverage: 0.86,
        communityCoverage: 0.74,
        recurrenceFidelity: 0.88,
        temporalCertainty: 0.84,
        trustQuality: 0.93,
        overallScore: 0.86,
        notes: <String>['strong civic calendars'],
        sourceRefs: <String>['city-events', 'venue-calendars'],
      );

      final decoded = ReplayYearCompletenessScore.fromJson(score.toJson());
      expect(decoded.year, 2025);
      expect(decoded.overallScore, closeTo(0.86, 0.0001));
      expect(decoded.notes, contains('strong civic calendars'));
      expect(decoded.sourceRefs, contains('city-events'));
    });

    test('GroundTruthOverrideRecord round-trips', () {
      final record = GroundTruthOverrideRecord(
        overrideId: 'override-1',
        subjectId: 'venue:coffee-shop',
        priorSource: 'historical_replay',
        overrideSource: 'locality_agent',
        overriddenAt: instant,
        reason: 'closure acknowledged by locality and admin',
        resolution: 'prior_downgraded',
        priorConfidence: 0.79,
        overrideConfidence: 0.97,
        branchId: 'branch-a',
        runId: 'run-17',
        metadata: const <String, dynamic>{'admin_case_id': 'case-9'},
      );

      final decoded = GroundTruthOverrideRecord.fromJson(record.toJson());
      expect(decoded.overrideId, 'override-1');
      expect(decoded.overrideSource, 'locality_agent');
      expect(decoded.resolution, 'prior_downgraded');
      expect(decoded.metadata['admin_case_id'], 'case-9');
    });

    test('supporting replay and forecast contracts round-trip', () {
      final source = ReplaySourceDescriptor(
        sourceName: 'City Events',
        sourceType: 'official_calendar',
        accessMethod: ReplaySourceAccessMethod.api,
        trustTier: ReplaySourceTrustTier.tier1,
        status: ReplaySourceStatus.approved,
        entityCoverage: const <String>['events', 'venues'],
        temporalStartYear: 2024,
        temporalEndYear: 2026,
        replayRole: 'event_truth',
        legalStatus: 'allowed',
        structuredExportAvailable: true,
        seedingEligible: true,
      );
      final entity = ReplayEntityIdentity(
        normalizedEntityId: 'venue:saturn',
        entityType: 'venue',
        canonicalName: 'Saturn',
        sourceAliases: const <String>['Saturn Birmingham'],
        dedupeKeys: const <String, String>{'osm': '123'},
        localityAnchor: 'Avondale',
      );
      final lineage = ReplayBranchLineage(
        branchId: 'branch-a',
        runId: 'run-17',
        canonicalReplayYear: 2025,
        seed: 17,
        createdAt: instant,
        branchPurpose: 'attendance_stress',
      );
      final transition = AgentLifecycleTransition(
        transitionId: 'life-1',
        agentId: 'agent-1',
        role: SimulatedPopulationRole.humanWithAgent,
        fromState: AgentLifecycleState.active,
        toState: AgentLifecycleState.dormant,
        occurredAt: instant,
        trigger: 'user_stalled',
      );

      final decodedSource = ReplaySourceDescriptor.fromJson(source.toJson());
      final decodedEntity = ReplayEntityIdentity.fromJson(entity.toJson());
      final decodedLineage = ReplayBranchLineage.fromJson(lineage.toJson());
      final decodedTransition =
          AgentLifecycleTransition.fromJson(transition.toJson());

      expect(decodedSource.sourceName, 'City Events');
      expect(decodedEntity.normalizedEntityId, 'venue:saturn');
      expect(decodedLineage.branchId, 'branch-a');
      expect(decodedTransition.toState, AgentLifecycleState.dormant);
    });

    test('replay truth resolution and forecast trace round-trip', () {
      final envelope = ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: provenance,
        uncertainty: uncertainty,
        temporalAuthoritySource: 'when_kernel',
      );
      const runContext = MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-a',
        runId: 'run-17',
        seed: 17,
        divergencePolicy: 'seasonal_variation',
      );
      final trace = ForecastEvaluationTrace(
        traceId: 'trace-1',
        forecastId: 'forecast-1',
        subjectId: 'venue:saturn',
        replayEnvelope: envelope,
        runContext: runContext,
        validityWindow: TemporalInterval(start: instant, end: instant),
        uncertainty: uncertainty,
        explanation: 'baseline',
        contradictionHooks: const <String>['locality_agent_override'],
      );
      final resolution = ReplayTruthResolution(
        resolutionId: 'resolution-1',
        subjectId: 'venue:saturn',
        outcome: ReplayTruthResolutionOutcome.overridden,
        confidence: 0.96,
        rationale: 'locality truth outranked stale prior',
        resolvedAt: instant,
        contributingSources: const <String>['city-events', 'bham-now'],
        overrideRecordIds: const <String>['override-1'],
      );

      final decodedTrace = ForecastEvaluationTrace.fromJson(trace.toJson());
      final decodedResolution =
          ReplayTruthResolution.fromJson(resolution.toJson());

      expect(decodedTrace.forecastId, 'forecast-1');
      expect(
          decodedTrace.contradictionHooks, contains('locality_agent_override'));
      expect(
          decodedResolution.outcome, ReplayTruthResolutionOutcome.overridden);
    });

    test('replay virtual world environment and higher-agent rollups round-trip',
        () {
      final node = ReplayVirtualWorldNode(
        nodeId: 'replay-node:venue:saturn',
        environmentNamespace: 'replay-world/bham/2023/run-17',
        subjectIdentity: const ReplayEntityIdentity(
          normalizedEntityId: 'venue:saturn',
          entityType: 'venue',
          canonicalName: 'Saturn',
          localityAnchor: 'Avondale',
        ),
        localityAnchor: 'Avondale',
        sourceRefs: const <String>['OSM', 'IN Birmingham'],
        observationIds: const <String>['obs-1', 'obs-2'],
        firstObservedAt: instant,
        lastObservedAt: instant,
        forecastDispositionCounts: const <String, int>{'admitted': 2},
      );
      final environment = ReplayVirtualWorldEnvironment(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2023,
          replayYear: 2023,
          branchId: 'canonical',
          runId: 'run-17',
          seed: 17,
          divergencePolicy: 'none',
        ),
        isolationBoundary: const ReplayWorldIsolationBoundary(
          environmentNamespace: 'replay-world/bham/2023/run-17',
          sourceArtifactRefs: <String>['36', '37', '39'],
          runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
          liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
          appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
          adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
          higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
        ),
        nodeCount: 1,
        observationCount: 2,
        forecastEvaluatedCount: 2,
        sourceCounts: const <String, int>{'OSM': 1},
        entityTypeCounts: const <String, int>{'venue': 1},
        localityCounts: const <String, int>{'Avondale': 1},
        forecastDispositionCounts: const <String, int>{'admitted': 2},
        nodes: <ReplayVirtualWorldNode>[node],
      );
      final rollupBatch = ReplayHigherAgentRollupBatch(
        environmentId: 'env-1',
        replayYear: 2023,
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2023,
          replayYear: 2023,
          branchId: 'canonical',
          runId: 'run-17',
          seed: 17,
          divergencePolicy: 'none',
        ),
        rollupCountsByLevel: const <String, int>{'locality': 1},
        rollups: const <ReplayHigherAgentRollup>[
          ReplayHigherAgentRollup(
            rollupId: 'rollup-1',
            environmentId: 'env-1',
            level: ReplayHigherAgentLevel.locality,
            agentId: 'locality-agent:avondale',
            canonicalName: 'Avondale',
            localityAnchor: 'Avondale',
            nodeCount: 1,
            nodeIds: <String>['replay-node:venue:saturn'],
            sourceCounts: <String, int>{'OSM': 1},
            entityTypeCounts: <String, int>{'venue': 1},
            forecastDispositionCounts: <String, int>{'admitted': 2},
            boundedGuidance: <String>['Monitor replay-only venue pressure.'],
          ),
        ],
      );

      final decodedEnvironment =
          ReplayVirtualWorldEnvironment.fromJson(environment.toJson());
      final decodedRollupBatch =
          ReplayHigherAgentRollupBatch.fromJson(rollupBatch.toJson());

      expect(
        decodedEnvironment.isolationBoundary.appSurfacePolicy,
        ReplayWorldAccessPolicy.blocked,
      );
      expect(decodedEnvironment.nodes.single.subjectIdentity.canonicalName,
          'Saturn');
      expect(decodedRollupBatch.rollups.single.level,
          ReplayHigherAgentLevel.locality);
      expect(
          decodedRollupBatch.rollups.single.agentId, 'locality-agent:avondale');
    });

    test('replay ingestion manifest contracts round-trip', () {
      final source = ReplaySourceDescriptor(
        sourceName: 'City Events',
        sourceType: 'official_calendar',
        accessMethod: ReplaySourceAccessMethod.api,
        trustTier: ReplaySourceTrustTier.tier1,
        status: ReplaySourceStatus.approved,
        entityCoverage: const <String>['events', 'venues', 'communities'],
        temporalStartYear: 2023,
        temporalEndYear: 2025,
        replayRole: 'event_truth',
        legalStatus: 'allowed',
        structuredExportAvailable: true,
      );
      final plan = ReplayIngestionSourcePlan(
        source: source,
        replayYear: 2023,
        readiness: ReplayIngestionReadiness.ready,
        ingestPriority: 2,
        normalizationTargetTypes: const <String>['event', 'venue', 'community'],
        dedupeKeys: const <String>['event_name', 'venue_name', 'event_start'],
      );
      const score = ReplayYearCompletenessScore(
        year: 2023,
        eventCoverage: 0.7,
        venueCoverage: 0.6,
        communityCoverage: 0.65,
        recurrenceFidelity: 0.8,
        temporalCertainty: 0.79,
        trustQuality: 0.83,
        overallScore: 0.73,
      );
      final manifest = ReplayIngestionManifest(
        manifestId: 'manifest-2023',
        replayYear: 2023,
        generatedAtUtc: DateTime.utc(2026, 3, 10, 18),
        selectedScore: score,
        sourcePlans: <ReplayIngestionSourcePlan>[plan],
        canonicalEntityTypes: const <String>['event', 'venue', 'community'],
        sourceStatusCounts: const <String, int>{'approved': 1},
      );

      final decoded = ReplayIngestionManifest.fromJson(manifest.toJson());

      expect(decoded.manifestId, 'manifest-2023');
      expect(
          decoded.sourcePlans.single.readiness, ReplayIngestionReadiness.ready);
      expect(decoded.canonicalEntityTypes, contains('community'));
    });

    test('replay source record and normalized observation round-trip', () {
      final envelope = ReplayTemporalEnvelope(
        envelopeId: 'env-2',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: provenance,
        uncertainty: uncertainty,
        temporalAuthoritySource: 'when_kernel',
      );
      final record = ReplaySourceRecord(
        recordId: 'record-1',
        sourceName: 'City Events',
        replayYear: 2023,
        rawEntityId: 'city-events-1',
        rawEntityType: 'event',
        replayEnvelope: envelope,
        localityHint: 'Avondale',
        payload: const <String, dynamic>{'name': 'Saturn Concert'},
      );
      final observation = ReplayNormalizedObservation(
        observationId: 'obs-1',
        subjectIdentity: const ReplayEntityIdentity(
          normalizedEntityId: 'event:saturn-concert',
          entityType: 'event',
          canonicalName: 'Saturn Concert',
        ),
        replayEnvelope: envelope,
        status: ReplayNormalizationStatus.normalized,
        sourceRefs: const <String>['City Events'],
        normalizedFields: const <String, dynamic>{'name': 'Saturn Concert'},
      );

      final decodedRecord = ReplaySourceRecord.fromJson(record.toJson());
      final decodedObservation =
          ReplayNormalizedObservation.fromJson(observation.toJson());

      expect(decodedRecord.recordId, 'record-1');
      expect(decodedRecord.localityHint, 'Avondale');
      expect(decodedObservation.status, ReplayNormalizationStatus.normalized);
      expect(decodedObservation.subjectIdentity.normalizedEntityId,
          'event:saturn-concert');
    });
  });
}
