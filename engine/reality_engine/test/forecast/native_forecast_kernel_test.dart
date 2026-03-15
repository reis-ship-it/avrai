import 'package:avrai_core/avra_core.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_native_priority.dart';
import 'package:reality_engine/forecast/forecast_native_support.dart';
import 'package:reality_engine/forecast/native_forecast_kernel.dart';
import 'package:test/test.dart';

class _FakeForecastNativeBridge extends ForecastKernelJsonNativeBridge {
  _FakeForecastNativeBridge(this._payload, {this.available = true});

  final Map<String, dynamic> _payload;
  final bool available;
  bool initialized = false;

  @override
  bool get isAvailable => available;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    expect(syscall, 'forecast');
    return <String, dynamic>{
      'ok': true,
      'handled': true,
      'payload': _payload,
    };
  }
}

void main() {
  group('NativeForecastKernel', () {
    const provenance = TemporalProvenance(
      authority: TemporalAuthority.historicalImport,
      source: 'bham_registry',
    );
    const uncertainty = TemporalUncertainty(
      window: Duration(minutes: 20),
      confidence: 0.8,
    );

    TemporalInstant buildInstant() {
      return TemporalInstant(
        referenceTime: DateTime.utc(2025, 4, 1, 18),
        civilTime: DateTime.utc(2025, 4, 1, 13),
        timezoneId: 'America/Chicago',
        provenance: provenance,
        uncertainty: uncertainty,
      );
    }

    ForecastKernelRequest buildRequest() {
      final instant = buildInstant();
      return ForecastKernelRequest(
        forecastId: 'forecast-1',
        subjectId: 'venue:saturn',
        replayEnvelope: ReplayTemporalEnvelope(
          envelopeId: 'env-1',
          subjectId: 'venue:saturn',
          observedAt: instant,
          provenance: provenance,
          uncertainty: uncertainty,
          temporalAuthoritySource: 'when_kernel',
        ),
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2025,
          replayYear: 2025,
          branchId: 'branch-bham',
          runId: 'run-1',
          seed: 42,
          divergencePolicy: 'none',
        ),
        targetWindow: TemporalInterval(start: instant, end: instant),
        evidenceWindow: TemporalInterval(start: instant, end: instant),
      );
    }

    test('uses native payload when available', () async {
      final payload = <String, dynamic>{
        'claim': <String, dynamic>{
          'claimId': 'forecast-1',
          'forecastCreatedAt': '2025-04-01T18:00:00.000Z',
          'targetWindow': buildRequest().targetWindow.toJson(),
          'evidenceWindow': buildRequest().evidenceWindow.toJson(),
          'confidence': 0.83,
          'modelVersion': 'rust_forecast_kernel_v1',
          'provenance': const <String, dynamic>{
            'authority': 'forecast',
            'source': 'reality_engine.rust_forecast_kernel',
          },
          'laterOutcomeRef': 'venue:saturn',
        },
        'predicted_outcome': 'high-confidence-positive',
        'confidence': 0.83,
        'forecast_family_id': 'native_test_family',
        'outcome_probability': 0.86,
        'outcome_kind': 'binary',
        'raw_predictive_distribution': <String, dynamic>{
          'outcomeKind': 'binary',
          'discreteProbabilities': <String, double>{
            'positive': 0.86,
            'negative': 0.14,
          },
          'mean': 0.86,
          'variance': 0.1204,
          'componentId': 'rust_forecast_kernel',
        },
        'branch_id': 'branch-bham',
        'run_id': 'run-1',
        'explanation': 'native forecast',
        'contradiction_hooks': const <String>['locality_agent_override'],
        'metadata': const <String, dynamic>{'replay_year': 2025},
      };
      final kernel = NativeForecastKernel(
        nativeBridge: _FakeForecastNativeBridge(payload),
        fallback: const _FailingForecastKernel(),
      );

      final result = await kernel.forecast(buildRequest());
      expect(result.claim.modelVersion, 'rust_forecast_kernel_v1');
      expect(result.predictedOutcome, 'high-confidence-positive');
      expect(result.outcomeProbability, 0.86);
      expect(result.rawPredictiveDistribution?.topOutcome, 'positive');
      expect(result.metadata['replay_year'], 2025);
      expect(result.metadata['forecast_kernel_id'], 'native_forecast_kernel');
      expect(result.metadata['forecast_kernel_execution_mode'], 'native');
    });

    test('falls back when native is unavailable and policy allows it',
        () async {
      final kernel = NativeForecastKernel(
        nativeBridge: _FakeForecastNativeBridge(
          const <String, dynamic>{},
          available: false,
        ),
        fallback: const _EchoForecastKernel(),
        policy: const ForecastNativeExecutionPolicy(requireNative: false),
      );

      final result = await kernel.forecast(buildRequest());
      expect(result.claim.modelVersion, 'echo');
      expect(result.predictedOutcome, 'fallback');
      expect(result.metadata['forecast_kernel_execution_mode'], 'fallback');
      expect(
          result.metadata['forecast_kernel_wrapper'], 'native_forecast_kernel');
    });
  });
}

class _FailingForecastKernel implements ForecastKernel {
  const _FailingForecastKernel();

  @override
  Future<ForecastKernelResult> forecast(ForecastKernelRequest request) {
    throw StateError('fallback should not be used');
  }
}

class _EchoForecastKernel implements ForecastKernel {
  const _EchoForecastKernel();

  @override
  Future<ForecastKernelResult> forecast(ForecastKernelRequest request) async {
    return ForecastKernelResult(
      claim: ForecastTemporalClaim(
        claimId: request.forecastId,
        forecastCreatedAt: request.replayEnvelope.observedAt.referenceTime,
        targetWindow: request.targetWindow,
        evidenceWindow: request.evidenceWindow,
        confidence: 0.5,
        modelVersion: 'echo',
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.forecast,
          source: 'test.echo',
        ),
      ),
      predictedOutcome: 'fallback',
      confidence: 0.5,
      branchId: request.runContext.branchId,
      runId: request.runContext.runId,
      explanation: 'fallback',
      metadata: const <String, dynamic>{
        'forecast_kernel_id': 'echo_forecast_kernel',
      },
    );
  }
}
