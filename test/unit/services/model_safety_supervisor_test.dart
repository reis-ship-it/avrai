import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/services/recommendations/agent_happiness_service.dart';
import 'package:avrai/core/services/ai_infrastructure/model_safety_supervisor.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  setUp(() {
    MockGetStorage.reset();
  });

  test('rolls back a model version when happiness drops materially', () async {
    final storage = MockGetStorage.getInstance(boxName: 'prefs');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

    // Seed baseline happiness history (20 samples at ~0.9).
    final svc = AgentHappinessService(prefs: prefs);
    for (int i = 0; i < 20; i++) {
      await svc.recordSignal(source: 'chat_rating', score: 0.9);
    }

    // Switch to a new version (candidate).
    expect(
        ModelVersionRegistry.activeCallingScoreVersion, equals('v1.0-hybrid'));
    ModelVersionRegistry.registerCallingScoreVersion(
      ModelVersionRegistry.getCallingScoreVersion('v1.0-hybrid')!.copyWith(
        version: 'v9.9-test',
        modelPath:
            'assets/models/optimized/calling_score_model_v1_1_batch_128.onnx',
      ),
    );
    expect(
        ModelVersionRegistry.setActiveCallingScoreVersion('v9.9-test'), isTrue);

    final supervisor = ModelSafetySupervisor(prefs: prefs);
    await supervisor.startRolloutCandidate(
      modelType: 'calling_score',
      fromVersion: 'v1.0-hybrid',
      toVersion: 'v9.9-test',
    );

    // Add post-switch low scores (>=12 samples at ~0.6) → should rollback.
    for (int i = 0; i < 12; i++) {
      // Directly write a signal entry with a timestamp "now" so it counts post.
      await svc.recordSignal(source: 'chat_rating', score: 0.6);
    }

    // Supervisor evaluation is called by recordSignal, but call again to be safe.
    await supervisor.evaluateAndRollbackIfNeeded();

    expect(
        ModelVersionRegistry.activeCallingScoreVersion, equals('v1.0-hybrid'));

    final events = supervisor.getRollbackEvents();
    expect(events, isNotEmpty);
    expect(events.first['model_type'], equals('calling_score'));
  });

  test('does not rollback when there are too few baseline samples', () async {
    final storage = MockGetStorage.getInstance(boxName: 'prefs2');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

    final svc = AgentHappinessService(prefs: prefs);

    // Baseline is sparse (<8) so we should not rollback.
    for (int i = 0; i < 5; i++) {
      await svc.recordSignal(source: 'chat_rating', score: 0.9);
    }

    ModelVersionRegistry.registerCallingScoreVersion(
      ModelVersionRegistry.getCallingScoreVersion('v1.0-hybrid')!.copyWith(
        version: 'v9.8-test',
        modelPath:
            'assets/models/optimized/calling_score_model_v1_1_batch_128.onnx',
      ),
    );
    ModelVersionRegistry.setActiveCallingScoreVersion('v9.8-test');

    final supervisor = ModelSafetySupervisor(prefs: prefs);
    await supervisor.startRolloutCandidate(
      modelType: 'calling_score',
      fromVersion: 'v1.0-hybrid',
      toVersion: 'v9.8-test',
    );

    for (int i = 0; i < 12; i++) {
      await svc.recordSignal(source: 'chat_rating', score: 0.1);
    }

    await supervisor.evaluateAndRollbackIfNeeded();

    // Still on candidate since baseline too small.
    expect(ModelVersionRegistry.activeCallingScoreVersion, equals('v9.8-test'));

    // Candidate entry should still exist (not removed).
    final raw = prefs.getString('model_rollout_candidate_calling_score_v1');
    expect(raw, isNotNull);
    expect((jsonDecode(raw!) as Map<String, dynamic>)['to_version'],
        equals('v9.8-test'));
  });
}
