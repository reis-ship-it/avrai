import 'package:get_it/get_it.dart';

/// Small helper to reduce duplicated GetIt setup/teardown code in tests.
///
/// Why this exists:
/// - Many tests register/unregister the same services repeatedly
/// - Boilerplate `if (GetIt.instance.isRegistered<T>()) { unregister<T>(); }` is noisy
/// - Centralizing the pattern makes tests easier to read and less error-prone
///
/// Note:
/// - This is a **test-only** utility.
/// - It does not attempt to "reset everything" (which can break unrelated tests).
class GetItTestHarness {
  final GetIt sl;

  GetItTestHarness({GetIt? sl}) : sl = sl ?? GetIt.instance;

  /// Unregister `T` if currently registered.
  void unregisterIfRegistered<T extends Object>() {
    if (sl.isRegistered<T>()) {
      sl.unregister<T>();
    }
  }

  /// Register a singleton, replacing any existing registration for `T`.
  void registerSingletonReplace<T extends Object>(T instance) {
    unregisterIfRegistered<T>();
    sl.registerSingleton<T>(instance);
  }

  /// Register a lazy singleton, replacing any existing registration for `T`.
  void registerLazySingletonReplace<T extends Object>(T Function() factory) {
    unregisterIfRegistered<T>();
    sl.registerLazySingleton<T>(factory);
  }
}

