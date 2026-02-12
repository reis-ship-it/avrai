import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory FlutterSecureStorage implementation for testing
/// 
/// Implements the same interface as FlutterSecureStorage without requiring
/// platform channels. This allows tests to run reliably in all environments
/// (CI, local, different platforms) without MissingPluginException errors.
/// 
/// **Usage:**
/// ```dart
/// final secureStorage = InMemoryFlutterSecureStorage();
/// await secureStorage.write(key: 'test', value: 'data');
/// final value = await secureStorage.read(key: 'test');
/// ```
/// 
/// **Benefits:**
/// - No platform channel dependencies
/// - Works in all test environments
/// - Same interface as production FlutterSecureStorage
/// - No complex mock setup required
class InMemoryFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return Map<String, String>.from(_storage);
  }

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async {
    return true; // Always available in tests
  }

  @override
  void registerListener({
    required String key,
    required void Function(String?) listener,
  }) {
    // No-op in tests
  }

  @override
  void unregisterListener({
    required String key,
    required void Function(String?) listener,
  }) {
    // No-op in tests
  }

  @override
  void unregisterAllListeners() {
    // No-op in tests
  }

  @override
  void unregisterAllListenersForKey({required String key}) {
    // No-op in tests
  }

  @override
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  Map<String, List<void Function(String?)>> get getListeners => {};

  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged => 
      Stream<bool>.value(true); // Always available in tests

  /// Direct access to storage map (for testing/debugging)
  /// Returns an unmodifiable view of the storage
  Map<String, String> get storage => Map.unmodifiable(_storage);

  /// Clear all stored data (convenience method)
  void clear() {
    _storage.clear();
  }
}
