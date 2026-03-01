import 'dart:developer' as developer;
import 'package:avrai_core/models/user/preferences_profile.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// PreferencesProfile Service
///
/// Manages PreferencesProfile persistence and retrieval.
/// Uses agentId for privacy-preserving storage.
///
/// **Phase 8.8:** Initializes PreferencesProfile from onboarding data
class PreferencesProfileService {
  static const String _logName = 'PreferencesProfileService';
  static const String _storageKeyPrefix = 'preferences_profile_';

  final StorageService _storage;

  PreferencesProfileService({
    StorageService? storage,
  }) : _storage = storage ?? StorageService.instance;

  /// Initialize PreferencesProfile from onboarding data
  ///
  /// Creates and saves PreferencesProfile seeded from onboarding choices.
  ///
  /// **Parameters:**
  /// - `onboardingData`: Onboarding data to seed from
  ///
  /// **Returns:**
  /// Initialized PreferencesProfile
  Future<PreferencesProfile> initializeFromOnboarding(
    OnboardingData onboardingData,
  ) async {
    developer.log(
      'Initializing PreferencesProfile from onboarding for agentId: ${onboardingData.agentId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      // Check if profile already exists
      final existing = await getPreferencesProfile(onboardingData.agentId);
      if (existing != null && existing.source != 'onboarding') {
        // Profile already exists and learned from behavior, don't overwrite
        developer.log(
          'PreferencesProfile already exists and learned, returning existing',
          name: _logName,
        );
        return existing;
      }

      // Create from onboarding data
      final profile = PreferencesProfile.fromOnboarding(
        agentId: onboardingData.agentId,
        onboardingData: onboardingData,
      );

      // Save to storage
      await savePreferencesProfile(profile);

      developer.log(
        '✅ PreferencesProfile initialized from onboarding: ${profile.categoryPreferences.length} categories, ${profile.localityPreferences.length} localities',
        name: _logName,
      );

      return profile;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing PreferencesProfile from onboarding: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to empty profile
      return PreferencesProfile.empty(agentId: onboardingData.agentId);
    }
  }

  /// Get PreferencesProfile for agentId
  Future<PreferencesProfile?> getPreferencesProfile(String agentId) async {
    try {
      final key = '$_storageKeyPrefix$agentId';
      final data = _storage.getObject<Map<String, dynamic>>(key);
      if (data == null) return null;

      return PreferencesProfile.fromJson(data);
    } catch (e) {
      developer.log('Error loading PreferencesProfile: $e', name: _logName);
      return null;
    }
  }

  /// Save PreferencesProfile
  Future<void> savePreferencesProfile(PreferencesProfile profile) async {
    try {
      final key = '$_storageKeyPrefix${profile.agentId}';
      await _storage.setObject(key, profile.toJson());
    } catch (e) {
      developer.log('Error saving PreferencesProfile: $e', name: _logName);
      rethrow;
    }
  }

  /// Update PreferencesProfile (for learning from behavior)
  Future<void> updatePreferencesProfile(PreferencesProfile profile) async {
    try {
      final updated = profile.copyWith(
        lastUpdated: DateTime.now(),
        source: profile.source == 'onboarding' ? 'hybrid' : 'learned',
      );
      await savePreferencesProfile(updated);
    } catch (e) {
      developer.log('Error updating PreferencesProfile: $e', name: _logName);
      rethrow;
    }
  }
}
