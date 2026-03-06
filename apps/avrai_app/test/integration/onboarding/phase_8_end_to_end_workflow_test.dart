import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;

import '../../helpers/platform_channel_helper.dart';

/// Phase 8 End-to-End Workflow Integration Test
///
/// Verifies the complete onboarding → agent creation workflow:
/// 1. Onboarding data collection and persistence
/// 2. PersonalityProfile creation with agentId
/// 3. PreferencesProfile initialization from onboarding
/// 4. Both profiles work together
/// 5. Data persistence and retrieval
/// 6. Quantum-ready state
///
/// Date: December 23, 2025
/// Status: Phase 8 Complete - End-to-End Verification

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

  group('Phase 8: End-to-End Onboarding Workflow', () {
    test(
        'Complete workflow: Onboarding → PersonalityProfile → PreferencesProfile',
        () async {
      // Arrange
      const userId = 'test_user_e2e_1';
      final onboardingService = di.sl<OnboardingDataService>();
      final personalityLearning = di.sl<PersonalityLearning>();
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();

      final agentId = await agentIdService.getUserAgentId(userId);

      // Step 1: Create and save onboarding data
      final onboardingData = OnboardingData(
        agentId: agentId,
        age: 28,
        homebase: 'San Francisco, CA',
        favoritePlaces: ['Golden Gate Park', 'Mission District'],
        preferences: {
          'Food & Drink': ['Coffee', 'Craft Beer'],
          'Activities': ['Hiking', 'Live Music'],
          'Outdoor & Nature': ['Parks', 'Beaches'],
        },
        baselineLists: ['My Coffee Spots', 'Hiking Trails'],
        respectedFriends: ['friend1', 'friend2'],
        socialMediaConnected: {'google': true, 'instagram': false},
        completedAt: DateTime.now(),
      );

      await onboardingService.saveOnboardingData(userId, onboardingData);

      // Step 2: Initialize PersonalityProfile from onboarding
      final personalityProfile =
          await personalityLearning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {
          'age': onboardingData.age,
          'homebase': onboardingData.homebase,
          'favoritePlaces': onboardingData.favoritePlaces,
          'preferences': onboardingData.preferences,
          'baselineLists': onboardingData.baselineLists,
          'respectedFriends': onboardingData.respectedFriends,
        },
        socialMediaData: null,
      );

      // Step 3: Initialize PreferencesProfile from onboarding
      final preferencesProfile =
          await preferencesService.initializeFromOnboarding(
        onboardingData,
      );

      // Assert - Verify PersonalityProfile
      expect(personalityProfile, isNotNull);
      expect(personalityProfile.agentId, equals(agentId));
      expect(personalityProfile.agentId, isNot(equals(userId)));
      expect(personalityProfile.dimensions, isNotEmpty);
      expect(personalityProfile.archetype, isNotEmpty);
      expect(personalityProfile.authenticity, greaterThan(0.0));
      expect(personalityProfile.authenticity, lessThanOrEqualTo(1.0));

      // Assert - Verify PreferencesProfile
      expect(preferencesProfile, isNotNull);
      expect(preferencesProfile.agentId, equals(agentId));
      expect(preferencesProfile.categoryPreferences, isNotEmpty);
      expect(preferencesProfile.categoryPreferences['Coffee'], equals(0.8));
      expect(preferencesProfile.categoryPreferences['Food & Drink'],
          greaterThan(0.7));
      expect(preferencesProfile.localityPreferences['San Francisco, CA'],
          equals(0.8));
      expect(preferencesProfile.source, equals('onboarding'));

      // Assert - Verify both profiles use same agentId
      expect(personalityProfile.agentId, equals(preferencesProfile.agentId));

      // Assert - Verify profiles are saved and retrievable
      final savedPersonality =
          await personalityLearning.getCurrentPersonality(userId);
      expect(savedPersonality, isNotNull);
      expect(savedPersonality!.agentId, equals(agentId));

      final savedPreferences =
          await preferencesService.getPreferencesProfile(agentId);
      expect(savedPreferences, isNotNull);
      expect(savedPreferences!.agentId, equals(agentId));
      expect(savedPreferences.categoryPreferences['Coffee'], equals(0.8));
    });

    test('Workflow: Onboarding data → Both profiles → Quantum state conversion',
        () async {
      // Arrange
      const userId = 'test_user_e2e_2';
      final onboardingService = di.sl<OnboardingDataService>();
      final personalityLearning = di.sl<PersonalityLearning>();
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();

      final agentId = await agentIdService.getUserAgentId(userId);

      // Step 1: Save onboarding data
      final onboardingData = OnboardingData(
        agentId: agentId,
        age: 25,
        homebase: 'Brooklyn, NY',
        preferences: {
          'Food & Drink': ['Coffee', 'Restaurants'],
          'Art & Culture': ['Museums', 'Galleries'],
        },
        completedAt: DateTime.now(),
      );

      await onboardingService.saveOnboardingData(userId, onboardingData);

      // Step 2: Create both profiles
      final personalityProfile =
          await personalityLearning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {
          'age': onboardingData.age,
          'homebase': onboardingData.homebase,
          'preferences': onboardingData.preferences,
        },
        socialMediaData: null,
      );

      final preferencesProfile =
          await preferencesService.initializeFromOnboarding(
        onboardingData,
      );

      // Step 3: Verify quantum state conversion works
      final personalityQuantum =
          personalityProfile.dimensions; // Already quantum-enabled
      expect(personalityQuantum, isNotEmpty);
      expect(
          personalityQuantum.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);

      final preferencesQuantum = preferencesProfile.toQuantumState();
      expect(preferencesQuantum, isA<Map<String, dynamic>>());
      expect(preferencesQuantum['category'], isA<Map<String, double>>());
      expect(preferencesQuantum['locality'], isA<Map<String, double>>());
      expect(preferencesQuantum['local_expert'], isA<double>());
      expect(preferencesQuantum['exploration'], isA<double>());

      // Assert - Verify both profiles are quantum-ready
      expect(personalityProfile.dimensions.isNotEmpty, isTrue);
      expect(preferencesProfile.toQuantumState().isNotEmpty, isTrue);
    });

    test('Workflow: Profiles persist across app restarts', () async {
      // Arrange
      const userId = 'test_user_e2e_3';
      final onboardingService = di.sl<OnboardingDataService>();
      final personalityLearning = di.sl<PersonalityLearning>();
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();

      final agentId = await agentIdService.getUserAgentId(userId);

      // Step 1: Create onboarding data and profiles
      final onboardingData = OnboardingData(
        agentId: agentId,
        age: 30,
        homebase: 'Seattle, WA',
        preferences: {
          'Food & Drink': ['Coffee']
        },
        completedAt: DateTime.now(),
      );

      await onboardingService.saveOnboardingData(userId, onboardingData);
      await personalityLearning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {
          'age': onboardingData.age,
          'homebase': onboardingData.homebase,
          'preferences': onboardingData.preferences,
        },
        socialMediaData: null,
      );
      await preferencesService.initializeFromOnboarding(onboardingData);

      // Step 2: Simulate app restart (reload from storage)
      final reloadedPersonality =
          await personalityLearning.getCurrentPersonality(userId);
      final reloadedPreferences =
          await preferencesService.getPreferencesProfile(agentId);
      final reloadedOnboarding =
          await onboardingService.getOnboardingData(userId);

      // Assert - Verify all data persists
      expect(reloadedPersonality, isNotNull);
      expect(reloadedPersonality!.agentId, equals(agentId));
      expect(reloadedPersonality.dimensions, isNotEmpty);

      expect(reloadedPreferences, isNotNull);
      expect(reloadedPreferences!.agentId, equals(agentId));
      expect(reloadedPreferences.categoryPreferences, isNotEmpty);

      expect(reloadedOnboarding, isNotNull);
      expect(reloadedOnboarding!.agentId, equals(agentId));
      expect(reloadedOnboarding.homebase, equals('Seattle, WA'));
    });

    test(
        'Workflow: PreferencesProfile updates without overwriting PersonalityProfile',
        () async {
      // Arrange
      const userId = 'test_user_e2e_4';
      final onboardingService = di.sl<OnboardingDataService>();
      final personalityLearning = di.sl<PersonalityLearning>();
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();

      final agentId = await agentIdService.getUserAgentId(userId);

      // Step 1: Create initial profiles
      final onboardingData = OnboardingData(
        agentId: agentId,
        preferences: {
          'Food & Drink': ['Coffee']
        },
        completedAt: DateTime.now(),
      );

      await onboardingService.saveOnboardingData(userId, onboardingData);
      final initialPersonality =
          await personalityLearning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {'preferences': onboardingData.preferences},
        socialMediaData: null,
      );
      final initialPreferences =
          await preferencesService.initializeFromOnboarding(
        onboardingData,
      );

      // Step 2: Update PreferencesProfile (simulating learning from behavior)
      final updatedPreferences = initialPreferences.copyWith(
        categoryPreferences: {
          ...initialPreferences.categoryPreferences,
          'Art': 0.7,
        },
        eventsAnalyzed: 10,
        source: 'hybrid',
      );
      await preferencesService.savePreferencesProfile(updatedPreferences);

      // Step 3: Verify PersonalityProfile unchanged
      final currentPersonality =
          await personalityLearning.getCurrentPersonality(userId);
      expect(currentPersonality, isNotNull);
      expect(currentPersonality!.agentId, equals(initialPersonality.agentId));
      expect(
          currentPersonality.dimensions, equals(initialPersonality.dimensions));

      // Step 4: Verify PreferencesProfile updated
      final currentPreferences =
          await preferencesService.getPreferencesProfile(agentId);
      expect(currentPreferences, isNotNull);
      expect(currentPreferences!.categoryPreferences['Art'], equals(0.7));
      expect(currentPreferences.eventsAnalyzed, equals(10));
      expect(currentPreferences.source,
          equals('hybrid')); // Changed from 'onboarding'
    });

    test('Workflow: Complete data flow with all onboarding factors', () async {
      // Arrange
      const userId = 'test_user_e2e_5';
      final onboardingService = di.sl<OnboardingDataService>();
      final personalityLearning = di.sl<PersonalityLearning>();
      final preferencesService = di.sl<PreferencesProfileService>();
      final agentIdService = di.sl<AgentIdService>();

      final agentId = await agentIdService.getUserAgentId(userId);

      // Step 1: Create comprehensive onboarding data
      final onboardingData = OnboardingData(
        agentId: agentId,
        age: 32,
        birthday: DateTime(1993, 1, 15),
        homebase: 'Portland, OR',
        favoritePlaces: ['Powell\'s Books', 'Forest Park', 'Coffee Shops'],
        preferences: {
          'Food & Drink': ['Coffee', 'Craft Beer', 'Farm-to-Table'],
          'Activities': ['Hiking', 'Reading', 'Live Music'],
          'Outdoor & Nature': ['Parks', 'Trails', 'Gardens'],
          'Art & Culture': ['Bookstores', 'Museums', 'Music Venues'],
        },
        baselineLists: ['Coffee Spots', 'Hiking Trails', 'Bookstores'],
        respectedFriends: ['friend1', 'friend2', 'friend3'],
        socialMediaConnected: {
          'google': true,
          'instagram': true,
          'facebook': false,
        },
        completedAt: DateTime.now(),
      );

      await onboardingService.saveOnboardingData(userId, onboardingData);

      // Step 2: Initialize both profiles
      final personalityProfile =
          await personalityLearning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {
          'age': onboardingData.age,
          'birthday': onboardingData.birthday?.toIso8601String(),
          'homebase': onboardingData.homebase,
          'favoritePlaces': onboardingData.favoritePlaces,
          'preferences': onboardingData.preferences,
          'baselineLists': onboardingData.baselineLists,
          'respectedFriends': onboardingData.respectedFriends,
        },
        socialMediaData: null,
      );

      final preferencesProfile =
          await preferencesService.initializeFromOnboarding(
        onboardingData,
      );

      // Assert - Verify PersonalityProfile reflects onboarding data
      expect(personalityProfile.dimensions, isNotEmpty);
      // Age 32 should influence exploration_eagerness, temporal_flexibility
      expect(personalityProfile.dimensions['exploration_eagerness'] ?? 0.0,
          greaterThan(0.0));
      // Multiple favorite places should increase exploration
      expect(personalityProfile.dimensions['location_adventurousness'] ?? 0.0,
          greaterThan(0.0));
      // Multiple preferences should influence various dimensions
      expect(personalityProfile.archetype, isNotEmpty);

      // Assert - Verify PreferencesProfile reflects onboarding data
      expect(preferencesProfile.categoryPreferences.length,
          greaterThan(4)); // Multiple categories
      expect(preferencesProfile.categoryPreferences['Coffee'], equals(0.8));
      expect(preferencesProfile.categoryPreferences['Craft Beer'], equals(0.8));
      expect(preferencesProfile.categoryPreferences['Food & Drink'],
          greaterThan(0.7));
      expect(
          preferencesProfile.localityPreferences['Portland, OR'], equals(0.8));
      expect(preferencesProfile.source, equals('onboarding'));

      // Assert - Verify both profiles work together
      expect(personalityProfile.agentId, equals(preferencesProfile.agentId));
      expect(personalityProfile.agentId, equals(agentId));
      expect(preferencesProfile.agentId, equals(agentId));

      // Assert - Verify quantum readiness
      final personalityQuantum = personalityProfile.dimensions;
      final preferencesQuantum = preferencesProfile.toQuantumState();
      expect(personalityQuantum.isNotEmpty, isTrue);
      expect(preferencesQuantum.isNotEmpty, isTrue);
    });
  }, skip: !runHeavyIntegrationTests);
}
