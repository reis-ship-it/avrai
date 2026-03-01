-- Migration: Outside Buyer Insights (v1) - Precompute + cache releases
-- Created: 2026-01-01
-- Purpose: Serve stable DP releases from cache (budget spent on release generation, not per request)
-- Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- Cache tables
-- ============================================================

-- One row = one metric cell row in spots_insights_v1 (stored as JSONB + indexed dimensions)
CREATE TABLE IF NOT EXISTS public.outside_buyer_insights_v1_cache (
  api_key_id UUID NOT NULL REFERENCES public.api_keys(id) ON DELETE CASCADE,

  time_bucket_start_utc TIMESTAMPTZ NOT NULL,
  time_granularity TEXT NOT NULL,
  reporting_delay_hours INTEGER NOT NULL,

  geo_bucket_type TEXT NOT NULL,
  geo_bucket_id TEXT NOT NULL,

  door_type TEXT NOT NULL,
  category TEXT NOT NULL,
  context TEXT NOT NULL,

  k_min_enforced INTEGER NOT NULL,
  dominance_max_fraction DOUBLE PRECISION NOT NULL,

  dp_mechanism TEXT NOT NULL DEFAULT 'laplace',
  dp_epsilon DOUBLE PRECISION NOT NULL,
  dp_delta DOUBLE PRECISION NOT NULL,
  budget_window_days INTEGER NOT NULL,

  suppressed BOOLEAN NOT NULL,
  suppressed_reason TEXT,

  payload JSONB NOT NULL,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (
    api_key_id,
    time_bucket_start_utc,
    time_granularity,
    reporting_delay_hours,
    geo_bucket_type,
    geo_bucket_id,
    door_type,
    category,
    context,
    k_min_enforced,
    dominance_max_fraction,
    dp_mechanism,
    dp_epsilon,
    dp_delta,
    budget_window_days
  )
);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_insights_cache_api_time
  ON public.outside_buyer_insights_v1_cache(api_key_id, time_bucket_start_utc DESC);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_insights_cache_geo
  ON public.outside_buyer_insights_v1_cache(api_key_id, geo_bucket_id);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_insights_cache_segment
  ON public.outside_buyer_insights_v1_cache(api_key_id, door_type, category, context);

ALTER TABLE public.outside_buyer_insights_v1_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage outside_buyer_insights_v1_cache"
  ON public.outside_buyer_insights_v1_cache
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Run ledger: one record means the FULL cube for that time bucket was computed and cached
CREATE TABLE IF NOT EXISTS public.outside_buyer_insights_v1_cache_runs (
  api_key_id UUID NOT NULL REFERENCES public.api_keys(id) ON DELETE CASCADE,
  time_bucket_start_utc TIMESTAMPTZ NOT NULL,
  time_granularity TEXT NOT NULL,
  reporting_delay_hours INTEGER NOT NULL,
  geo_bucket_type TEXT NOT NULL,

  k_min_enforced INTEGER NOT NULL,
  dominance_max_fraction DOUBLE PRECISION NOT NULL,

  dp_mechanism TEXT NOT NULL DEFAULT 'laplace',
  dp_epsilon DOUBLE PRECISION NOT NULL,
  dp_delta DOUBLE PRECISION NOT NULL,
  budget_window_days INTEGER NOT NULL,

  row_count BIGINT NOT NULL DEFAULT 0,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (
    api_key_id,
    time_bucket_start_utc,
    time_granularity,
    reporting_delay_hours,
    geo_bucket_type,
    k_min_enforced,
    dominance_max_fraction,
    dp_mechanism,
    dp_epsilon,
    dp_delta,
    budget_window_days
  )
);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_insights_cache_runs_api_time
  ON public.outside_buyer_insights_v1_cache_runs(api_key_id, time_bucket_start_utc DESC);

ALTER TABLE public.outside_buyer_insights_v1_cache_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage outside_buyer_insights_v1_cache_runs"
  ON public.outside_buyer_insights_v1_cache_runs
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- ============================================================
-- Precompute + cache (day granularity v1)
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  p_api_key_id UUID,
  p_day_start_utc TIMESTAMPTZ,
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'geohash3',
  p_k_min INTEGER DEFAULT 100,
  p_dominance_max_fraction DOUBLE PRECISION DEFAULT 0.05,
  p_dp_epsilon DOUBLE PRECISION DEFAULT 0.5,
  p_dp_delta DOUBLE PRECISION DEFAULT 1e-6,
  p_budget_window_days INTEGER DEFAULT 30,
  p_privacy_budget_total_epsilon DOUBLE PRECISION DEFAULT 10.0,
  p_budget_cost_epsilon DOUBLE PRECISION DEFAULT 0.5
) RETURNS BIGINT AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
  v_cutoff TIMESTAMPTZ := v_now - make_interval(hours => p_reporting_delay_hours);
  v_day_end_utc TIMESTAMPTZ := p_day_start_utc + INTERVAL '1 day';
  v_exists BOOLEAN;
  v_budget_ok BOOLEAN;
  v_inserted BIGINT := 0;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_day_start_utc IS NULL THEN
    RAISE EXCEPTION 'day_start_utc is required';
  END IF;
  IF date_trunc('day', p_day_start_utc) <> p_day_start_utc THEN
    RAISE EXCEPTION 'day_start_utc must be day-aligned (UTC)';
  END IF;
  IF v_day_end_utc > v_cutoff THEN
    RAISE EXCEPTION 'reporting delay violation (end=% cutoff=%)', v_day_end_utc, v_cutoff;
  END IF;
  IF p_geo_bucket_type <> 'geohash3' THEN
    RAISE EXCEPTION 'unsupported geo_bucket_type for v1 cache: %', p_geo_bucket_type;
  END IF;
  IF p_k_min IS NULL OR p_k_min < 1 THEN
    RAISE EXCEPTION 'k_min must be >= 1';
  END IF;
  IF p_dp_epsilon IS NULL OR p_dp_epsilon <= 0 THEN
    RAISE EXCEPTION 'dp_epsilon must be positive';
  END IF;

  -- If we already computed the full cube for this day+params, no work.
  SELECT EXISTS(
    SELECT 1
    FROM public.outside_buyer_insights_v1_cache_runs r
    WHERE r.api_key_id = p_api_key_id
      AND r.time_bucket_start_utc = p_day_start_utc
      AND r.time_granularity = 'day'
      AND r.reporting_delay_hours = p_reporting_delay_hours
      AND r.geo_bucket_type = p_geo_bucket_type
      AND r.k_min_enforced = p_k_min
      AND r.dominance_max_fraction = p_dominance_max_fraction
      AND r.dp_mechanism = 'laplace'
      AND r.dp_epsilon = p_dp_epsilon
      AND r.dp_delta = p_dp_delta
      AND r.budget_window_days = p_budget_window_days
  ) INTO v_exists;

  IF v_exists THEN
    RETURN 0;
  END IF;

  -- Consume privacy budget ONCE per day-release generation.
  v_budget_ok := public.outside_buyer_consume_privacy_budget(
    p_api_key_id,
    p_budget_cost_epsilon,
    p_budget_window_days,
    p_privacy_budget_total_epsilon,
    p_dp_delta
  );
  IF NOT v_budget_ok THEN
    RAISE EXCEPTION 'privacy budget exceeded';
  END IF;

  WITH base_events AS (
    SELECT
      date_trunc('day', ie.timestamp) AS time_bucket_start_utc,
      ie.agent_id,
      ie.event_type,
      ie.parameters,
      ie.context,
      ie.timestamp,
      -- Coarsen geo immediately (v1 cache uses geohash3)
      CASE
        WHEN ie.context ? 'location'
         AND (ie.context->'location') ? 'latitude'
         AND (ie.context->'location') ? 'longitude'
        THEN ST_GeoHash(
          ST_SetSRID(
            ST_MakePoint(
              (ie.context->'location'->>'longitude')::DOUBLE PRECISION,
              (ie.context->'location'->>'latitude')::DOUBLE PRECISION
            ),
            4326
          ),
          3
        )
        ELSE NULL
      END AS geo_bucket_id
    FROM public.interaction_events ie
    WHERE ie.timestamp >= p_day_start_utc
      AND ie.timestamp < v_day_end_utc
  ),
  normalized AS (
    SELECT
      be.time_bucket_start_utc,
      COALESCE(be.geo_bucket_id, 'unknown') AS geo_bucket_id,
      be.agent_id,
      be.event_type,
      be.parameters,
      be.timestamp,
      CASE
        WHEN be.event_type = 'event_attended' THEN 'event'
        WHEN be.event_type LIKE 'list_%' THEN 'community'
        WHEN be.event_type = 'respect_tap' AND lower(COALESCE(be.parameters->>'target_type', '')) = 'list' THEN 'community'
        WHEN COALESCE(
          be.parameters->>'spot_id',
          CASE
            WHEN be.event_type = 'respect_tap' AND lower(COALESCE(be.parameters->>'target_type', '')) = 'spot'
              THEN be.parameters->>'target_id'
            ELSE NULL
          END
        ) IS NOT NULL THEN 'spot'
        ELSE 'community'
      END AS door_type,
      CASE
        WHEN EXTRACT(ISODOW FROM be.timestamp) IN (6, 7) THEN 'weekend'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 5 AND EXTRACT(HOUR FROM be.timestamp) < 11 THEN 'morning'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 11 AND EXTRACT(HOUR FROM be.timestamp) < 17 THEN 'midday'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 17 AND EXTRACT(HOUR FROM be.timestamp) < 22 THEN 'evening'
        ELSE 'unknown'
      END AS context_bucket,
      COALESCE(
        be.parameters->>'spot_id',
        CASE
          WHEN be.event_type = 'respect_tap' AND lower(COALESCE(be.parameters->>'target_type', '')) = 'spot'
            THEN be.parameters->>'target_id'
          ELSE NULL
        END
      ) AS spot_id_text,
      NULLIF(lower(COALESCE(be.parameters->>'category', '')), '') AS category_hint
    FROM base_events be
  ),
  enriched AS (
    SELECT
      n.time_bucket_start_utc,
      n.geo_bucket_id,
      n.agent_id,
      n.door_type,
      n.context_bucket,
      CASE
        WHEN n.category_hint IN ('coffee','music','sports','art','food','outdoor','tech','community','other')
          THEN n.category_hint
        WHEN lower(COALESCE(s.category, '')) IN ('coffee','music','sports','art','food','outdoor','tech','community','other')
          THEN lower(s.category)
        WHEN n.door_type = 'community' THEN 'community'
        ELSE 'other'
      END AS category,
      n.event_type
    FROM normalized n
    LEFT JOIN public.spots s
      ON s.id::text = n.spot_id_text
  ),
  per_agent_cell AS (
    SELECT
      e.time_bucket_start_utc,
      e.geo_bucket_id,
      e.door_type,
      e.category,
      e.context_bucket AS context,
      e.agent_id,
      COUNT(*)::BIGINT AS event_count
    FROM enriched e
    WHERE e.event_type IN (
      'spot_visited',
      'event_attended',
      'respect_tap',
      'list_view_started'
    )
    GROUP BY
      e.time_bucket_start_utc,
      e.geo_bucket_id,
      e.door_type,
      e.category,
      e.context_bucket,
      e.agent_id
  ),
  cell_raw AS (
    SELECT
      pac.time_bucket_start_utc,
      pac.geo_bucket_id,
      pac.door_type,
      pac.category,
      pac.context,
      COUNT(*)::BIGINT AS unique_participants,
      SUM(pac.event_count)::BIGINT AS doors_opened,
      COUNT(*) FILTER (WHERE pac.event_count >= 2)::BIGINT AS repeat_participants,
      MAX(pac.event_count)::BIGINT AS top_contributor_events
    FROM per_agent_cell pac
    GROUP BY
      pac.time_bucket_start_utc,
      pac.geo_bucket_id,
      pac.door_type,
      pac.category,
      pac.context
  ),
  cell_policy AS (
    SELECT
      cr.*,
      (cr.unique_participants < p_k_min) AS suppressed_kmin,
      (
        (cr.top_contributor_events::DOUBLE PRECISION / GREATEST(cr.doors_opened::DOUBLE PRECISION, 1.0))
        > p_dominance_max_fraction
      ) AS suppressed_dominance
    FROM cell_raw cr
  ),
  cell_dp AS (
    SELECT
      cp.*,
      GREATEST(
        0,
        ROUND(cp.unique_participants::DOUBLE PRECISION + public.dp_laplace_noise(1.0 / p_dp_epsilon))
      )::BIGINT AS unique_participants_dp,
      GREATEST(
        0,
        ROUND(cp.doors_opened::DOUBLE PRECISION + public.dp_laplace_noise(1.0 / p_dp_epsilon))
      )::BIGINT AS doors_opened_dp,
      GREATEST(
        0,
        ROUND(cp.repeat_participants::DOUBLE PRECISION + public.dp_laplace_noise(1.0 / p_dp_epsilon))
      )::BIGINT AS repeat_participants_dp
    FROM cell_policy cp
  ),
  cell_final AS (
    SELECT
      cd.time_bucket_start_utc,
      cd.geo_bucket_id,
      cd.door_type,
      cd.category,
      cd.context,
      (cd.suppressed_kmin OR cd.suppressed_dominance) AS suppressed,
      CASE
        WHEN cd.suppressed_kmin THEN 'k_min'
        WHEN cd.suppressed_dominance THEN 'dominance'
        ELSE NULL
      END AS suppressed_reason,
      cd.unique_participants_dp,
      cd.doors_opened_dp,
      LEAST(
        1.0,
        GREATEST(
          0.0,
          (cd.repeat_participants_dp::DOUBLE PRECISION / GREATEST(cd.unique_participants_dp::DOUBLE PRECISION, 1.0))
        )
      ) AS repeat_rate_est,
      LEAST(
        1.0,
        GREATEST(
          0.0,
          (1.0 - exp(-GREATEST(cd.doors_opened_dp::DOUBLE PRECISION, 0.0) / 1000.0))
        )
      ) AS trend_score_est
    FROM cell_dp cd
  ),
  to_insert AS (
    SELECT
      jsonb_build_object(
        'schema_version', '1.0',
        'dataset', 'spots_insights_v1',
        'time_bucket_start_utc', to_char((cell_final.time_bucket_start_utc AT TIME ZONE 'utc'), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'time_granularity', 'day',
        'reporting_delay_hours', p_reporting_delay_hours,
        'geo_bucket', jsonb_build_object(
          'type', p_geo_bucket_type,
          'id', cell_final.geo_bucket_id
        ),
        'segment', jsonb_build_object(
          'door_type', cell_final.door_type,
          'category', cell_final.category,
          'context', cell_final.context
        ),
        'metrics',
          CASE
            WHEN cell_final.suppressed THEN jsonb_build_object(
              'unique_participants_est', NULL,
              'doors_opened_est', NULL,
              'repeat_rate_est', NULL,
              'trend_score_est', NULL
            )
            ELSE jsonb_build_object(
              'unique_participants_est', cell_final.unique_participants_dp,
              'doors_opened_est', cell_final.doors_opened_dp,
              'repeat_rate_est', cell_final.repeat_rate_est,
              'trend_score_est', cell_final.trend_score_est
            )
          END,
        'privacy', jsonb_build_object(
          'k_min_enforced', p_k_min,
          'suppressed', cell_final.suppressed,
          'suppressed_reason', cell_final.suppressed_reason,
          'dp', jsonb_build_object(
            'enabled', TRUE,
            'mechanism', 'laplace',
            'epsilon', p_dp_epsilon,
            'delta', p_dp_delta,
            'budget_window_days', p_budget_window_days
          )
        )
      ) AS payload,
      cell_final.*
    FROM cell_final
  )
  INSERT INTO public.outside_buyer_insights_v1_cache (
    api_key_id,
    time_bucket_start_utc,
    time_granularity,
    reporting_delay_hours,
    geo_bucket_type,
    geo_bucket_id,
    door_type,
    category,
    context,
    k_min_enforced,
    dominance_max_fraction,
    dp_mechanism,
    dp_epsilon,
    dp_delta,
    budget_window_days,
    suppressed,
    suppressed_reason,
    payload
  )
  SELECT
    p_api_key_id,
    ti.time_bucket_start_utc,
    'day',
    p_reporting_delay_hours,
    p_geo_bucket_type,
    ti.geo_bucket_id,
    ti.door_type,
    ti.category,
    ti.context,
    p_k_min,
    p_dominance_max_fraction,
    'laplace',
    p_dp_epsilon,
    p_dp_delta,
    p_budget_window_days,
    ti.suppressed,
    ti.suppressed_reason,
    ti.payload
  FROM to_insert ti
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;

  INSERT INTO public.outside_buyer_insights_v1_cache_runs (
    api_key_id,
    time_bucket_start_utc,
    time_granularity,
    reporting_delay_hours,
    geo_bucket_type,
    k_min_enforced,
    dominance_max_fraction,
    dp_mechanism,
    dp_epsilon,
    dp_delta,
    budget_window_days,
    row_count
  )
  VALUES (
    p_api_key_id,
    p_day_start_utc,
    'day',
    p_reporting_delay_hours,
    p_geo_bucket_type,
    p_k_min,
    p_dominance_max_fraction,
    'laplace',
    p_dp_epsilon,
    p_dp_delta,
    p_budget_window_days,
    v_inserted
  )
  ON CONFLICT DO NOTHING;

  RETURN v_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

-- Cached getter: ensures day buckets are precomputed, then returns cached rows filtered.
CREATE OR REPLACE FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  p_api_key_id UUID,
  p_time_bucket_start_utc TIMESTAMPTZ,
  p_time_bucket_end_utc TIMESTAMPTZ,
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'geohash3',
  p_geo_bucket_ids TEXT[] DEFAULT NULL,
  p_door_types TEXT[] DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_contexts TEXT[] DEFAULT NULL,
  p_k_min INTEGER DEFAULT 100,
  p_dominance_max_fraction DOUBLE PRECISION DEFAULT 0.05,
  p_dp_epsilon DOUBLE PRECISION DEFAULT 0.5,
  p_dp_delta DOUBLE PRECISION DEFAULT 1e-6,
  p_budget_window_days INTEGER DEFAULT 30,
  p_privacy_budget_total_epsilon DOUBLE PRECISION DEFAULT 10.0,
  p_budget_cost_epsilon DOUBLE PRECISION DEFAULT 0.5
) RETURNS SETOF JSONB AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
  v_cutoff TIMESTAMPTZ := v_now - make_interval(hours => p_reporting_delay_hours);
  v_start_day TIMESTAMPTZ;
  v_day TIMESTAMPTZ;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_time_bucket_start_utc IS NULL OR p_time_bucket_end_utc IS NULL THEN
    RAISE EXCEPTION 'time window is required';
  END IF;
  IF p_time_bucket_end_utc <= p_time_bucket_start_utc THEN
    RAISE EXCEPTION 'end time must be after start time';
  END IF;
  IF (p_time_bucket_end_utc - p_time_bucket_start_utc) > INTERVAL '90 days' THEN
    RAISE EXCEPTION 'requested range too large (max 90 days)';
  END IF;
  IF p_time_bucket_end_utc > v_cutoff THEN
    RAISE EXCEPTION 'reporting delay violation (end=% cutoff=%)', p_time_bucket_end_utc, v_cutoff;
  END IF;

  -- v1 cache supports day granularity only (keeps releases stable and prevents query-shape drift)
  v_start_day := date_trunc('day', p_time_bucket_start_utc AT TIME ZONE 'utc') AT TIME ZONE 'utc';

  FOR v_day IN
    SELECT generate_series(
      v_start_day,
      (date_trunc('day', (p_time_bucket_end_utc AT TIME ZONE 'utc')) AT TIME ZONE 'utc') - INTERVAL '1 day',
      INTERVAL '1 day'
    )
  LOOP
    PERFORM public.outside_buyer_precompute_spots_insights_v1_day(
      p_api_key_id,
      v_day,
      p_reporting_delay_hours,
      p_geo_bucket_type,
      p_k_min,
      p_dominance_max_fraction,
      p_dp_epsilon,
      p_dp_delta,
      p_budget_window_days,
      p_privacy_budget_total_epsilon,
      p_budget_cost_epsilon
    );
  END LOOP;

  RETURN QUERY
  SELECT c.payload
  FROM public.outside_buyer_insights_v1_cache c
  WHERE c.api_key_id = p_api_key_id
    AND c.time_granularity = 'day'
    AND c.reporting_delay_hours = p_reporting_delay_hours
    AND c.geo_bucket_type = p_geo_bucket_type
    AND c.k_min_enforced = p_k_min
    AND c.dominance_max_fraction = p_dominance_max_fraction
    AND c.dp_mechanism = 'laplace'
    AND c.dp_epsilon = p_dp_epsilon
    AND c.dp_delta = p_dp_delta
    AND c.budget_window_days = p_budget_window_days
    AND c.time_bucket_start_utc >= v_start_day
    AND c.time_bucket_start_utc < (date_trunc('day', (p_time_bucket_end_utc AT TIME ZONE 'utc')) AT TIME ZONE 'utc')
    AND (p_geo_bucket_ids IS NULL OR c.geo_bucket_id = ANY(p_geo_bucket_ids))
    AND (p_door_types IS NULL OR c.door_type = ANY(p_door_types))
    AND (p_categories IS NULL OR c.category = ANY(p_categories))
    AND (p_contexts IS NULL OR c.context = ANY(p_contexts));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

COMMENT ON TABLE public.outside_buyer_insights_v1_cache IS 'Cached DP releases for outside-buyer insights (v1). Stable per time bucket + params.';
COMMENT ON TABLE public.outside_buyer_insights_v1_cache_runs IS 'Ledger of completed precompute runs for outside-buyer insights (v1).';
COMMENT ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_day IS 'Precompute+cache v1 insights for a single UTC day (budget spent once per day-release).';
COMMENT ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached IS 'Return v1 insights from cache, precomputing missing day buckets as needed.';

