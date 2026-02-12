import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Simple Supabase initializer for Flutter app (example)
class SupabaseInitializer {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: SupabaseConfig.debug,
    );
    _isInitialized = true;
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}


