import 'package:avrai_core/avra_core.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('BaselineForecastKernel', () {
    test('produces a governed forecast claim from replay context', () async {
      const provenance = TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: 'bham_registry',
      );
      const uncertainty = TemporalUncertainty(
        window: Duration(minutes: 20),
        confidence: 0.8,
      );
      final instant = TemporalInstant(
        referenceTime: DateTime.utc(2025, 4, 1, 18),
        civilTime: DateTime.utc(2025, 4, 1, 13),
        timezoneId: 'America/Chicago',
        provenance: provenance,
        uncertainty: uncertainty,
      );
      final replayEnvelope = ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: provenance,
        uncertainty: uncertainty,
        temporalAuthoritySource: 'when_kernel',
        branchId: 'branch-bham',
        runId: 'run-1',
        metadata: const <String, dynamic>{'demand_signal': 0.9},
      );
      const runContext = MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-bham',
        runId: 'run-1',
        seed: 42,
        divergencePolicy: 'none',
      );
      final targetWindow = TemporalInterval(start: instant, end: instant);
      final evidenceWindow = TemporalInterval(start: instant, end: instant);
      final request = ForecastKernelRequest(
        forecastId: 'forecast-1',
        subjectId: 'venue:saturn',
        replayEnvelope: replayEnvelope,
        runContext: runContext,
        targetWindow: targetWindow,
        evidenceWindow: evidenceWindow,
        truthScope: const TruthScopeDescriptor.defaultForecast(
          governanceStratum: GovernanceStratum.locality,
          agentClass: TruthAgentClass.business,
          sphereId: 'bham_replay',
          familyId: 'default_forecast_family',
        ),
        metadata: const <String, dynamic>{
          'ai2ai_runtime_state_summary': <String, dynamic>{
            'learning_applied_count': 1,
          },
          'agent_class': 'business',
        },
      );

      const kernel = BaselineForecastKernel();
      final result = await kernel.forecast(request);

      expect(result.claim.claimId, 'forecast-1');
      expect(result.branchId, 'branch-bham');
      expect(result.runId, 'run-1');
      expect(result.predictedOutcome, isNotEmpty);
      expect(result.outcomeProbability, greaterThan(0.8));
      expect(result.rawPredictiveDistribution?.topOutcome, 'positive');
      expect(
        result.rawPredictiveDistribution?.representationComponent,
        ForecastRepresentationComponent.classical,
      );
      expect(result.claim.provenance.authority, TemporalAuthority.forecast);
      expect(result.claim.outcomeProbability, result.outcomeProbability);
      expect(result.truthScope?.truthSurfaceKind, TruthSurfaceKind.forecast);
      expect(result.claim.truthScope?.scopeKey, result.truthScope?.scopeKey);
      expect(result.contradictionHooks, contains('locality_agent_override'));
      expect(
        result.metadata['temporal_authority_source'],
        'when_kernel',
      );
      expect(result.metadata['forecast_kernel_id'], 'baseline_forecast_kernel');
      expect(result.metadata['forecast_kernel_execution_mode'], 'baseline');
      expect(result.metadata['truth_scope'], isA<Map<String, dynamic>>());
      expect(
        (result.metadata['ai2ai_runtime_state_summary']
            as Map)['learning_applied_count'],
        1,
      );
    });
  });
}
