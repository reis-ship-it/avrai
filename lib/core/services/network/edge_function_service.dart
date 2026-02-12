import 'dart:developer' as developer;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for calling Supabase Edge Functions
/// Phase 11 Section 4: Edge Mesh Functions
class EdgeFunctionService {
  static const String _logName = 'EdgeFunctionService';
  
  final SupabaseClient client;
  final Connectivity connectivity;
  
  EdgeFunctionService({
    required this.client,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();
  
  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      developer.log('Connectivity check failed, assuming offline: $e', name: _logName);
      return false;
    }
  }
  
  /// Call an edge function
  /// 
  /// [functionName] - Name of the edge function
  /// [body] - Request body (will be JSON encoded)
  /// 
  /// Returns the response data
  /// Throws Exception if request fails
  Future<Map<String, dynamic>> invokeFunction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      throw Exception('Edge function requires internet connection');
    }
    
    try {
      developer.log('Calling edge function: $functionName', name: _logName);
      
      final response = await client.functions.invoke(
        functionName,
        body: jsonEncode(body),
      );
      
      if (response.status != 200) {
        final errorData = response.data is String 
            ? jsonDecode(response.data as String) 
            : response.data;
        final errorMessage = errorData is Map && errorData.containsKey('error')
            ? errorData['error']
            : 'Unknown error';
        
        throw Exception('Edge function $functionName failed: ${response.status} - $errorMessage');
      }
      
      final data = response.data is String 
          ? jsonDecode(response.data as String) 
          : response.data;
      
      developer.log('Edge function $functionName succeeded', name: _logName);
      
      return data is Map<String, dynamic> ? data : {'data': data};
    } catch (e, stackTrace) {
      developer.log(
        'Error calling edge function $functionName: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
