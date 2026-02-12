-- Migration: Onboarding Aggregations Table
-- Created: 2025-12-27
-- Purpose: Store aggregated onboarding data for edge function processing
-- Phase 11 Section 4: Edge Mesh Functions

-- Create onboarding_aggregations table
CREATE TABLE IF NOT EXISTS public.onboarding_aggregations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    aggregated_data JSONB DEFAULT '{}'::jsonb, -- Aggregated onboarding data
    dimensions JSONB DEFAULT '{}'::jsonb, -- Mapped personality dimensions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id) -- One aggregation per user
);

-- Create indexes for onboarding_aggregations
CREATE INDEX IF NOT EXISTS idx_onboarding_aggregations_agent_id ON public.onboarding_aggregations(agent_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_aggregations_updated_at ON public.onboarding_aggregations(updated_at DESC);

-- Enable RLS on onboarding_aggregations
ALTER TABLE public.onboarding_aggregations ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role can manage all aggregations (edge functions use service role)
CREATE POLICY "Service role can manage all aggregations" ON public.onboarding_aggregations
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policy: Users can read their own aggregations (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can read own aggregations" ON public.onboarding_aggregations
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_onboarding_aggregations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_onboarding_aggregations_updated_at
    BEFORE UPDATE ON public.onboarding_aggregations
    FOR EACH ROW
    EXECUTE FUNCTION update_onboarding_aggregations_updated_at();
