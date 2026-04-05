// Quantum Matching Connectivity Listener
//
// Monitors connectivity and syncs offline matches when device comes back online
// Part of Phase 19 Section 19.16: AI2AI Integration
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:async';

import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

/// Service that monitors connectivity and syncs offline matches when device comes back online
///
/// **Purpose:**
/// - Listens to connectivity changes
/// - Syncs offline matches when device comes back online
/// - Handles user ID retrieval for sync operations
///
/// **Phase 19.16 Integration:**
/// - Automatically syncs offline matches when connectivity is restored
class QuantumMatchingConnectivityListener {
  static const String _logName = 'QuantumMatchingConnectivityListener';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final EnhancedConnectivityService _connectivityService;
  final QuantumMatchingAILearningService? _aiLearningService;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isInitialized = false;

  QuantumMatchingConnectivityListener({
    required EnhancedConnectivityService connectivityService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _connectivityService = connectivityService,
        _aiLearningService = aiLearningService;

  /// Start monitoring connectivity
  Future<void> start() async {
    if (_isInitialized) return;

    _logger.info('Starting quantum matching connectivity listener',
        tag: _logName);

    // Check initial connectivity
    final initialConnectivity = await _connectivityService.hasInternetAccess();
    _wasOffline = !initialConnectivity;

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivityService.internetAccessStream().listen(
      (isOnline) {
        _handleConnectivityChange(isOnline);
      },
      onError: (error) {
        _logger.warn('Connectivity stream error: $error', tag: _logName);
      },
    );

    _isInitialized = true;
  }

  /// Stop monitoring connectivity
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    _logger.info('Stopped quantum matching connectivity listener',
        tag: _logName);
  }

  /// Handle connectivity change
  Future<void> _handleConnectivityChange(bool isOnline) async {
    try {
      // If we were offline and now online, sync offline matches
      if (_wasOffline && isOnline) {
        _logger.info('Device came back online, syncing offline matches',
            tag: _logName);
        await _syncOfflineMatches();
      }

      _wasOffline = !isOnline;
    } catch (e, stackTrace) {
      _logger.error(
        'Error handling connectivity change: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }

  /// Public API for [BackupSyncCoordinator] – syncs offline matches.
  Future<void> syncWhenOnline() => _syncOfflineMatches();

  /// Sync offline matches for all users
  ///
  /// **Note:** This is a simplified implementation. In production, you might want to:
  /// - Track which users have offline matches
  /// - Sync per-user
  /// - Handle user authentication state
  Future<void> _syncOfflineMatches() async {
    if (_aiLearningService == null) {
      _logger.debug('AI learning service not available, skipping sync',
          tag: _logName);
      return;
    }

    try {
      // Get current user ID from Supabase (if available)
      // This is a simplified approach - in production, you might want to track
      // which users have offline matches and sync per-user
      final sl = GetIt.instance;
      if (sl.isRegistered<SupabaseService>()) {
        final supabaseService = sl<SupabaseService>();
        if (supabaseService.isAvailable) {
          final client = supabaseService.client;
          final currentUser = client.auth.currentUser;
          if (currentUser != null) {
            await _aiLearningService.syncOfflineMatches(currentUser.id);
            _logger.info('Synced offline matches for user: ${currentUser.id}',
                tag: _logName);
          } else {
            _logger.debug('No authenticated user, skipping offline match sync',
                tag: _logName);
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error syncing offline matches: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
}
