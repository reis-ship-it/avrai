import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/event_queue.dart';
import 'package:avrai_runtime_os/ai2ai/cloud_intelligence_sync.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/services/network/network_circuit_breaker.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_notification_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_connectivity_listener.dart';
import 'package:get_it/get_it.dart';

/// Coordinates all backup sync steps when the device comes back online.
///
/// Subscribes to [EnhancedConnectivityService.onBackOnline] and runs sync
/// steps in order. One step failing does not stop the rest. Each step is
/// wrapped in a per-step circuit breaker so a flaky backend does not block others.
class BackupSyncCoordinator {
  static const String _logName = 'BackupSyncCoordinator';

  final EnhancedConnectivityService _connectivityService;
  StreamSubscription<void>? _backOnlineSub;
  bool _started = false;

  final NetworkCircuitBreaker _cloudIntelligenceBreaker =
      NetworkCircuitBreaker();
  final NetworkCircuitBreaker _quantumBreaker = NetworkCircuitBreaker();
  final NetworkCircuitBreaker _federatedBreaker = NetworkCircuitBreaker();
  final NetworkCircuitBreaker _eventQueueBreaker = NetworkCircuitBreaker();
  final NetworkCircuitBreaker _reservationNotificationBreaker =
      NetworkCircuitBreaker();

  BackupSyncCoordinator({
    required EnhancedConnectivityService connectivityService,
  }) : _connectivityService = connectivityService;

  /// Start listening for "back online" and run sync when it fires.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    developer.log('Starting BackupSyncCoordinator', name: _logName);

    _backOnlineSub = _connectivityService.onBackOnline.listen((_) {
      unawaited(runSync());
    });

    final hasInternet = await _connectivityService.hasInternetAccess();
    if (hasInternet) {
      unawaited(runSync());
    }
  }

  /// Stop listening. Sync steps are no longer triggered by connectivity.
  void stop() {
    _backOnlineSub?.cancel();
    _backOnlineSub = null;
    _started = false;
    developer.log('Stopped BackupSyncCoordinator', name: _logName);
  }

  /// Run all backup sync steps in order. Catches per-step errors so one
  /// failure does not block the rest.
  Future<void> runSync() async {
    developer.log('Running backup sync', name: _logName);
    final sl = GetIt.instance;

    if (sl.isRegistered<CloudIntelligenceSync>()) {
      try {
        await _cloudIntelligenceBreaker.run(
          () => sl<CloudIntelligenceSync>().syncQueue(),
        );
      } on NetworkCircuitBreakerOpenException catch (e) {
        developer.log('CloudIntelligenceSync circuit open: $e', name: _logName);
      } catch (e, st) {
        developer.log(
          'CloudIntelligenceSync.syncQueue failed',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    if (sl.isRegistered<QuantumMatchingConnectivityListener>()) {
      try {
        await _quantumBreaker.run(
          () => sl<QuantumMatchingConnectivityListener>().syncWhenOnline(),
        );
      } on NetworkCircuitBreakerOpenException catch (e) {
        developer.log('Quantum sync circuit open: $e', name: _logName);
      } catch (e, st) {
        developer.log(
          'QuantumMatchingConnectivityListener.syncWhenOnline failed',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    if (sl.isRegistered<VibeConnectionOrchestrator>()) {
      try {
        await _federatedBreaker.run(
          () => sl<VibeConnectionOrchestrator>().syncFederatedCloudQueue(),
        );
      } on NetworkCircuitBreakerOpenException catch (e) {
        developer.log('Federated sync circuit open: $e', name: _logName);
      } catch (e, st) {
        developer.log(
          'VibeConnectionOrchestrator.syncFederatedCloudQueue failed',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    if (sl.isRegistered<EventQueue>()) {
      try {
        await _eventQueueBreaker.run(
          () => sl<EventQueue>().tryProcessQueue(),
        );
      } on NetworkCircuitBreakerOpenException catch (e) {
        developer.log('EventQueue circuit open: $e', name: _logName);
      } catch (e, st) {
        developer.log(
          'EventQueue.tryProcessQueue failed',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    if (sl.isRegistered<ReservationNotificationService>()) {
      try {
        await _reservationNotificationBreaker.run(
          () => sl<ReservationNotificationService>().syncQueuedNotifications(),
        );
      } on NetworkCircuitBreakerOpenException catch (e) {
        developer.log(
          'ReservationNotification circuit open: $e',
          name: _logName,
        );
      } catch (e, st) {
        developer.log(
          'ReservationNotificationService.syncQueuedNotifications failed',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    developer.log('Backup sync completed', name: _logName);
  }
}
