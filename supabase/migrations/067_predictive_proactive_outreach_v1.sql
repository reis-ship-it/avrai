-- Migration: Predictive Proactive Outreach System (v1) - Vectorless Architecture
-- Created: 2026-01-06
-- Purpose: Database schema for predictive proactive outreach using vectorless approach
-- Architecture: JSONB for complex structures, scalar cache for compatibility, no vector embeddings
-- Reference: docs/plans/predictive_outreach/PREDICTIVE_PROACTIVE_OUTREACH_PLAN.md

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- Outreach Queue Table
-- ============================================================
-- Stores proactive outreach messages queued for delivery
-- Silent delivery: no push notifications, shown when user opens app

CREATE TABLE IF NOT EXISTS public.outreach_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Outreach Type
    type TEXT NOT NULL CHECK (type IN (
        'community_invitation',
        'group_formation',
        'event_call',
        'spot_recommendation',
        'friend_suggestion',
        'business_event_invitation',
        'business_expert_partnership',
        'business_business_partnership',
        'club_membership_invitation',
        'club_event_invitation',
        'expert_learning_opportunity',
        'expert_business_partnership',
        'list_suggestion',
        'expert_curated_list'
    )),
    
    -- Target and Source
    target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_id TEXT NOT NULL, -- Community ID, Event ID, Business ID, Expert ID, etc.
    source_type TEXT NOT NULL CHECK (source_type IN (
        'community',
        'group',
        'event',
        'spot',
        'user',
        'business',
        'club',
        'expert',
        'list',
        'system'
    )),
    
    -- Compatibility Scores (scalar values, not vectors)
    compatibility_score DOUBLE PRECISION NOT NULL CHECK (compatibility_score >= 0.0 AND compatibility_score <= 1.0),
    
    -- Predictive Signals (scalar values from knot/quantum calculations)
    string_prediction_score DOUBLE PRECISION, -- From knot evolution string predictions
    quantum_trajectory_score DOUBLE PRECISION, -- From temporal quantum compatibility
    fabric_stability_score DOUBLE PRECISION, -- From fabric stability predictions
    current_weave_fit DOUBLE PRECISION, -- Current compatibility baseline
    evolution_trend TEXT CHECK (evolution_trend IN ('improving', 'stable', 'declining', 'unknown')),
    
    -- AI2AI Metadata
    from_agent_id TEXT NOT NULL, -- Source AI's agentId
    to_agent_id TEXT NOT NULL, -- Target user's AI agentId
    ai_decision_reasoning TEXT, -- Why the AI made this decision
    ai_decision_confidence DOUBLE PRECISION CHECK (ai_decision_confidence >= 0.0 AND ai_decision_confidence <= 1.0),
    
    -- Outreach Content
    reasoning TEXT, -- Human-readable explanation for outreach
    title TEXT, -- Notification title
    body TEXT, -- Notification body
    metadata JSONB DEFAULT '{}'::jsonb, -- Additional outreach data (includes encryption_type: 'signalProtocol' or 'aes256gcm')
    
    -- Timing
    optimal_timing TIMESTAMPTZ, -- When outreach should be delivered (if scheduled)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scheduled_for TIMESTAMPTZ, -- When to process this outreach
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- Queued, not yet processed
        'scheduled',    -- Scheduled for future delivery
        'delivered',    -- Delivered to user (in-app notification)
        'seen',         -- User has seen the notification
        'accepted',     -- User accepted the outreach
        'rejected',     -- User rejected the outreach
        'ignored',      -- User ignored the outreach
        'expired'       -- Outreach expired before delivery
    )),
    
    -- Delivery Tracking
    delivered_at TIMESTAMPTZ,
    seen_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    response_action TEXT CHECK (response_action IN ('accepted', 'rejected', 'ignored')),
    
    -- Expiration
    expires_at TIMESTAMPTZ, -- When outreach expires if not delivered
    
    -- Metadata
    created_by TEXT DEFAULT 'system', -- 'system', 'ai', 'user', etc.
    priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10), -- 1=low, 10=high
    retry_count INTEGER DEFAULT 0 CHECK (retry_count >= 0),
    last_retry_at TIMESTAMPTZ
);

-- Indexes for Outreach Queue
CREATE INDEX IF NOT EXISTS idx_outreach_queue_target_user 
    ON public.outreach_queue(target_user_id, status, created_at DESC)
    WHERE status IN ('pending', 'scheduled', 'delivered');

CREATE INDEX IF NOT EXISTS idx_outreach_queue_optimal_timing 
    ON public.outreach_queue(optimal_timing) 
    WHERE status = 'pending' AND optimal_timing IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_outreach_queue_scheduled_for 
    ON public.outreach_queue(scheduled_for) 
    WHERE status = 'scheduled' AND scheduled_for IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_outreach_queue_source 
    ON public.outreach_queue(source_id, source_type, type);

CREATE INDEX IF NOT EXISTS idx_outreach_queue_agent_ids 
    ON public.outreach_queue(from_agent_id, to_agent_id);

CREATE INDEX IF NOT EXISTS idx_outreach_queue_compatibility 
    ON public.outreach_queue(compatibility_score DESC) 
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_outreach_queue_type_status 
    ON public.outreach_queue(type, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_queue_expires_at 
    ON public.outreach_queue(expires_at) 
    WHERE status IN ('pending', 'scheduled') AND expires_at IS NOT NULL;

-- ============================================================
-- Outreach History Table
-- ============================================================
-- Tracks all outreach sent to prevent duplicates and manage frequency

CREATE TABLE IF NOT EXISTS public.outreach_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Target and Source
    target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_id TEXT NOT NULL,
    source_type TEXT NOT NULL CHECK (source_type IN (
        'community',
        'group',
        'event',
        'spot',
        'user',
        'business',
        'club',
        'expert',
        'list',
        'system'
    )),
    type TEXT NOT NULL CHECK (type IN (
        'community_invitation',
        'group_formation',
        'event_call',
        'spot_recommendation',
        'friend_suggestion',
        'business_event_invitation',
        'business_expert_partnership',
        'business_business_partnership',
        'club_membership_invitation',
        'club_event_invitation',
        'expert_learning_opportunity',
        'expert_business_partnership',
        'list_suggestion',
        'expert_curated_list'
    )),
    
    -- Outreach Details
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    compatibility_score DOUBLE PRECISION CHECK (compatibility_score >= 0.0 AND compatibility_score <= 1.0),
    
    -- Response Tracking
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN (
        'sent',      -- Outreach sent
        'accepted',  -- User accepted
        'rejected',  -- User rejected
        'ignored'    -- User ignored
    )),
    responded_at TIMESTAMPTZ,
    response_action TEXT CHECK (response_action IN ('accepted', 'rejected', 'ignored')),
    
    -- AI2AI Metadata
    from_agent_id TEXT,
    to_agent_id TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Unique constraint: prevent duplicate outreach on same day
    CONSTRAINT unique_outreach_per_day UNIQUE(target_user_id, source_id, type, DATE(sent_at))
);

-- Indexes for Outreach History
CREATE INDEX IF NOT EXISTS idx_outreach_history_target 
    ON public.outreach_history(target_user_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_history_source 
    ON public.outreach_history(source_id, source_type, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_history_type 
    ON public.outreach_history(type, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_history_status 
    ON public.outreach_history(status, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_history_recent 
    ON public.outreach_history(target_user_id, source_id, type, sent_at DESC);

-- ============================================================
-- Compatibility Cache Table
-- ============================================================
-- Caches compatibility scores (scalar values) for fast lookups
-- Vectorless: stores pre-calculated scalar scores, not embeddings

CREATE TABLE IF NOT EXISTS public.compatibility_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Source and Target
    source_id TEXT NOT NULL, -- Can be user_id, agent_id, community_id, etc.
    source_type TEXT NOT NULL CHECK (source_type IN (
        'user',
        'agent',
        'community',
        'group',
        'event',
        'spot',
        'business',
        'club',
        'expert',
        'list'
    )),
    target_id TEXT NOT NULL,
    target_type TEXT NOT NULL CHECK (target_type IN (
        'user',
        'agent',
        'community',
        'group',
        'event',
        'spot',
        'business',
        'club',
        'expert',
        'list'
    )),
    
    -- Compatibility Scores (scalar values, not vectors)
    compatibility_score DOUBLE PRECISION NOT NULL CHECK (compatibility_score >= 0.0 AND compatibility_score <= 1.0),
    
    -- Component Scores (from different calculation methods)
    knot_compatibility DOUBLE PRECISION CHECK (knot_compatibility >= 0.0 AND knot_compatibility <= 1.0),
    quantum_fidelity DOUBLE PRECISION CHECK (quantum_fidelity >= 0.0 AND quantum_fidelity <= 1.0),
    location_compatibility DOUBLE PRECISION CHECK (location_compatibility >= 0.0 AND location_compatibility <= 1.0),
    timing_compatibility DOUBLE PRECISION CHECK (timing_compatibility >= 0.0 AND timing_compatibility <= 1.0),
    vibe_alignment DOUBLE PRECISION CHECK (vibe_alignment >= 0.0 AND vibe_alignment <= 1.0),
    
    -- Predictive Scores (future compatibility)
    future_compatibility DOUBLE PRECISION CHECK (future_compatibility >= 0.0 AND future_compatibility <= 1.0),
    future_compatibility_time TIMESTAMPTZ, -- When future_compatibility is predicted for
    compatibility_trajectory JSONB, -- Time series of compatibility scores
    
    -- Fabric/Group Scores (for group compatibility)
    fabric_stability_improvement DOUBLE PRECISION, -- How much adding target improves fabric
    current_fabric_stability DOUBLE PRECISION,
    predicted_fabric_stability DOUBLE PRECISION,
    
    -- Evolution Scores
    evolution_trend TEXT CHECK (evolution_trend IN ('improving', 'stable', 'declining', 'unknown')),
    evolution_rate DOUBLE PRECISION, -- Rate of compatibility change per day
    
    -- Caching Metadata
    calculation_method TEXT, -- 'knot', 'quantum', 'statistical', 'hybrid', etc.
    calculation_version INTEGER DEFAULT 1, -- Version of calculation algorithm
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL, -- When cache entry expires
    
    -- Source Data Snapshots (for cache invalidation)
    source_snapshot JSONB, -- Snapshot of source data used in calculation
    target_snapshot JSONB, -- Snapshot of target data used in calculation
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Unique constraint: one cache entry per source-target pair
    CONSTRAINT unique_compatibility_cache UNIQUE(source_id, target_id, source_type, target_type)
);

-- Indexes for Compatibility Cache
CREATE INDEX IF NOT EXISTS idx_compatibility_cache_source 
    ON public.compatibility_cache(source_id, source_type, expires_at);

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_target 
    ON public.compatibility_cache(target_id, target_type, expires_at);

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_score 
    ON public.compatibility_cache(compatibility_score DESC, expires_at) 
    WHERE expires_at > NOW();

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_future 
    ON public.compatibility_cache(future_compatibility DESC, future_compatibility_time) 
    WHERE future_compatibility IS NOT NULL AND future_compatibility_time > NOW();

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_expires 
    ON public.compatibility_cache(expires_at) 
    WHERE expires_at <= NOW();

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_method 
    ON public.compatibility_cache(calculation_method, calculated_at DESC);

-- ============================================================
-- Predictive Signals Cache Table
-- ============================================================
-- Caches predictive signals (string predictions, quantum trajectories, etc.)
-- Vectorless: stores pre-calculated predictions, not embeddings

CREATE TABLE IF NOT EXISTS public.predictive_signals_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Entity
    entity_id TEXT NOT NULL, -- User ID, Agent ID, Community ID, etc.
    entity_type TEXT NOT NULL CHECK (entity_type IN (
        'user',
        'agent',
        'community',
        'group',
        'event',
        'spot',
        'business',
        'club',
        'expert'
    )),
    
    -- Signal Type
    signal_type TEXT NOT NULL CHECK (signal_type IN (
        'knot_evolution_string',      -- Knot evolution string prediction
        'quantum_trajectory',          -- Quantum compatibility trajectory
        'fabric_stability',            -- Fabric stability prediction
        'evolution_patterns',          -- Evolution pattern analysis
        'compatibility_trajectory',    -- Compatibility over time
        'optimal_timing'               -- Optimal outreach timing
    )),
    
    -- Prediction Data (JSONB for complex structures)
    prediction_data JSONB NOT NULL, -- Stores prediction results
    
    -- Prediction Metadata
    prediction_time TIMESTAMPTZ NOT NULL, -- When prediction was made
    target_time TIMESTAMPTZ, -- What time the prediction is for
    confidence DOUBLE PRECISION CHECK (confidence >= 0.0 AND confidence <= 1.0),
    
    -- Caching
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL, -- When cache entry expires
    
    -- Source Data Snapshot (for cache invalidation)
    source_snapshot JSONB, -- Snapshot of source data used in prediction
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Unique constraint: one prediction per entity-signal-type-target_time
    CONSTRAINT unique_predictive_signal UNIQUE(entity_id, entity_type, signal_type, target_time)
);

-- Indexes for Predictive Signals Cache
CREATE INDEX IF NOT EXISTS idx_predictive_signals_entity 
    ON public.predictive_signals_cache(entity_id, entity_type, signal_type, expires_at);

CREATE INDEX IF NOT EXISTS idx_predictive_signals_target_time 
    ON public.predictive_signals_cache(target_time, signal_type) 
    WHERE target_time > NOW() AND expires_at > NOW();

CREATE INDEX IF NOT EXISTS idx_predictive_signals_expires 
    ON public.predictive_signals_cache(expires_at) 
    WHERE expires_at <= NOW();

CREATE INDEX IF NOT EXISTS idx_predictive_signals_type 
    ON public.predictive_signals_cache(signal_type, calculated_at DESC);

-- ============================================================
-- Outreach Processing Jobs Table
-- ============================================================
-- Tracks background job processing for outreach

CREATE TABLE IF NOT EXISTS public.outreach_processing_jobs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Job Details
    job_type TEXT NOT NULL CHECK (job_type IN (
        'high_priority',      -- Every 30 minutes
        'medium_priority',    -- Every 2 hours
        'low_priority',       -- Every 12 hours
        'incremental',        -- Every 15 minutes (small batches)
        'event_driven'        -- Immediate triggers
    )),
    
    -- Processing Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'processing',
        'completed',
        'failed',
        'cancelled'
    )),
    
    -- Processing Details
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    processing_time_ms INTEGER,
    
    -- Results
    items_processed INTEGER DEFAULT 0,
    items_succeeded INTEGER DEFAULT 0,
    items_failed INTEGER DEFAULT 0,
    outreach_created INTEGER DEFAULT 0,
    
    -- Error Handling
    error_message TEXT,
    error_stack TEXT,
    retry_count INTEGER DEFAULT 0 CHECK (retry_count >= 0),
    
    -- Job Parameters
    parameters JSONB DEFAULT '{}'::jsonb, -- Job-specific parameters
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for Outreach Processing Jobs
CREATE INDEX IF NOT EXISTS idx_outreach_jobs_type_status 
    ON public.outreach_processing_jobs(job_type, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_jobs_status 
    ON public.outreach_processing_jobs(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_jobs_failed 
    ON public.outreach_processing_jobs(status, retry_count) 
    WHERE status = 'failed' AND retry_count < 3;

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Outreach Queue RLS
ALTER TABLE public.outreach_queue ENABLE ROW LEVEL SECURITY;

-- Users can view their own outreach
DROP POLICY IF EXISTS "Users can view own outreach" ON public.outreach_queue;
CREATE POLICY "Users can view own outreach"
    ON public.outreach_queue
    FOR SELECT
    USING (auth.uid() = target_user_id);

-- Users can update their own outreach (mark as seen, respond, etc.)
DROP POLICY IF EXISTS "Users can update own outreach" ON public.outreach_queue;
CREATE POLICY "Users can update own outreach"
    ON public.outreach_queue
    FOR UPDATE
    USING (auth.uid() = target_user_id)
    WITH CHECK (auth.uid() = target_user_id);

-- Service role can manage all outreach
DROP POLICY IF EXISTS "Service role can manage outreach_queue" ON public.outreach_queue;
CREATE POLICY "Service role can manage outreach_queue"
    ON public.outreach_queue
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Outreach History RLS
ALTER TABLE public.outreach_history ENABLE ROW LEVEL SECURITY;

-- Users can view their own outreach history
DROP POLICY IF EXISTS "Users can view own outreach history" ON public.outreach_history;
CREATE POLICY "Users can view own outreach history"
    ON public.outreach_history
    FOR SELECT
    USING (auth.uid() = target_user_id);

-- Service role can manage all outreach history
DROP POLICY IF EXISTS "Service role can manage outreach_history" ON public.outreach_history;
CREATE POLICY "Service role can manage outreach_history"
    ON public.outreach_history
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Compatibility Cache RLS
ALTER TABLE public.compatibility_cache ENABLE ROW LEVEL SECURITY;

-- Users can view compatibility cache entries involving them
-- (via source_id or target_id matching their user_id or agent_id)
DROP POLICY IF EXISTS "Users can view relevant compatibility cache" ON public.compatibility_cache;
CREATE POLICY "Users can view relevant compatibility cache"
    ON public.compatibility_cache
    FOR SELECT
    USING (
        -- Allow if user is source or target
        (source_type = 'user' AND source_id = auth.uid()::text) OR
        (target_type = 'user' AND target_id = auth.uid()::text) OR
        -- Service role can see all
        ((select auth.role()) = 'service_role')
    );

-- Service role can manage all compatibility cache
DROP POLICY IF EXISTS "Service role can manage compatibility_cache" ON public.compatibility_cache;
CREATE POLICY "Service role can manage compatibility_cache"
    ON public.compatibility_cache
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Predictive Signals Cache RLS
ALTER TABLE public.predictive_signals_cache ENABLE ROW LEVEL SECURITY;

-- Users can view predictive signals for their own entities
DROP POLICY IF EXISTS "Users can view own predictive signals" ON public.predictive_signals_cache;
CREATE POLICY "Users can view own predictive signals"
    ON public.predictive_signals_cache
    FOR SELECT
    USING (
        (entity_type = 'user' AND entity_id = auth.uid()::text) OR
        ((select auth.role()) = 'service_role')
    );

-- Service role can manage all predictive signals cache
DROP POLICY IF EXISTS "Service role can manage predictive_signals_cache" ON public.predictive_signals_cache;
CREATE POLICY "Service role can manage predictive_signals_cache"
    ON public.predictive_signals_cache
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Outreach Processing Jobs RLS
ALTER TABLE public.outreach_processing_jobs ENABLE ROW LEVEL SECURITY;

-- Service role only (background jobs)
DROP POLICY IF EXISTS "Service role can manage outreach_processing_jobs" ON public.outreach_processing_jobs;
CREATE POLICY "Service role can manage outreach_processing_jobs"
    ON public.outreach_processing_jobs
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- ============================================================
-- Helper Functions
-- ============================================================

-- Function to clean up expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_outreach_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete expired compatibility cache entries
    DELETE FROM public.compatibility_cache
    WHERE expires_at <= NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete expired predictive signals cache entries
    DELETE FROM public.predictive_signals_cache
    WHERE expires_at <= NOW();
    
    -- Delete expired outreach queue entries
    UPDATE public.outreach_queue
    SET status = 'expired'
    WHERE status IN ('pending', 'scheduled')
      AND expires_at IS NOT NULL
      AND expires_at <= NOW();
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending outreach count for a user
CREATE OR REPLACE FUNCTION get_pending_outreach_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    count_result INTEGER;
BEGIN
    SELECT COUNT(*) INTO count_result
    FROM public.outreach_queue
    WHERE target_user_id = p_user_id
      AND status IN ('pending', 'scheduled', 'delivered')
      AND (expires_at IS NULL OR expires_at > NOW());
    
    RETURN count_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if recent outreach exists (for duplicate prevention)
CREATE OR REPLACE FUNCTION has_recent_outreach(
    p_target_user_id UUID,
    p_source_id TEXT,
    p_type TEXT,
    p_lookback_days INTEGER DEFAULT 30
)
RETURNS BOOLEAN AS $$
DECLARE
    exists_result BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM public.outreach_history
        WHERE target_user_id = p_target_user_id
          AND source_id = p_source_id
          AND type = p_type
          AND sent_at >= NOW() - (p_lookback_days || ' days')::INTERVAL
    ) INTO exists_result;
    
    RETURN exists_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Comments for Documentation
-- ============================================================

COMMENT ON TABLE public.outreach_queue IS 
    'Stores proactive outreach messages queued for silent delivery. No push notifications - shown when user opens app.';

COMMENT ON TABLE public.outreach_history IS 
    'Tracks all outreach sent to prevent duplicates and manage frequency. One entry per user-source-type per day.';

COMMENT ON TABLE public.compatibility_cache IS 
    'Caches compatibility scores (scalar values) for fast lookups. Vectorless approach - stores pre-calculated scores, not embeddings.';

COMMENT ON TABLE public.predictive_signals_cache IS 
    'Caches predictive signals (string predictions, quantum trajectories, etc.). Vectorless approach - stores pre-calculated predictions.';

COMMENT ON TABLE public.outreach_processing_jobs IS 
    'Tracks background job processing for outreach. Monitors job execution and results.';

COMMENT ON COLUMN public.compatibility_cache.compatibility_score IS 
    'Combined compatibility score (0.0-1.0). Calculated from knot, quantum, location, timing, vibe components.';

COMMENT ON COLUMN public.compatibility_cache.knot_compatibility IS 
    'Topological knot compatibility score. Calculated from braid data, not vector similarity.';

COMMENT ON COLUMN public.compatibility_cache.quantum_fidelity IS 
    'Quantum fidelity score. Calculated from quantum state vectors, not embeddings.';

COMMENT ON COLUMN public.compatibility_cache.future_compatibility IS 
    'Predicted future compatibility score. From knot evolution string predictions and quantum trajectories.';

COMMENT ON COLUMN public.predictive_signals_cache.prediction_data IS 
    'JSONB storing prediction results. Structure varies by signal_type (knot evolution, quantum trajectory, etc.).';
