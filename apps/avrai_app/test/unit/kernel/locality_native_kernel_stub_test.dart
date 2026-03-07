import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeKernelStub', () {
    test('round-trips sync and async locality syscalls in process', () async {
      final delegate = _FakeLocalityKernelContract();
      final transport = InProcessLocalitySyscallTransport(delegate: delegate);
      final stub = LocalityNativeKernelStub(transport: transport);

      final resolvedPoint = await stub.resolvePoint(
        LocalityPointQuery(
          latitude: 33.5186,
          longitude: -86.8104,
          occurredAtUtc: DateTime.utc(2026, 3, 6),
          audience: LocalityProjectionAudience.admin,
          includePrediction: true,
        ),
      );
      final projection = stub.project(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: delegate.state,
          includePrediction: true,
        ),
      );
      final report = await stub.evaluateZeroLocalityReadiness(
        cityProfile: 'birmingham_alabama',
        modelFamily: 'reality_kernel',
        localityCount: 12,
      );
      final snapshot = stub.snapshot('agent-1');
      final receipt = await stub.observe(
        LocalityObservation(
          userId: 'user-1',
          agentId: 'agent-1',
          type: LocalityObservationType.visitComplete,
          key: delegate.key,
          occurredAtUtc: DateTime.utc(2026, 3, 6),
          source: 'test',
        ),
      );

      expect(resolvedPoint.projection.primaryLabel, 'Avondale');
      expect(projection.metadata['predictiveTrend'], 'stable');
      expect(report.passes, isTrue);
      expect(snapshot, isNotNull);
      expect(snapshot!.state.activeToken.id, 'gh7:dr5ru7k');
      expect(receipt.state.activeToken.id, 'gh7:dr5ru7k');
    });

    test('round-trips observeVisit payloads through the syscall bridge',
        () async {
      final delegate = _FakeLocalityKernelContract();
      final transport = InProcessLocalitySyscallTransport(delegate: delegate);
      final stub = LocalityNativeKernelStub(transport: transport);

      final visit = Visit(
        id: 'visit-1',
        userId: 'user-1',
        locationId: 'spot-1',
        checkInTime: DateTime.utc(2026, 3, 6, 18),
        createdAt: DateTime.utc(2026, 3, 6, 18),
        updatedAt: DateTime.utc(2026, 3, 6, 19),
        metadata: const <String, dynamic>{
          'latitude': 33.5186,
          'longitude': -86.8104,
        },
      );

      final receipt = await stub.observeVisit(
        userId: 'user-1',
        visit: visit,
        source: 'test',
      );

      expect(receipt, isNotNull);
      expect(receipt!.cloudUpdated, isTrue);
      expect(receipt.state.topAlias, 'Avondale');
    });
  });
}

class _FakeLocalityKernelContract implements LocalityKernelContract {
  final LocalityAgentKeyV1 key = const LocalityAgentKeyV1(
    geohashPrefix: 'dr5ru7k',
    precision: 7,
    cityCode: 'birmingham_alabama',
  );

  final LocalityState state = LocalityState(
    activeToken: const LocalityToken(
      kind: LocalityTokenKind.geohashCell,
      id: 'gh7:dr5ru7k',
      alias: 'Avondale',
    ),
    embedding: const <double>[
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.4,
      0.3,
      0.5,
      0.6,
      0.4,
      0.5,
    ],
    confidence: 0.82,
    boundaryTension: 0.28,
    reliabilityTier: LocalityReliabilityTier.established,
    freshness: DateTime.utc(2026, 3, 6),
    evidenceCount: 11,
    evolutionRate: 0.04,
    advisoryStatus: LocalityAdvisoryStatus.inactive,
    sourceMix: LocalitySourceMix(
      local: 0.5,
      mesh: 0.1,
      federated: 0.3,
      geometry: 0.1,
      syntheticPrior: 0.0,
    ),
    topAlias: 'Avondale',
  );

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocalityReadiness({
    required String cityProfile,
    String modelFamily = 'default',
    int localityCount = 12,
  }) async {
    return const LocalityZeroReliabilityReport(
      evaluationId: 'eval-1',
      metrics: <LocalityEvaluationMetric>[
        LocalityEvaluationMetric(
          name: 'cold_start_plausibility',
          value: 0.81,
          target: 0.7,
        ),
      ],
      calibration: <String, dynamic>{'cityProfile': 'birmingham_alabama'},
    );
  }

  @override
  Future<LocalityUpdateReceipt> observe(LocalityObservation observation) async {
    return LocalityUpdateReceipt(
      state: state,
      cloudUpdated: true,
      meshForwarded:
          observation.type == LocalityObservationType.meshLocalityUpdate,
    );
  }

  @override
  Future<bool> observeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    return true;
  }

  @override
  Future<LocalityUpdateReceipt?> observeVisit({
    required String userId,
    required Visit visit,
    required String source,
  }) async {
    return LocalityUpdateReceipt(
      state: state,
      cloudUpdated: true,
      meshForwarded: true,
    );
  }

  @override
  LocalityProjection project(LocalityProjectionRequest request) {
    return LocalityProjection(
      primaryLabel: request.state.topAlias ?? 'Avondale',
      confidenceBucket: 'high',
      nearBoundary: request.state.boundaryTension > 0.5,
      activeToken: request.state.activeToken,
      metadata: const <String, dynamic>{
        'predictiveTrend': 'stable',
        'reliabilityTier': 'established',
        'advisoryStatus': 'inactive',
      },
    );
  }

  @override
  Future<LocalityRecoveryResult> recover(
      LocalityRecoveryRequest request) async {
    return LocalityRecoveryResult(
      state: state,
      recoveredFromSnapshot: true,
    );
  }

  @override
  Future<LocalityPointResolution> resolvePoint(
      LocalityPointQuery request) async {
    return LocalityPointResolution(
      state: state,
      projection: project(
        LocalityProjectionRequest(
          audience: request.audience,
          state: state,
          includePrediction: request.includePrediction,
          includeGeometry: request.includeGeometry,
          includeAttribution: request.includeAttribution,
        ),
      ),
      cityCode: 'birmingham_alabama',
      localityCode: 'avondale',
      displayName: 'Avondale',
    );
  }

  @override
  Future<LocalityState> resolveWhere(LocalityPerceptionInput input) async =>
      state;

  @override
  Future<LocalityState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'onboarding_seed',
  }) async {
    return state;
  }

  @override
  LocalityKernelSnapshot? snapshot(String agentId) {
    return LocalityKernelSnapshot(
      agentId: agentId,
      state: state,
      savedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<LocalitySyncResult> sync(LocalitySyncRequest request) async {
    return const LocalitySyncResult(
      synced: true,
      message: 'ok',
    );
  }
}
