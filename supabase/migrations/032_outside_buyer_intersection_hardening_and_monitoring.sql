-- Migration: Outside Buyer Insights - Intersection hardening + monitoring views
-- Created: 2026-01-01
-- Purpose: Prevent intersection attacks and provide monitoring/alert primitives.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- Query fingerprint ledger (intersection attack hardening)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.outside_buyer_query_fingerprints (
  api_key_id UUID NOT NULL REFERENCES public.api_keys(id) ON DELETE CASCADE,
  day DATE NOT NULL,
  fingerprint TEXT NOT NULL,
  request_count BIGINT NOT NULL DEFAULT 0,
  first_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (api_key_id, day, fingerprint)
);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_query_fingerprints_api_day
  ON public.outside_buyer_query_fingerprints(api_key_id, day DESC);

ALTER TABLE public.outside_buyer_query_fingerprints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage outside_buyer_query_fingerprints"
  ON public.outside_buyer_query_fingerprints
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Record a query fingerprint and enforce max distinct fingerprints/day.
CREATE OR REPLACE FUNCTION public.outside_buyer_record_query_fingerprint(
  p_api_key_id UUID,
  p_fingerprint TEXT,
  p_max_distinct_per_day INTEGER DEFAULT 200
) RETURNS BOOLEAN AS $$
DECLARE
  v_day DATE := (NOW() AT TIME ZONE 'utc')::date;
  v_distinct_count INTEGER;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_fingerprint IS NULL OR length(p_fingerprint) < 16 THEN
    RAISE EXCEPTION 'fingerprint is required';
  END IF;
  IF p_max_distinct_per_day IS NULL OR p_max_distinct_per_day < 1 THEN
    RAISE EXCEPTION 'max_distinct_per_day must be >= 1';
  END IF;

  INSERT INTO public.outside_buyer_query_fingerprints (
    api_key_id,
    day,
    fingerprint,
    request_count,
    first_seen,
    last_seen
  )
  VALUES (p_api_key_id, v_day, p_fingerprint, 1, NOW(), NOW())
  ON CONFLICT (api_key_id, day, fingerprint)
  DO UPDATE SET
    request_count = public.outside_buyer_query_fingerprints.request_count + 1,
    last_seen = NOW();

  SELECT COUNT(*)::INTEGER
  INTO v_distinct_count
  FROM public.outside_buyer_query_fingerprints
  WHERE api_key_id = p_api_key_id
    AND day = v_day;

  IF v_distinct_count > p_max_distinct_per_day THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_record_query_fingerprint(UUID, TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_record_query_fingerprint(UUID, TEXT, INTEGER) TO service_role;

-- ============================================================
-- Monitoring views
-- ============================================================

CREATE OR REPLACE VIEW public.outside_buyer_privacy_budget_usage_v1 AS
SELECT
  b.api_key_id,
  b.window_start,
  b.budget_window_days,
  b.epsilon_budget,
  b.epsilon_spent,
  CASE
    WHEN b.epsilon_budget <= 0 THEN NULL
    ELSE (b.epsilon_spent / b.epsilon_budget)
  END AS epsilon_fraction_spent,
  b.delta,
  b.updated_at
FROM public.outside_buyer_privacy_budgets b;

CREATE OR REPLACE VIEW public.outside_buyer_export_request_stats_v1 AS
SELECT
  l.api_key_id,
  date_trunc('day', l.created_at AT TIME ZONE 'utc') AS day_utc,
  COUNT(*)::BIGINT AS total_requests,
  COUNT(*) FILTER (WHERE l.response_status >= 400)::BIGINT AS error_requests,
  COUNT(*) FILTER (WHERE l.response_status = 429)::BIGINT AS rate_limited_requests,
  MAX(l.created_at) AS last_request_at,
  AVG(l.processing_time_ms)::DOUBLE PRECISION AS avg_processing_ms
FROM public.api_request_logs l
WHERE l.endpoint = 'outside-buyer-insights'
GROUP BY l.api_key_id, date_trunc('day', l.created_at AT TIME ZONE 'utc');

CREATE OR REPLACE VIEW public.outside_buyer_query_fingerprint_stats_v1 AS
SELECT
  q.api_key_id,
  q.day AS day_utc,
  COUNT(*)::BIGINT AS distinct_fingerprints,
  SUM(q.request_count)::BIGINT AS total_requests,
  MAX(q.last_seen) AS last_seen
FROM public.outside_buyer_query_fingerprints q
GROUP BY q.api_key_id, q.day;

-- ============================================================
-- Alert helper (writes to audit_logs when budget is high)
-- ============================================================

CREATE OR REPLACE FUNCTION public.outside_buyer_maybe_alert_budget(
  p_api_key_id UUID,
  p_threshold_fraction DOUBLE PRECISION DEFAULT 0.8
) RETURNS BOOLEAN AS $$
DECLARE
  v_window_start DATE;
  v_row public.outside_buyer_privacy_budgets%ROWTYPE;
  v_fraction DOUBLE PRECISION;
BEGIN
  IF p_api_key_id IS NULL THEN
    RAISE EXCEPTION 'api_key_id is required';
  END IF;
  IF p_threshold_fraction IS NULL OR p_threshold_fraction <= 0 OR p_threshold_fraction >= 1 THEN
    RAISE EXCEPTION 'threshold_fraction must be in (0,1)';
  END IF;

  v_window_start := public.outside_buyer_budget_window_start(NOW(), 30);

  SELECT *
  INTO v_row
  FROM public.outside_buyer_privacy_budgets
  WHERE api_key_id = p_api_key_id
    AND window_start = v_window_start;

  IF v_row.api_key_id IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_row.epsilon_budget <= 0 THEN
    RETURN FALSE;
  END IF;

  v_fraction := v_row.epsilon_spent / v_row.epsilon_budget;

  IF v_fraction >= p_threshold_fraction THEN
    INSERT INTO public.audit_logs (
      type,
      action,
      status,
      metadata
    )
    VALUES (
      'outside_buyer_privacy_budget',
      'alert',
      'success',
      jsonb_build_object(
        'api_key_id', p_api_key_id,
        'window_start', v_row.window_start,
        'epsilon_spent', v_row.epsilon_spent,
        'epsilon_budget', v_row.epsilon_budget,
        'epsilon_fraction_spent', v_fraction,
        'threshold', p_threshold_fraction
      )
    );

    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_maybe_alert_budget(UUID, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_maybe_alert_budget(UUID, DOUBLE PRECISION) TO service_role;

COMMENT ON TABLE public.outside_buyer_query_fingerprints IS 'Intersection-attack hardening: counts distinct query fingerprints per buyer key per day';
COMMENT ON VIEW public.outside_buyer_privacy_budget_usage_v1 IS 'Monitoring view: privacy budget usage for outside-buyer DP exports';
COMMENT ON VIEW public.outside_buyer_export_request_stats_v1 IS 'Monitoring view: request/error rates for outside buyer insights endpoint';
COMMENT ON VIEW public.outside_buyer_query_fingerprint_stats_v1 IS 'Monitoring view: distinct query fingerprint counts per day';

