import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../mocks/mock_storage_service.dart';

/// Test storage helper for initializing GetStorage in tests
///
/// Uses in-memory MockGetStorage to avoid platform channel (path_provider)
/// requirements in VM-based flutter test runs.
///
/// Usage:
/// ```dart
/// setUp(() async {
///   await TestStorageHelper.initTestStorage();
/// });
///
/// tearDown(() async {
///   await TestStorageHelper.clearTestStorage();
/// });
///
/// // Tests that need direct box access:
/// final box = TestStorageHelper.getBox('tax_profiles');
/// ```
class TestStorageHelper {
  static bool _initialized = false;
  static bool _pathProviderMocked = false;
  static const MethodChannel _pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  /// All GetStorage box names used by services
  ///
  /// This list must be kept in sync with the boxes initialized in main.dart
  /// and used by services throughout the application.
  static const List<String> _boxNames = [
    // Chat services
    'personality_chat',
    'business_expert_messages',
    'business_expert_conversations',
    'business_business_messages',
    'business_business_conversations',
    'community_chat',
    'friend_chat',
    'friend_chat_outbox',
    'delivered_ai2ai_messages',
    // Onboarding and user data
    'onboarding_data',
    'onboarding_completion',
    'onboarding_suggestion_events',
    'users_data',
    'agent_ids',
    // AI/ML services
    'language_patterns',
    'local_llm_bootstrap',
    'visit_patterns',
    'decoherence_patterns',
    // Tax services
    'tax_profiles',
    'tax_documents',
    // Cache services
    'apple_places_cache',
    'google_places_cache',
    'google_places_details',
    'search_results',
    'popular_queries',
    'offline_cache',
    // Other services
    'permissions_persistence',
    'connection_orchestrator',
  ];

  /// Initialize all storage boxes used by tests (in-memory, no platform channel).
  ///
  /// Call this in setUp() before running tests that use GetStorage-backed services.
  /// Uses MockGetStorage so VM-based tests do not hit MissingPluginException.
  static Future<void> initTestStorage() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    if (!_pathProviderMocked) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel,
              (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
          case 'getLibraryDirectory':
          case 'getExternalStorageDirectory':
            return '/tmp';
          case 'getExternalStorageDirectories':
            return <String>['/tmp'];
          default:
            return '/tmp';
        }
      });
      _pathProviderMocked = true;
    }

    for (final name in _boxNames) {
      MockGetStorage.getInstance(boxName: name);
    }

    _initialized = true;
  }

  /// Clear all test storage and reset mock instances.
  ///
  /// Call this in tearDown() to clean up between tests.
  static Future<void> clearTestStorage() async {
    MockGetStorage.reset();
    _initialized = false;
  }

  /// Return the GetStorage-compatible instance for [name].
  ///
  /// Only valid after [initTestStorage] has been called. Use in tests that need
  /// direct box access (e.g. to erase or assert contents).
  static GetStorage getBox(String name) {
    return MockGetStorage.getInstance(boxName: name);
  }

  /// Reset initialization flag (for test isolation).
  static void reset() {
    _initialized = false;
  }

  /// Get the list of box names (for debugging).
  static List<String> get boxNames => List.unmodifiable(_boxNames);
}
