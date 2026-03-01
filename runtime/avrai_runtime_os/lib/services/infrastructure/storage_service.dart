import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_core/services/key_value_store.dart';

/// Storage service that provides a compatible interface for get_storage
/// This replaces SharedPreferences usage throughout the app
class StorageService implements IStorageService, SpotsKeyValueStore {
  static const String _defaultBox = 'spots_default';
  static const String _userBox = 'spots_user';
  static const String _aiBox = 'spots_ai';
  static const String _analyticsBox = 'spots_analytics';

  GetStorage? _defaultStorage;
  GetStorage? _userStorage;
  GetStorage? _aiStorage;
  GetStorage? _analyticsStorage;
  bool _initialized = false;

  static StorageService? _instance;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize storage boxes
  @override
  Future<void> init() async {
    if (_initialized) return; // Already initialized

    await GetStorage.init(_defaultBox);
    await GetStorage.init(_userBox);
    await GetStorage.init(_aiBox);
    await GetStorage.init(_analyticsBox);

    _defaultStorage = GetStorage(_defaultBox);
    _userStorage = GetStorage(_userBox);
    _aiStorage = GetStorage(_aiBox);
    _analyticsStorage = GetStorage(_analyticsBox);
    _initialized = true;
  }

  /// Test-only initialization with mock storage
  /// This bypasses platform channel requirements by accepting mock storage instances
  ///
  /// Use this in tests to initialize StorageService without requiring platform channels.
  /// The mock storage instances should be created using MockGetStorage.getInstance().
  ///
  /// Example:
  /// ```dart
  /// setUpAll(() async {
  ///   await StorageService.instance.initForTesting(
  ///     defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
  ///     userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
  ///     aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
  ///     analyticsStorage: MockGetStorage.getInstance(boxName: 'spots_analytics'),
  ///   );
  /// });
  /// ```
  @override
  Future<void> initForTesting({
    required GetStorage defaultStorage,
    required GetStorage userStorage,
    required GetStorage aiStorage,
    required GetStorage analyticsStorage,
  }) async {
    if (_initialized) return; // Already initialized

    // Set all storage instances from provided mocks
    _defaultStorage = defaultStorage;
    _userStorage = userStorage;
    _aiStorage = aiStorage;
    _analyticsStorage = analyticsStorage;
    _initialized = true;
  }

  /// Static method to get a SharedPreferencesCompat instance for backward compatibility
  static Future<SharedPreferencesCompat> getInstance() async {
    await instance.init();
    return SharedPreferencesCompat._(null);
  }

  /// Get storage instance for different contexts
  ///
  /// Throws StateError if storage is not initialized.
  /// In tests, ensure StorageService is initialized with mock storage.
  @override
  GetStorage get defaultStorage {
    if (!_initialized || _defaultStorage == null) {
      throw StateError(
          'Default storage not initialized. Call StorageService.instance.init() first. '
          'In tests, use mock storage via dependency injection.');
    }
    return _defaultStorage!;
  }

  @override
  GetStorage get userStorage {
    if (!_initialized || _userStorage == null) {
      throw StateError(
          'User storage not initialized. Call StorageService.instance.init() first. '
          'In tests, use mock storage via dependency injection.');
    }
    return _userStorage!;
  }

  @override
  GetStorage get aiStorage {
    if (!_initialized || _aiStorage == null) {
      throw StateError(
          'AI storage not initialized. Call StorageService.instance.init() first. '
          'In tests, use mock storage via dependency injection.');
    }
    return _aiStorage!;
  }

  @override
  GetStorage get analyticsStorage {
    if (!_initialized || _analyticsStorage == null) {
      throw StateError(
          'Analytics storage not initialized. Call StorageService.instance.init() first. '
          'In tests, use mock storage via dependency injection.');
    }
    return _analyticsStorage!;
  }

  // String operations
  @override
  Future<bool> setString(String key, String value,
      {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  String? getString(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<String>(key);
  }

  // Bool operations
  @override
  Future<bool> setBool(String key, bool value,
      {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  bool? getBool(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<bool>(key);
  }

  // Int operations
  @override
  Future<bool> setInt(String key, int value, {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  int? getInt(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<int>(key);
  }

  // Double operations
  @override
  Future<bool> setDouble(String key, double value,
      {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  double? getDouble(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<double>(key);
  }

  // List operations
  @override
  Future<bool> setStringList(String key, List<String> value,
      {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  List<String>? getStringList(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<List<String>>(key);
  }

  // Generic operations
  @override
  Future<bool> setObject(String key, dynamic value,
      {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.write(key, value);
    return true;
  }

  @override
  T? getObject<T>(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.read<T>(key);
  }

  // Remove operations
  @override
  Future<bool> remove(String key, {String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear({String box = _defaultBox}) async {
    final storage = _getStorageForBox(box);
    await storage.erase();
    return true;
  }

  // Check if key exists
  @override
  bool containsKey(String key, {String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.hasData(key);
  }

  // Get all keys
  @override
  List<String> getKeys({String box = _defaultBox}) {
    final storage = _getStorageForBox(box);
    return storage.getKeys().cast<String>();
  }

  GetStorage _getStorageForBox(String box) {
    // Ensure storage is initialized before use
    // In tests, this will throw MissingPluginException if not properly mocked
    if (!_initialized) {
      throw StateError(
          'StorageService not initialized. Call StorageService.instance.init() first. '
          'In tests, use mock storage via dependency injection.');
    }

    switch (box) {
      case _userBox:
        return _userStorage ??
            (throw StateError('User storage not initialized'));
      case _aiBox:
        return _aiStorage ?? (throw StateError('AI storage not initialized'));
      case _analyticsBox:
        return _analyticsStorage ??
            (throw StateError('Analytics storage not initialized'));
      case _defaultBox:
      default:
        return _defaultStorage ??
            (throw StateError('Default storage not initialized'));
    }
  }
}

/// Compatibility class that mimics SharedPreferences interface
/// This allows for easier migration of existing code
class SharedPreferencesCompat {
  final GetStorage? _testStorage;

  SharedPreferencesCompat._(this._testStorage);

  /// Get instance - accepts optional storage for testing
  static Future<SharedPreferencesCompat> getInstance(
      {GetStorage? storage}) async {
    if (storage != null) {
      // For testing: use provided storage instance
      return SharedPreferencesCompat._(storage);
    } else {
      // Normal initialization
      await StorageService.instance.init();
      return SharedPreferencesCompat._(null);
    }
  }

  /// Get the storage instance to use
  GetStorage get _storage {
    if (_testStorage != null) {
      return _testStorage;
    }
    return StorageService.instance.defaultStorage;
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    await _storage.write(key, value);
    return true;
  }

  String? getString(String key) {
    return _storage.read<String>(key);
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    await _storage.write(key, value);
    return true;
  }

  bool? getBool(String key) {
    return _storage.read<bool>(key);
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    await _storage.write(key, value);
    return true;
  }

  int? getInt(String key) {
    return _storage.read<int>(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    await _storage.write(key, value);
    return true;
  }

  double? getDouble(String key) {
    return _storage.read<double>(key);
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    await _storage.write(key, value);
    return true;
  }

  List<String>? getStringList(String key) {
    return _storage.read<List<String>>(key);
  }

  // Remove operations
  Future<bool> remove(String key) async {
    await _storage.remove(key);
    return true;
  }

  Future<bool> clear() async {
    await _storage.erase();
    return true;
  }

  // Check if key exists
  bool containsKey(String key) {
    return _storage.hasData(key);
  }

  // Get all keys
  Set<String> getKeys() {
    final keys = _storage.getKeys<List<String>>();
    return keys.toSet();
  }
}

// For backward compatibility, export SharedPreferencesCompat as SharedPreferences
typedef SharedPreferences = SharedPreferencesCompat;
