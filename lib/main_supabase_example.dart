// Moved to examples/supabase/main_supabase_example.dart
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Example of how to use Supabase in your actual app
class SupabaseUsageExample {
  static SupabaseClient get _supabase => Supabase.instance.client;
  
  /// Sign in a user
  static Future<void> signInUser(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      developer.log('✅ User signed in: ${response.user?.email}', name: 'SupabaseExample');
    } catch (e) {
      developer.log('❌ Sign in failed: $e', name: 'SupabaseExample', error: e);
      rethrow;
    }
  }
  
  /// Create a new spot
  static Future<void> createSpot(String name, double lat, double lng) async {
    try {
      final spotData = {
        'name': name,
        'latitude': lat,
        'longitude': lng,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('spots').insert(spotData);
      developer.log('✅ Spot created: $name', name: 'SupabaseExample');
    } catch (e) {
      developer.log('❌ Failed to create spot: $e', name: 'SupabaseExample', error: e);
      rethrow;
    }
  }
  
  /// Get all spots
  static Future<List<Map<String, dynamic>>> getSpots() async {
    try {
      final response = await _supabase.from('spots').select('*');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('❌ Failed to get spots: $e', name: 'SupabaseExample', error: e);
      return [];
    }
  }
  
  /// Subscribe to real-time updates
  static Stream<List<Map<String, dynamic>>> getSpotsStream() {
    return _supabase
        .from('spots')
        .stream(primaryKey: ['id'])
        .map((event) => List<Map<String, dynamic>>.from(event));
  }
}
