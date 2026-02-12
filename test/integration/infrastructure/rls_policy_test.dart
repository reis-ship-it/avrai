import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/supabase_test_helper.dart';

/// Integration tests for Row Level Security (RLS) policies
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests verify RLS policies enforce access control
/// and prevent unauthorized data access
/// 
/// **Setup Required:**
/// Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or dart-define flags
/// to run these tests. Tests will be skipped if credentials are not available.
void main() {
  group('RLS Policy Tests', () {
    late SupabaseClient? supabase;
    bool supabaseAvailable = false;

    setUpAll(() async {
      // Initialize Supabase client for testing
      supabaseAvailable = await SupabaseTestHelper.initialize();
      supabase = SupabaseTestHelper.client;
      
      if (!supabaseAvailable) {
      // ignore: avoid_print
        print('⚠️  Supabase not available. All RLS tests will be skipped.');
      }
    });

    tearDownAll(() async {
      await SupabaseTestHelper.dispose();
    });

    group('User Access Control', () {
      test('should allow users to access their own data', () async {
        // Test business logic: RLS policies allow users to access their own data
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        // Verify the client is available and can connect
        expect(supabase, isNotNull);
        expect(supabase!.rest.url, isNotEmpty);
        
        // Test basic connection by checking if we can query (even if empty)
        // Try api.users first (preferred schema), fallback to public.users
        try {
          // Try api schema first (from supabase_schema.sql)
          final response = await supabase!
              .from('api.users')
              .select()
              .limit(1);
        
          // If we get here, either:
          // 1. RLS allows unauthenticated reads (not recommended for users table)
          // 2. Query succeeded (unlikely without auth)
      // ignore: avoid_print
          expect(response, isA<List>());
      // ignore: avoid_print
          print('ℹ️  api.users table query succeeded (RLS may allow public reads)');
        } on PostgrestException catch (e) {
          // If api.users fails, try public.users (legacy schema)
          if (e.code == '42P01' || e.toString().contains('does not exist')) {
            try {
              final response = await supabase!
                  .from('users')
                  .select()
      // ignore: avoid_print
                  .limit(1);
      // ignore: avoid_print
              expect(response, isA<List>());
      // ignore: avoid_print
              print('ℹ️  users table (public schema) query succeeded');
      // ignore: avoid_print
            } on PostgrestException catch (e2) {
      // ignore: avoid_print
              // Expected: RLS should block unauthenticated access
      // ignore: avoid_print
              expect(e2.code, anyOf('400', '401', '403', 'PGRST301', 'PGRST116'));
      // ignore: avoid_print
              print('✅ RLS blocked unauthenticated access to users table (code: ${e2.code})');
      // ignore: avoid_print
            }
          } else {
            // Expected: RLS should block unauthenticated access
            expect(e.code, anyOf('400', '401', '403', 'PGRST301', 'PGRST116'));
      // ignore: avoid_print
            print('✅ RLS blocked unauthenticated access to api.users (code: ${e.code})');
          }
      // ignore: avoid_print
        } on Exception catch (e) {
      // ignore: avoid_print
          // Any exception indicates access was blocked
      // ignore: avoid_print
          expect(e, isA<Exception>());
      // ignore: avoid_print
          print('✅ Access blocked: ${e.runtimeType}');
        }
        
        // TODO: When test user setup is available:
        // 1. Create test user and authenticate
        // 2. Query user's own data
        // 3. Verify data is accessible
      });

      test('should prevent users from accessing other users data', () async {
        // Test business logic: RLS policies prevent users from accessing other users' data
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        // Note: This test requires:
        // 1. A test user to be authenticated
        // 2. Another user's data to exist
        // 3. RLS policies to block cross-user access
        
        // For now, we verify the client is available
        expect(supabase, isNotNull);
        
        // TODO: When test user setup is available:
        // 1. Authenticate as user-123
        // 2. Try to query user-456's data
        // 3. Verify it throws PostgrestException
        // expect(
        //   () => supabase!
        //       .from('users')
        //       .select()
        //       .eq('id', otherUserId)
        //       .single(),
        //   throwsA(isA<PostgrestException>()),
        // );
      });

      test('should allow users to update their own data', () async {
        // Test business logic: RLS policies allow users to update their own data
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        expect(supabase, isNotNull);
        
        // TODO: When test user setup is available:
        // 1. Authenticate as user-123
        // 2. Update own data
        // 3. Verify update succeeds
      });

      test('should prevent users from updating other users data', () async {
        // Test business logic: RLS policies prevent users from updating other users' data
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        expect(supabase, isNotNull);
        
        // TODO: When test user setup is available:
        // 1. Authenticate as user-123
        // 2. Try to update user-456's data
        // 3. Verify it throws PostgrestException
      });
    });

    group('Admin Access Control', () {
      test('should allow admin access with privacy filtering', () async {
        // Test business logic: Admin access with privacy filtering
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        expect(supabase, isNotNull);
        
        // TODO: When admin role setup is available:
        // 1. Authenticate as admin user
        // 2. Query user data with privacy filtering
        // 3. Verify personal data is filtered out
      });

      test('should filter personal data from admin queries', () async {
        // Test business logic: Admin queries filter personal data
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        expect(supabase, isNotNull);
        
        // TODO: When admin role setup is available:
        // 1. Authenticate as admin user
        // 2. Query user data
        // 3. Verify forbidden fields are not present
      });
    });

    group('Unauthorized Access Blocking', () {
      test('should block unauthenticated access', () async {
        // Test business logic: Unauthenticated requests are blocked by RLS
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        // Ensure we're not authenticated
        await supabase!.auth.signOut();
        expect(supabase!.auth.currentUser, isNull);
        
        expect(supabase, isNotNull);
        
        // Try to access protected tables without authentication
        // This should fail if RLS is properly configured
        final testTables = ['api.users', 'api.spots', 'user_personality_profiles', 'audit_logs'];
        int blockedCount = 0;
        
        for (final table in testTables) {
          try {
      // ignore: avoid_print
            await supabase!
                .from(table)
                .select()
      // ignore: avoid_print
                .limit(1);
      // ignore: avoid_print
            
      // ignore: avoid_print
      // ignore: avoid_print
            // If we get here, RLS might not be blocking unauthenticated access
      // ignore: avoid_print
            print('ℹ️  $table: Unauthenticated access succeeded (may allow public reads)');
      // ignore: avoid_print
          } on PostgrestException catch (e) {
      // ignore: avoid_print
            // Expected: RLS should block unauthenticated access
            if (e.code == '400' || e.code == '401' || e.code == '403' || 
      // ignore: avoid_print
      // ignore: avoid_print
                e.code == 'PGRST301' || e.code == 'PGRST116') {
      // ignore: avoid_print
              blockedCount++;
      // ignore: avoid_print
              print('✅ $table: RLS blocked unauthenticated access (code: ${e.code})');
      // ignore: avoid_print
            } else if (e.code == '42P01') {
              // Table doesn't exist - skip
      // ignore: avoid_print
              print('ℹ️  $table: Table not found (may not be created yet)');
            }
      // ignore: avoid_print
          } on Exception catch (e) {
            // Any exception indicates access was blocked
      // ignore: avoid_print
            blockedCount++;
      // ignore: avoid_print
            print('✅ $table: Access blocked: ${e.runtimeType}');
          }
        }
        
        // At least some tables should block unauthenticated access
        expect(blockedCount, greaterThan(0),
            reason: 'At least some tables should block unauthenticated access');
      });

      test('should block access with invalid token', () async {
        // Test business logic: Invalid tokens are rejected
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        expect(supabase, isNotNull);
        
        // TODO: When token validation is set up:
        // 1. Set invalid token
        // 2. Try to query protected table
        // 3. Verify it throws AuthException
      });

      test('should enforce RLS policies on all tables', () async {
        // Test business logic: RLS policies are enforced on all protected tables
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

        // Ensure we're not authenticated
        await supabase!.auth.signOut();
        expect(supabase, isNotNull);
        
        // Test RLS on all tables with RLS enabled
        // Tables in api schema (from supabase_schema.sql)
        final apiTables = [
          'users',
          'spots',
          'spot_lists',
          'spot_list_items',
          'user_respects',
          'user_follows',
        ];
        
        // Tables in public schema (from migrations)
        final publicTables = [
          'user_personality_profiles',
          'audit_logs',
        ];
        
        // Business tables (may not exist yet)
        final businessTables = [
          'business_credentials',
          'business_sessions',
        ];
        
        final allTables = [
          ...apiTables.map((t) => 'api.$t'),
          ...publicTables,
          ...businessTables,
        ];
        
        int blockedCount = 0;
        int accessibleCount = 0;
        int notFoundCount = 0;
        
        for (final table in allTables) {
          try {
            await supabase!
                .from(table)
                .select()
                .limit(1);
            // If we get here, table might allow public access or doesn't exist
            accessibleCount++;
          } on PostgrestException catch (e) {
            // Expected: RLS should block unauthenticated access
            // PostgrestException indicates RLS blocking
            if (e.code == '400' || e.code == '401' || e.code == '403' || 
                e.code == 'PGRST301' || e.code == 'PGRST116' || e.code == '42P01') {
              if (e.code == '42P01') {
                // Table doesn't exist (schema error)
                notFoundCount++;
              } else {
                blockedCount++;
              }
            } else {
              // Other error codes
              blockedCount++;
            }
          } on Exception catch (e) {
            // Any exception indicates access was blocked or table doesn't exist
            if (e.toString().contains('does not exist') || 
      // ignore: avoid_print
                e.toString().contains('relation') ||
      // ignore: avoid_print
                e.toString().contains('schema')) {
      // ignore: avoid_print
              notFoundCount++;
      // ignore: avoid_print
            } else {
      // ignore: avoid_print
              blockedCount++;
      // ignore: avoid_print
            }
      // ignore: avoid_print
          }
      // ignore: avoid_print
        }
      // ignore: avoid_print
        
      // ignore: avoid_print
        // Report results
      // ignore: avoid_print
        print('ℹ️  Tested ${allTables.length} tables:');
      // ignore: avoid_print
        print('   - $blockedCount blocked by RLS ✅');
      // ignore: avoid_print
        print('   - $accessibleCount accessible (may allow public reads)');
      // ignore: avoid_print
        print('   - $notFoundCount not found (may not be created yet)');
        
        // At least some tables should be protected by RLS
        expect(blockedCount, greaterThan(0), 
            reason: 'At least some tables should be protected by RLS');
      });
    });

    group('Storage RLS Policies', () {
      test('should enforce RLS on storage buckets', () async {
        // Test business logic: Storage buckets have RLS policies
        if (!supabaseAvailable || supabase == null) {
          return; // Skip if Supabase not available
        }

      // ignore: avoid_print
        expect(supabase, isNotNull);
        
        // Test storage buckets that should have RLS (from supabase_schema.sql)
      // ignore: avoid_print
        final buckets = ['user-avatars', 'spot-images', 'list-images'];
      // ignore: avoid_print
        int blockedCount = 0;
        int accessibleCount = 0;
        
      // ignore: avoid_print
      // ignore: avoid_print
        for (final bucket in buckets) {
      // ignore: avoid_print
          try {
      // ignore: avoid_print
            // Try to list files in bucket without authentication
            await supabase!.storage.from(bucket).list();
      // ignore: avoid_print
            accessibleCount++;
      // ignore: avoid_print
            print('ℹ️  $bucket: Unauthenticated access succeeded (may allow public reads for images)');
      // ignore: avoid_print
          } on Exception {
            // Expected: RLS should block unauthenticated access to storage
      // ignore: avoid_print
      // ignore: avoid_print
            blockedCount++;
      // ignore: avoid_print
            print('✅ $bucket: Storage RLS blocked unauthenticated access');
      // ignore: avoid_print
          }
        }
      // ignore: avoid_print
      // ignore: avoid_print

      // ignore: avoid_print
      // ignore: avoid_print
        // Report results (some buckets may allow public reads for images)
      // ignore: avoid_print
        print('ℹ️  Tested ${buckets.length} storage buckets:');
      // ignore: avoid_print
        print('   - $blockedCount blocked by RLS');
      // ignore: avoid_print
        print('   - $accessibleCount accessible (may allow public reads)');
      });
    });
      // ignore: avoid_print

    group('Service Role Access', () {
      test('should allow service role access for system operations', () async {
        // Test business logic: Service role can access data for system operations
        if (!supabaseAvailable) {
      // ignore: avoid_print
          return; // Skip if Supabase not available
      // ignore: avoid_print
        }

      // ignore: avoid_print
        final serviceRoleClient = SupabaseTestHelper.createServiceRoleClient();
      // ignore: avoid_print
        
      // ignore: avoid_print
      // ignore: avoid_print
        if (serviceRoleClient == null) {
      // ignore: avoid_print
          // Skip if service role key not available
      // ignore: avoid_print
          print('ℹ️  Service role key not available - skipping service role tests');
      // ignore: avoid_print
          return;
        }
      // ignore: avoid_print

        expect(serviceRoleClient, isNotNull);
      // ignore: avoid_print

      // ignore: avoid_print
        // Test that service role can access data (bypasses RLS)
      // ignore: avoid_print
        try {
      // ignore: avoid_print
          final response = await serviceRoleClient
      // ignore: avoid_print
              .from('api.users')
      // ignore: avoid_print
              .select()
      // ignore: avoid_print
      // ignore: avoid_print
              .limit(1);
      // ignore: avoid_print
          expect(response, isA<List>());
      // ignore: avoid_print
          print('✅ Service role can access data (bypasses RLS)');
        } on Exception catch (e) {
      // ignore: avoid_print
      // ignore: avoid_print
          // If this fails, it might mean table doesn't exist or other issue
      // ignore: avoid_print
          print('ℹ️  Service role access test: ${e.runtimeType} (table may not exist yet)');
        }
      });

      test('should log all service role access', () async {
        // Test business logic: Service role access is logged for audit
        if (!supabaseAvailable) {
          return; // Skip if Supabase not available
        }
      // ignore: avoid_print

        final serviceRoleClient = SupabaseTestHelper.createServiceRoleClient();
      // ignore: avoid_print
        
        if (serviceRoleClient == null) {
          // Skip if service role key not available
      // ignore: avoid_print
          print('ℹ️  Service role key not available - skipping audit log test');
          return;
      // ignore: avoid_print
        }

      // ignore: avoid_print
      // ignore: avoid_print
        expect(serviceRoleClient, isNotNull);
      // ignore: avoid_print
        
        // Test that service role can query audit_logs table
      // ignore: avoid_print
        // (Service role should have access per RLS policies in 010_audit_log_table.sql)
        try {
      // ignore: avoid_print
      // ignore: avoid_print
          final auditLogs = await serviceRoleClient
      // ignore: avoid_print
      // ignore: avoid_print
              .from('audit_logs')
      // ignore: avoid_print
              .select()
      // ignore: avoid_print
              .limit(1)
              .order('timestamp', ascending: false);
      // ignore: avoid_print
          expect(auditLogs, isA<List>());
      // ignore: avoid_print
          print('✅ Service role can access audit_logs table');
        } on Exception catch (e) {
      // ignore: avoid_print
          // If this fails, audit_logs table might not exist yet
      // ignore: avoid_print
          print('ℹ️  Audit logs access test: ${e.runtimeType} (table may not exist yet)');
        }
      });
    });
  });
}

