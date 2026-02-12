-- Migration: Secure Agent ID Mappings
-- Created: 2025-12-30
-- Purpose: Encrypt userId ↔ agentId mappings using AES-256-GCM
-- Security: Critical - Replaces insecure plaintext storage
-- Phase: Secure Agent ID Mapping Implementation Plan - Phase 2

-- ============================================
-- Create new secure mapping table
-- ============================================
-- This table stores encrypted userId ↔ agentId mappings
-- All mappings are encrypted before storage (no plaintext)

CREATE TABLE IF NOT EXISTS public.user_agent_mappings_secure (
    -- Primary key
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Encrypted mapping blob (NOT plaintext)
    encrypted_mapping BYTEA NOT NULL,
    
    -- Encryption metadata
    encryption_key_id TEXT NOT NULL,
    encryption_algorithm TEXT NOT NULL DEFAULT 'aes256_gcm',
    encryption_version INTEGER NOT NULL DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_rotated_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    
    -- Security metadata
    access_count INTEGER DEFAULT 0,
    rotation_count INTEGER DEFAULT 0,
    
    -- Constraints
    CONSTRAINT encryption_algorithm_check CHECK (encryption_algorithm IN ('signal_protocol', 'aes256_gcm')),
    CONSTRAINT encryption_version_check CHECK (encryption_version >= 1)
);

-- ============================================
-- Indexes (for performance, NOT for reverse lookup)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_agent_mappings_secure_user_id 
    ON public.user_agent_mappings_secure(user_id);
CREATE INDEX IF NOT EXISTS idx_user_agent_mappings_secure_key_id 
    ON public.user_agent_mappings_secure(encryption_key_id);

-- ============================================
-- RLS Policies (CRITICAL for security)
-- ============================================
-- Performance: Wrap auth.uid() and auth.role() in subqueries for caching
-- Reference: migration 021_fix_rls_performance.sql

ALTER TABLE public.user_agent_mappings_secure ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only SELECT their own encrypted mapping
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can access own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR SELECT
    USING ((select auth.uid()) = user_id);

-- Policy: Users can INSERT their own mapping (with RLS enforcement)
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can insert own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

-- Policy: Users can UPDATE their own mapping (for rotation)
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can update own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

-- Policy: Service role can manage all mappings (for admin operations)
-- Performance: Wrap auth.role() in subquery for caching
CREATE POLICY "Service role can manage encrypted mappings"
    ON public.user_agent_mappings_secure
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- ============================================
-- Audit log table (for security monitoring)
-- ============================================

CREATE TABLE IF NOT EXISTS public.agent_mapping_audit_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'created', 'accessed', 'rotated', 'deleted'
    encryption_key_id TEXT,
    accessed_by TEXT, -- 'user' or 'service_role'
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT action_check CHECK (action IN ('created', 'accessed', 'rotated', 'deleted'))
);

-- Index for audit log
CREATE INDEX IF NOT EXISTS idx_agent_mapping_audit_log_user_id 
    ON public.agent_mapping_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_mapping_audit_log_created_at 
    ON public.agent_mapping_audit_log(created_at DESC);

-- RLS for audit log (users can only see their own audit entries)
ALTER TABLE public.agent_mapping_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own audit log"
    ON public.agent_mapping_audit_log
    FOR SELECT
    USING ((select auth.uid()) = user_id);

-- Service role can view all audit logs (for security monitoring)
CREATE POLICY "Service role can view all audit logs"
    ON public.agent_mapping_audit_log
    FOR SELECT
    USING ((select auth.role()) = 'service_role');

-- ============================================
-- Helper Function: Increment access count
-- ============================================
-- Used for updating access_count atomically

CREATE OR REPLACE FUNCTION increment_access_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.user_agent_mappings_secure
    SET access_count = access_count + 1
    WHERE user_id = p_user_id
    RETURNING access_count INTO v_count;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Helper Function: Increment rotation count
-- ============================================
-- Used for updating rotation_count atomically

CREATE OR REPLACE FUNCTION increment_rotation_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.user_agent_mappings_secure
    SET rotation_count = rotation_count + 1
    WHERE user_id = p_user_id
    RETURNING rotation_count INTO v_count;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Comments
-- ============================================

COMMENT ON TABLE public.user_agent_mappings_secure IS 
    'Stores encrypted userId ↔ agentId mappings. All mappings are encrypted using AES-256-GCM before storage. Keys are stored in FlutterSecureStorage (not in database).';

COMMENT ON COLUMN public.user_agent_mappings_secure.encrypted_mapping IS 
    'Encrypted blob containing userId and agentId. Format: [IV (12 bytes)][ciphertext][tag (16 bytes)]. Cannot be read without decryption.';

COMMENT ON COLUMN public.user_agent_mappings_secure.encryption_key_id IS 
    'Identifier for the encryption key used. Keys are stored in FlutterSecureStorage, not in database.';

COMMENT ON TABLE public.agent_mapping_audit_log IS 
    'Audit log for all agent ID mapping operations. Tracks creation, access, rotation, and deletion for security monitoring.';

-- ============================================
-- Verification
-- ============================================
-- After running this migration, verify:
-- 1. Table created successfully
-- 2. RLS policies enabled
-- 3. Indexes created
-- 4. Helper functions created
-- 5. Old table (user_agent_mappings) still exists for migration
