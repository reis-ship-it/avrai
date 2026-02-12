-- Migration: Calling Score Training Data Table
-- Created: 2025-12-28
-- Purpose: Store calling score calculations and outcomes for neural network training
-- Phase 12 Section 1: Foundation & Data Collection

-- Create calling_score_training_data table
CREATE TABLE IF NOT EXISTS public.calling_score_training_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    opportunity_id TEXT NOT NULL, -- Spot, event, list, etc. ID
    
    -- Input features (for training)
    user_vibe_dimensions JSONB NOT NULL, -- User vibe dimensions (12D)
    spot_vibe_dimensions JSONB NOT NULL, -- Spot vibe dimensions (12D)
    context_features JSONB DEFAULT '{}'::jsonb, -- Context features (location, time, etc.)
    timing_features JSONB DEFAULT '{}'::jsonb, -- Timing features (time of day, day of week, etc.)
    
    -- Formula-based calculation (baseline)
    formula_calling_score DOUBLE PRECISION NOT NULL CHECK (formula_calling_score >= 0.0 AND formula_calling_score <= 1.0),
    formula_is_called BOOLEAN NOT NULL,
    formula_breakdown JSONB NOT NULL, -- CallingScoreBreakdown (vibe_compatibility, life_betterment, etc.)
    
    -- Outcome data (linked when available)
    outcome_id UUID, -- Link to outcome_result table (if exists)
    outcome_type TEXT, -- 'positive', 'negative', 'neutral', or NULL if no outcome yet
    outcome_score DOUBLE PRECISION CHECK (outcome_score IS NULL OR (outcome_score >= 0.0 AND outcome_score <= 1.0)),
    outcome_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb -- Additional metadata
);

-- Create indexes for calling_score_training_data
CREATE INDEX IF NOT EXISTS idx_calling_score_training_agent_id ON public.calling_score_training_data(agent_id);
CREATE INDEX IF NOT EXISTS idx_calling_score_training_opportunity_id ON public.calling_score_training_data(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_calling_score_training_timestamp ON public.calling_score_training_data(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_calling_score_training_outcome_type ON public.calling_score_training_data(outcome_type) WHERE outcome_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calling_score_training_formula_is_called ON public.calling_score_training_data(formula_is_called);
CREATE INDEX IF NOT EXISTS idx_calling_score_training_agent_opportunity ON public.calling_score_training_data(agent_id, opportunity_id);

-- Enable RLS on calling_score_training_data
ALTER TABLE public.calling_score_training_data ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role can manage all training data (edge functions use service role)
CREATE POLICY "Service role can manage all training data" ON public.calling_score_training_data
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policy: Users can read their own training data (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can read own training data" ON public.calling_score_training_data
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_calling_score_training_data_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER calling_score_training_data_updated_at
    BEFORE UPDATE ON public.calling_score_training_data
    FOR EACH ROW
    EXECUTE FUNCTION update_calling_score_training_data_updated_at();

-- Add comment to table
COMMENT ON TABLE public.calling_score_training_data IS 'Stores calling score calculations and outcomes for neural network training (Phase 12)';
