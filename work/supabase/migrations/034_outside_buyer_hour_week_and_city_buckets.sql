-- Migration: Outside Buyer Insights - Hour/Week granularity + City-coded geo buckets (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Add cached releases for hour/week in addition to day
-- - Add `city_code` geo buckets via a geohash3→city mapping table
-- - Keep privacy budget spend tied to release generation (per bucket), not per request
--
-- Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- City bucket mapping (geohash3 -> city_code)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.city_geohash3_map (
  city_code TEXT NOT NULL,   -- ex: 'us-sf', 'us-nyc'
  geohash3_id TEXT NOT NULL, -- 3-char geohash
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (city_code, geohash3_id)
);

CREATE INDEX IF NOT EXISTS idx_city_geohash3_map_geohash3_id
  ON public.city_geohash3_map(geohash3_id);

ALTER TABLE public.city_geohash3_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage city_geohash3_map"
  ON public.city_geohash3_map
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Seed a couple of known city codes for demo/verification (computed from canonical lat/lon).
INSERT INTO public.city_geohash3_map (city_code, geohash3_id)
SELECT 'us-sf', ST_GeoHash(ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326), 3)
ON CONFLICT DO NOTHING;

INSERT INTO public.city_geohash3_map (city_code, geohash3_id)
SELECT 'us-nyc', ST_GeoHash(ST_SetSRID(ST_MakePoint(-74.0060, 40.7128), 4326), 3)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE public.city_geohash3_map IS 'Maps geohash3 buckets to human-friendly city codes for outside-buyer exports (service role only).';

-- ============================================================
-- Precompute core helper (bucket-level)
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(
  p_api_key_id UUID,
  p_bucket_start_utc TIMESTAMPTZ,
  p_time_granularity TEXT DEFAULT 'day',
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'city_code',
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
  v_step INTERVAL;
  v_bucket_end_utc TIMESTAMPTZ;
  v_exists BOOLEAN;
  v_budget_ok BOOLEAN;
  v_inserted BIGINT := 0;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_bucket_start_utc IS NULL THEN
    RAISE EXCEPTION 'bucket_start_utc is required';
  END IF;

  IF p_time_granularity NOT IN ('hour','day','week') THEN
    RAISE EXCEPTION 'unsupported time_granularity: %', p_time_granularity;
  END IF;

  v_step := CASE
    WHEN p_time_granularity = 'hour' THEN INTERVAL '1 hour'
    WHEN p_time_granularity = 'day' THEN INTERVAL '1 day'
    WHEN p_time_granularity = 'week' THEN INTERVAL '1 week'
    ELSE INTERVAL '1 day'
  END;

  -- Ensure bucket alignment (UTC)
  IF (date_trunc(p_time_granularity, p_bucket_start_utc AT TIME ZONE 'utc') AT TIME ZONE 'utc') <> p_bucket_start_utc THEN
    RAISE EXCEPTION 'bucket_start_utc must be % aligned (UTC)', p_time_granularity;
  END IF;

  v_bucket_end_utc := p_bucket_start_utc + v_step;

  IF v_bucket_end_utc > v_cutoff THEN
    RAISE EXCEPTION 'reporting delay violation (end=% cutoff=%)', v_bucket_end_utc, v_cutoff;
  END IF;

  IF p_geo_bucket_type NOT IN ('geohash3','city_code') THEN
    RAISE EXCEPTION 'unsupported geo_bucket_type for v1 cache: %', p_geo_bucket_type;
  END IF;

  IF p_k_min IS NULL OR p_k_min < 1 THEN
    RAISE EXCEPTION 'k_min must be >= 1';
  END IF;
  IF p_dp_epsilon IS NULL OR p_dp_epsilon <= 0 THEN
    RAISE EXCEPTION 'dp_epsilon must be positive';
  END IF;

  -- Idempotency: if we already computed full cube for this bucket+params, no work.
  SELECT EXISTS(
    SELECT 1
    FROM public.outside_buyer_insights_v1_cache_runs r
    WHERE r.api_key_id = p_api_key_id
      AND r.time_bucket_start_utc = p_bucket_start_utc
      AND r.time_granularity = p_time_granularity
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

  -- Consume privacy budget ONCE per bucket-release generation.
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
      date_trunc(p_time_granularity, ie.timestamp) AS time_bucket_start_utc,
      ie.agent_id,
      ie.event_type,
      ie.parameters,
      ie.context,
      ie.timestamp,
      -- Always coarsen to geohash3 first; then optionally map to city_code.
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
      END AS geohash3_id
    FROM public.interaction_events ie
    WHERE ie.timestamp >= p_bucket_start_utc
      AND ie.timestamp < v_bucket_end_utc
  ),
  normalized AS (
    SELECT
      be.time_bucket_start_utc,
      CASE
        WHEN p_geo_bucket_type = 'geohash3' THEN COALESCE(be.geohash3_id, 'unknown')
        WHEN p_geo_bucket_type = 'city_code' THEN COALESCE(
          (SELECT m.city_code FROM public.city_geohash3_map m WHERE m.geohash3_id = be.geohash3_id LIMIT 1),
          'unknown'
        )
        ELSE 'unknown'
      END AS geo_bucket_id,
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
        'time_granularity', p_time_granularity,
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
    p_time_granularity,
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
    p_bucket_start_utc,
    p_time_granularity,
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

REVOKE ALL ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(
  UUID, TIMESTAMPTZ, TEXT, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(
  UUID, TIMESTAMPTZ, TEXT, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

-- Convenience wrappers (preserve existing call sites / semantics)
CREATE OR REPLACE FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  p_api_key_id UUID,
  p_day_start_utc TIMESTAMPTZ,
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'city_code',
  p_k_min INTEGER DEFAULT 100,
  p_dominance_max_fraction DOUBLE PRECISION DEFAULT 0.05,
  p_dp_epsilon DOUBLE PRECISION DEFAULT 0.5,
  p_dp_delta DOUBLE PRECISION DEFAULT 1e-6,
  p_budget_window_days INTEGER DEFAULT 30,
  p_privacy_budget_total_epsilon DOUBLE PRECISION DEFAULT 10.0,
  p_budget_cost_epsilon DOUBLE PRECISION DEFAULT 0.5
) RETURNS BIGINT AS $$
BEGIN
  RETURN public.outside_buyer_precompute_spots_insights_v1_bucket(
    p_api_key_id,
    p_day_start_utc,
    'day',
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.outside_buyer_precompute_spots_insights_v1_hour(
  p_api_key_id UUID,
  p_hour_start_utc TIMESTAMPTZ,
  p_reporting_delay_hours INTEGER DEFAULT 168,
  p_geo_bucket_type TEXT DEFAULT 'city_code',
  p_k_min INTEGER DEFAULT 300,
  p_dominance_max_fraction DOUBLE PRECISION DEFAULT 0.05,
  p_dp_epsilon DOUBLE PRECISION DEFAULT 0.25,
  p_dp_delta DOUBLE PRECISION DEFAULT 1e-6,
  p_budget_window_days INTEGER DEFAULT 30,
  p_privacy_budget_total_epsilon DOUBLE PRECISION DEFAULT 10.0,
  p_budget_cost_epsilon DOUBLE PRECISION DEFAULT 0.25
) RETURNS BIGINT AS $$
BEGIN
  RETURN public.outside_buyer_precompute_spots_insights_v1_bucket(
    p_api_key_id,
    p_hour_start_utc,
    'hour',
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.outside_buyer_precompute_spots_insights_v1_week(
  p_api_key_id UUID,
  p_week_start_utc TIMESTAMPTZ,
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'city_code',
  p_k_min INTEGER DEFAULT 100,
  p_dominance_max_fraction DOUBLE PRECISION DEFAULT 0.05,
  p_dp_epsilon DOUBLE PRECISION DEFAULT 0.5,
  p_dp_delta DOUBLE PRECISION DEFAULT 1e-6,
  p_budget_window_days INTEGER DEFAULT 30,
  p_privacy_budget_total_epsilon DOUBLE PRECISION DEFAULT 10.0,
  p_budget_cost_epsilon DOUBLE PRECISION DEFAULT 0.5
) RETURNS BIGINT AS $$
BEGIN
  RETURN public.outside_buyer_precompute_spots_insights_v1_bucket(
    p_api_key_id,
    p_week_start_utc,
    'week',
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

REVOKE ALL ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_hour(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_hour(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

REVOKE ALL ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_week(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_week(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

COMMENT ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(
  UUID, TIMESTAMPTZ, TEXT, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Precompute+cache v1 insights for a single UTC bucket (hour/day/week). Budget spent once per release.';

COMMENT ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_hour(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Precompute+cache v1 insights for a single UTC hour (stricter defaults).';

COMMENT ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_week(
  UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Precompute+cache v1 insights for a single UTC week (Monday 00:00 UTC aligned).';

-- ============================================================
-- Cached getter: now supports hour/day/week + city_code/geohash3
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  p_api_key_id UUID,
  p_time_bucket_start_utc TIMESTAMPTZ,
  p_time_bucket_end_utc TIMESTAMPTZ,
  p_time_granularity TEXT DEFAULT 'day',
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'city_code',
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
  v_step INTERVAL;
  v_start_bucket TIMESTAMPTZ;
  v_end_bucket_excl TIMESTAMPTZ;
  v_bucket TIMESTAMPTZ;
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
  IF p_time_bucket_end_utc > v_cutoff THEN
    RAISE EXCEPTION 'reporting delay violation (end=% cutoff=%)', p_time_bucket_end_utc, v_cutoff;
  END IF;

  IF p_time_granularity NOT IN ('hour','day','week') THEN
    RAISE EXCEPTION 'unsupported time_granularity: %', p_time_granularity;
  END IF;

  -- Bound range per granularity (prevents runaway bucket precompute + intersection surface)
  IF p_time_granularity = 'hour' AND (p_time_bucket_end_utc - p_time_bucket_start_utc) > INTERVAL '7 days' THEN
    RAISE EXCEPTION 'requested range too large for hour granularity (max 7 days)';
  END IF;
  IF p_time_granularity = 'day' AND (p_time_bucket_end_utc - p_time_bucket_start_utc) > INTERVAL '90 days' THEN
    RAISE EXCEPTION 'requested range too large for day granularity (max 90 days)';
  END IF;
  IF p_time_granularity = 'week' AND (p_time_bucket_end_utc - p_time_bucket_start_utc) > INTERVAL '365 days' THEN
    RAISE EXCEPTION 'requested range too large for week granularity (max 365 days)';
  END IF;

  v_step := CASE
    WHEN p_time_granularity = 'hour' THEN INTERVAL '1 hour'
    WHEN p_time_granularity = 'day' THEN INTERVAL '1 day'
    WHEN p_time_granularity = 'week' THEN INTERVAL '1 week'
    ELSE INTERVAL '1 day'
  END;

  v_start_bucket := (date_trunc(p_time_granularity, p_time_bucket_start_utc AT TIME ZONE 'utc') AT TIME ZONE 'utc');
  v_end_bucket_excl := (date_trunc(p_time_granularity, p_time_bucket_end_utc AT TIME ZONE 'utc') AT TIME ZONE 'utc');

  FOR v_bucket IN
    SELECT generate_series(v_start_bucket, v_end_bucket_excl - v_step, v_step)
  LOOP
    PERFORM public.outside_buyer_precompute_spots_insights_v1_bucket(
      p_api_key_id,
      v_bucket,
      p_time_granularity,
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
    AND c.time_granularity = p_time_granularity
    AND c.reporting_delay_hours = p_reporting_delay_hours
    AND c.geo_bucket_type = p_geo_bucket_type
    AND c.k_min_enforced = p_k_min
    AND c.dominance_max_fraction = p_dominance_max_fraction
    AND c.dp_mechanism = 'laplace'
    AND c.dp_epsilon = p_dp_epsilon
    AND c.dp_delta = p_dp_delta
    AND c.budget_window_days = p_budget_window_days
    AND c.time_bucket_start_utc >= v_start_bucket
    AND c.time_bucket_start_utc < v_end_bucket_excl
    AND (p_geo_bucket_ids IS NULL OR c.geo_bucket_id = ANY(p_geo_bucket_ids))
    AND (p_door_types IS NULL OR c.door_type = ANY(p_door_types))
    AND (p_categories IS NULL OR c.category = ANY(p_categories))
    AND (p_contexts IS NULL OR c.context = ANY(p_contexts));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

COMMENT ON FUNCTION public.outside_buyer_get_spots_insights_v1_cached(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Return v1 insights from cache for hour/day/week, precomputing missing buckets as needed.';

