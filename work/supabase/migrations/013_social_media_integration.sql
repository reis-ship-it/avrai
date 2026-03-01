-- Migration: Social Media Integration Tables
-- Created: 2025-12-23
-- Purpose: Store social media connections, profiles, and insights
-- Phase 10 Section 1: Core Infrastructure
-- Philosophy: Privacy-first, offline-first, agentId-based

-- Create social_media_connections table
CREATE TABLE IF NOT EXISTS public.social_media_connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier (not userId)
    platform TEXT NOT NULL CHECK (platform IN ('google', 'instagram', 'facebook', 'twitter', 'tiktok', 'linkedin', 'pinterest', 'youtube', 'reddit', 'discord')),
    platform_user_id TEXT, -- Platform user ID (from social media platform)
    platform_username TEXT, -- Platform username/display name
    access_token_encrypted TEXT, -- Encrypted with AES-256-GCM (stored in secure storage, not here)
    refresh_token_encrypted TEXT, -- Encrypted with AES-256-GCM (stored in secure storage, not here)
    token_expires_at TIMESTAMP WITH TIME ZONE,
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    last_token_refresh TIMESTAMP WITH TIME ZONE,
    permissions JSONB DEFAULT '{}'::jsonb, -- What user consented to
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb, -- Platform-specific data
    error_message TEXT, -- Last error (if any)
    sync_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id, platform) -- One connection per platform per user
);

-- Create indexes for social_media_connections
CREATE INDEX IF NOT EXISTS idx_social_media_connections_agent_id ON public.social_media_connections(agent_id);
CREATE INDEX IF NOT EXISTS idx_social_media_connections_platform ON public.social_media_connections(platform);
CREATE INDEX IF NOT EXISTS idx_social_media_connections_active ON public.social_media_connections(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_social_media_connections_token_expires ON public.social_media_connections(token_expires_at) WHERE token_expires_at IS NOT NULL;

-- Create social_media_profiles table
CREATE TABLE IF NOT EXISTS public.social_media_profiles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    connection_id UUID NOT NULL REFERENCES public.social_media_connections(id) ON DELETE CASCADE,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    platform TEXT NOT NULL,
    username TEXT,
    display_name TEXT,
    profile_image_url TEXT,
    interests TEXT[] DEFAULT '{}', -- Extracted interests
    communities TEXT[] DEFAULT '{}', -- Groups, pages, etc.
    friends_hashed TEXT[] DEFAULT '{}', -- Friend IDs (hashed with SHA-256)
    raw_data_encrypted TEXT, -- Raw platform data (encrypted, local only - stored in secure storage)
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(connection_id) -- One profile per connection
);

-- Create indexes for social_media_profiles
CREATE INDEX IF NOT EXISTS idx_social_media_profiles_agent_id ON public.social_media_profiles(agent_id);
CREATE INDEX IF NOT EXISTS idx_social_media_profiles_connection_id ON public.social_media_profiles(connection_id);
CREATE INDEX IF NOT EXISTS idx_social_media_profiles_platform ON public.social_media_profiles(platform);
CREATE INDEX IF NOT EXISTS idx_social_media_profiles_interests ON public.social_media_profiles USING GIN(interests);
CREATE INDEX IF NOT EXISTS idx_social_media_profiles_communities ON public.social_media_profiles USING GIN(communities);

-- Create social_media_insights table
CREATE TABLE IF NOT EXISTS public.social_media_insights (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    interest_scores JSONB DEFAULT '{}'::jsonb, -- Interest → score mapping
    community_scores JSONB DEFAULT '{}'::jsonb, -- Community → score mapping
    extracted_interests TEXT[] DEFAULT '{}',
    extracted_communities TEXT[] DEFAULT '{}',
    dimension_updates JSONB DEFAULT '{}'::jsonb, -- Personality dimension updates
    confidence_score DOUBLE PRECISION DEFAULT 0.0 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    metadata JSONB DEFAULT '{}'::jsonb, -- Analysis metadata
    last_analyzed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id) -- One insight record per user
);

-- Create indexes for social_media_insights
CREATE INDEX IF NOT EXISTS idx_social_media_insights_agent_id ON public.social_media_insights(agent_id);
CREATE INDEX IF NOT EXISTS idx_social_media_insights_confidence ON public.social_media_insights(confidence_score);
CREATE INDEX IF NOT EXISTS idx_social_media_insights_last_analyzed ON public.social_media_insights(last_analyzed);

-- Enable RLS on all tables
ALTER TABLE public.social_media_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_media_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_media_insights ENABLE ROW LEVEL SECURITY;

-- RLS Policies for social_media_connections
-- Note: Since we use agentId (not userId), we need to check via user lookup
-- For now, we'll use a service role approach or check via user_id lookup
-- This will be enhanced when user_agent_mappings table exists

-- Policy: Users can only access their own connections (via agentId lookup)
-- TODO(Phase 10): Enhance RLS policies when user_agent_mappings table exists
-- For now, using a placeholder that allows service role access
CREATE POLICY "Service role can manage all connections" ON public.social_media_connections
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for social_media_profiles
CREATE POLICY "Service role can manage all profiles" ON public.social_media_profiles
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for social_media_insights
CREATE POLICY "Service role can manage all insights" ON public.social_media_insights
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_social_media_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to automatically update updated_at
CREATE TRIGGER trigger_update_social_media_connections_updated_at
    BEFORE UPDATE ON public.social_media_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_social_media_updated_at();

CREATE TRIGGER trigger_update_social_media_profiles_updated_at
    BEFORE UPDATE ON public.social_media_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_social_media_updated_at();

CREATE TRIGGER trigger_update_social_media_insights_updated_at
    BEFORE UPDATE ON public.social_media_insights
    FOR EACH ROW
    EXECUTE FUNCTION update_social_media_updated_at();
