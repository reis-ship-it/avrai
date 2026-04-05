import 'dart:async';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:avrai_runtime_os/services/admin/permissions/admin_access_control.dart';
import 'package:avrai_runtime_os/services/admin/admin_privacy_filter.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart' hide JourneyStep;
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_core/models/expertise/expertise_progress.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart'
    as admin_models
    show
        UserProgressData,
        UserPredictionsData,
        UserSearchResult,
        UserDataSnapshot,
        PredictionAction,
        JourneyStep;

/// Admin User Management Service
/// Handles user-related admin operations
/// Phase 1.6: Extracted from AdminGodModeService
class AdminUserManagementService {
  static const String _logName = 'AdminUserManagementService';

  final AdminAccessControl _accessControl;
  final SupabaseService _supabaseService;
  final PredictiveAnalytics _predictiveAnalytics;

  AdminUserManagementService({
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

  /// Get user progress data
  /// Privacy-preserving: Only returns progress metrics, NO personal data
  Future<admin_models.UserProgressData> getUserProgress(String userId) async {
    _accessControl.requireAuthorization();

    try {
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get user's lists count
      final listsResponse =
          await client.from('spot_lists').select('id').eq('created_by', userId);
      final listsCreated = (listsResponse as List).length;

      // Get user's spots count
      final spotsResponse =
          await client.from('spots').select('id').eq('created_by', userId);
      final spotsAdded = (spotsResponse as List).length;

      // Get user's respects (reviews/interactions)
      final respectsResponse =
          await client.from('user_respects').select('id').eq('user_id', userId);
      final totalRespects = (respectsResponse as List).length;

      // Calculate total contributions
      final totalContributions = listsCreated + spotsAdded + totalRespects;

      // Get respected lists count (lists that have been respected by others)
      final respectedListsResponse = await client
          .from('user_respects')
          .select('list_id')
          .not('list_id', 'is', null);

      final respectedListIds = (respectedListsResponse as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['list_id'] as String)
          .toSet();

      // Filter user's lists that have been respected
      final userListsResponse =
          await client.from('spot_lists').select('id').eq('created_by', userId);

      final userListIds = (userListsResponse as List)
          .cast<Map<String, dynamic>>()
          .map((l) => l['id'] as String)
          .toSet();

      final respectedListsCount =
          respectedListIds.intersection(userListIds).length;

      // Calculate expertise progress using ExpertiseService
      // For now, we'll create basic progress entries
      final expertiseProgress = <ExpertiseProgress>[];

      // Calculate pins earned (simplified - would need full expertise calculation)
      final pinsEarned = respectedListsCount; // Simplified calculation

      return admin_models.UserProgressData(
        userId: userId,
        expertiseProgress: expertiseProgress,
        totalContributions: totalContributions,
        pinsEarned: pinsEarned,
        listsCreated: listsCreated,
        spotsAdded: spotsAdded,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching user progress: $e', name: _logName);
      // Return empty progress on error
      return admin_models.UserProgressData(
        userId: userId,
        expertiseProgress: [],
        totalContributions: 0,
        pinsEarned: 0,
        listsCreated: 0,
        spotsAdded: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get user predictions
  /// Privacy-preserving: Only returns AI predictions, NO personal data
  Future<admin_models.UserPredictionsData> getUserPredictions(
      String userId) async {
    _accessControl.requireAuthorization();

    try {
      // Get predictions using only user ID
      // IMPORTANT: Do not pass personal data (name, email) to prediction service
      // Create minimal user object with ID only for prediction service
      final user = User(
        id: userId,
        email: '', // Empty - not used for predictions
        name: '', // Empty - not used for predictions
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final journey = await _predictiveAnalytics.predictUserJourney(user);

      return admin_models.UserPredictionsData(
        userId: userId,
        currentStage: journey.currentStage.name,
        predictedActions: journey.predictedNextActions
            .map((a) => admin_models.PredictionAction(
                  action: a.action,
                  probability: a.probability,
                  category: a.category,
                ))
            .toList(),
        journeyPath: journey.journeyPath
            .map((s) => admin_models.JourneyStep(
                  description: s.description,
                  estimatedTime: s.estimatedTime,
                  likelihood: s.likelihood,
                ))
            .toList(),
        confidence: journey.confidence,
        timeframe: journey.timeframe,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching user predictions: $e', name: _logName);
      rethrow;
    }
  }

  /// Get follower count for a user
  /// Returns number of users following this user
  Future<int> getFollowerCount(String userId) async {
    _accessControl.requireAuthorization();

    try {
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }
      final response = await client
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);

      final follows = (response as List).cast<Map<String, dynamic>>();
      return follows.length;
    } catch (e) {
      developer.log('Error getting follower count: $e', name: _logName);
      return 0;
    }
  }

  /// Get users who have a following (follower count >= threshold)
  /// Returns list of user IDs with their follower counts
  Future<Map<String, int>> getUsersWithFollowing({int minFollowers = 1}) async {
    _accessControl.requireAuthorization();

    try {
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get all follow relationships
      final response = await client.from('user_follows').select('following_id');

      final follows = (response as List).cast<Map<String, dynamic>>();

      // Count followers per user
      final followerCounts = <String, int>{};
      for (final follow in follows) {
        final followingId = follow['following_id'] as String;
        followerCounts[followingId] = (followerCounts[followingId] ?? 0) + 1;
      }

      // Filter by minimum followers
      return Map.fromEntries(
        followerCounts.entries.where((e) => e.value >= minFollowers),
      );
    } catch (e) {
      developer.log('Error getting users with following: $e', name: _logName);
      return {};
    }
  }

  /// Search users by AI signature or user ID only
  /// Privacy-preserving: No personal data (name, email, phone, address) is returned
  Future<List<admin_models.UserSearchResult>> searchUsers({
    String? query, // Search by user ID or AI signature only
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    _accessControl.requireAuthorization();

    try {
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }
      dynamic dbQuery =
          client.from('users').select('id, created_at, updated_at');

      // Apply filters
      if (query != null && query.isNotEmpty) {
        // Search by user ID (partial match)
        dbQuery = dbQuery.ilike('id', '%$query%');
      }

      if (createdAfter != null) {
        dbQuery = dbQuery.gte('created_at', createdAfter.toIso8601String());
      }

      if (createdBefore != null) {
        dbQuery = dbQuery.lte('created_at', createdBefore.toIso8601String());
      }

      // Limit results for performance
      dbQuery = dbQuery.limit(100);
      dbQuery = dbQuery.order('created_at', ascending: false);

      final response = await dbQuery;
      final users = (response as List).cast<Map<String, dynamic>>();

      // Convert to UserSearchResult with AI signature generation
      // IMPORTANT: Only return user ID and AI signature, NO personal data
      return users.map((userData) {
        final userId = userData['id'] as String;
        final createdAt = DateTime.parse(userData['created_at'] as String);
        final updatedAt = DateTime.parse(userData['updated_at'] as String);

        // Generate AI signature from user ID (deterministic but anonymized)
        final aiSignature = _generateAISignature(userId);

        // Check if user is active (updated within last 7 days)
        final isActive = DateTime.now().difference(updatedAt).inDays < 7;

        return admin_models.UserSearchResult(
          userId: userId,
          aiSignature: aiSignature,
          createdAt: createdAt,
          isActive: isActive,
        );
      }).toList();
    } catch (e) {
      developer.log('Error searching users: $e', name: _logName);
      return [];
    }
  }

  /// Get real-time user data stream
  Stream<admin_models.UserDataSnapshot> watchUserData(String userId) {
    _accessControl.requireAuthorization();

    final controller =
        StreamController<admin_models.UserDataSnapshot>.broadcast();

    // Start periodic updates
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final snapshot = await _fetchUserDataSnapshot(userId);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in user data stream: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Fetch user data snapshot
  Future<admin_models.UserDataSnapshot> _fetchUserDataSnapshot(
      String userId) async {
    // Fetch actual user data from database
    // IMPORTANT: Filter out all personal data before returning

    try {
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Fetch user data - only select fields that are safe (no personal data)
      final userResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        // User not found, return minimal snapshot
        return admin_models.UserDataSnapshot(
          userId: userId,
          isOnline: false,
          lastActive: DateTime.now(),
          data: {'ai_signature': _generateAISignature(userId)},
        );
      }

      final userData = userResponse;
      final updatedAt = DateTime.parse(userData['updated_at'] as String);

      // Build raw data with only safe fields
      final rawData = <String, dynamic>{
        'ai_signature': _generateAISignature(userId),
        'ai_connections': 0, // TODO: Get from connection monitor
        'ai_status': 'active',
      };

      // Add location data if available (allowed as vibe indicator)
      if (userData['location'] != null) {
        final location = userData['location'] as String?;
        if (location != null && location.isNotEmpty) {
          rawData['location'] = location;
        }
      }

      // Get user's spots for location data (vibe indicators)
      try {
        final spotsResponse = await client
            .from('spots')
            .select('latitude, longitude')
            .eq('created_by', userId)
            .limit(10);

        final spots = (spotsResponse as List).cast<Map<String, dynamic>>();
        if (spots.isNotEmpty) {
          final visitedLocations = spots
              .map((spot) => <String, double>{
                    'lat': (spot['latitude'] as num).toDouble(),
                    'lng': (spot['longitude'] as num).toDouble(),
                  })
              .toList();
          rawData['visited_locations'] = visitedLocations;
        }
      } catch (e) {
        developer.log('Error fetching user spots: $e', name: _logName);
      }

      // Apply privacy filter to ensure no personal data leaks through
      final filteredData = AdminPrivacyFilter.filterPersonalData(rawData);

      // Validate that no personal data is included
      if (!AdminPrivacyFilter.isValid(filteredData)) {
        developer.log(
            'WARNING: Personal data detected in user snapshot for $userId',
            name: _logName);
        // Return minimal data if personal data detected
        return admin_models.UserDataSnapshot(
          userId: userId,
          isOnline: false,
          lastActive: updatedAt,
          data: {'ai_signature': _generateAISignature(userId)},
        );
      }

      // Check if user is online (updated within last hour)
      final isOnline = DateTime.now().difference(updatedAt).inHours < 1;

      return admin_models.UserDataSnapshot(
        userId: userId,
        isOnline: isOnline,
        lastActive: updatedAt,
        data: filteredData,
      );
    } catch (e) {
      developer.log('Error fetching user data snapshot: $e', name: _logName);
      // Return minimal snapshot on error
      return admin_models.UserDataSnapshot(
        userId: userId,
        isOnline: false,
        lastActive: DateTime.now(),
        data: {'ai_signature': _generateAISignature(userId)},
      );
    }
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
}
