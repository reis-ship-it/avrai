import 'dart:convert';

import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai/core/services/ai_infrastructure/model_safety_supervisor.dart';
import 'package:avrai/core/services/ai_infrastructure/model_version_manager.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/recommendations/agent_happiness_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  setUp(() {
    MockGetStorage.reset();
  });

  KernelGovernanceGate buildEnforcedGateMissingKernels() {
    return KernelGovernanceGate(
      defaultMode: KernelGovernanceMode.enforce,
      snapshotLoader: () async => const UrkKernelRegistrySnapshot(
        version: 'v-test',
        updatedAt: '2026-02-28',
        kernels: <UrkKernelRecord>[],
        byProng: <String, int>{},
        byMode: <String, int>{},
        byImpactTier: <String, int>{},
      ),
    );
  }

  test('ModelVersionManager blocks switch in enforce mode when kernels missing',
      () async {
    final gate = buildEnforcedGateMissingKernels();
    final manager = ModelVersionManager(kernelGovernanceGate: gate);

    final baseline = ModelVersionRegistry.activeCallingScoreVersion;
    final targetVersion = 'v9.7-governance-blocked';
    ModelVersionRegistry.registerCallingScoreVersion(
      ModelVersionRegistry.getCallingScoreVersion('v1.0-hybrid')!.copyWith(
        version: targetVersion,
        modelPath:
            'assets/models/optimized/calling_score_model_v1_1_batch_128.onnx',
      ),
    );

    final switched = await manager.switchCallingScoreVersion(targetVersion);
    expect(switched, isFalse);
    expect(ModelVersionRegistry.activeCallingScoreVersion, baseline);
  });

  test('ModelSafetySupervisor blocks rollout candidate start in enforce mode',
      () async {
    final storage = MockGetStorage.getInstance(boxName: 'prefs');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    final gate = buildEnforcedGateMissingKernels();

    final supervisor = ModelSafetySupervisor(
      prefs: prefs,
      kernelGovernanceGate: gate,
    );
    await supervisor.startRolloutCandidate(
      modelType: 'calling_score',
      fromVersion: 'v1.0-hybrid',
      toVersion: 'v9.9-test',
    );

    expect(prefs.getString('model_rollout_candidate_calling_score_v1'), isNull);
  });

  test('AgentHappinessService blocks signal ingest in enforce mode', () async {
    final storage = MockGetStorage.getInstance(boxName: 'prefs2');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    final gate = buildEnforcedGateMissingKernels();

    final service = AgentHappinessService(
      prefs: prefs,
      kernelGovernanceGate: gate,
    );
    await service.recordSignal(source: 'chat_rating', score: 0.91);

    final stored = prefs.getStringList('agent_happiness_signals_v1');
    expect(stored, isNull);
  });

  test('AgentHappinessService stores governance ids with each signal',
      () async {
    final storage = MockGetStorage.getInstance(boxName: 'prefs3');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    final service = AgentHappinessService(prefs: prefs);

    await service.recordSignal(source: 'chat_rating', score: 0.82);

    final stored = prefs.getStringList('agent_happiness_signals_v1');
    expect(stored, isNotNull);
    final first = jsonDecode(stored!.first) as Map<String, dynamic>;
    expect(first['governance_decision_id'], isNotNull);
    expect(
        (first['governance_decision_id'] as String).startsWith('kgd_'), isTrue);
    expect(first['governance_correlation_id'], isNotNull);
  });
}
