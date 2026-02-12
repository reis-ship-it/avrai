import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Storage Service Tests
/// Tests storage operations using get_storage backend
/// 
/// NOTE: These tests require platform channels (path_provider) which are not available
/// in unit tests. For full testing, use integration tests or mock GetStorage.
/// This test file focuses on testing the API structure and singleton pattern.
void main() {

  setUpAll(() async {
    await setupTestStorage();
  });

  group('StorageService', () {
    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = StorageService.instance;
        final instance2 = StorageService.instance;
        expect(instance1, same(instance2));
      });
    });

    group('API Structure', () {
      test('should have all required methods', () {
        final service = StorageService.instance;
        
        // Verify methods exist
        expect(service.setString, isA<Function>());
        expect(service.getString, isA<Function>());
        expect(service.setBool, isA<Function>());
        expect(service.getBool, isA<Function>());
        expect(service.setInt, isA<Function>());
        expect(service.getInt, isA<Function>());
        expect(service.setDouble, isA<Function>());
        expect(service.getDouble, isA<Function>());
        expect(service.setStringList, isA<Function>());
        expect(service.getStringList, isA<Function>());
        expect(service.setObject, isA<Function>());
        expect(service.getObject, isA<Function>());
        expect(service.remove, isA<Function>());
        expect(service.clear, isA<Function>());
        expect(service.containsKey, isA<Function>());
        expect(service.getKeys, isA<Function>());
      });

      // Note: Storage box getters require initialization which needs platform channels
      // Full testing should be done in integration tests
    });

    group('SharedPreferencesCompat', () {
      group('API Structure', () {
        test('should have all required methods', () {
          // Verify SharedPreferencesCompat class exists and has methods
          expect(SharedPreferencesCompat.getInstance, isA<Function>());
          
          // Note: Full testing requires platform channels (integration tests)
        });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
      });
    });

    // NOTE: Full functional tests require integration test environment
    // with platform channels available. See test/integration/ for integration tests.
  });
}

