-- Migration: Event User Calls Table
-- Created: 2025-12-29
-- Purpose: Store event user calls for Phase 19 Section 19.4: Dynamic Real-Time User Calling System
-- Patent #29: Multi-Entity Quantum Entanglement Matching System

-- Create event_user_calls table
CREATE TABLE IF NOT EXISTS public.event_user_calls (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_id TEXT NOT NULL,
    user_id TEXT NOT NULL, -- User ID (can be agent_id for privacy in future)
    compatibility_score DOUBLE PRECISION NOT NULL CHECK (compatibility_score >= 0.0 AND compatibility_score <= 1.0),
    called_at TIMESTAMPTZ NOT NULL,
    atomic_timestamp_id TEXT, -- For precise temporal tracking
    stopped_at TIMESTAMPTZ, -- NULL if still active
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'stopped', 'expired')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_event_user_calls_event_id ON public.event_user_calls(event_id);
CREATE INDEX IF NOT EXISTS idx_event_user_calls_user_id ON public.event_user_calls(user_id);
CREATE INDEX IF NOT EXISTS idx_event_user_calls_status ON public.event_user_calls(status);
CREATE INDEX IF NOT EXISTS idx_event_user_calls_called_at ON public.event_user_calls(called_at DESC);
CREATE INDEX IF NOT EXISTS idx_event_user_calls_event_status ON public.event_user_calls(event_id, status);

-- Enable RLS (Row Level Security)
ALTER TABLE public.event_user_calls ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own calls
CREATE POLICY "Users can view own calls"
  ON public.event_user_calls
  FOR SELECT
  USING (user_id = auth.uid()::text);

-- Policy: Service role can manage all calls (for RealTimeUserCallingService)
CREATE POLICY "Service role can manage all calls"
  ON public.event_user_calls
  FOR ALL
  USING ((select auth.role()) = 'service_role');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_event_user_calls_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_event_user_calls_updated_at_trigger
  BEFORE UPDATE ON public.event_user_calls
  FOR EACH ROW
  EXECUTE FUNCTION update_event_user_calls_updated_at();
