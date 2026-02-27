import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class FederatedCloudSyncStartResult {
  const FederatedCloudSyncStartResult({
    required this.timer,
    required this.subscription,
  });

  final Timer? timer;
  final StreamSubscription<List<ConnectivityResult>>? subscription;
}

class FederatedCloudSyncStartLane {
  const FederatedCloudSyncStartLane._();

  static Future<FederatedCloudSyncStartResult> start({
    required bool isTestBinding,
    required Connectivity connectivity,
    required Future<void> Function() syncFederatedCloudQueue,
    required Timer? existingTimer,
    required StreamSubscription<List<ConnectivityResult>>? existingSubscription,
    required AppLogger logger,
    required String logName,
  }) async {
    if (isTestBinding) {
      logger.debug(
        'Test binding detected; skipping federated cloud sync timers',
        tag: logName,
      );
      return const FederatedCloudSyncStartResult(
        timer: null,
        subscription: null,
      );
    }

    existingTimer?.cancel();
    unawaited(existingSubscription?.cancel());

    final subscription =
        connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) return;
      unawaited(syncFederatedCloudQueue());
    });

    final timer = Timer.periodic(const Duration(minutes: 10), (_) async {
      unawaited(syncFederatedCloudQueue());
    });

    return FederatedCloudSyncStartResult(
      timer: timer,
      subscription: subscription,
    );
  }
}
