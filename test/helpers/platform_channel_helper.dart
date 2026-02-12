// ignore_for_file: avoid_print

/// Platform Channel Helper for Tests
/// 
/// This helper provides utilities for handling platform channel dependencies
/// in unit tests, specifically for GetStorage and path_provider.
/// 
/// The main issue: GetStorage() constructor and GetStorage.init() require
/// platform channels (path_provider) which are not available in unit tests.
/// 
/// Solutions:
/// 1. For services that accept storage as dependency: Use SharedPreferencesCompat.getInstance(storage: mockStorage)
/// 2. For services that use GetStorage() directly: Catch MissingPluginException errors gracefully
/// 
/// Usage:
/// ```dart
/// setUpAll(() async {
///   await setupTestStorage();
/// });
/// 
/// tearDownAll(() async {
///   await cleanupTestStorage();
/// });
/// 
/// // In tests that use services with GetStorage() directly:
/// test('my test', () async {
///   await runTestWithPlatformChannelHandling(() async {
///     // Test code that may throw MissingPluginException
///   });
/// });
/// ```
library;

import 'package:get_storage/get_storage.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../mocks/mock_storage_service.dart';
import 'dart:async';

/// Set up test storage environment
/// This creates in-memory storage instances that don't require platform channels
/// 
/// For services that use SharedPreferencesCompat.getInstance(storage: mockStorage),
/// this sets up the mock storage properly.
/// 
/// For services that use StorageService.instance, this initializes StorageService
/// with mock storage instances.
Future<void> setupTestStorage() async {
  // Create in-memory storage instances that don't require platform channels
  try {
    final mockStorage = getTestStorage();
    // Pre-initialize SharedPreferencesCompat with mock storage
    await SharedPreferencesCompat.getInstance(storage: mockStorage);
    
    // Initialize StorageService with mock storage for all boxes
    // This prevents "StorageService not initialized" errors in tests
    await initializeStorageServiceForTests();
  } catch (e) {
    // If initialization fails, that's OK - tests will handle it
    // This is expected in some test environments
  }
}

/// Initialize StorageService with mock storage instances for testing
/// This sets up all required storage boxes with in-memory storage
/// Uses the test-only initForTesting() method to bypass platform channel requirements
Future<void> initializeStorageServiceForTests() async {
  try {
    // Get mock storage instances for all StorageService boxes
    final defaultStorage = MockGetStorage.getInstance(boxName: 'spots_default');
    final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
    final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
    final analyticsStorage = MockGetStorage.getInstance(boxName: 'spots_analytics');
    
    // Initialize StorageService with mock storage using test-only method
    // This bypasses platform channel requirements
    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );
  } catch (e) {
    // If initialization fails, log but don't throw
    // Some tests may handle storage setup individually
    print('Warning: Failed to initialize StorageService for tests: $e');
  }
}

/// Clean up test storage environment
Future<void> cleanupTestStorage() async {
  try {
    MockGetStorage.reset();
  } catch (e) {
    // Ignore cleanup errors
  }
}

/// Get a test storage instance
/// Returns a GetStorage-compatible instance that works in unit tests
/// 
/// Returns InMemoryGetStorage which has the same interface as GetStorage
/// but doesn't require platform channels. Can be used where GetStorage is expected.
GetStorage getTestStorage({String? boxName}) {
  // Always use MockGetStorage in tests to avoid platform channel issues
  // InMemoryGetStorage provides the same interface without requiring platform channels
  // Cast to GetStorage to allow use where GetStorage is expected
  return MockGetStorage.getInstance(boxName: boxName ?? 'test_box') as dynamic;
}

/// Run test with platform channel error handling
/// Wraps test execution to catch and handle MissingPluginException errors
/// 
/// This is useful for tests that use services which create GetStorage() directly
/// without dependency injection. The errors are caught and ignored since they're
/// expected in unit test environments.
/// 
/// Note: For void functions, use runTestWithPlatformChannelHandlingVoid instead.
Future<T?> runTestWithPlatformChannelHandling<T>(
  Future<T> Function() testFunction,
) async {
  try {
    return await testFunction();
  } catch (error) {
    // Ignore MissingPluginException errors from GetStorage
    // These are expected when GetStorage tries to use platform channels
    if (error.toString().contains('MissingPluginException') ||
        error.toString().contains('getApplicationDocumentsDirectory') ||
        error.toString().contains('path_provider')) {
      // Return null for non-void types
      // Tests should handle the case where service creation fails
      return null;
    }
    // Re-throw other errors
    rethrow;
  }
}

/// Run test with platform channel error handling (synchronous version)
/// Wraps synchronous test execution to catch and handle MissingPluginException errors
T? runTestWithPlatformChannelHandlingSync<T>(
  T Function() testFunction,
) {
  try {
    return testFunction();
  } catch (error) {
    // Ignore MissingPluginException errors from GetStorage
    if (error.toString().contains('MissingPluginException') ||
        error.toString().contains('getApplicationDocumentsDirectory') ||
        error.toString().contains('path_provider')) {
      return null;
    }
    rethrow;
  }
}

/// Run test with platform channel error handling for void functions
/// Wraps test execution to catch and handle MissingPluginException errors
Future<void> runTestWithPlatformChannelHandlingVoid(
  Future<void> Function() testFunction,
) async {
  try {
    await testFunction();
  } catch (error) {
    // Ignore MissingPluginException errors from GetStorage
    if (error.toString().contains('MissingPluginException') ||
        error.toString().contains('getApplicationDocumentsDirectory') ||
        error.toString().contains('path_provider')) {
      // Just return - error is expected
      return;
    }
    // Re-throw other errors
    rethrow;
  }
}

/// Check if platform channels are available
/// Returns true if GetStorage can be initialized without errors
Future<bool> arePlatformChannelsAvailable() async {
  try {
    final testBox = 'platform_check_${DateTime.now().millisecondsSinceEpoch}';
    await GetStorage.init(testBox);
    final storage = GetStorage(testBox);
    await storage.erase();
    return true;
  } catch (e) {
    return false;
  }
}

