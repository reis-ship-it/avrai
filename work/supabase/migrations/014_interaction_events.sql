-- Migration: Interaction Events Table
-- Phase 11: User-AI Interaction Update - Section 1.1
-- Creates table for tracking user interaction events with context enrichment

-- Create interaction_events table
CREATE TABLE IF NOT EXISTS interaction_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT NOT NULL, -- Privacy-protected identifier
  event_type TEXT NOT NULL, -- list_view_started, respect_tap, scroll_depth, etc.
  parameters JSONB NOT NULL DEFAULT '{}', -- Flexible event parameters
  context JSONB, -- time, location, weather, social context
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_interaction_events_agent_id ON interaction_events(agent_id);
CREATE INDEX IF NOT EXISTS idx_interaction_events_timestamp ON interaction_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_interaction_events_type ON interaction_events(event_type);
CREATE INDEX IF NOT EXISTS idx_interaction_events_agent_type ON interaction_events(agent_id, event_type);

-- Enable RLS (Row Level Security)
ALTER TABLE interaction_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own events (via agentId)
-- Note: This policy uses a function to resolve agent_id from user_id
-- The actual enforcement happens at the application level using agent_id
CREATE POLICY "Users can view own events"
  ON interaction_events
  FOR SELECT
  USING (
    agent_id IN (
      SELECT agent_id 
      FROM user_agent_mappings 
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Users can insert their own events
CREATE POLICY "Users can insert own events"
  ON interaction_events
  FOR INSERT
  WITH CHECK (
    agent_id IN (
      SELECT agent_id 
      FROM user_agent_mappings 
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Users can update their own events (for corrections)
CREATE POLICY "Users can update own events"
  ON interaction_events
  FOR UPDATE
  USING (
    agent_id IN (
      SELECT agent_id 
      FROM user_agent_mappings 
      WHERE user_id = auth.uid()
    )
  );

-- Add comment to table
COMMENT ON TABLE interaction_events IS 'Tracks user interaction events with rich context (location, weather, time, social, app state) for AI personality learning';
COMMENT ON COLUMN interaction_events.agent_id IS 'Privacy-protected user identifier for ai2ai network routing';
COMMENT ON COLUMN interaction_events.event_type IS 'Type of interaction event (list_view_started, respect_tap, scroll_depth, etc.)';
COMMENT ON COLUMN interaction_events.parameters IS 'Event-specific parameters (list_id, category, duration_ms, etc.)';
COMMENT ON COLUMN interaction_events.context IS 'Rich context at time of event (time, location, weather, social, app state)';
