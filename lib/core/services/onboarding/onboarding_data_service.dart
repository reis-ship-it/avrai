import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/onboarding/onboarding_aggregation_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get_it/get_it.dart';

/// OnboardingDataService
///
/// Service for persisting and retrieving onboarding data.
/// Uses agentId (not userId) internally for privacy protection per Master Plan Phase 7.3.
///
/// Accepts userId in public API but converts to agentId internally.
/// Phase 11 Section 4: Integrates with onboarding-aggregation edge function.
///
/// Phase 26: Migrated from Sembast to GetStorage.
class OnboardingDataService {
  static const String _logName = 'OnboardingDataService';
  static const String _dataKeyPrefix = 'onboarding_data_';
  static const String _boxName = 'onboarding_data';

  static GetStorage? _storage;

  /// Optional storage for testing (avoids path_provider in VM tests).
  final GetStorage? _injectedStorage;

  GetStorage get _box {
    if (_injectedStorage != null) return _injectedStorage;
    _storage ??= GetStorage(_boxName);
    return _storage!;
  }

  /// Initialize storage
  static Future<void> initStorage() async {
    await GetStorage.init(_boxName);
  }

  final AgentIdService _agentIdService;
  final OnboardingAggregationService? _onboardingAggregationService;

  static AgentIdService _resolveAgentIdService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        return sl<AgentIdService>();
      }
    } catch (_) {
      // Fall through to a safe default instance.
    }
    return AgentIdService();
  }

  OnboardingDataService({
    AgentIdService? agentIdService,
    OnboardingAggregationService? onboardingAggregationService,
    GetStorage? storage,
  })  : _agentIdService = agentIdService ?? _resolveAgentIdService(),
        _onboardingAggregationService = onboardingAggregationService,
        _injectedStorage = storage;

  /// Save onboarding data (accepts userId, converts to agentId internally)
  ///
  /// [userId] - Authenticated user ID from UI layer
  /// [data] - OnboardingData to save (should already have agentId set)
  Future<void> saveOnboardingData(String userId, OnboardingData data) async {
    try {
      developer.log(
        'Saving onboarding data for user: $userId',
        name: _logName,
      );

      // Convert userId → agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Ensure data uses agentId (not userId)
      final dataWithAgentId = OnboardingData(
        agentId: agentId, // ✅ Use agentId
        age: data.age,
        birthday: data.birthday,
        homebase: data.homebase,
        favoritePlaces: data.favoritePlaces,
        preferences: data.preferences,
        baselineLists: data.baselineLists,
        respectedFriends: data.respectedFriends,
        socialMediaConnected: data.socialMediaConnected,
        completedAt: data.completedAt,
        // New onboarding flow fields
        dimensionValues: data.dimensionValues,
        dimensionConfidence: data.dimensionConfidence,
        tosAccepted: data.tosAccepted,
        privacyAccepted: data.privacyAccepted,
      );

      // Validate data before saving
      if (!dataWithAgentId.isValid) {
        throw Exception('Invalid onboarding data: validation failed');
      }

      // Store using agentId as key
      await _box.write('$_dataKeyPrefix$agentId', dataWithAgentId.toJson());

      developer.log(
        '✅ Onboarding data saved for user: $userId (agentId: ${agentId.substring(0, 10)}...)',
        name: _logName,
      );

      // Phase 11 Section 4: Trigger onboarding aggregation via edge function (non-blocking)
      _triggerOnboardingAggregation(userId, dataWithAgentId);
    } catch (e, stackTrace) {
      developer.log(
        'Error saving onboarding data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Trigger onboarding aggregation via edge function (non-blocking)
  void _triggerOnboardingAggregation(String userId, OnboardingData data) {
    // Use service if available, otherwise try to get from DI
    final aggregationService = _onboardingAggregationService ??
        (GetIt.instance.isRegistered<OnboardingAggregationService>()
            ? GetIt.instance<OnboardingAggregationService>()
            : null);

    if (aggregationService == null) {
      developer.log(
        'OnboardingAggregationService not available, skipping aggregation',
        name: _logName,
      );
      return;
    }

    // Call aggregation in background (don't block)
    unawaited(
      aggregationService
          .aggregateOnboardingData(
        userId: userId,
        onboardingData: data,
      )
          .catchError((error) {
        developer.log(
          'Error in onboarding aggregation (non-blocking): $error',
          name: _logName,
        );
        // Don't rethrow - aggregation failure shouldn't break onboarding
        // Return empty map to satisfy return type requirement
        return <String, double>{};
      }),
    );
  }

  /// Get onboarding data (accepts userId, converts to agentId internally)
  ///
  /// [userId] - Authenticated user ID from UI layer
  /// Returns OnboardingData if found, null otherwise
  Future<OnboardingData?> getOnboardingData(String userId) async {
    try {
      developer.log(
        'Getting onboarding data for user: $userId',
        name: _logName,
      );

      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Retrieve using agentId
      final data = _box.read<Map<String, dynamic>>('$_dataKeyPrefix$agentId');

      if (data == null) {
        developer.log(
          'No onboarding data found for user: $userId',
          name: _logName,
        );
        return null;
      }

      final onboardingData = OnboardingData.fromJson(data);

      developer.log(
        '✅ Onboarding data retrieved for user: $userId',
        name: _logName,
      );

      return onboardingData;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting onboarding data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete onboarding data (accepts userId, converts to agentId internally)
  ///
  /// [userId] - Authenticated user ID from UI layer
  Future<void> deleteOnboardingData(String userId) async {
    try {
      developer.log(
        'Deleting onboarding data for user: $userId',
        name: _logName,
      );

      final agentId = await _agentIdService.getUserAgentId(userId);
      await _box.remove('$_dataKeyPrefix$agentId');

      developer.log(
        '✅ Onboarding data deleted for user: $userId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting onboarding data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if onboarding data exists (accepts userId, converts to agentId internally)
  ///
  /// [userId] - Authenticated user ID from UI layer
  /// Returns true if data exists, false otherwise
  Future<bool> hasOnboardingData(String userId) async {
    final data = await getOnboardingData(userId);
    return data != null;
  }
}
