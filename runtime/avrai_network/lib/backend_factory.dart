import 'interfaces/backend_interface.dart';
import 'models/connection_config.dart';
import 'backends/supabase/supabase_module.dart';

/// Factory for creating backend instances
/// Supports Firebase, Supabase, and Custom backends
class BackendFactory {
  static BackendInterface? _instance;

  /// Get the current backend instance
  static BackendInterface? get instance => _instance;

  /// Create and initialize a backend
  static Future<BackendInterface> create(BackendConfig config) async {
    BackendInterface backend;

    switch (config.type) {
      case BackendType.firebase:
        backend = await _createFirebaseBackend(config);
        break;
      case BackendType.supabase:
        backend = await _createSupabaseBackend(config);
        break;
      case BackendType.custom:
        backend = await _createCustomBackend(config);
        break;
    }

    // Pass the config map directly, not the serialized BackendConfig object
    await backend.initialize(config.config);
    _instance = backend;
    return backend;
  }

  /// Create Firebase backend
  static Future<BackendInterface> _createFirebaseBackend(
    BackendConfig config,
  ) async {
    // Import Firebase backend implementation
    try {
      // Dynamic import to avoid dependency issues when not using Firebase
      final module = await _loadFirebaseModule();
      return module.createFirebaseBackend();
    } catch (e) {
      throw BackendInitializationException(
        'Failed to initialize Firebase backend: $e\n'
        'Make sure firebase_core and related packages are added to pubspec.yaml',
      );
    }
  }

  /// Create Supabase backend
  static Future<BackendInterface> _createSupabaseBackend(
    BackendConfig config,
  ) async {
    try {
      final module = await _loadSupabaseModule();
      return module.createSupabaseBackend();
    } catch (e) {
      throw BackendInitializationException(
        'Failed to initialize Supabase backend: $e\n'
        'Make sure supabase_flutter package is added to pubspec.yaml',
      );
    }
  }

  /// Create Custom backend
  static Future<BackendInterface> _createCustomBackend(
    BackendConfig config,
  ) async {
    try {
      final module = await _loadCustomModule();
      return module.createCustomBackend();
    } catch (e) {
      throw BackendInitializationException(
        'Failed to initialize Custom backend: $e\n'
        'Make sure your custom backend implementation is available',
      );
    }
  }

  /// Switch to a different backend
  static Future<BackendInterface> switchBackend(BackendConfig newConfig) async {
    // Dispose current backend
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }

    // Create new backend
    return await create(newConfig);
  }

  /// Dispose current backend
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }
  }

  /// Reset factory state (for testing)
  static void reset() {
    _instance = null;
  }

  // Dynamic module loading
  static Future<FirebaseModule> _loadFirebaseModule() async {
    throw UnimplementedError('Firebase module not yet implemented');
  }

  static Future<SupabaseModule> _loadSupabaseModule() async {
    try {
      // Import Supabase module
      final module = SupabaseModule();
      return module;
    } catch (e) {
      throw BackendInitializationException(
        'Failed to load Supabase module: $e\n'
        'Make sure supabase_flutter package is added to pubspec.yaml',
      );
    }
  }

  static Future<CustomModule> _loadCustomModule() async {
    throw UnimplementedError('Custom module not yet implemented');
  }
}

/// Exception thrown when backend initialization fails
class BackendInitializationException implements Exception {
  final String message;
  const BackendInitializationException(this.message);

  @override
  String toString() => 'BackendInitializationException: $message';
}

/// Module interfaces for dynamic loading
abstract class FirebaseModule {
  BackendInterface createFirebaseBackend();
}

// Use concrete SupabaseModule from backends/supabase/supabase_module.dart

abstract class CustomModule {
  BackendInterface createCustomBackend();
}
