-- Migration: Learning History Table
-- Created: 2025-12-28
-- Purpose: Store learning history for quality monitoring and analytics
-- Phase 11 Section 8: Learning Quality Monitoring

-- Create learning_history table
CREATE TABLE IF NOT EXISTS public.learning_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    dimension TEXT NOT NULL, -- Learning dimension (e.g., 'user_preference_understanding')
    improvement DOUBLE PRECISION NOT NULL, -- Improvement value (0.0-1.0)
    data_source TEXT NOT NULL, -- Data source that contributed to learning (e.g., 'user_actions')
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb -- Additional metadata about the learning event
);

-- Create indexes for learning_history
CREATE INDEX IF NOT EXISTS idx_learning_history_agent_id ON public.learning_history(agent_id);
CREATE INDEX IF NOT EXISTS idx_learning_history_dimension ON public.learning_history(dimension);
CREATE INDEX IF NOT EXISTS idx_learning_history_timestamp ON public.learning_history(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_learning_history_data_source ON public.learning_history(data_source);
CREATE INDEX IF NOT EXISTS idx_learning_history_agent_dimension ON public.learning_history(agent_id, dimension);

-- Enable RLS on learning_history
ALTER TABLE public.learning_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role can manage all learning history (edge functions use service role)
CREATE POLICY "Service role can manage all learning history" ON public.learning_history
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policy: Users can read their own learning history (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can read own learning history" ON public.learning_history
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists

-- Create function to get learning history summary
CREATE OR REPLACE FUNCTION get_learning_history_summary(
    p_agent_id TEXT,
    p_dimension TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    dimension TEXT,
    total_events BIGINT,
    avg_improvement DOUBLE PRECISION,
    max_improvement DOUBLE PRECISION,
    min_improvement DOUBLE PRECISION,
    most_effective_source TEXT,
    last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        lh.dimension,
        COUNT(*)::BIGINT AS total_events,
        AVG(lh.improvement)::DOUBLE PRECISION AS avg_improvement,
        MAX(lh.improvement)::DOUBLE PRECISION AS max_improvement,
        MIN(lh.improvement)::DOUBLE PRECISION AS min_improvement,
        MODE() WITHIN GROUP (ORDER BY lh.data_source) AS most_effective_source,
        MAX(lh.timestamp) AS last_updated
    FROM public.learning_history lh
    WHERE lh.agent_id = p_agent_id
        AND (p_dimension IS NULL OR lh.dimension = p_dimension)
    GROUP BY lh.dimension
    ORDER BY last_updated DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
