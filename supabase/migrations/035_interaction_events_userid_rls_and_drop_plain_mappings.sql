-- Migration: Interaction Events - user_id-based RLS + drop plaintext agent mapping dependency
-- Created: 2026-01-01
-- Purpose:
-- - Remove dependency on `public.user_agent_mappings` for RLS (plaintext mapping)
-- - Enforce ownership on `public.interaction_events` via `user_id = auth.uid()`
-- - Keep `agent_id` column for ai2ai routing and internal aggregation, but don't use it for RLS
--
-- Security rationale:
-- - The linking table `user_agent_mappings` (user_id ↔ agent_id) is a high-risk join surface.
-- - `interaction_events` is an internal telemetry table; user-level access can be enforced via user_id.

-- Add user_id to interaction_events (nullable for legacy rows)
ALTER TABLE public.interaction_events
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_interaction_events_user_id
  ON public.interaction_events(user_id);

-- Replace RLS policies that depended on user_agent_mappings
DROP POLICY IF EXISTS "Users can view own events" ON public.interaction_events;
DROP POLICY IF EXISTS "Users can insert own events" ON public.interaction_events;
DROP POLICY IF EXISTS "Users can update own events" ON public.interaction_events;

CREATE POLICY "Users can view own events"
  ON public.interaction_events
  FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own events"
  ON public.interaction_events
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own events"
  ON public.interaction_events
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Ensure service role can operate (edge functions / internal pipelines)
DROP POLICY IF EXISTS "Service role can manage interaction events" ON public.interaction_events;

CREATE POLICY "Service role can manage interaction events"
  ON public.interaction_events
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Drop plaintext mapping table (no longer used by RLS)
DROP TABLE IF EXISTS public.user_agent_mappings;

COMMENT ON COLUMN public.interaction_events.user_id IS 'Internal ownership for RLS (auth.uid). Not exported to outside buyers.';

