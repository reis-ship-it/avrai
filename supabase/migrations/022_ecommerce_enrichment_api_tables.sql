-- Migration: E-Commerce Enrichment API Tables
-- Created: 2025-12-23
-- Purpose: Create tables for API key management and request logging
-- Phase 21 Section 1: Foundation & Infrastructure

-- ============================================
-- API Keys Table
-- ============================================
-- Stores API keys for e-commerce partners
-- API keys are hashed (SHA-256) for security

CREATE TABLE IF NOT EXISTS public.api_keys (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    partner_id TEXT NOT NULL, -- E-commerce partner identifier (e.g., "alibaba", "shopify")
    api_key_hash TEXT NOT NULL UNIQUE, -- SHA-256 hash of the API key
    rate_limit_per_minute INTEGER DEFAULT 100, -- Requests per minute limit
    rate_limit_per_day INTEGER DEFAULT 10000, -- Requests per day limit
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- Optional expiration date
    metadata JSONB DEFAULT '{}'::jsonb -- Additional partner metadata
);

-- Index for fast API key lookups
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON public.api_keys(api_key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_partner_id ON public.api_keys(partner_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON public.api_keys(is_active) WHERE is_active = true;

-- ============================================
-- API Request Logs Table
-- ============================================
-- Logs all API requests for rate limiting and analytics

CREATE TABLE IF NOT EXISTS public.api_request_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    api_key_id UUID NOT NULL REFERENCES public.api_keys(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL, -- Endpoint name (e.g., "real-world-behavior")
    method TEXT NOT NULL, -- HTTP method (GET, POST, etc.)
    request_body JSONB, -- Request body (optional, for debugging)
    response_status INTEGER NOT NULL, -- HTTP status code
    processing_time_ms INTEGER NOT NULL, -- Processing time in milliseconds
    error_code TEXT, -- Error code if request failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for rate limiting queries
CREATE INDEX IF NOT EXISTS idx_api_request_logs_api_key_id ON public.api_request_logs(api_key_id);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_created_at ON public.api_request_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_api_key_created ON public.api_request_logs(api_key_id, created_at);

-- Composite index for rate limiting queries (optimized)
CREATE INDEX IF NOT EXISTS idx_api_request_logs_rate_limit ON public.api_request_logs(api_key_id, created_at DESC);

-- ============================================
-- Market Segments Table (for caching)
-- ============================================
-- Caches market segment definitions and metadata
-- Reduces redundant calculations for common segments

CREATE TABLE IF NOT EXISTS public.market_segments (
    segment_id TEXT PRIMARY KEY, -- Unique segment identifier (e.g., "tech_enthusiasts_25_35_sf")
    segment_definition JSONB NOT NULL, -- Segment criteria (age_range, interests, location, etc.)
    sample_size INTEGER, -- Number of users in segment
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_ttl_minutes INTEGER DEFAULT 60, -- Cache TTL in minutes
    metadata JSONB DEFAULT '{}'::jsonb -- Additional segment metadata
);

-- Index for cache invalidation
CREATE INDEX IF NOT EXISTS idx_market_segments_last_updated ON public.market_segments(last_updated);

-- ============================================
-- Enable RLS on all tables
-- ============================================

ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_request_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_segments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS Policies
-- ============================================
-- Service role can manage all API-related tables
-- No user access (API keys are for service-to-service communication)

-- API Keys: Service role only
CREATE POLICY "Service role can manage api_keys" ON public.api_keys
    FOR ALL 
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- API Request Logs: Service role only
CREATE POLICY "Service role can manage api_request_logs" ON public.api_request_logs
    FOR ALL 
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Market Segments: Service role only
CREATE POLICY "Service role can manage market_segments" ON public.market_segments
    FOR ALL 
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- ============================================
-- Helper Function: Generate API Key
-- ============================================
-- Function to generate a new API key for a partner
-- Returns the plaintext key (store securely) and stores the hash

CREATE OR REPLACE FUNCTION generate_api_key(
    p_partner_id TEXT,
    p_rate_limit_per_minute INTEGER DEFAULT 100,
    p_rate_limit_per_day INTEGER DEFAULT 10000,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    v_api_key TEXT;
    v_api_key_hash TEXT;
BEGIN
    -- Generate random API key (format: spots_poc_{partner_id}_{random_hex})
    v_api_key := 'spots_poc_' || p_partner_id || '_' || encode(gen_random_bytes(16), 'hex');
    
    -- Hash the API key (SHA-256)
    v_api_key_hash := encode(digest(v_api_key, 'sha256'), 'hex');
    
    -- Insert into api_keys table
    INSERT INTO public.api_keys (
        partner_id,
        api_key_hash,
        rate_limit_per_minute,
        rate_limit_per_day,
        expires_at
    ) VALUES (
        p_partner_id,
        v_api_key_hash,
        p_rate_limit_per_minute,
        p_rate_limit_per_day,
        p_expires_at
    );
    
    -- Return the plaintext key (caller must store securely)
    RETURN v_api_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Helper Function: Validate API Key
-- ============================================
-- Function to validate an API key and return key info
-- Used by Edge Function for authentication

CREATE OR REPLACE FUNCTION validate_api_key(p_api_key_hash TEXT)
RETURNS TABLE (
    id UUID,
    partner_id TEXT,
    rate_limit_per_minute INTEGER,
    rate_limit_per_day INTEGER,
    is_active BOOLEAN,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ak.id,
        ak.partner_id,
        ak.rate_limit_per_minute,
        ak.rate_limit_per_day,
        ak.is_active,
        ak.expires_at
    FROM public.api_keys ak
    WHERE ak.api_key_hash = p_api_key_hash
    AND ak.is_active = true
    AND (ak.expires_at IS NULL OR ak.expires_at > NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Comments
-- ============================================

COMMENT ON TABLE public.api_keys IS 'API keys for e-commerce enrichment API partners';
COMMENT ON TABLE public.api_request_logs IS 'Logs all API requests for rate limiting and analytics';
COMMENT ON TABLE public.market_segments IS 'Cached market segment definitions and metadata';
COMMENT ON FUNCTION generate_api_key IS 'Generates a new API key for a partner and returns the plaintext key';
COMMENT ON FUNCTION validate_api_key IS 'Validates an API key hash and returns key information';
