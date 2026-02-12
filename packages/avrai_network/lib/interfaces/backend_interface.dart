import 'auth_backend.dart';
import 'data_backend.dart';
import 'realtime_backend.dart';

/// Main backend interface that all backend implementations must implement
/// This provides a unified API for authentication, data operations, and real-time features
abstract class BackendInterface {
  /// Authentication backend
  AuthBackend get auth;
  
  /// Data operations backend
  DataBackend get data;
  
  /// Real-time operations backend
  RealtimeBackend get realtime;
  
  /// Initialize the backend with configuration
  Future<void> initialize(Map<String, dynamic> config);
  
  /// Check if the backend is initialized and ready
  bool get isInitialized;
  
  /// Get backend type identifier
  String get backendType;
  
  /// Get backend configuration
  Map<String, dynamic> get config;
  
  /// Dispose of resources
  Future<void> dispose();
  
  /// Health check - verify backend connectivity
  Future<bool> healthCheck();
  
  /// Get backend capabilities
  BackendCapabilities get capabilities;
}

/// Defines what features a backend supports
class BackendCapabilities {
  final bool supportsRealtimeUpdates;
  final bool supportsOfflineSync;
  final bool supportsFileUpload;
  final bool supportsFullTextSearch;
  final bool supportsTransactions;
  final bool supportsCustomQueries;
  final bool supportsAuth;
  final bool supportsPushNotifications;
  final bool supportsAnalytics;
  final bool supportsEdgeFunctions;
  
  const BackendCapabilities({
    this.supportsRealtimeUpdates = false,
    this.supportsOfflineSync = false,
    this.supportsFileUpload = false,
    this.supportsFullTextSearch = false,
    this.supportsTransactions = false,
    this.supportsCustomQueries = false,
    this.supportsAuth = true,
    this.supportsPushNotifications = false,
    this.supportsAnalytics = false,
    this.supportsEdgeFunctions = false,
  });
  
  /// Firebase capabilities
  static const firebase = BackendCapabilities(
    supportsRealtimeUpdates: true,
    supportsOfflineSync: true,
    supportsFileUpload: true,
    supportsFullTextSearch: false, // Limited
    supportsTransactions: true,
    supportsCustomQueries: true,
    supportsAuth: true,
    supportsPushNotifications: true,
    supportsAnalytics: true,
    supportsEdgeFunctions: true,
  );
  
  /// Supabase capabilities
  static const supabase = BackendCapabilities(
    supportsRealtimeUpdates: true,
    supportsOfflineSync: false, // Limited
    supportsFileUpload: true,
    supportsFullTextSearch: true,
    supportsTransactions: true,
    supportsCustomQueries: true,
    supportsAuth: true,
    supportsPushNotifications: false, // Through third party
    supportsAnalytics: false, // Through third party
    supportsEdgeFunctions: true,
  );
  
  /// Custom backend capabilities (configurable)
  static const custom = BackendCapabilities(
    supportsRealtimeUpdates: true,
    supportsOfflineSync: false,
    supportsFileUpload: true,
    supportsFullTextSearch: true,
    supportsTransactions: true,
    supportsCustomQueries: true,
    supportsAuth: true,
    supportsPushNotifications: false,
    supportsAnalytics: false,
    supportsEdgeFunctions: false,
  );
}
