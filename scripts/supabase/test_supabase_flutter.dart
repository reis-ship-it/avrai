import 'dart:io';
// ignore_for_file: avoid_print - Script file
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test script to verify Supabase connection using supabase_flutter
void main() async {
  print('🧪 Testing Supabase with Authentication');
  print('=======================================');
  
  const String url = 'https://dsttvxuislebwriaprmt.supabase.co';
  const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (anonKey.isEmpty) {
    stderr.writeln('❌ Provide anon key via --dart-define=SUPABASE_ANON_KEY=...');
    exit(1);
  }
  
  try {
    print('🔧 Initializing Supabase...');
    await Supabase.initialize(url: url, anonKey: anonKey, debug: true);
    final client = Supabase.instance.client;
    print('✅ Supabase initialized successfully');
    
    await testAuthentication(client);
    await testDatabaseOperations(client);
    await testStorageOperations(client);
    await testRealtime(client);
    
    print('\n✅ All tests passed!');
  } catch (e) {
    stderr.writeln('❌ Test failed: $e');
    exit(1);
  }
}

Future<void> testAuthentication(SupabaseClient client) async {
  try {
    await client.auth.signInAnonymously();
    print('✅ Anonymous sign in successful');
    await client.auth.signOut();
    print('✅ Sign out successful');
  } catch (e) {
    stderr.writeln('❌ Authentication failed: $e');
    rethrow;
  }
}

Future<void> testDatabaseOperations(SupabaseClient client) async {
  try {
    final response = await client.from('users').select().limit(1);
    print('✅ Database read successful (${response.length} rows)');
  } catch (e) {
    stderr.writeln('❌ Database test failed: $e');
    rethrow;
  }
}

Future<void> testStorageOperations(SupabaseClient client) async {
  try {
    final buckets = await client.storage.listBuckets();
    print('✅ Storage buckets accessible (${buckets.length})');
  } catch (e) {
    stderr.writeln('❌ Storage test failed: $e');
    rethrow;
  }
}

Future<void> testRealtime(SupabaseClient client) async {
  try {
    final channel = client.channel('test-channel');
    channel.subscribe((status, [error]) {
      // ignore: unrelated_type_equality_checks - Script file, status comparison needed for testing
      if (status.toString().contains('subscribed') || status.toString() == 'SUBSCRIBED') {
        print('✅ Realtime subscription successful');
      } else if (status.toString().contains('error') || status.toString() == 'CHANNEL_ERROR') {
        stderr.writeln('❌ Realtime subscription failed: $error');
      }
    });
    await Future.delayed(const Duration(seconds: 2));
    await channel.unsubscribe();
    print('✅ Realtime unsubscribe successful');
  } catch (e) {
    stderr.writeln('❌ Realtime test failed: $e');
    rethrow;
  }
}



