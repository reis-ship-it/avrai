import '../../interfaces/backend_interface.dart';
import 'supabase_backend_simple.dart';

/// Supabase module for dynamic loading
/// This allows the BackendFactory to load Supabase backend without direct dependencies
class SupabaseModule {
  /// Create a new Supabase backend instance
  BackendInterface createSupabaseBackend() {
    return SupabaseBackendSimple();
  }
  
  /// Get module information
  static Map<String, dynamic> get moduleInfo => {
    'name': 'Supabase Backend',
    'version': '1.0.0',
    'description': 'Supabase backend implementation for SPOTS',
    'capabilities': {
      'authentication': true,
      'real_time': true,
      'file_storage': true,
      'database': true,
      'edge_functions': true,
    },
  };
}

/// Factory function to create Supabase module
/// This is used by the BackendFactory for dynamic loading
SupabaseModule createSupabaseModule() {
  return SupabaseModule();
}
