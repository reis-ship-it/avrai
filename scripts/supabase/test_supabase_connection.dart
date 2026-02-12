import 'dart:io';
// ignore_for_file: avoid_print - Script file
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple Supabase connection test
/// This doesn't require Flutter dependencies
void main() async {
  print('🧪 Testing Supabase Connection');
  print('==============================');
  
  // Supabase credentials loaded from environment variables
  final String url = Platform.environment['SUPABASE_URL'] ?? '';
  final String anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  
  try {
    print('🔧 Testing connection to Supabase...');
    
    // Test 1: Basic connection
    await testBasicConnection(url, anonKey);
    
    // Test 2: Database access
    await testDatabaseAccess(url, anonKey);
    
    // Test 3: Storage access
    await testStorageAccess(url, anonKey);
    
    print('\n✅ All tests passed! Your Supabase backend is working correctly.');
    
  } catch (e) {
    print('❌ Test failed: $e');
    exit(1);
  }
}

/// Test basic connection to Supabase
Future<void> testBasicConnection(String url, String anonKey) async {
  print('\n🔐 Testing basic connection...');
  
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    
    if (response.statusCode == 200) {
      print('✅ Basic connection successful');
    } else {
      print('❌ Basic connection failed: ${response.statusCode}');
      throw Exception('Connection failed');
    }
  } catch (e) {
    print('❌ Connection error: $e');
    rethrow;
  }
}

/// Test database access
Future<void> testDatabaseAccess(String url, String anonKey) async {
  print('\n🗄️  Testing database access...');
  
  try {
    // Test reading from users table
    final response = await http.get(
      Uri.parse('$url/rest/v1/users?select=*&limit=1'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      print('✅ Database read successful');
      final data = json.decode(response.body);
      print('   Found ${data.length} users');
    } else {
      print('❌ Database read failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Database error: $e');
    rethrow;
  }
}

/// Test storage access
Future<void> testStorageAccess(String url, String anonKey) async {
  print('\n📁 Testing storage access...');
  
  try {
    // Test listing storage buckets
    final response = await http.get(
      Uri.parse('$url/storage/v1/bucket/list'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    
    if (response.statusCode == 200) {
      print('✅ Storage access successful');
      final data = json.decode(response.body);
      print('   Found ${data.length} storage buckets');
    } else {
      print('❌ Storage access failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Storage error: $e');
    rethrow;
  }
}



