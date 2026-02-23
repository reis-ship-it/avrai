import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:avrai/core/ai/memory/consolidation/consolidation_federated_gradient_sync_service.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart'
    show VibeConnectionOrchestrator;

class _MockVibeConnectionOrchestrator extends Mock
    implements VibeConnectionOrchestrator {}

void main() {
  group('ConsolidationFederatedGradientSyncService', () {
    test('syncs federated cloud queue when orchestrator is available',
        () async {
      final orchestrator = _MockVibeConnectionOrchestrator();
      when(() => orchestrator.syncFederatedCloudQueue())
          .thenAnswer((_) async {});
      final service = ConsolidationFederatedGradientSyncService(
        orchestrator: orchestrator,
      );

      final result = await service.syncAfterLocalTraining();
      expect(result.status, ConsolidationFederatedGradientSyncStatus.synced);
      verify(() => orchestrator.syncFederatedCloudQueue()).called(1);
    });

    test('returns skipped when orchestrator is not available', () async {
      final service = ConsolidationFederatedGradientSyncService();
      final result = await service.syncAfterLocalTraining();
      expect(result.status, ConsolidationFederatedGradientSyncStatus.skipped);
    });
  });
}
