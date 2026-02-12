import 'interfaces/backend_interface.dart';
import 'models/connection_config.dart';
import 'backend_factory.dart';

/// Factory for creating component-specific backend instances
/// Allows different components to use different backends based on their needs
class ComponentBackendFactory {
  static final Map<String, BackendInterface> _instances = {};
  
  /// Get backend for specific component
  static BackendInterface? getComponentBackend(String componentName) {
    return _instances[componentName];
  }
  
  /// Create backend for specific component
  static Future<BackendInterface> createForComponent(
    String componentName,
    BackendConfig config,
  ) async {
    // Dispose existing backend for this component
    await disposeComponent(componentName);
    
    // Create new backend
    final backend = await BackendFactory.create(config);
    _instances[componentName] = backend;
    
    return backend;
  }
  
  /// Dispose backend for specific component
  static Future<void> disposeComponent(String componentName) async {
    final backend = _instances[componentName];
    if (backend != null) {
      await backend.dispose();
      _instances.remove(componentName);
    }
  }
  
  /// Dispose all component backends
  static Future<void> disposeAll() async {
    for (final backend in _instances.values) {
      await backend.dispose();
    }
    _instances.clear();
  }
  
  /// Get all active component backends
  static Map<String, BackendInterface> get allInstances => Map.unmodifiable(_instances);
  
  /// Check if component has backend
  static bool hasComponentBackend(String componentName) {
    return _instances.containsKey(componentName);
  }
  
  /// Health check for all component backends
  static Future<Map<String, bool>> healthCheckAll() async {
    final results = <String, bool>{};
    
    for (final entry in _instances.entries) {
      try {
        final isHealthy = await entry.value.healthCheck();
        results[entry.key] = isHealthy;
      } catch (e) {
        results[entry.key] = false;
      }
    }
    
    return results;
  }
}

/// Predefined component names for consistency
class ComponentNames {
  static const String authentication = 'authentication';
  static const String ai2ai = 'ai2ai';
  static const String dataStorage = 'data_storage';
  static const String fileUpload = 'file_upload';
  static const String analytics = 'analytics';
  static const String notifications = 'notifications';
  static const String realtime = 'realtime';
  static const String ml = 'ml';
}

/// Component-specific backend configurations
class ComponentBackendConfigs {
  /// Authentication component - Supabase (privacy-focused)
  static BackendConfig get authentication => BackendConfig.supabase(
    url: 'https://your-auth.supabase.co',
    anonKey: 'your-auth-anon-key',
    name: 'Auth Backend',
  );
  
  /// AI2AI component - Firebase (best real-time)
  static BackendConfig get ai2ai => BackendConfig.firebase(
    projectId: 'your-ai2ai-project',
    apiKey: 'your-ai2ai-api-key',
    appId: 'your-ai2ai-app-id',
    name: 'AI2AI Backend',
  );
  
  /// Data Storage component - Custom API (full control)
  static BackendConfig get dataStorage => BackendConfig.custom(
    baseUrl: 'https://your-data-api.com',
    apiKey: 'your-data-api-key',
    name: 'Data Storage Backend',
  );
  
  /// File Upload component - Supabase (built-in storage)
  static BackendConfig get fileUpload => BackendConfig.supabase(
    url: 'https://your-storage.supabase.co',
    anonKey: 'your-storage-anon-key',
    name: 'File Upload Backend',
  );
  
  /// Analytics component - Firebase (best analytics)
  static BackendConfig get analytics => BackendConfig.firebase(
    projectId: 'your-analytics-project',
    apiKey: 'your-analytics-api-key',
    appId: 'your-analytics-app-id',
    name: 'Analytics Backend',
  );
  
  /// Notifications component - Firebase (native mobile)
  static BackendConfig get notifications => BackendConfig.firebase(
    projectId: 'your-notifications-project',
    apiKey: 'your-notifications-api-key',
    appId: 'your-notifications-app-id',
    name: 'Notifications Backend',
  );
}
