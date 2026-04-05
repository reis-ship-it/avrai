// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Test Helper
///
/// Provides utilities for initializing Supabase in integration tests.
/// Credentials are loaded from environment variables or dart-define flags.
///
/// **Usage:**
/// ```dart
/// setUpAll(() async {
///   await SupabaseTestHelper.initialize();
///   supabase = SupabaseTestHelper.client;
/// });
///
/// tearDownAll(() async {
///   await SupabaseTestHelper.dispose();
/// });
/// ```
class SupabaseTestHelper {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Initialize Supabase for testing
  ///
  /// Loads credentials from:
  /// 1. Platform environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)
  /// 2. Dart-define flags (SUPABASE_URL, SUPABASE_ANON_KEY)
  ///
  /// Returns true if initialization succeeded, false if credentials are missing
  static Future<bool> initialize() async {
    if (_isInitialized && _client != null) {
      return true;
    }

    // Ensure Flutter bindings for plugin channel
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Try to get credentials from environment
    String? url = Platform.environment['SUPABASE_URL'];
    String? anonKey = Platform.environment['SUPABASE_ANON_KEY'];
    String? serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    // If not in environment, try dart-define (from SupabaseConfig)
    if (url == null || url.isEmpty) {
      url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    }
    if (anonKey == null || anonKey.isEmpty) {
      anonKey =
          const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    }
    if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
      serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY',
          defaultValue: '');
    }

    // Credentials must be provided via environment variables or dart-define
    // DO NOT hardcode Supabase credentials in source code
    if (url.isEmpty || anonKey.isEmpty) {
      print('ℹ️  Supabase credentials not found in environment.');
      print('   Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables');
      print('   or pass via --dart-define flags.');
    }

    // Check if credentials are available
    if (url.isEmpty || anonKey.isEmpty) {
      print('⚠️  Supabase credentials not found. Skipping Supabase tests.');
      print(
          '   Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or dart-define flags.');
      return false;
    }

    try {
      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false, // Set to true for verbose logging
      );

      _client = Supabase.instance.client;

      // Stop auto-refresh timers to avoid pending timers in tests
      _client!.auth.stopAutoRefresh();

      _isInitialized = true;
      print('✅ Supabase initialized successfully for testing');
      return true;
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      return false;
    }
  }

  /// Get the Supabase client
  ///
  /// Returns null if not initialized
  static SupabaseClient? get client => _client;

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized && _client != null;

  /// Create a service role client (for admin operations)
  ///
  /// Requires SUPABASE_SERVICE_ROLE_KEY to be set
  static SupabaseClient? createServiceRoleClient() {
    String? url = Platform.environment['SUPABASE_URL'];
    String? serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    if (url == null || url.isEmpty) {
      url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    }
    if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
      serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY',
          defaultValue: '');
    }

    if (url.isEmpty || serviceRoleKey.isEmpty) {
      print(
          '⚠️  Service role key not found. Cannot create service role client.');
      return null;
    }

    return SupabaseClient(url, serviceRoleKey);
  }

  /// Dispose Supabase client
  static Future<void> dispose() async {
    if (_client != null) {
      try {
        await _client!.auth.signOut();
        await _client!.rest.dispose();
      } catch (e) {
        print('Warning: Error disposing Supabase client: $e');
      }
      _client = null;
    }
    _isInitialized = false;
  }

  /// Reset initialization state (for testing)
  static void reset() {
    _client = null;
    _isInitialized = false;
  }
}
