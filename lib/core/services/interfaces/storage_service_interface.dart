import 'package:get_storage/get_storage.dart';

/// Storage Service Interface
///
/// Defines the contract for storage operations in the application.
/// This interface allows for easier testing and potential future implementation swapping.
///
/// **Usage:**
/// Services should depend on `IStorageService` instead of `StorageService`
/// for better testability and reduced coupling.
abstract class IStorageService {
  /// Initialize storage boxes
  Future<void> init();

  /// Test-only initialization with mock storage
  /// This bypasses platform channel requirements by accepting mock storage instances
  Future<void> initForTesting({
    required GetStorage defaultStorage,
    required GetStorage userStorage,
    required GetStorage aiStorage,
    required GetStorage analyticsStorage,
  });

  /// Get storage instance for default context
  GetStorage get defaultStorage;

  /// Get storage instance for user context
  GetStorage get userStorage;

  /// Get storage instance for AI context
  GetStorage get aiStorage;

  /// Get storage instance for analytics context
  GetStorage get analyticsStorage;

  // String operations
  Future<bool> setString(String key, String value,
      {String box = 'spots_default'});
  String? getString(String key, {String box = 'spots_default'});

  // Bool operations
  Future<bool> setBool(String key, bool value, {String box = 'spots_default'});
  bool? getBool(String key, {String box = 'spots_default'});

  // Int operations
  Future<bool> setInt(String key, int value, {String box = 'spots_default'});
  int? getInt(String key, {String box = 'spots_default'});

  // Double operations
  Future<bool> setDouble(String key, double value,
      {String box = 'spots_default'});
  double? getDouble(String key, {String box = 'spots_default'});

  // List operations
  Future<bool> setStringList(String key, List<String> value,
      {String box = 'spots_default'});
  List<String>? getStringList(String key, {String box = 'spots_default'});

  // Generic operations
  Future<bool> setObject(String key, dynamic value,
      {String box = 'spots_default'});
  T? getObject<T>(String key, {String box = 'spots_default'});

  // Remove operations
  Future<bool> remove(String key, {String box = 'spots_default'});
  Future<bool> clear({String box = 'spots_default'});

  // Check if key exists
  bool containsKey(String key, {String box = 'spots_default'});

  // Get all keys
  List<String> getKeys({String box = 'spots_default'});
}
