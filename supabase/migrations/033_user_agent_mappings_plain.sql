-- Migration: user_agent_mappings (plaintext)
-- Created: 2026-01-01
-- Purpose: Provide minimal userId ↔ agentId mapping table required by existing RLS policies
-- Notes:
-- - Some parts of the repo reference a secure encrypted mapping table, but `interaction_events` RLS
--   currently references `user_agent_mappings`. This migration makes that dependency explicit.

CREATE TABLE IF NOT EXISTS public.user_agent_mappings (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  agent_id TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_agent_mappings_agent_id
  ON public.user_agent_mappings(agent_id);

ALTER TABLE public.user_agent_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own agent mapping"
  ON public.user_agent_mappings
  FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own agent mapping"
  ON public.user_agent_mappings
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Service role can manage agent mappings"
  ON public.user_agent_mappings
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.user_agent_mappings IS 'Plaintext userId ↔ agentId mapping (used by interaction_events RLS).';

