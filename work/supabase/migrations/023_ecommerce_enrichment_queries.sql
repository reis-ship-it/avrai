-- Migration: E-Commerce Enrichment API - Database Queries
-- Created: 2025-12-23
-- Purpose: Create helper functions for data aggregation queries
-- Phase 21 Section 1: Foundation & Infrastructure

-- ============================================
-- Helper Function: Get Agent IDs for Segment
-- ============================================
-- Returns agent IDs that match a market segment definition
-- This is a placeholder - actual segment matching logic will be implemented
-- based on segment_definition JSONB criteria

CREATE OR REPLACE FUNCTION get_agent_ids_for_segment(
    p_segment_definition JSONB
) RETURNS TABLE (agent_id TEXT) AS $$
BEGIN
    -- Placeholder: Return all agent IDs for now
    -- TODO: Implement actual segment matching based on:
    -- - Geographic region (from user_actions or personality_profiles)
    -- - Age range (from onboarding_aggregations)
    -- - Interests (from preferences_profile or personality_profiles)
    -- - Category preferences (from preferences_profile)
    
    RETURN QUERY
    SELECT DISTINCT pp.agent_id
    FROM public.personality_profiles pp
    WHERE pp.agent_id IS NOT NULL
    LIMIT 1000; -- Temporary limit for POC
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Aggregate Real-World Behavior
-- ============================================
-- Aggregates real-world behavior patterns for a market segment

CREATE OR REPLACE FUNCTION aggregate_real_world_behavior(
    p_segment_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_sample_size INTEGER;
    v_agent_ids TEXT[];
BEGIN
    -- Get segment definition
    SELECT segment_definition INTO v_result
    FROM public.market_segments
    WHERE segment_id = p_segment_id;
    
    IF v_result IS NULL THEN
        RETURN jsonb_build_object('error', 'Segment not found');
    END IF;
    
    -- Get agent IDs for segment (placeholder - will use actual matching)
    SELECT ARRAY_AGG(agent_id) INTO v_agent_ids
    FROM get_agent_ids_for_segment(v_result);
    
    IF v_agent_ids IS NULL OR array_length(v_agent_ids, 1) = 0 THEN
        RETURN jsonb_build_object('error', 'No agents found for segment');
    END IF;
    
    v_sample_size := array_length(v_agent_ids, 1);
    
    -- Aggregate behavior patterns
    WITH behavior_stats AS (
        SELECT 
            AVG(EXTRACT(EPOCH FROM (end_time - start_time))/60) as avg_dwell_time,
            COUNT(DISTINCT spot_id) as unique_spots,
            COUNT(*) FILTER (WHERE is_return_visit = true)::float / NULLIF(COUNT(*), 0) as return_rate,
            COUNT(*) FILTER (WHERE EXTRACT(EPOCH FROM (end_time - start_time))/60 < 15)::float / NULLIF(COUNT(*), 0) as short_visits,
            COUNT(*) FILTER (WHERE EXTRACT(EPOCH FROM (end_time - start_time))/60 BETWEEN 15 AND 60)::float / NULLIF(COUNT(*), 0) as medium_visits,
            COUNT(*) FILTER (WHERE EXTRACT(EPOCH FROM (end_time - start_time))/60 > 60)::float / NULLIF(COUNT(*), 0) as long_visits
        FROM public.user_actions
        WHERE agent_id = ANY(v_agent_ids)
        AND action_type = 'spot_visit'
        AND created_at >= NOW() - INTERVAL '30 days'
        AND end_time IS NOT NULL
        AND start_time IS NOT NULL
    )
    SELECT jsonb_build_object(
        'average_dwell_time', jsonb_build_object(
            'value', COALESCE(avg_dwell_time, 0)::numeric(10,2),
            'unit', 'minutes',
            'confidence', CASE WHEN v_sample_size >= 100 THEN 0.85 ELSE 0.70 END
        ),
        'return_visit_rate', jsonb_build_object(
            'value', COALESCE(return_rate, 0)::numeric(10,2),
            'interpretation', 'Percentage of visits that are returns to previously visited spots',
            'confidence', CASE WHEN v_sample_size >= 100 THEN 0.82 ELSE 0.68 END
        ),
        'exploration_tendency', jsonb_build_object(
            'value', COALESCE(1 - return_rate, 0.5)::numeric(10,2),
            'interpretation', 'Tendency to explore new places vs return to favorites',
            'confidence', CASE WHEN v_sample_size >= 100 THEN 0.79 ELSE 0.65 END
        ),
        'time_spent_analysis', jsonb_build_object(
            'short_visits', COALESCE(short_visits, 0)::numeric(10,2),
            'medium_visits', COALESCE(medium_visits, 0)::numeric(10,2),
            'long_visits', COALESCE(long_visits, 0)::numeric(10,2)
        ),
        'sample_size', v_sample_size
    ) INTO v_result
    FROM behavior_stats;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Aggregate Personality Profiles
-- ============================================
-- Aggregates personality profile dimensions for a market segment

CREATE OR REPLACE FUNCTION aggregate_personality_profiles(
    p_segment_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_segment_definition JSONB;
    v_agent_ids TEXT[];
    v_sample_size INTEGER;
BEGIN
    -- Get segment definition
    SELECT segment_definition INTO v_segment_definition
    FROM public.market_segments
    WHERE segment_id = p_segment_id;
    
    IF v_segment_definition IS NULL THEN
        RETURN jsonb_build_object('error', 'Segment not found');
    END IF;
    
    -- Get agent IDs for segment
    SELECT ARRAY_AGG(agent_id) INTO v_agent_ids
    FROM get_agent_ids_for_segment(v_segment_definition);
    
    IF v_agent_ids IS NULL OR array_length(v_agent_ids, 1) = 0 THEN
        RETURN jsonb_build_object('error', 'No agents found for segment');
    END IF;
    
    v_sample_size := array_length(v_agent_ids, 1);
    
    -- Aggregate personality dimensions
    WITH dimension_stats AS (
        SELECT 
            key as dimension_name,
            AVG((value::text)::numeric) as avg_value,
            STDDEV((value::text)::numeric) as std_dev,
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY (value::text)::numeric) as p25,
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY (value::text)::numeric) as p50,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY (value::text)::numeric) as p75
        FROM public.personality_profiles pp,
        LATERAL jsonb_each(pp.dimensions)
        WHERE pp.agent_id = ANY(v_agent_ids)
        AND pp.dimensions IS NOT NULL
        GROUP BY key
    )
    SELECT jsonb_object_agg(
        dimension_name,
        jsonb_build_object(
            'value', avg_value::numeric(10,2),
            'std_dev', COALESCE(std_dev, 0)::numeric(10,2),
            'percentiles', jsonb_build_object(
                'p25', p25::numeric(10,2),
                'p50', p50::numeric(10,2),
                'p75', p75::numeric(10,2)
            )
        )
    ) INTO v_result
    FROM dimension_stats;
    
    -- Add metadata
    v_result := v_result || jsonb_build_object(
        'sample_size', v_sample_size,
        'archetype', 'Aggregate', -- TODO: Calculate most common archetype
        'authenticity_score', 0.85 -- TODO: Calculate average authenticity
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Aggregate AI2AI Network Insights
-- ============================================
-- Aggregates AI2AI network insights for a market segment

CREATE OR REPLACE FUNCTION aggregate_ai2ai_insights(
    p_segment_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_segment_definition JSONB;
    v_agent_ids TEXT[];
    v_sample_size INTEGER;
BEGIN
    -- Get segment definition
    SELECT segment_definition INTO v_segment_definition
    FROM public.market_segments
    WHERE segment_id = p_segment_id;
    
    IF v_segment_definition IS NULL THEN
        RETURN jsonb_build_object('error', 'Segment not found');
    END IF;
    
    -- Get agent IDs for segment
    SELECT ARRAY_AGG(agent_id) INTO v_agent_ids
    FROM get_agent_ids_for_segment(v_segment_definition);
    
    IF v_agent_ids IS NULL OR array_length(v_agent_ids, 1) = 0 THEN
        RETURN jsonb_build_object('error', 'No agents found for segment');
    END IF;
    
    v_sample_size := array_length(v_agent_ids, 1);
    
    -- Aggregate AI2AI network metrics
    WITH network_stats AS (
        SELECT 
            AVG(compatibility_score) as avg_compatibility,
            COUNT(*) as total_connections,
            COUNT(DISTINCT agent_id_1) as unique_users_1,
            COUNT(DISTINCT agent_id_2) as unique_users_2
        FROM public.ai2ai_connections
        WHERE (agent_id_1 = ANY(v_agent_ids) OR agent_id_2 = ANY(v_agent_ids))
        AND created_at >= NOW() - INTERVAL '30 days'
    )
    SELECT jsonb_build_object(
        'average_compatibility', COALESCE(avg_compatibility, 0)::numeric(10,2),
        'total_connections', COALESCE(total_connections, 0),
        'unique_users', COALESCE(GREATEST(unique_users_1, unique_users_2), 0),
        'connection_frequency', CASE 
            WHEN COALESCE(total_connections, 0) / NULLIF(v_sample_size, 0) > 10 THEN 'high'
            WHEN COALESCE(total_connections, 0) / NULLIF(v_sample_size, 0) > 5 THEN 'medium'
            ELSE 'low'
        END,
        'learning_rate', COALESCE(avg_compatibility, 0)::numeric(10,2),
        'sample_size', v_sample_size
    ) INTO v_result
    FROM network_stats;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Comments
-- ============================================

COMMENT ON FUNCTION get_agent_ids_for_segment IS 'Returns agent IDs matching a market segment definition';
COMMENT ON FUNCTION aggregate_real_world_behavior IS 'Aggregates real-world behavior patterns for a market segment';
COMMENT ON FUNCTION aggregate_personality_profiles IS 'Aggregates personality profile dimensions for a market segment';
COMMENT ON FUNCTION aggregate_ai2ai_insights IS 'Aggregates AI2AI network insights for a market segment';
