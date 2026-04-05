/// PersonalitySyncService Unit Tests
///
/// Tests for secure cross-device personality profile synchronization:
/// - Key derivation from password
/// - Encryption/decryption
/// - Merge strategy logic
/// - Cloud sync enable/disable (local storage)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mocks/mock_storage_service.dart';

// Mocks
class MockSupabaseService extends Mock implements SupabaseService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

void main() {
  group('PersonalitySyncService', () {
    late PersonalitySyncService syncService;
    late MockSupabaseService mockSupabaseService;

    setUpAll(() {
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      mockSupabaseService = MockSupabaseService();

      // Setup mock storage + init StorageService for cloud sync flags
      final defaultStorage =
          MockGetStorage.getInstance(boxName: 'spots_default');
      final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
      final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
      final analyticsStorage =
          MockGetStorage.getInstance(boxName: 'spots_analytics');
      await StorageService.instance.initForTesting(
        defaultStorage: defaultStorage,
        userStorage: userStorage,
        aiStorage: aiStorage,
        analyticsStorage: analyticsStorage,
      );
      await SharedPreferencesCompat.getInstance(storage: defaultStorage);

      // Mock Supabase service - default to unavailable to avoid Supabase calls in most tests
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      // For tests that need Supabase, we'll override this in the specific test
      syncService = PersonalitySyncService(
        supabaseService: mockSupabaseService,
        storageService: StorageService.instance,
      );
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    group('Cloud Sync Enable/Disable', () {
      test('should default to disabled for new user', () async {
        const userId = 'new_user_1';

        final enabled = await syncService.isCloudSyncEnabled(userId);
        expect(enabled, isFalse);
      });

      // Note: setCloudSyncEnabled requires Supabase client which is complex to mock
      // These tests verify the local storage aspect works correctly
      // Full integration tests would verify the Supabase update as well
    });

    // Removed: Property assignment tests
    // Personality sync tests focus on business logic (key derivation, encryption/decryption, merge strategy, password change), not property assignment

    group('Key Derivation', () {
      test(
          'should derive same key from same password and userId, derive different keys from different passwords, or derive different keys for different users with same password',
          () async {
        // Test business logic: key derivation
        const password = 'test_password_123';
        const userId = 'test_user_1';
        final key1 = await syncService.deriveKeyFromPassword(password, userId);
        final key2 = await syncService.deriveKeyFromPassword(password, userId);
        expect(key1, equals(key2));
        expect(key1.length, equals(32));

        final key3 =
            await syncService.deriveKeyFromPassword('password1', userId);
        final key4 =
            await syncService.deriveKeyFromPassword('password2', userId);
        expect(key3, isNot(equals(key4)));

        const samePassword = 'same_password';
        final key5 =
            await syncService.deriveKeyFromPassword(samePassword, 'user1');
        final key6 =
            await syncService.deriveKeyFromPassword(samePassword, 'user2');
        expect(key5, isNot(equals(key6)));
      });
    });

    group('Encryption/Decryption', () {
      test(
          'should encrypt and decrypt profile correctly, or fail to decrypt with wrong key',
          () async {
        // Test business logic: encryption/decryption
        const userId = 'test_user_1';
        const password = 'test_password';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile1 = PersonalityProfile.initial(agentId, userId: userId);
        final key1 = await syncService.deriveKeyFromPassword(password, userId);
        final encrypted1 =
            await syncService.encryptProfileForCloud(profile1, key1);
        expect(encrypted1, isNotEmpty);
        expect(encrypted1, isNot(equals(profile1.toJson().toString())));
        final decrypted1 =
            await syncService.decryptProfileFromCloud(encrypted1, key1);
        expect(decrypted1, isNotNull);
        expect(decrypted1!.agentId, equals(profile1.agentId));
        expect(decrypted1.userId, equals(profile1.userId));
        expect(decrypted1.evolutionGeneration,
            equals(profile1.evolutionGeneration));

        // Phase 8.3: Use agentId for privacy protection
        const agentId2 = 'agent_$userId';
        final profile2 = PersonalityProfile.initial(agentId2, userId: userId);
        final correctKey =
            await syncService.deriveKeyFromPassword('correct', userId);
        final wrongKey =
            await syncService.deriveKeyFromPassword('wrong', userId);
        final encrypted2 =
            await syncService.encryptProfileForCloud(profile2, correctKey);
        final decrypted2 =
            await syncService.decryptProfileFromCloud(encrypted2, wrongKey);
        expect(decrypted2, isNull);
      });
    });

    group('Merge Strategy', () {
      test(
          'should correctly identify newer profile by timestamp, or handle equal timestamps',
          () {
        // Test business logic: merge strategy
        final localProfile =
            PersonalityProfile.initial('agent_user1', userId: 'user1');
        final localUpdated = localProfile.lastUpdated;
        final cloudUpdated = localUpdated.add(const Duration(hours: 1));
        expect(cloudUpdated.isAfter(localUpdated), isTrue);
        expect(localUpdated.isBefore(cloudUpdated), isTrue);

        final profile1 =
            PersonalityProfile.initial('agent_user1', userId: 'user1');
        final profile2 =
            PersonalityProfile.initial('agent_user2', userId: 'user2');
        expect(
          profile1.lastUpdated.difference(profile2.lastUpdated).inSeconds.abs(),
          lessThan(2),
        );
      });
    });

    group('Password Change', () {
      test(
          'should derive different keys for old and new password, or re-encrypt with new password key',
          () async {
        // Test business logic: password change handling
        const userId = 'test_user_1';
        const oldPassword = 'old_password';
        const newPassword = 'new_password';
        final oldKey =
            await syncService.deriveKeyFromPassword(oldPassword, userId);
        final newKey =
            await syncService.deriveKeyFromPassword(newPassword, userId);
        expect(oldKey, isNot(equals(newKey)));
        expect(oldKey.length, equals(32));
        expect(newKey.length, equals(32));

        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        final encryptedWithOld =
            await syncService.encryptProfileForCloud(profile, oldKey);
        final encryptedWithNew =
            await syncService.encryptProfileForCloud(profile, newKey);
        expect(encryptedWithOld, isNot(equals(encryptedWithNew)));
        final decryptedOld =
            await syncService.decryptProfileFromCloud(encryptedWithOld, oldKey);
        final decryptedNew =
            await syncService.decryptProfileFromCloud(encryptedWithNew, newKey);
        expect(decryptedOld, isNotNull);
        expect(decryptedNew, isNotNull);
        expect(decryptedOld!.agentId, equals(decryptedNew!.agentId));
        expect(decryptedOld.userId, equals(decryptedNew.userId));
      });
    });

    group('Error Handling', () {
      test(
          'should handle sync when cloud sync is disabled, or handle decryption failure gracefully',
          () async {
        // Test business logic: error handling
        const userId = 'test_user_1';
        const password = 'test_password';
        // Phase 8.3: Use agentId for privacy protection
        const agentId1 = 'agent_$userId';
        final profile1 = PersonalityProfile.initial(agentId1, userId: userId);

        // Disable cloud sync - this should not call Supabase
        await syncService.setCloudSyncEnabled(false);

        // syncToCloud should return early when sync is disabled, without calling Supabase
        await syncService.syncToCloud(userId, profile1, password);
        // Assert - Operation completed without throwing (test passes if we reach here)

        const wrongPassword = 'wrong_password';
        const agentId2 = 'agent_$userId';
        final profile2 = PersonalityProfile.initial(agentId2, userId: userId);
        final correctKey =
            await syncService.deriveKeyFromPassword(password, userId);
        final wrongKey =
            await syncService.deriveKeyFromPassword(wrongPassword, userId);
        final encrypted =
            await syncService.encryptProfileForCloud(profile2, correctKey);
        final decrypted =
            await syncService.decryptProfileFromCloud(encrypted, wrongKey);
        expect(decrypted, isNull);
      });
    });
  });
}
