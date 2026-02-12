-- Security Validation: RLS Policies Verification
-- 
-- Verifies Row Level Security (RLS) policies for secure agent ID mappings
-- 
-- Usage: Run this script against your Supabase database
-- 
-- Expected Results:
-- - RLS enabled on user_agent_mappings_secure
-- - Policies for SELECT, INSERT, UPDATE
-- - Users can only access their own mappings
-- - Service role can access all mappings

-- ============================================
-- 1. Verify RLS is enabled
-- ============================================
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'user_agent_mappings_secure';

-- Expected: rls_enabled = true

-- ============================================
-- 2. List all RLS policies
-- ============================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'user_agent_mappings_secure'
ORDER BY cmd, policyname;

-- Expected policies:
-- - SELECT: Users can only SELECT their own mappings
-- - INSERT: Users can only INSERT their own mappings
-- - UPDATE: Users can only UPDATE their own mappings
-- - Service role: Can access all mappings

-- ============================================
-- 3. Verify policy expressions
-- ============================================
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '✅ Uses auth.uid()'
        WHEN qual LIKE '%service_role%' THEN '✅ Uses service_role'
        ELSE '⚠️  Check policy expression'
    END as validation
FROM pg_policies 
WHERE tablename = 'user_agent_mappings_secure';

-- Expected: All policies should use auth.uid() or service_role

-- ============================================
-- 4. Count policies by command
-- ============================================
SELECT 
    cmd as command,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'user_agent_mappings_secure'
GROUP BY cmd
ORDER BY cmd;

-- Expected:
-- - SELECT: At least 1 policy
-- - INSERT: At least 1 policy
-- - UPDATE: At least 1 policy

-- ============================================
-- 5. Verify audit log table RLS
-- ============================================
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'agent_mapping_audit_log';

-- Expected: rls_enabled = true (if RLS is enabled)

-- ============================================
-- 6. Test RLS enforcement (requires authenticated user)
-- ============================================
-- Note: This should be run as an authenticated user
-- 
-- Test 1: User should only see their own mapping
-- SELECT * FROM user_agent_mappings_secure;
-- Expected: Only returns rows where user_id = auth.uid()
--
-- Test 2: User should not be able to INSERT for another user
-- INSERT INTO user_agent_mappings_secure (user_id, ...) 
-- VALUES ('[different_user_id]', ...);
-- Expected: Should fail with permission denied
--
-- Test 3: User should not be able to UPDATE another user's mapping
-- UPDATE user_agent_mappings_secure 
-- SET ... 
-- WHERE user_id = '[different_user_id]';
-- Expected: Should fail with permission denied or return 0 rows

-- ============================================
-- 7. Verify indexes (for performance)
-- ============================================
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'user_agent_mappings_secure'
ORDER BY indexname;

-- Expected indexes:
-- - idx_user_agent_mappings_secure_user_id (on user_id)
-- - idx_user_agent_mappings_secure_key_id (on encryption_key_id)
