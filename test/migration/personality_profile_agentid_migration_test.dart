import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import '../mocks/mock_storage_service.dart';

/// Phase 8.3: PersonalityProfile agentId Migration Test
///
/// Tests that PersonalityProfile correctly uses agentId as primary key:
/// - New profiles use agentId
/// - Legacy profiles (userId) are migrated automatically
/// - Storage uses agentId as key
/// - Backward compatibility maintained
///
/// Date: December 23, 2025
/// Status: Testing Phase 8.3 implementation

void main() {
  setUpAll(() async {
    // Initialize dependency injection for tests
    try {
      await di.init();
    } catch (e) {
      // DI may fail in test environment, that's okay
      // ignore: avoid_print
      print('⚠️  DI initialization failed in test: $e');
    }
  });

  group('Phase 8.3: PersonalityProfile agentId Migration', () {
    test('PersonalityProfile.initial() creates profile with agentId', () async {
      // Arrange
      const agentId = 'agent_test_123';
      const userId = 'user_test_123';

      // Act
      final profile = PersonalityProfile.initial(agentId, userId: userId);

      // Assert
      expect(profile.agentId, equals(agentId));
      expect(profile.userId, equals(userId));
      expect(profile.agentId, isNot(equals(profile.userId)));
    });

    test('PersonalityProfile.fromJson() supports both agentId and userId (migration)', () {
      // Arrange - Legacy format (userId only)
      final legacyJson = {
        'user_id': 'legacy_user_123',
        'dimensions': {'exploration_eagerness': 0.7},
        'dimension_confidence': {'exploration_eagerness': 0.5},
        'archetype': 'explorer',
        'authenticity': 0.8,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
        'evolution_generation': 1,
        'learning_history': {},
      };

      // Act
      final profile = PersonalityProfile.fromJson(legacyJson);

      // Assert - Should use userId as agentId for migration
      expect(profile.agentId, equals('legacy_user_123'));
      expect(profile.userId, equals('legacy_user_123'));
    });

    test('PersonalityProfile.fromJson() prefers agentId over userId', () {
      // Arrange - New format (both agentId and userId)
      final newJson = {
        'agent_id': 'agent_new_123',
        'user_id': 'user_new_123',
        'dimensions': {'exploration_eagerness': 0.7},
        'dimension_confidence': {'exploration_eagerness': 0.5},
        'archetype': 'explorer',
        'authenticity': 0.8,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
        'evolution_generation': 1,
        'learning_history': {},
      };

      // Act
      final profile = PersonalityProfile.fromJson(newJson);

      // Assert - Should use agentId
      expect(profile.agentId, equals('agent_new_123'));
      expect(profile.userId, equals('user_new_123'));
    });

    test('PersonalityProfile.toJson() includes both agentId and userId', () {
      // Arrange
      const agentId = 'agent_test_456';
      const userId = 'user_test_456';
      final profile = PersonalityProfile.initial(agentId, userId: userId);

      // Act
      final json = profile.toJson();

      // Assert
      expect(json['agent_id'], equals(agentId));
      expect(json['user_id'], equals(userId));
    });

    test('PersonalityProfile equality uses agentId', () {
      // Arrange
      const agentId = 'agent_test_789';
      final profile1 = PersonalityProfile.initial(agentId);
      final profile2 = PersonalityProfile.initial(agentId);

      // Act & Assert
      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
    });

    test('PersonalityLearning saves profile with agentId key', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      real_prefs.SharedPreferences.setMockInitialValues({});
      
      // Use mock storage for tests
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      final prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      final learning = PersonalityLearning.withPrefs(prefs);
      const userId = 'test_user_migration';
      
      // Get agentId
      final agentIdService = AgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Act - Initialize personality
      final profile = await learning.initializePersonality(userId);

      // Assert - Profile should have agentId
      expect(profile.agentId, equals(agentId));
      expect(profile.agentId, startsWith('agent_'));
      
      // Verify storage key uses agentId
      final storedJson = prefs.getString('personality_profile_$agentId');
      expect(storedJson, isNotNull);
      
      final storedProfile = PersonalityProfile.fromJson(
        jsonDecode(storedJson!) as Map<String, dynamic>,
      );
      expect(storedProfile.agentId, equals(agentId));
    });

    test('PersonalityLearning migrates legacy profile on load', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      real_prefs.SharedPreferences.setMockInitialValues({});
      
      // Use mock storage for tests
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      final prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      final learning = PersonalityLearning.withPrefs(prefs);
      const userId = 'test_user_legacy';
      
      // Get agentId
      final agentIdService = AgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);
      
      // Create legacy profile (userId-based) - use legacy JSON format
      final legacyJson = {
        'user_id': userId, // Legacy: only userId, no agentId
        'dimensions': {'exploration_eagerness': 0.8},
        'dimension_confidence': {'exploration_eagerness': 0.6},
        'archetype': 'explorer',
        'authenticity': 0.9,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
        'evolution_generation': 2,
        'learning_history': {},
      };
      
      // Save with legacy key (userId) using legacy JSON format
      await prefs.setString(
        'personality_profile_$userId',
        jsonEncode(legacyJson),
      );

      // Act - Load profile (should trigger migration)
      // Use initializePersonality which will call _loadPersonalityProfile
      final loadedProfile = await learning.initializePersonality(userId);

      // Assert - Profile should be migrated to use agentId
      expect(loadedProfile, isNotNull);
      expect(loadedProfile.agentId, equals(agentId));
      expect(loadedProfile.userId, equals(userId));
      
      // Verify new key exists
      final migratedJson = prefs.getString('personality_profile_$agentId');
      expect(migratedJson, isNotNull);
      
      // Verify migrated profile has correct agentId
      final migratedProfile = PersonalityProfile.fromJson(
        jsonDecode(migratedJson!) as Map<String, dynamic>,
      );
      expect(migratedProfile.agentId, equals(agentId));
    });

    test('PersonalityLearning.initializePersonalityFromOnboarding uses agentId', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      real_prefs.SharedPreferences.setMockInitialValues({});
      
      // Use mock storage for tests
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      final prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      final learning = PersonalityLearning.withPrefs(prefs);
      const userId = 'test_user_onboarding';
      
      // Get agentId
      final agentIdService = AgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Act
      final profile = await learning.initializePersonalityFromOnboarding(
        userId,
        onboardingData: {
          'age': 25,
          'homebase': 'San Francisco',
        },
      );

      // Assert
      expect(profile.agentId, equals(agentId));
      expect(profile.agentId, startsWith('agent_'));
      expect(profile.userId, equals(userId));
    });
  });
}

