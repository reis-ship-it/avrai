-- Migration: Outside Buyer Insights (v1) - DP + budgeted exports
-- Created: 2026-01-01
-- Purpose: Implement safe-to-sell market insights per contract
-- Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md

-- Ensure needed extensions exist (digest/random helpers + geospatial buckets)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- Outside buyer privacy budgets (query accounting)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.outside_buyer_privacy_budgets (
  api_key_id UUID NOT NULL REFERENCES public.api_keys(id) ON DELETE CASCADE,
  window_start DATE NOT NULL,
  budget_window_days INTEGER NOT NULL DEFAULT 30,
  epsilon_budget DOUBLE PRECISION NOT NULL DEFAULT 10.0,
  epsilon_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  delta DOUBLE PRECISION NOT NULL DEFAULT 1e-6,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (api_key_id, window_start)
);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_privacy_budgets_api_key_id
  ON public.outside_buyer_privacy_budgets(api_key_id);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_privacy_budgets_window_start
  ON public.outside_buyer_privacy_budgets(window_start DESC);

ALTER TABLE public.outside_buyer_privacy_budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage outside_buyer_privacy_budgets"
  ON public.outside_buyer_privacy_budgets
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

CREATE OR REPLACE FUNCTION public.update_outside_buyer_privacy_budgets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_outside_buyer_privacy_budgets_updated_at_trigger
  ON public.outside_buyer_privacy_budgets;

CREATE TRIGGER update_outside_buyer_privacy_budgets_updated_at_trigger
  BEFORE UPDATE ON public.outside_buyer_privacy_budgets
  FOR EACH ROW
  EXECUTE FUNCTION public.update_outside_buyer_privacy_budgets_updated_at();

-- ============================================================
-- Helper: fixed-size rolling budget window start (epoch-based)
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_budget_window_start(
  p_now TIMESTAMPTZ,
  p_budget_window_days INTEGER
) RETURNS DATE AS $$
DECLARE
  v_days_since_epoch INTEGER;
  v_window_index INTEGER;
BEGIN
  IF p_budget_window_days IS NULL OR p_budget_window_days <= 0 THEN
    RAISE EXCEPTION 'budget_window_days must be positive';
  END IF;

  v_days_since_epoch := (p_now::date - DATE '1970-01-01');
  v_window_index := (v_days_since_epoch / p_budget_window_days);

  RETURN (DATE '1970-01-01' + (v_window_index * p_budget_window_days));
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Helper: consume privacy budget (epsilon accounting)
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_consume_privacy_budget(
  p_api_key_id UUID,
  p_epsilon_cost DOUBLE PRECISION,
  p_budget_window_days INTEGER DEFAULT 30,
  p_epsilon_budget DOUBLE PRECISION DEFAULT 10.0,
  p_delta DOUBLE PRECISION DEFAULT 1e-6
) RETURNS BOOLEAN AS $$
DECLARE
  v_window_start DATE;
  v_current_spent DOUBLE PRECISION;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_epsilon_cost IS NULL OR p_epsilon_cost <= 0 THEN
    RAISE EXCEPTION 'epsilon_cost must be positive';
  END IF;
  IF p_epsilon_budget IS NULL OR p_epsilon_budget <= 0 THEN
    RAISE EXCEPTION 'epsilon_budget must be positive';
  END IF;

  v_window_start := public.outside_buyer_budget_window_start(NOW(), p_budget_window_days);

  -- Create budget row if missing (idempotent)
  INSERT INTO public.outside_buyer_privacy_budgets (
    api_key_id,
    window_start,
    budget_window_days,
    epsilon_budget,
    epsilon_spent,
    delta
  )
  VALUES (
    p_api_key_id,
    v_window_start,
    p_budget_window_days,
    p_epsilon_budget,
    0.0,
    p_delta
  )
  ON CONFLICT (api_key_id, window_start) DO NOTHING;

  SELECT epsilon_spent
  INTO v_current_spent
  FROM public.outside_buyer_privacy_budgets
  WHERE api_key_id = p_api_key_id
    AND window_start = v_window_start
  FOR UPDATE;

  IF v_current_spent + p_epsilon_cost > p_epsilon_budget THEN
    RETURN FALSE;
  END IF;

  UPDATE public.outside_buyer_privacy_budgets
  SET epsilon_spent = epsilon_spent + p_epsilon_cost
  WHERE api_key_id = p_api_key_id
    AND window_start = v_window_start;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Lock down budget function to service role only (outside-buyer exports are never user-facing)
REVOKE ALL ON FUNCTION public.outside_buyer_consume_privacy_budget(UUID, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_consume_privacy_budget(UUID, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION) TO service_role;

-- ============================================================
-- Helper: Laplace noise sampler (for DP counts)
-- Laplace(0, b) where b = sensitivity / epsilon
-- ============================================================

CREATE OR REPLACE FUNCTION public.dp_laplace_noise(p_scale DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  u DOUBLE PRECISION;
  s DOUBLE PRECISION;
BEGIN
  IF p_scale IS NULL OR p_scale <= 0 THEN
    RAISE EXCEPTION 'scale must be positive';
  END IF;

  -- u ~ Uniform(-0.5, 0.5)
  u := random() - 0.5;
  s := CASE WHEN u < 0 THEN -1.0 ELSE 1.0 END;

  -- Inverse-CDF sampling: noise = -b * sign(u) * ln(1 - 2|u|)
  RETURN (-p_scale * s * ln(1.0 - 2.0 * abs(u)));
END;
$$ LANGUAGE plpgsql VOLATILE;

REVOKE ALL ON FUNCTION public.dp_laplace_noise(DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dp_laplace_noise(DOUBLE PRECISION) TO service_role;

-- ============================================================
-- Outside-buyer export function (v1 schema)
-- Returns JSONB rows following the contract schema.
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_get_spots_insights_v1(
  p_api_key_id UUID,
  p_time_bucket_start_utc TIMESTAMPTZ,
  p_time_bucket_end_utc TIMESTAMPTZ,
  p_time_granularity TEXT DEFAULT 'day',
  p_reporting_delay_hours INTEGER DEFAULT 72,
  p_geo_bucket_type TEXT DEFAULT 'geohash4',
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
  v_budget_ok BOOLEAN;
BEGIN
  -- Input validation + contract enforcement
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
  IF p_k_min IS NULL OR p_k_min < 1 THEN
    RAISE EXCEPTION 'k_min must be >= 1';
  END IF;
  IF p_dp_epsilon IS NULL OR p_dp_epsilon <= 0 THEN
    RAISE EXCEPTION 'dp_epsilon must be positive';
  END IF;

  -- Privacy budget accounting (query-level)
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

  RETURN QUERY
  WITH base_events AS (
    SELECT
      date_trunc(p_time_granularity, ie.timestamp) AS time_bucket_start_utc,
      ie.agent_id,
      ie.event_type,
      ie.parameters,
      ie.context,
      ie.timestamp,
      -- Coarsen geo immediately (no precise GPS in outputs)
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
          4
        )
        ELSE NULL
      END AS geo_bucket_id
    FROM public.interaction_events ie
    WHERE ie.timestamp >= p_time_bucket_start_utc
      AND ie.timestamp < p_time_bucket_end_utc
  ),
  normalized AS (
    SELECT
      be.time_bucket_start_utc,
      COALESCE(be.geo_bucket_id, 'unknown') AS geo_bucket_id,
      be.agent_id,
      be.event_type,
      be.parameters,
      be.timestamp,
      -- Door type classification (spot | event | community)
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
      -- Context bucket (morning | midday | evening | weekend | unknown)
      CASE
        WHEN EXTRACT(ISODOW FROM be.timestamp) IN (6, 7) THEN 'weekend'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 5 AND EXTRACT(HOUR FROM be.timestamp) < 11 THEN 'morning'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 11 AND EXTRACT(HOUR FROM be.timestamp) < 17 THEN 'midday'
        WHEN EXTRACT(HOUR FROM be.timestamp) >= 17 AND EXTRACT(HOUR FROM be.timestamp) < 22 THEN 'evening'
        ELSE 'unknown'
      END AS context_bucket,
      -- Spot ID (if present) for category enrichment
      COALESCE(
        be.parameters->>'spot_id',
        CASE
          WHEN be.event_type = 'respect_tap' AND lower(COALESCE(be.parameters->>'target_type', '')) = 'spot'
            THEN be.parameters->>'target_id'
          ELSE NULL
        END
      ) AS spot_id_text,
      -- Category hint (if provided directly on event)
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
      -- Normalize category to contract enum (fallback to spots.category, else other)
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
    -- Count only "door-opening" events for this dataset
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
      -- k-min + dominance rules
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
      (1.0 / p_dp_epsilon) AS dp_scale,
      -- DP-noised counts (clamped to >= 0)
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
      -- Smooth "trend" proxy from DP'd doors_opened
      LEAST(
        1.0,
        GREATEST(
          0.0,
          (1.0 - exp(-GREATEST(cd.doors_opened_dp::DOUBLE PRECISION, 0.0) / 1000.0))
        )
      ) AS trend_score_est
    FROM cell_dp cd
  ),
  filtered AS (
    SELECT *
    FROM cell_final
    WHERE (p_geo_bucket_ids IS NULL OR geo_bucket_id = ANY(p_geo_bucket_ids))
      AND (p_door_types IS NULL OR door_type = ANY(p_door_types))
      AND (p_categories IS NULL OR category = ANY(p_categories))
      AND (p_contexts IS NULL OR context = ANY(p_contexts))
  )
  SELECT jsonb_build_object(
    'schema_version', '1.0',
    'dataset', 'spots_insights_v1',
    'time_bucket_start_utc', to_char((filtered.time_bucket_start_utc AT TIME ZONE 'utc'), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'time_granularity', p_time_granularity,
    'reporting_delay_hours', p_reporting_delay_hours,
    'geo_bucket', jsonb_build_object(
      'type', p_geo_bucket_type,
      'id', filtered.geo_bucket_id
    ),
    'segment', jsonb_build_object(
      'door_type', filtered.door_type,
      'category', filtered.category,
      'context', filtered.context
    ),
    'metrics',
      CASE
        WHEN filtered.suppressed THEN jsonb_build_object(
          'unique_participants_est', NULL,
          'doors_opened_est', NULL,
          'repeat_rate_est', NULL,
          'trend_score_est', NULL
        )
        ELSE jsonb_build_object(
          'unique_participants_est', filtered.unique_participants_dp,
          'doors_opened_est', filtered.doors_opened_dp,
          'repeat_rate_est', filtered.repeat_rate_est,
          'trend_score_est', filtered.trend_score_est
        )
      END,
    'privacy', jsonb_build_object(
      'k_min_enforced', p_k_min,
      'suppressed', filtered.suppressed,
      'suppressed_reason', filtered.suppressed_reason,
      'dp', jsonb_build_object(
        'enabled', TRUE,
        'mechanism', 'laplace',
        'epsilon', p_dp_epsilon,
        'delta', p_dp_delta,
        'budget_window_days', p_budget_window_days
      )
    )
  )
  FROM filtered;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_get_spots_insights_v1(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_get_spots_insights_v1(
  UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INTEGER, TEXT, TEXT[], TEXT[], TEXT[], TEXT[], INTEGER, DOUBLE PRECISION,
  DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

COMMENT ON TABLE public.outside_buyer_privacy_budgets IS 'Privacy budget accounting for outside-buyer DP exports (epsilon budgeting)';
COMMENT ON FUNCTION public.outside_buyer_get_spots_insights_v1 IS 'Outside-buyer insights export (v1): aggregate-only, delayed, DP-noised, k-min + dominance enforced';

