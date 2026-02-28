import 'dart:async';

import 'package:avrai/core/ai2ai/resilience/federated_cloud_queue_lane.dart';
import 'package:avrai/core/ai2ai/resilience/federated_cloud_sync_lane.dart';
import 'package:avrai/core/ai2ai/resilience/federated_cloud_sync_start_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:connectivity_plus/connectivity_plus.dart';

class FederatedCloudOrchestrationLane {
  const FederatedCloudOrchestrationLane._();

  static bool isParticipationEnabled({
    required SharedPreferencesCompat prefs,
    required String prefsKeyFederatedLearningParticipation,
  }) {
    return prefs.getBool(prefsKeyFederatedLearningParticipation) ?? true;
  }

  static Future<FederatedCloudSyncStartResult> startSync({
    required bool isTestBinding,
    required Connectivity connectivity,
    required Future<void> Function() syncFederatedCloudQueue,
    required Timer? existingTimer,
    required StreamSubscription<List<ConnectivityResult>>? existingSubscription,
    required AppLogger logger,
    required String logName,
  }) {
    return FederatedCloudSyncStartLane.start(
      isTestBinding: isTestBinding,
      connectivity: connectivity,
      syncFederatedCloudQueue: syncFederatedCloudQueue,
      existingTimer: existingTimer,
      existingSubscription: existingSubscription,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> enqueueLearningInsightDelta({
    required bool federatedLearningParticipationEnabled,
    required SharedPreferencesCompat prefs,
    required String prefsKeyQueue,
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!federatedLearningParticipationEnabled) return;
    await FederatedCloudQueueLane.enqueueFromLearningInsightPayload(
      prefs: prefs,
      prefsKeyQueue: prefsKeyQueue,
      payload: payload,
      logger: logger,
      logName: logName,
    );
  }

  static Future<int> syncQueue({
    required bool federatedLearningParticipationEnabled,
    required int lastFederatedCloudSyncAttemptMs,
    required SharedPreferencesCompat prefs,
    required String prefsKeyQueue,
    required AppLogger logger,
    required String logName,
  }) {
    return FederatedCloudSyncLane.run(
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      lastFederatedCloudSyncAttemptMs: lastFederatedCloudSyncAttemptMs,
      prefs: prefs,
      prefsKeyQueue: prefsKeyQueue,
      logger: logger,
      logName: logName,
    );
  }
}
