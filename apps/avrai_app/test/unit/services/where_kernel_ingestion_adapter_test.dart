import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/kernel/locality/legacy/where_kernel_ingestion_adapter.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('WhereKernelIngestionAdapter', () {
    late SharedPreferencesCompat prefs;
    late UrkGovernedRuntimeRegistryService registry;
    late WhereKernelIngestionAdapter service;

    setUp(() async {
      await cleanupTestStorage();
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'where_kernel_ingestion_runtime_registry_test',
        ),
      );
      registry = UrkGovernedRuntimeRegistryService(prefs: prefs);
      service = WhereKernelIngestionAdapter(
        kernel: _FakeWhereKernelContract(),
        governedRuntimeRegistryService: registry,
      );
    });

    test('registers locality runtime bindings when homebase is seeded',
        () async {
      await service.seedHomebase(
        userId: 'user-1',
        agentId: 'agent-1',
        latitude: 41.8781,
        longitude: -87.6298,
        cityCode: 'chicago_il',
      );

      final bindings = await registry.listBindings(
        limit: 20,
        stratum: GovernanceStratum.locality,
      );
      final expectedRuntimeIds =
          UrkGovernedRuntimeRegistryService.canonicalLocalityRuntimeIds(
        userId: 'user-1',
        agentId: 'agent-1',
        localityTokenId: 'gh7:dp3wjzt',
        cityCode: 'chicago_il',
        topAlias: 'Loop',
      );

      expect(
        bindings.map((binding) => binding.runtimeId).toSet(),
        expectedRuntimeIds.toSet(),
      );
      expect(
        bindings.every((binding) => binding.source == 'locality_homebase_seed'),
        isTrue,
      );
    });
  });
}

class _FakeWhereKernelContract extends WhereKernelContract {
  final WhereState _state = WhereState(
    activeTokenId: 'gh7:dp3wjzt',
    activeTokenAlias: 'Loop',
    activeTokenKind: LocalityTokenKind.geohashCell.name,
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
    reliabilityTier: LocalityReliabilityTier.established.name,
    freshness: DateTime.utc(2026, 3, 6),
    evidenceCount: 11,
    evolutionRate: 0.04,
    advisoryStatus: LocalityAdvisoryStatus.inactive.name,
    sourceMix: const <String, double>{
      'local': 0.5,
      'mesh': 0.1,
      'federated': 0.3,
      'geometry': 0.1,
      'synthetic_prior': 0.0,
    },
    topAlias: 'Loop',
  );

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'onboarding_seed',
  }) async {
    return _state;
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'default',
    int localityCount = 12,
  }) async {
    return const LocalityZeroReliabilityReport(
      evaluationId: 'eval-1',
      metrics: <LocalityEvaluationMetric>[],
      calibration: <String, dynamic>{},
    );
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    return true;
  }

  @override
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return WhereProjection(
      primaryLabel: request.state.topAlias ?? 'Loop',
      confidenceBucket: 'high',
      nearBoundary: false,
      activeTokenId: request.state.activeTokenId,
      activeTokenKind: request.state.activeTokenKind,
      activeTokenAlias: request.state.activeTokenAlias,
      metadata: const <String, dynamic>{},
    );
  }

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) async {
    return WhereRecoveryResult(
      state: _state,
      recoveredFromSnapshot: true,
    );
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) async {
    return WherePointResolution(
      state: _state,
      projection: WhereProjection(
        primaryLabel: 'Loop',
        confidenceBucket: 'high',
        nearBoundary: false,
        activeTokenId: _state.activeTokenId,
        activeTokenKind: _state.activeTokenKind,
        activeTokenAlias: _state.activeTokenAlias,
      ),
      localityCode: 'loop_chicago',
      cityCode: 'chicago_il',
      displayName: 'Loop',
    );
  }

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) async {
    return _state;
  }

  @override
  WhereSnapshot? snapshot(String agentId) {
    return null;
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) async {
    return const WhereSyncResult(
      synced: true,
      message: 'ok',
    );
  }

  @override
  WhySnapshot explainWhy(WhereWhyRequest request) {
    return const WhySnapshot(
      goal: 'test',
      drivers: <WhySignal>[],
      inhibitors: <WhySignal>[],
      confidence: 0.0,
      rootCauseType: WhyRootCauseType.unknown,
      summary: 'test',
      counterfactuals: <WhyCounterfactual>[],
    );
  }
}
