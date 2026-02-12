import 'package:supabase_flutter/supabase_flutter.dart';
// ignore_for_file: avoid_print - Example file demonstrating usage

/// Very simple Supabase example
/// Demonstrates the concept without complex type issues
class SupabaseSimpleExample {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  
  /// Initialize Supabase
  static Future<bool> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      print('✅ Supabase initialized successfully');
      return true;
      
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      return false;
    }
  }
  
  /// Check if initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final user = _client!.auth.currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'email': user.email ?? '',
          'name': user.userMetadata?['name'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Get current user failed: $e');
      return null;
    }
  }
  
  /// Sign in with email and password
  static Future<Map<String, dynamic>?> signIn(String email, String password) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return {
          'id': response.user!.id,
          'email': response.user!.email ?? '',
          'name': response.user!.userMetadata?['name'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Sign in failed: $e');
      return null;
    }
  }
  
  /// Sign up with email and password
  static Future<Map<String, dynamic>?> signUp(String email, String password, String name) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user != null) {
        return {
          'id': response.user!.id,
          'email': response.user!.email ?? '',
          'name': response.user!.userMetadata?['name'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Sign up failed: $e');
      return null;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    if (!_isInitialized || _client == null) {
      return;
    }
    
    try {
      await _client!.auth.signOut();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
    }
  }
  
  /// Create a document in a collection
  static Future<Map<String, dynamic>?> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!
        .from(collection)
        .insert(data)
        .select()
        .single();
      
      return response;
    } catch (e) {
      print('Create document failed: $e');
      return null;
    }
  }
  
  /// Get documents from a collection
  static Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    if (!_isInitialized || _client == null) {
      return [];
    }
    
    try {
      final response = await _client!.from(collection).select();
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Get documents failed: $e');
      return [];
    }
  }
  
  /// Health check
  static Future<bool> healthCheck() async {
    if (!_isInitialized || _client == null) {
      return false;
    }
    
    try {
      // ignore: unused_local_variable - Example file demonstrating auth check
      final user = _client!.auth.currentUser;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Dispose resources
  static Future<void> dispose() async {
    _isInitialized = false;
    _client = null;
  }
}

/// Example usage
class SupabaseSimpleUsage {
  static Future<void> runExample() async {
    print('🚀 Starting simple Supabase example...');
    
    // Initialize Supabase
    final success = await SupabaseSimpleExample.initialize(
      url: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
    );
    
    if (!success) {
      print('❌ Failed to initialize Supabase');
      return;
    }
    
    // Health check
    final isHealthy = await SupabaseSimpleExample.healthCheck();
    print('🏥 Health check: ${isHealthy ? 'Healthy' : 'Unhealthy'}');
    
    // Create a user document
    final userData = {
      'name': 'John Doe',
      'email': 'john@example.com',
      'created_at': DateTime.now().toString(),
    };
    
    final createdUser = await SupabaseSimpleExample.createDocument('users', userData);
    if (createdUser != null) {
      print('✅ Created user: ${createdUser['id']}');
      
      // Get all users
      final users = await SupabaseSimpleExample.getDocuments('users');
      print('📋 Found ${users.length} users');
    }
    
    print('✅ Simple Supabase example completed successfully!');
  }
}
