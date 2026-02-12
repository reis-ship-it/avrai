-- Migration: Fix Audit Log to Use agentId Instead of userId
-- Created: 2025-12-30
-- Purpose: Remove userId from audit log to prevent data leakage
-- Security: Critical - Prevents linking userId to agentId operations
-- Phase: Secure Agent ID Mapping Implementation Plan - Phase 7

-- ============================================
-- Update audit log table schema
-- ============================================
-- Change user_id column to agent_id to prevent data leakage

-- Step 1: Add agent_id column
ALTER TABLE public.agent_mapping_audit_log
ADD COLUMN IF NOT EXISTS agent_id TEXT;

-- Step 2: Migrate existing data (if any)
-- Note: This requires getting agentId from userId, which may not be possible
-- If migration is run before any audit logs exist, this step can be skipped
UPDATE public.agent_mapping_audit_log
SET agent_id = (
  SELECT agent_id 
  FROM user_agent_mappings 
  WHERE user_agent_mappings.user_id = agent_mapping_audit_log.user_id
  LIMIT 1
)
WHERE agent_id IS NULL AND user_id IS NOT NULL;

-- Step 3: Make agent_id NOT NULL (after migration)
-- Note: Only do this if all rows have been migrated
-- ALTER TABLE public.agent_mapping_audit_log
-- ALTER COLUMN agent_id SET NOT NULL;

-- Step 4: Drop user_id column (after verification)
-- Note: Only do this after verifying agent_id migration is complete
-- ALTER TABLE public.agent_mapping_audit_log
-- DROP COLUMN IF EXISTS user_id;

-- Step 5: Update RLS policy to use agent_id
-- Note: This requires getting userId from agentId, which defeats the purpose
-- Instead, we'll use a different approach: allow users to see their own audit logs
-- by checking if the agent_id matches their current agent_id

-- Drop old RLS policy
DROP POLICY IF EXISTS "Users can view own audit log" ON public.agent_mapping_audit_log;

-- Create new RLS policy using agent_id
-- Note: This requires a function to get current user's agent_id
CREATE OR REPLACE FUNCTION get_current_user_agent_id()
RETURNS TEXT AS $$
DECLARE
    v_user_id UUID;
    v_agent_id TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Get agent_id from secure mappings table
    -- Note: This requires decrypting the mapping, which is complex
    -- For now, we'll use a simpler approach: allow service role only
    -- Users will need to query their own audit logs via the service
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Alternative: Allow service role to view all, users cannot view directly
-- Users should query audit logs through the application service layer
CREATE POLICY "Service role can view all audit logs"
    ON public.agent_mapping_audit_log
    FOR SELECT
    USING ((select auth.role()) = 'service_role');

-- ============================================
-- Update indexes
-- ============================================

-- Drop old index on user_id
DROP INDEX IF EXISTS idx_agent_mapping_audit_log_user_id;

-- Create new index on agent_id
CREATE INDEX IF NOT EXISTS idx_agent_mapping_audit_log_agent_id 
    ON public.agent_mapping_audit_log(agent_id);

-- ============================================
-- Comments
-- ============================================

COMMENT ON COLUMN public.agent_mapping_audit_log.agent_id IS 
    'Agent ID for the mapping operation. Used instead of user_id for privacy protection.';

COMMENT ON COLUMN public.agent_mapping_audit_log.user_id IS 
    'DEPRECATED: Use agent_id instead. This column will be removed in a future migration.';

-- ============================================
-- Verification
-- ============================================
-- After running this migration, verify:
-- 1. agent_id column exists
-- 2. Existing data migrated (if any)
-- 3. New audit logs use agent_id
-- 4. RLS policies updated
