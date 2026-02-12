import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../interfaces/backend_interface.dart';
import '../../interfaces/auth_backend.dart';
import '../../interfaces/data_backend.dart';
import '../../interfaces/realtime_backend.dart';
import 'supabase_auth_backend.dart';
import 'supabase_data_backend.dart';
import 'supabase_realtime_backend.dart';

/// Supabase backend implementation
/// Provides authentication, data operations, and real-time features via Supabase
class SupabaseBackend implements BackendInterface {
  late final SupabaseAuthBackend _authBackend;
  late final SupabaseDataBackend _dataBackend;
  late final SupabaseRealtimeBackend _realtimeBackend;
  
  SupabaseClient? _client;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  
  @override
  AuthBackend get auth => _authBackend;
  
  @override
  DataBackend get data => _dataBackend;
  
  @override
  RealtimeBackend get realtime => _realtimeBackend;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  String get backendType => 'supabase';
  
  @override
  Map<String, dynamic> get config => Map.unmodifiable(_config);
  
  @override
  BackendCapabilities get capabilities => BackendCapabilities.supabase;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    try {
      _config = Map.unmodifiable(config);
      
      // Initialize Supabase client
      final url = config['url'] as String?;
      final anonKey = config['anonKey'] as String?;
      
      if (url == null || anonKey == null) {
        throw ArgumentError('Supabase URL and anon key are required');
      }
      
      // Initialize Supabase Flutter
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false, // Set to true for development
      );
      
      _client = Supabase.instance.client;
      
      // Initialize component backends
      _authBackend = SupabaseAuthBackend(_client!);
      _dataBackend = SupabaseDataBackend(_client!);
      _realtimeBackend = SupabaseRealtimeBackend(_client!);
      
      // Initialize component backends
      await _authBackend.initialize(config);
      await _dataBackend.initialize(config);
      await _realtimeBackend.initialize(config);
      
      _isInitialized = true;
      
    } catch (e) {
      _isInitialized = false;
      throw BackendInitializationException(
        'Failed to initialize Supabase backend: $e',
      );
    }
  }
  
  @override
  Future<void> dispose() async {
    try {
      // Dispose component backends
      await _authBackend.dispose();
      await _dataBackend.dispose();
      await _realtimeBackend.dispose();
      
      // Close Supabase client
      await _client?.rest.dispose();
      
      _isInitialized = false;
      _client = null;
      
    } catch (e) {
      // Log error but don't throw during disposal
      developer.log('Warning: Error during Supabase backend disposal: $e', name: 'SupabaseBackend');
    }
  }
  
  @override
  Future<bool> healthCheck() async {
    try {
      if (!_isInitialized || _client == null) {
        return false;
      }
      
      // Simple health check - try to get current user
      // ignore: unused_local_variable - Health check verification
      final user = _client!.auth.currentUser;
      
      // Additional check - try a simple query
      await _client!.from('health_check').select('count').limit(1);
      
      return true;
      
    } catch (e) {
      return false;
    }
  }
}

/// Exception thrown when Supabase backend initialization fails
class BackendInitializationException implements Exception {
  final String message;
  const BackendInitializationException(this.message);
  
  @override
  String toString() => 'BackendInitializationException: $message';
}
