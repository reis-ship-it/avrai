import 'dart:developer' as developer;

import 'package:avrai/core/ai2ai/connection_orchestrator.dart'
    show VibeConnectionOrchestrator;

enum ConsolidationFederatedGradientSyncStatus {
  synced,
  skipped,
}

class ConsolidationFederatedGradientSyncResult {
  final ConsolidationFederatedGradientSyncStatus status;

  const ConsolidationFederatedGradientSyncResult({
    required this.status,
  });
}

/// Phase 1.1C.7: push local gradient deltas after overnight training.
class ConsolidationFederatedGradientSyncService {
  static const String _logName = 'ConsolidationFederatedGradientSyncService';

  const ConsolidationFederatedGradientSyncService({
    VibeConnectionOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator;

  final VibeConnectionOrchestrator? _orchestrator;

  Future<ConsolidationFederatedGradientSyncResult>
      syncAfterLocalTraining() async {
    final orchestrator = _orchestrator;
    if (orchestrator == null) {
      developer.log(
        'Skipping federated gradient sync: orchestrator unavailable.',
        name: _logName,
      );
      return const ConsolidationFederatedGradientSyncResult(
        status: ConsolidationFederatedGradientSyncStatus.skipped,
      );
    }

    await orchestrator.syncFederatedCloudQueue();
    developer.log(
      'Triggered federated gradient sync after local training.',
      name: _logName,
    );
    return const ConsolidationFederatedGradientSyncResult(
      status: ConsolidationFederatedGradientSyncStatus.synced,
    );
  }
}
