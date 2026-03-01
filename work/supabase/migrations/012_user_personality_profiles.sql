-- Migration: User Personality Profiles Table
-- Created: 2025-12-01
-- Purpose: Store encrypted personality profiles for cross-device sync
-- Philosophy: Encrypted cloud backup, local-first primary storage

-- Create user_personality_profiles table
CREATE TABLE IF NOT EXISTS public.user_personality_profiles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    encrypted_profile JSONB NOT NULL, -- Encrypted personality profile JSON
    profile_version INTEGER DEFAULT 1, -- For conflict resolution
    cloud_sync_enabled BOOLEAN DEFAULT false, -- Opt-in flag (stored in cloud for consistency)
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on cloud_sync_enabled for querying enabled profiles
CREATE INDEX IF NOT EXISTS idx_user_personality_profiles_sync_enabled 
    ON public.user_personality_profiles(cloud_sync_enabled) 
    WHERE cloud_sync_enabled = true;

-- Create index on last_synced_at for monitoring
CREATE INDEX IF NOT EXISTS idx_user_personality_profiles_last_synced 
    ON public.user_personality_profiles(last_synced_at);

-- Enable RLS
ALTER TABLE public.user_personality_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only SELECT their own profile
DROP POLICY IF EXISTS "Users can read own personality profile" ON public.user_personality_profiles;

CREATE POLICY "Users can read own personality profile" 
    ON public.user_personality_profiles
    FOR SELECT 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only UPDATE their own profile
DROP POLICY IF EXISTS "Users can update own personality profile" ON public.user_personality_profiles;

CREATE POLICY "Users can update own personality profile" 
    ON public.user_personality_profiles
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only INSERT their own profile
DROP POLICY IF EXISTS "Users can insert own personality profile" ON public.user_personality_profiles;

CREATE POLICY "Users can insert own personality profile" 
    ON public.user_personality_profiles
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_personality_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS trigger_update_user_personality_profiles_updated_at 
    ON public.user_personality_profiles;

CREATE TRIGGER trigger_update_user_personality_profiles_updated_at
    BEFORE UPDATE ON public.user_personality_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_user_personality_profiles_updated_at();

-- Function to increment profile_version on update
CREATE OR REPLACE FUNCTION increment_personality_profile_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW.profile_version = OLD.profile_version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically increment version
DROP TRIGGER IF EXISTS trigger_increment_personality_profile_version 
    ON public.user_personality_profiles;

CREATE TRIGGER trigger_increment_personality_profile_version
    BEFORE UPDATE ON public.user_personality_profiles
    FOR EACH ROW
    WHEN (OLD.encrypted_profile IS DISTINCT FROM NEW.encrypted_profile)
    EXECUTE FUNCTION increment_personality_profile_version();
