-- Migration: Structured Facts Table
-- Created: 2025-12-27
-- Purpose: Store structured facts extracted from user interactions for LLM context
-- Phase 11 Section 5: Retrieval + LLM Fusion

-- Create structured_facts table
CREATE TABLE IF NOT EXISTS public.structured_facts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    traits TEXT[] DEFAULT '{}', -- User traits/preferences
    places TEXT[] DEFAULT '{}', -- Place IDs user has interacted with
    social_graph TEXT[] DEFAULT '{}', -- Social graph connections
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id) -- One facts record per user (updated incrementally)
);

-- Create indexes for structured_facts
CREATE INDEX IF NOT EXISTS idx_structured_facts_agent_id ON public.structured_facts(agent_id);
CREATE INDEX IF NOT EXISTS idx_structured_facts_updated_at ON public.structured_facts(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_structured_facts_traits ON public.structured_facts USING GIN(traits);
CREATE INDEX IF NOT EXISTS idx_structured_facts_places ON public.structured_facts USING GIN(places);

-- Enable RLS on structured_facts
ALTER TABLE public.structured_facts ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role can manage all facts (edge functions use service role)
CREATE POLICY "Service role can manage all facts" ON public.structured_facts
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policy: Users can read their own facts (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can read own facts" ON public.structured_facts
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_structured_facts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_structured_facts_updated_at
    BEFORE UPDATE ON public.structured_facts
    FOR EACH ROW
    EXECUTE FUNCTION update_structured_facts_updated_at();
