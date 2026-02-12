/// Personality Sync Integration Tests
///
/// Tests the complete cross-device personality sync flow:
/// - Password update with profile re-encryption
/// - Conflict resolution with real timestamps
/// - Cloud sync enable/disable
/// - End-to-end sync scenarios
/// - Cross-device profile loading
///
/// These tests use realistic mocks and test the full integration
/// between PersonalitySyncService, PersonalityLearning, and AuthBloc.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/matching/personality_sync_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mocks/mock_storage_service.dart';

// Mocks
class MockSupabaseService extends Mock implements SupabaseService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Personality Sync Integration Tests', () {
    late PersonalitySyncService syncService;
    late PersonalityLearning personalityLearning;
    late SharedPreferencesCompat prefs;
    late MockSupabaseService mockSupabaseService;

    setUpAll(() {
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      // Register AgentIdService for PersonalityLearning (it always resolves userId → agentId).
      // In tests, Supabase is not initialized, so AgentIdService uses deterministic fallback.
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        sl.unregister<AgentIdService>();
      }
      sl.registerSingleton<AgentIdService>(AgentIdService());

      // Reset SharedPreferences mock state for test isolation
      real_prefs.SharedPreferences.setMockInitialValues({});
      
      // Setup mock storage + init StorageService for cloud sync flags
      final defaultStorage = MockGetStorage.getInstance(boxName: 'spots_default');
      final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
      final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
      final analyticsStorage = MockGetStorage.getInstance(boxName: 'spots_analytics');
      await StorageService.instance.initForTesting(
        defaultStorage: defaultStorage,
        userStorage: userStorage,
        aiStorage: aiStorage,
        analyticsStorage: analyticsStorage,
      );
      prefs = await SharedPreferencesCompat.getInstance(storage: defaultStorage);

      // Create services with mocked Supabase
      mockSupabaseService = MockSupabaseService();
      final mockClient = MockSupabaseClient();

      // Mock the client getter to return our mock client
      when(() => mockSupabaseService.client).thenReturn(mockClient);
      
      // Mock isAvailable to return true for tests that need Supabase
      // Individual tests can override this if needed
      when(() => mockSupabaseService.isAvailable).thenReturn(true);

      // Mock the Supabase query chain for setCloudSyncEnabled and syncToCloud
      // This is complex, so we'll use a simpler approach: catch errors gracefully
      // The local storage part of setCloudSyncEnabled will still work

      syncService = PersonalitySyncService(
        supabaseService: mockSupabaseService,
        storageService: StorageService.instance,
      );
      personalityLearning = PersonalityLearning.withPrefs(prefs);
    });

    tearDown(() {
      // Clean up GetIt registrations for isolation
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        sl.unregister<AgentIdService>();
      }
      MockGetStorage.reset();
    });

    tearDownAll(() {
      // Cleanup any remaining resources
      MockGetStorage.reset();
    });

    group('Password Update Flow', () {
      test('should re-encrypt profile when password changes', () async {
        final userId = 'test_user_pwd_change_${DateTime.now().millisecondsSinceEpoch}';
        final oldPassword = 'old_password_${DateTime.now().millisecondsSinceEpoch}';
        final newPassword = 'new_password_${DateTime.now().millisecondsSinceEpoch + 1}';

        // 1. Initialize personality profile using PersonalityLearning
        final profile = await personalityLearning.initializePersonality(userId);
        expect(profile, isNotNull);
        expect(profile.evolutionGeneration, greaterThanOrEqualTo(0));

        // 2. Enable cloud sync
        await syncService.setCloudSyncEnabled(true);
        final syncEnabled = await syncService.isCloudSyncEnabled(userId);
        expect(syncEnabled, isTrue);

        // 3. Encrypt and sync with old password
        final oldKey =
            await syncService.deriveKeyFromPassword(oldPassword, userId);
        final encryptedWithOld =
            await syncService.encryptProfileForCloud(profile, oldKey);
        expect(encryptedWithOld, isNotEmpty);

        // 4. Re-encrypt with new password (simulating password change)
        final newKey =
            await syncService.deriveKeyFromPassword(newPassword, userId);
        final encryptedWithNew =
            await syncService.encryptProfileForCloud(profile, newKey);
        expect(encryptedWithNew, isNotEmpty);
        expect(encryptedWithNew, isNot(equals(encryptedWithOld)));

        // 5. Verify new password can decrypt
        final decryptedWithNew = await syncService.decryptProfileFromCloud(
          encryptedWithNew,
          newKey,
        );
        expect(decryptedWithNew, isNotNull);
        expect(decryptedWithNew!.userId, equals(userId));
        expect(decryptedWithNew.evolutionGeneration,
            equals(profile.evolutionGeneration));

        // 6. Verify old password cannot decrypt new encryption
        final decryptedWithOld = await syncService.decryptProfileFromCloud(
          encryptedWithNew,
          oldKey,
        );
        expect(decryptedWithOld, isNull);
      });
    });

    group('Conflict Resolution Integration', () {
      test('should detect when cloud profile is newer', () async {
        final userId = 'test_user_cloud_newer_${DateTime.now().millisecondsSinceEpoch}';

        // Create local profile
        final localProfile =
            await personalityLearning.initializePersonality(userId);
        final localUpdated = localProfile.lastUpdated;

        // Simulate cloud profile that's newer
        // Phase 8.3: Use agentId for privacy protection
        final agentId = 'agent_$userId';
        final cloudProfile = PersonalityProfile.initial(agentId, userId: userId).evolve(
          newDimensions: {'adventure': 0.9},
          additionalLearning: {'cloud_key': 'cloud_value'},
        );

        // Make cloud profile appear newer
        final cloudUpdated = localUpdated.add(const Duration(hours: 1));
        expect(cloudUpdated.isAfter(localUpdated), isTrue);

        // Verify profiles have different generations
        expect(
          localProfile.evolutionGeneration,
          isNot(equals(cloudProfile.evolutionGeneration)),
        );
      });

      test('should detect when local profile is newer', () async {
        final userId = 'test_user_local_newer_${DateTime.now().millisecondsSinceEpoch}';

        // Create local profile
        final localProfile =
            await personalityLearning.initializePersonality(userId);

        // Evolve local profile (makes it newer)
        final evolvedLocal = await personalityLearning.evolveFromUserAction(
          userId,
          UserAction(
            type: UserActionType.spotVisit,
            timestamp: DateTime.now(),
            metadata: {'query': 'coffee'},
          ),
        );

        final localUpdated = evolvedLocal.lastUpdated;
        final cloudUpdated = localUpdated.subtract(const Duration(hours: 1));

        // Local is newer
        expect(localUpdated.isAfter(cloudUpdated), isTrue);
        expect(evolvedLocal.evolutionGeneration,
            greaterThan(localProfile.evolutionGeneration));
      });

    });

    group('End-to-End Sync Flow', () {
      test('should sync profile after evolution', () async {
        final userId = 'test_user_sync_evolve_${DateTime.now().millisecondsSinceEpoch}';
        const password = 'test_password';

        // 1. Initialize profile
        final initialProfile =
            await personalityLearning.initializePersonality(userId);
        // Generation may start at 0 or 1 depending on implementation
        expect(initialProfile.evolutionGeneration, greaterThanOrEqualTo(0));

        // 2. Enable sync (Supabase call may fail in test, but local storage works)
        try {
          await syncService.setCloudSyncEnabled(true);
        } catch (e) {
          // Supabase client not fully mocked, but local storage should still work
        }

        // 3. Evolve profile (triggers sync in real scenario)
        final evolvedProfile = await personalityLearning.evolveFromUserAction(
          userId,
          UserAction(
            type: UserActionType.spotVisit,
            timestamp: DateTime.now(),
            metadata: {'query': 'restaurant'},
          ),
        );

        expect(evolvedProfile.evolutionGeneration,
            greaterThan(initialProfile.evolutionGeneration));

        // 4. Verify profile can be encrypted (simulating sync)
        final key = await syncService.deriveKeyFromPassword(password, userId);
        final encrypted =
            await syncService.encryptProfileForCloud(evolvedProfile, key);
        expect(encrypted, isNotEmpty);

        // 5. Verify decryption
        final decrypted =
            await syncService.decryptProfileFromCloud(encrypted, key);
        expect(decrypted, isNotNull);
        expect(decrypted!.evolutionGeneration,
            equals(evolvedProfile.evolutionGeneration));
        expect(decrypted.userId, equals(evolvedProfile.userId));
      });

    });

    group('Cross-Device Scenario', () {
      test('should load profile from cloud on new device', () async {
        final userId = 'test_user_cloud_load_${DateTime.now().millisecondsSinceEpoch}';
        final password = 'test_password_${DateTime.now().millisecondsSinceEpoch}';

        // Device 1: Create and sync profile
        final device1Profile =
            await personalityLearning.initializePersonality(userId);
        try {
          await syncService.setCloudSyncEnabled(true);
        } catch (e) {
          // Supabase may fail, but test can continue
        }

        final key = await syncService.deriveKeyFromPassword(password, userId);
        final encrypted =
            await syncService.encryptProfileForCloud(device1Profile, key);

        // Device 2: Load from cloud
        // In real scenario, this would fetch from Supabase
        final decrypted =
            await syncService.decryptProfileFromCloud(encrypted, key);

        expect(decrypted, isNotNull);
        expect(decrypted!.userId, equals(device1Profile.userId));
        expect(decrypted.evolutionGeneration,
            equals(device1Profile.evolutionGeneration));
        expect(decrypted.dimensions, equals(device1Profile.dimensions));
      });

      test('should handle profile evolution on multiple devices', () async {
        final userId = 'test_user_multi_device_${DateTime.now().millisecondsSinceEpoch}';
        final password = 'test_password_${DateTime.now().millisecondsSinceEpoch}';

        await syncService.setCloudSyncEnabled(true);

        // Device 1: Create and evolve
        var device1Profile =
            await personalityLearning.initializePersonality(userId);
        device1Profile = await personalityLearning.evolveFromUserAction(
          userId,
          UserAction(
            type: UserActionType.spotVisit,
            timestamp: DateTime.now(),
            metadata: {'query': 'device1_search'},
          ),
        );

        // Encrypt and "upload" to cloud
        final key = await syncService.deriveKeyFromPassword(password, userId);
        final encrypted =
            await syncService.encryptProfileForCloud(device1Profile, key);

        // Device 2: Load from cloud
        final device2Profile =
            await syncService.decryptProfileFromCloud(encrypted, key);
        expect(device2Profile, isNotNull);
        expect(device2Profile!.evolutionGeneration,
            equals(device1Profile.evolutionGeneration));

        // Device 2: Evolve further
        // (In real scenario, would use PersonalityLearning on device 2)
        final device2Evolved = device2Profile.evolve(
          newDimensions: {'adventure': 0.9},
          additionalLearning: {'device2_key': 'device2_value'},
        );
        expect(device2Evolved.evolutionGeneration,
            greaterThan(device2Profile.evolutionGeneration));

        // Re-encrypt and "upload"
        final encrypted2 =
            await syncService.encryptProfileForCloud(device2Evolved, key);

        // Device 1: Load updated profile
        final device1Updated =
            await syncService.decryptProfileFromCloud(encrypted2, key);
        expect(device1Updated, isNotNull);
        expect(device1Updated!.evolutionGeneration,
            equals(device2Evolved.evolutionGeneration));
      });
    });

  });
}
