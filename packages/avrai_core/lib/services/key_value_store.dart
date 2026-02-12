/// Minimal, package-safe key/value storage abstraction.
///
/// This lives in `spots_core` so non-app packages can persist state without
/// depending on the app's concrete `StorageService` implementation.
abstract class SpotsKeyValueStore {
  Future<bool> setObject(
    String key,
    Object? value, {
    String box = 'spots_default',
  });

  T? getObject<T>(
    String key, {
    String box = 'spots_default',
  });

  Future<bool> remove(
    String key, {
    String box = 'spots_default',
  });

  bool containsKey(
    String key, {
    String box = 'spots_default',
  });

  List<String> getKeys({
    String box = 'spots_default',
  });
}

