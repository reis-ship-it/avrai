import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/preferences_profile.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;

import '../../helpers/platform_channel_helper.dart';

/// PreferencesProfile Initialization Integration Test
///
/// Tests that PreferencesProfile is correctly initialized during onboarding:
/// - PreferencesProfile created from onboarding data
/// - PreferencesProfile saved to storage
/// - PreferencesProfile loaded after initialization
/// - PreferencesProfile works alongside PersonalityProfile
///
/// Date: December 23, 2025
/// Status: Phase 8.8 - PreferencesProfile Initialization

void main() {
  final runHeavyIntegrationTests =
      Platform.environment['RUN_HEAVY_INTEGRATION_TESTS'] == 'true';

  setUpAll(() async {
    if (!runHeavyIntegrationTests) {
      return;
    }

    // Initialize dependency injection for tests
    try {
      await setupTestStorage();
      await di.init();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️  DI initialization failed in test: $e');
    }
  });

  group('PreferencesProfile Initialization Integration', () {
    test('should initialize PreferencesProfile from onboarding data', () async {
      // Arrange
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_prefs_1';
      final agentId = await agentIdService.getUserAgentId(userId);

      final onboardingData = OnboardingData(
        agentId: agentId,
        age: 28,
        homebase: 'San Francisco, CA',
        favoritePlaces: ['Golden Gate Park', 'Mission District'],
        preferences: {
          'Food & Drink': ['Coffee', 'Craft Beer'],
          'Activities': ['Hiking', 'Live Music'],
        },
        baselineLists: ['My Coffee Spots'],
        completedAt: DateTime.now(),
      );

      // Act
      final profile =
          await preferencesService.initializeFromOnboarding(onboardingData);

      // Assert
      expect(profile, isNotNull);
      expect(profile.agentId, equals(agentId));
      expect(profile.categoryPreferences, isNotEmpty);
      expect(profile.categoryPreferences['Coffee'], equals(0.8));
      expect(profile.categoryPreferences['Food & Drink'], greaterThan(0.7));
      expect(profile.localityPreferences['San Francisco, CA'], equals(0.8));
      expect(profile.source, equals('onboarding'));
    });

    test('should save and load PreferencesProfile from storage', () async {
      // Arrange
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_prefs_2';
      final agentId = await agentIdService.getUserAgentId(userId);

      final onboardingData = OnboardingData(
        agentId: agentId,
        preferences: {
          'Food & Drink': ['Coffee'],
        },
        homebase: 'Brooklyn, NY',
        completedAt: DateTime.now(),
      );

      // Act - Initialize and save
      final savedProfile =
          await preferencesService.initializeFromOnboarding(onboardingData);

      // Load from storage
      final loadedProfile =
          await preferencesService.getPreferencesProfile(agentId);

      // Assert
      expect(loadedProfile, isNotNull);
      expect(loadedProfile!.agentId, equals(savedProfile.agentId));
      expect(loadedProfile.categoryPreferences,
          equals(savedProfile.categoryPreferences));
      expect(loadedProfile.localityPreferences,
          equals(savedProfile.localityPreferences));
      expect(loadedProfile.source, equals(savedProfile.source));
    });

    test('should not overwrite learned PreferencesProfile with onboarding data',
        () async {
      // Arrange
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_prefs_3';
      final agentId = await agentIdService.getUserAgentId(userId);

      // Create a learned profile first
      final learnedProfile = PreferencesProfile(
        agentId: agentId,
        categoryPreferences: const {'Coffee': 0.9, 'Food': 0.8},
        localityPreferences: const {'Manhattan': 0.7},
        source: 'learned',
        lastUpdated: DateTime.now(),
      );
      await preferencesService.savePreferencesProfile(learnedProfile);

      // Try to initialize from onboarding
      final onboardingData = OnboardingData(
        agentId: agentId,
        preferences: {
          'Activities': ['Hiking']
        },
        completedAt: DateTime.now(),
      );

      // Act
      final result =
          await preferencesService.initializeFromOnboarding(onboardingData);

      // Assert - Should return existing learned profile, not overwrite
      expect(result.source, equals('learned'));
      expect(result.categoryPreferences['Coffee'], equals(0.9));
      expect(result.categoryPreferences['Activities'],
          isNull); // Not from onboarding
    });

    test('should update PreferencesProfile with learned data', () async {
      // Arrange
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_prefs_4';
      final agentId = await agentIdService.getUserAgentId(userId);

      final onboardingData = OnboardingData(
        agentId: agentId,
        preferences: {
          'Food & Drink': ['Coffee']
        },
        completedAt: DateTime.now(),
      );

      // Initialize from onboarding
      final initialProfile =
          await preferencesService.initializeFromOnboarding(onboardingData);
      expect(initialProfile.source, equals('onboarding'));

      // Update with learned data
      final updatedProfile = initialProfile.copyWith(
        categoryPreferences: {
          ...initialProfile.categoryPreferences,
          'Art': 0.7,
        },
        eventsAnalyzed: 10,
      );
      await preferencesService.updatePreferencesProfile(updatedProfile);

      // Load and verify
      final loadedProfile =
          await preferencesService.getPreferencesProfile(agentId);
      expect(loadedProfile, isNotNull);
      expect(loadedProfile!.source,
          equals('hybrid')); // Changed from 'onboarding' to 'hybrid'
      expect(loadedProfile.categoryPreferences['Art'], equals(0.7));
      expect(loadedProfile.eventsAnalyzed, equals(10));
    });
  }, skip: !runHeavyIntegrationTests);
}
