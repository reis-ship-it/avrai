-- Migration: LLM Responses Table
-- Created: 2025-12-27
-- Purpose: Store LLM generation responses for tracking and analysis
-- Phase 11 Section 4: Edge Mesh Functions

-- Create llm_responses table
CREATE TABLE IF NOT EXISTS public.llm_responses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id TEXT NOT NULL, -- Privacy-protected identifier
    query TEXT NOT NULL, -- User query that triggered the LLM
    response TEXT NOT NULL, -- Generated LLM response
    model TEXT DEFAULT 'gemini-pro', -- LLM model used
    usage_metadata JSONB DEFAULT '{}'::jsonb, -- Token usage, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for llm_responses
CREATE INDEX IF NOT EXISTS idx_llm_responses_agent_id ON public.llm_responses(agent_id);
CREATE INDEX IF NOT EXISTS idx_llm_responses_created_at ON public.llm_responses(created_at DESC);

-- Enable RLS on llm_responses
ALTER TABLE public.llm_responses ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role can manage all responses (edge functions use service role)
CREATE POLICY "Service role can manage all responses" ON public.llm_responses
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policy: Users can read their own responses (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can read own responses" ON public.llm_responses
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists
