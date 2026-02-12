import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:avrai/core/services/admin/permissions/admin_access_control.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/ml/predictive_analytics.dart';
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/core/services/admin/admin_god_mode_service.dart' as admin_models
    show
        AIDataSnapshot,
        ActiveAIAgentData,
        PredictionAction;

/// Cache entry for AI snapshot data
class _CachedAISnapshot {
  final admin_models.AIDataSnapshot snapshot;
  final DateTime timestamp;

  _CachedAISnapshot(this.snapshot, this.timestamp);
}

/// Admin System Monitoring Service
/// Handles system monitoring and real-time streams
/// Phase 1.6: Extracted from AdminGodModeService
class AdminSystemMonitoringService {
  static const String _logName = 'AdminSystemMonitoringService';
  static const Duration _aiSnapshotCacheTTL = Duration(seconds: 5);

  final AdminAccessControl _accessControl;
  final SupabaseService _supabaseService;
  final PredictiveAnalytics _predictiveAnalytics;

  // Cache for AI data snapshots (5 second TTL)
  final Map<String, _CachedAISnapshot> _aiSnapshotCache = {};

  AdminSystemMonitoringService({
    required AdminAccessControl accessControl,
    required SupabaseService supabaseService,
    required PredictiveAnalytics predictiveAnalytics,
  })  : _accessControl = accessControl,
        _supabaseService = supabaseService,
        _predictiveAnalytics = predictiveAnalytics;

  /// Safely get Supabase client, returns null if not available
  dynamic _getSupabaseClient() {
    if (!_supabaseService.isAvailable) {
      developer.log('Supabase not available', name: _logName);
      return null;
    }
    try {
      return _supabaseService.tryGetClient();
    } catch (e) {
      developer.log('Error getting Supabase client: $e', name: _logName);
      return null;
    }
  }

  /// Get real-time AI data stream
  Stream<admin_models.AIDataSnapshot> watchAIData(String aiSignature) {
    _accessControl.requireAuthorization();

    final controller = StreamController<admin_models.AIDataSnapshot>.broadcast();

    // Start periodic updates
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final snapshot = await _fetchAIDataSnapshot(aiSignature);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in AI data stream: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Fetch AI data snapshot
  Future<admin_models.AIDataSnapshot> _fetchAIDataSnapshot(
      String aiSignature) async {
    // Check cache first
    final cached = _aiSnapshotCache[aiSignature];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _aiSnapshotCacheTTL) {
      return cached.snapshot;
    }

    try {
      // Extract user ID from AI signature (reverse of _generateAISignature)
      // This is a simplified approach - in production, you'd have a proper mapping
      // For now, we'll search for users and match by signature
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get all active users and generate signatures to find match
      // This is inefficient but works for admin monitoring
      final usersResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .gte('updated_at',
              DateTime.now().subtract(const Duration(hours: 1)).toIso8601String())
          .limit(1000);

      final users = (usersResponse as List).cast<Map<String, dynamic>>();
      String? matchedUserId;

      // Find user with matching AI signature
      for (final userData in users) {
        final userId = userData['id'] as String;
        final generatedSignature = _generateAISignature(userId);
        if (generatedSignature == aiSignature) {
          matchedUserId = userId;
          break;
        }
      }

      if (matchedUserId == null) {
        // No matching user found, return minimal snapshot
        final snapshot = admin_models.AIDataSnapshot(
          aiSignature: aiSignature,
          isActive: false,
          connections: 0,
          data: {},
        );
        _aiSnapshotCache[aiSignature] =
            _CachedAISnapshot(snapshot, DateTime.now());
        return snapshot;
      }

      // Get user's connection count (simplified - would use ConnectionMonitor in production)
      final connectionsResponse = await client
          .from('user_connections')
          .select('id')
          .or('user_id_1.eq.$matchedUserId,user_id_2.eq.$matchedUserId');
      final connections = (connectionsResponse as List).length;

      // Build AI data snapshot
      final snapshot = admin_models.AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: true,
        connections: connections,
        data: {
          'user_id': matchedUserId,
          'ai_status': 'active',
          'last_active': DateTime.now().toIso8601String(),
        },
      );

      // Cache snapshot
      _aiSnapshotCache[aiSignature] =
          _CachedAISnapshot(snapshot, DateTime.now());

      // Clean up stale cache entries periodically
      _cleanupAISnapshotCache();

      return snapshot;
    } catch (e) {
      developer.log('Error fetching AI data snapshot: $e', name: _logName);
      // Return minimal snapshot on error
      return admin_models.AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: false,
        connections: 0,
        data: {},
      );
    }
  }

  /// Clean up stale cache entries
  void _cleanupAISnapshotCache() {
    final now = DateTime.now();
    _aiSnapshotCache.removeWhere((key, cached) =>
        now.difference(cached.timestamp) > _aiSnapshotCacheTTL);
  }

  /// Generate AI signature from user ID (deterministic but anonymized)
  String _generateAISignature(String userId) {
    // Create a deterministic hash from user ID
    // This ensures the same user always gets the same signature
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16); // Use first 16 chars
    return 'ai_$hash';
  }

  /// Get all active AI agents with location and predictions
  /// Privacy-preserving: Returns AI agent data with location and predicted actions
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<admin_models.ActiveAIAgentData>> getAllActiveAIAgents() async {
    _accessControl.requireAuthorization();

    try {
      developer.log('Fetching all active AI agents', name: _logName);

      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get all users who are active (updated within last hour)
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final usersResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .gte('updated_at', oneHourAgo.toIso8601String())
          .limit(1000); // Limit for performance

      final users = (usersResponse as List).cast<Map<String, dynamic>>();

      final activeAgents = <admin_models.ActiveAIAgentData>[];

      // Process each user to get AI agent data
      for (final userData in users) {
        final userId = userData['id'] as String;
        final updatedAt = DateTime.parse(userData['updated_at'] as String);
        final isOnline = now.difference(updatedAt).inHours < 1;

        // Generate AI signature
        final aiSignature = _generateAISignature(userId);

        // Get location data (if available)
        double? latitude;
        double? longitude;
        if (userData['location'] != null) {
          // Location format may vary - this is simplified
          // In production, you'd parse the actual location format
          // For now, use placeholder coordinates
          // TODO: Parse actual location string or use geocoding service
          latitude = 40.7128; // Default to NYC coordinates
          longitude = -74.0060;
        }

        // Get AI connections count
        int aiConnections = 0;
        try {
          final connectionsResponse = await client
              .from('user_connections')
              .select('id')
              .or('user_id_1.eq.$userId,user_id_2.eq.$userId');
          aiConnections = (connectionsResponse as List).length;
        } catch (e) {
          developer.log('Error fetching connections for user $userId: $e',
              name: _logName);
        }

        // Get predictions (simplified - would use actual PredictiveAnalytics in production)
        final predictions = <admin_models.PredictionAction>[];
        try {
          // Create minimal user object for predictions
          final user = User(
            id: userId,
            email: '',
            name: '',
            role: UserRole.user,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final journey = await _predictiveAnalytics.predictUserJourney(user);
          predictions.addAll(journey.predictedNextActions.map((a) =>
              admin_models.PredictionAction(
                action: a.action,
                probability: a.probability,
                category: a.category,
              )));
        } catch (e) {
          developer.log('Error getting predictions for user $userId: $e',
              name: _logName);
        }

        // Only add if we have location data
        if (latitude != null && longitude != null) {
          activeAgents.add(admin_models.ActiveAIAgentData(
            userId: userId,
            aiSignature: aiSignature,
            latitude: latitude,
            longitude: longitude,
            isOnline: isOnline,
            lastActive: updatedAt,
            aiConnections: aiConnections,
            aiStatus: isOnline ? 'active' : 'inactive',
            predictedActions: predictions,
            currentStage: 'explorer', // Simplified
            confidence: predictions.isNotEmpty
                ? predictions.first.probability
                : 0.5,
          ));
        }
      }

      developer.log('Fetched ${activeAgents.length} active AI agents',
          name: _logName);
      return activeAgents;
    } catch (e) {
      developer.log('Error fetching active AI agents: $e', name: _logName);
      return [];
    }
  }
}
