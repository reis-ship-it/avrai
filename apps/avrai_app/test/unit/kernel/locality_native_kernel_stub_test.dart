import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show
        KernelAuthorityLevel,
        KernelDomain,
        KernelGovernanceProjection,
        KernelHealthReport,
        KernelHealthStatus,
        WhereRealityProjection;
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
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
      final reality = await stub.projectForRealityModel(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: delegate.state,
          includePrediction: true,
        ),
      );
      final governance = await stub.projectForGovernance(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: delegate.state,
          includePrediction: true,
        ),
      );
      final health = await stub.diagnoseWhere();

      expect(resolvedPoint.projection.primaryLabel, 'Avondale');
      expect(projection.metadata['predictiveTrend'], 'stable');
      expect(report.passes, isTrue);
      expect(snapshot, isNotNull);
      expect(snapshot!.state.activeToken.id, 'gh7:dr5ru7k');
      expect(receipt.state.activeToken.id, 'gh7:dr5ru7k');
      expect(reality.summary, contains('Avondale'));
      expect(reality.features['locality_contained_in_where'], isTrue);
      expect(governance.highlights, contains('locality_inside_where'));
      expect(health.nativeBacked, isTrue);
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
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

    test('round-trips explainWhy through the sync syscall bridge', () {
      final delegate = _FakeLocalityKernelContract();
      final transport = InProcessLocalitySyscallTransport(delegate: delegate);
      final stub = LocalityNativeKernelStub(transport: transport);

      final snapshot = stub.explainWhy(
        const WhyKernelRequest(
          action: 'recommend_park',
          outcome: 'rejected',
          coreSignals: <WhySignal>[
            WhySignal(label: 'outdoor_affinity', weight: 0.4),
          ],
          pheromoneSignals: <WhySignal>[
            WhySignal(label: 'social_fatigue', weight: -0.9),
          ],
        ),
      );

      expect(snapshot.rootCauseType, WhyRootCauseType.mixed);
      expect(snapshot.inhibitors.first.label, 'social_fatigue');
      expect(snapshot.inhibitors.first.source, 'pheromone');
      expect(snapshot.summary, contains('recommend_park'));
    });

    test('round-trips canonical explainWhy requests through the sync bridge',
        () {
      final delegate = _FakeLocalityKernelContract();
      final transport = InProcessLocalitySyscallTransport(delegate: delegate);
      final stub = LocalityNativeKernelStub(transport: transport);

      final snapshot = stub.explainWhy(
        const WhyKernelRequest(
          goal: 'explain_recommendation',
          queryKind: WhyQueryKind.recommendation,
          requestedPerspective: WhyRequestedPerspective.userSafe,
          evidenceBundle: WhyEvidenceBundle(
            entries: <WhyEvidence>[
              WhyEvidence(
                id: 'habit_memory',
                label: 'habit memory',
                weight: 0.8,
                polarity: WhyEvidencePolarity.positive,
                sourceKernel: WhyEvidenceSourceKernel.memory,
                sourceSubsystem: 'habit_store',
                durability: 'durable',
                confidence: 0.7,
              ),
              WhyEvidence(
                id: 'quiet_hours_policy',
                label: 'quiet hours policy',
                weight: 0.9,
                polarity: WhyEvidencePolarity.negative,
                sourceKernel: WhyEvidenceSourceKernel.policy,
                sourceSubsystem: 'policy',
                durability: 'durable',
                confidence: 0.92,
              ),
            ],
          ),
        ),
      );

      expect(snapshot.queryKind, WhyQueryKind.recommendation);
      expect(snapshot.schemaVersion, greaterThanOrEqualTo(2));
      expect(snapshot.governanceEnvelope.redacted, isTrue);
      expect(snapshot.drivers.first.evidenceId, 'habit_memory');
      expect(snapshot.inhibitors.first.evidenceId, 'quiet_hours_policy');
    });
  });
}

class _FakeLocalityKernelContract implements LocalityKernelFallbackSurface {
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
  Future<WhereRealityProjection> projectForRealityModel(
    LocalityProjectionRequest request,
  ) async {
    return const WhereRealityProjection(
      summary: 'Spatial truth for Avondale',
      confidence: 0.82,
      features: <String, dynamic>{
        'confidence_bucket': 'high',
        'near_boundary': false,
        'locality_contained_in_where': true,
      },
      payload: <String, dynamic>{
        'primaryLabel': 'Avondale',
      },
    );
  }

  @override
  Future<KernelGovernanceProjection> projectForGovernance(
    LocalityProjectionRequest request,
  ) async {
    return const KernelGovernanceProjection(
      domain: KernelDomain.where,
      summary: 'Governance spatial view for Avondale',
      confidence: 0.82,
      highlights: <String>['high', 'stable', 'locality_inside_where'],
      payload: <String, dynamic>{
        'primaryLabel': 'Avondale',
      },
    );
  }

  @override
  Future<KernelHealthReport> diagnoseWhere() async {
    return const KernelHealthReport(
      domain: KernelDomain.where,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary: 'where kernel exposes public spatial truth',
    );
  }

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

  @override
  WhySnapshot explainWhy(WhyKernelRequest request) {
    final normalizedEvidence = request.normalizedEvidence();
    final canonicalDrivers = normalizedEvidence
        .where((entry) => entry.polarity == WhyEvidencePolarity.positive)
        .map((entry) => entry.toSignal())
        .toList();
    final canonicalInhibitors = normalizedEvidence
        .where((entry) => entry.polarity == WhyEvidencePolarity.negative)
        .map((entry) => entry.toSignal())
        .toList();

    return WhySnapshot(
      goal: request.goal ?? 'optimize_${request.action ?? 'decision'}',
      queryKind: request.queryKind,
      drivers: canonicalDrivers.isNotEmpty
          ? canonicalDrivers
          : request.coreSignals
              .map(
                (signal) => WhySignal(
                  label: signal.label,
                  weight: signal.weight,
                  source: signal.source ?? 'core',
                  durable: signal.durable ?? true,
                ),
              )
              .toList(),
      inhibitors: canonicalInhibitors.isNotEmpty
          ? canonicalInhibitors
          : request.pheromoneSignals
              .where((signal) => signal.weight < 0)
              .map(
                (signal) => WhySignal(
                  label: signal.label,
                  weight: signal.weight.abs(),
                  source: signal.source ?? 'pheromone',
                  durable: signal.durable ?? false,
                ),
              )
              .toList(),
      confidence: 0.86,
      rootCauseType: request.coreSignals.isNotEmpty &&
              request.pheromoneSignals.isNotEmpty
          ? WhyRootCauseType.mixed
          : normalizedEvidence.any(
              (entry) => entry.sourceKernel == WhyEvidenceSourceKernel.policy,
            )
              ? WhyRootCauseType.policyDriven
              : WhyRootCauseType.unknown,
      summary:
          '${request.action ?? 'decision'} produced ${request.outcome ?? 'observed outcome'} because transient pheromone pressure outweighed durable preference.',
      governanceEnvelope: WhyGovernanceEnvelope(
        redacted:
            request.requestedPerspective == WhyRequestedPerspective.userSafe,
        redactionReason:
            request.requestedPerspective == WhyRequestedPerspective.userSafe
                ? 'user_safe_redaction'
                : null,
      ),
      schemaVersion: 2,
      counterfactuals: const <WhyCounterfactual>[
        WhyCounterfactual(
          condition: 'Reduce social_fatigue',
          expectedEffect: 'Outcome is more likely to improve',
          confidenceDelta: 0.25,
        ),
      ],
    );
  }
}
