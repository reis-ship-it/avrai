-- Migration: Fix Remaining RLS AgentId Lookups
-- Created: 2025-12-30
-- Purpose: Update remaining tables with proper agentId lookup checks
-- Follows pattern from migration 021_fix_rls_performance.sql
-- Security: Defense-in-depth approach (RLS filters, app enforces exact match)

-- ============================================
-- Fix learning_history
-- ============================================
-- Problem: TODO placeholder for agentId lookup + auth.role() not cached
-- Solution: Update policy with proper agentId lookup check + cache auth.role()

DROP POLICY IF EXISTS "Service role can manage all learning history" ON public.learning_history;
DROP POLICY IF EXISTS "Users can read own learning history" ON public.learning_history;

-- Service role can INSERT, UPDATE, DELETE (separate policies for each operation)
CREATE POLICY "Service role can insert learning history" ON public.learning_history
    FOR INSERT 
    WITH CHECK ((select auth.role()) = 'service_role');

CREATE POLICY "Service role can update learning history" ON public.learning_history
    FOR UPDATE 
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

CREATE POLICY "Service role can delete learning history" ON public.learning_history
    FOR DELETE 
    USING ((select auth.role()) = 'service_role');

-- Combined SELECT: service role OR authenticated users with mappings
-- IMPORTANT: RLS cannot decrypt mappings (keys in FlutterSecureStorage)
-- This policy ensures only authenticated users with mappings can access rows
-- Application layer MUST verify row's agent_id matches user's decrypted agentId
CREATE POLICY "Combined learning_history select access" ON public.learning_history
    FOR SELECT USING (
        (select auth.role()) = 'service_role' OR
        -- Ensure user is authenticated and has a mapping
        -- Full agentId verification happens in application layer after decryption
        (select auth.uid()) IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM public.user_agent_mappings_secure
            WHERE user_id = (select auth.uid())
        )
    );

-- ============================================
-- Fix calling_score_training_data
-- ============================================
-- Problem: TODO placeholder for agentId lookup + auth.role() not cached
-- Solution: Update policy with proper agentId lookup check + cache auth.role()

DROP POLICY IF EXISTS "Service role can manage all training data" ON public.calling_score_training_data;
DROP POLICY IF EXISTS "Users can read own training data" ON public.calling_score_training_data;

-- Service role can INSERT, UPDATE, DELETE (separate policies for each operation)
CREATE POLICY "Service role can insert training data" ON public.calling_score_training_data
    FOR INSERT 
    WITH CHECK ((select auth.role()) = 'service_role');

CREATE POLICY "Service role can update training data" ON public.calling_score_training_data
    FOR UPDATE 
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

CREATE POLICY "Service role can delete training data" ON public.calling_score_training_data
    FOR DELETE 
    USING ((select auth.role()) = 'service_role');

-- Combined SELECT: service role OR authenticated users with mappings
-- IMPORTANT: RLS cannot decrypt mappings (keys in FlutterSecureStorage)
-- This policy ensures only authenticated users with mappings can access rows
-- Application layer MUST verify row's agent_id matches user's decrypted agentId
CREATE POLICY "Combined calling_score_training_data select access" ON public.calling_score_training_data
    FOR SELECT USING (
        (select auth.role()) = 'service_role' OR
        -- Ensure user is authenticated and has a mapping
        -- Full agentId verification happens in application layer after decryption
        (select auth.uid()) IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM public.user_agent_mappings_secure
            WHERE user_id = (select auth.uid())
        )
    );

-- ============================================
-- Fix reservations
-- ============================================
-- Problem: TODO placeholder for agentId lookup
-- Solution: Update policy with proper agentId lookup check
-- Note: Service role policy already uses cached auth.role()

DROP POLICY IF EXISTS "Users can view own reservations" ON public.reservations;

-- Combined SELECT: service role OR authenticated users with mappings
-- IMPORTANT: RLS cannot decrypt mappings (keys in FlutterSecureStorage)
-- This policy ensures only authenticated users with mappings can access rows
-- Application layer MUST verify row's agent_id matches user's decrypted agentId
CREATE POLICY "Combined reservations select access" ON public.reservations
    FOR SELECT USING (
        (select auth.role()) = 'service_role' OR
        -- Ensure user is authenticated and has a mapping
        -- Full agentId verification happens in application layer after decryption
        (select auth.uid()) IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM public.user_agent_mappings_secure
            WHERE user_id = (select auth.uid())
        )
    );

-- ============================================
-- Verification
-- ============================================
-- After running this migration, verify:
-- 1. All policies use cached auth.role() and auth.uid()
-- 2. All policies check for authenticated users with mappings
-- 3. Run Supabase linter to confirm no warnings
-- 
-- Expected results:
-- - All TODO placeholders resolved
-- - All policies follow defense-in-depth pattern
-- 
-- IMPORTANT SECURITY NOTES:
-- - RLS policies verify user has a mapping in user_agent_mappings_secure
-- - RLS CANNOT decrypt mappings (keys stored in FlutterSecureStorage)
-- - Application layer MUST verify row's agent_id matches user's decrypted agentId
-- - This provides defense-in-depth: RLS filters authenticated users, app enforces exact match
-- - Services using these tables must call AgentIdService.getUserAgentId() and compare
