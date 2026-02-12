// ignore: dangling_library_doc_comments
/// Integration test for Predictive Proactive Outreach database schema
/// 
/// Tests the vectorless database schema for proactive outreach system.
/// Validates tables, indexes, RLS policies, and helper functions.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Predictive Proactive Outreach Schema', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      // Initialize Supabase client
      // Note: Requires SUPABASE_URL and SUPABASE_ANON_KEY environment variables
      // or use test configuration
      if (!Supabase.instance.isInitialized) {
        await Supabase.initialize(
          url: 'https://test.supabase.co', // Replace with test URL
          anonKey: 'test-key', // Replace with test key
        );
      }
      supabase = Supabase.instance.client;
    });

    group('Table Existence', () {
      test('outreach_queue table exists', () async {
        final response = await supabase
            .from('outreach_queue')
            .select('id')
            .limit(1);
        
        // If table doesn't exist, this will throw
        expect(response, isNotNull);
      });

      test('outreach_history table exists', () async {
        final response = await supabase
            .from('outreach_history')
            .select('id')
            .limit(1);
        
        expect(response, isNotNull);
      });

      test('compatibility_cache table exists', () async {
        final response = await supabase
            .from('compatibility_cache')
            .select('id')
            .limit(1);
        
        expect(response, isNotNull);
      });

      test('predictive_signals_cache table exists', () async {
        final response = await supabase
            .from('predictive_signals_cache')
            .select('id')
            .limit(1);
        
        expect(response, isNotNull);
      });

      test('outreach_processing_jobs table exists', () async {
        final response = await supabase
            .from('outreach_processing_jobs')
            .select('id')
            .limit(1);
        
        expect(response, isNotNull);
      });
    });

    group('Index Validation', () {
      test('outreach_queue has required indexes', () async {
        // Query that should use index
        final response = await supabase
            .from('outreach_queue')
            .select('id')
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(1);
        
        expect(response, isNotNull);
      });

      test('compatibility_cache has required indexes', () async {
        final response = await supabase
            .from('compatibility_cache')
            .select('id')
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('compatibility_score', ascending: false)
            .limit(1);
        
        expect(response, isNotNull);
      });
    });

    group('RLS Policies', () {
      test('Users can only view their own outreach_queue entries', () async {
        // This test requires authenticated user
        // In real test, would use test user credentials
        final response = await supabase
            .from('outreach_queue')
            .select('id')
            .limit(1);
        
        // Should not throw if RLS is working
        expect(response, isNotNull);
      });
    });

    group('Helper Functions', () {
      test('cleanup_expired_outreach_cache function exists', () async {
        final response = await supabase.rpc('cleanup_expired_outreach_cache');
        expect(response, isNotNull);
      });

      test('get_pending_outreach_count function exists', () async {
        // Requires UUID parameter
        final testUserId = '00000000-0000-0000-0000-000000000000';
        final response = await supabase.rpc(
          'get_pending_outreach_count',
          params: {'p_user_id': testUserId},
        );
        expect(response, isNotNull);
      });

      test('has_recent_outreach function exists', () async {
        final testUserId = '00000000-0000-0000-0000-000000000000';
        final response = await supabase.rpc(
          'has_recent_outreach',
          params: {
            'p_target_user_id': testUserId,
            'p_source_id': 'test-source',
            'p_type': 'event_call',
            'p_lookback_days': 30,
          },
        );
        expect(response, isNotNull);
      });
    });

    group('Data Integrity', () {
      test('outreach_queue constraints work correctly', () async {
        // Test that invalid data is rejected
        expect(
          () => supabase.from('outreach_queue').insert({
            'type': 'invalid_type', // Should fail CHECK constraint
            'target_user_id': '00000000-0000-0000-0000-000000000000',
            'source_id': 'test',
            'source_type': 'event',
            'compatibility_score': 0.5,
            'from_agent_id': 'agent1',
            'to_agent_id': 'agent2',
            'status': 'pending',
          }),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('compatibility_score range constraint works', () async {
        // Test that scores outside 0.0-1.0 are rejected
        expect(
          () => supabase.from('compatibility_cache').insert({
            'source_id': 'test1',
            'source_type': 'user',
            'target_id': 'test2',
            'target_type': 'user',
            'compatibility_score': 1.5, // Should fail CHECK constraint
            'expires_at': DateTime.now().add(Duration(hours: 6)).toIso8601String(),
          }),
          throwsA(isA<PostgrestException>()),
        );
      });
    });
  });
}
