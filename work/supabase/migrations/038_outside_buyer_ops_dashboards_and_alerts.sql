-- Migration: Outside Buyer Insights - ops dashboards + alerts (views + helpers)
-- Created: 2026-01-01
-- Purpose:
-- - Provide lightweight SQL-native dashboards for ops monitoring
-- - Add alert helpers for cron staleness (writes to audit_logs)

-- Cron job status (pg_cron)
CREATE OR REPLACE VIEW public.outside_buyer_cron_jobs_v1 AS
SELECT
  j.jobid,
  j.jobname,
  j.schedule,
  j.command,
  j.database,
  j.username,
  j.active,
  MAX(r.end_time) AS last_run_end_time,
  MAX(CASE WHEN r.status = 'succeeded' THEN r.end_time END) AS last_success_end_time,
  MAX(CASE WHEN r.status = 'failed' THEN r.end_time END) AS last_failure_end_time,
  COUNT(*) FILTER (WHERE r.start_time > NOW() - interval '7 days') AS runs_7d,
  COUNT(*) FILTER (WHERE r.status = 'failed' AND r.start_time > NOW() - interval '7 days') AS failures_7d
FROM cron.job j
LEFT JOIN cron.job_run_details r ON r.jobid = j.jobid
GROUP BY j.jobid, j.jobname, j.schedule, j.command, j.database, j.username, j.active;

COMMENT ON VIEW public.outside_buyer_cron_jobs_v1 IS 'Ops view: pg_cron job status + recent success/failure.';

-- Cache run freshness (precompute)
CREATE OR REPLACE VIEW public.outside_buyer_cache_run_freshness_v1 AS
SELECT
  api_key_id,
  time_granularity,
  MAX(computed_at) AS last_computed_at,
  COUNT(*) FILTER (WHERE computed_at > NOW() - interval '7 days') AS buckets_computed_7d,
  SUM(row_count) FILTER (WHERE computed_at > NOW() - interval '7 days') AS rows_computed_7d
FROM public.outside_buyer_insights_v1_cache_runs
GROUP BY api_key_id, time_granularity;

COMMENT ON VIEW public.outside_buyer_cache_run_freshness_v1 IS 'Ops view: cache run freshness per api_key_id/time_granularity.';

-- City bucket coverage
CREATE OR REPLACE VIEW public.outside_buyer_city_code_coverage_v1 AS
SELECT
  city_code,
  COUNT(*)::bigint AS geohash3_count,
  MAX(created_at) AS last_updated_at
FROM public.city_geohash3_map
GROUP BY city_code
ORDER BY city_code;

COMMENT ON VIEW public.outside_buyer_city_code_coverage_v1 IS 'Ops view: how many geohash3 tiles map to each city_code.';

-- Alert helper: cron job stale (best-effort; logs to audit_logs)
CREATE OR REPLACE FUNCTION public.outside_buyer_maybe_alert_cron_stale(
  p_jobname TEXT DEFAULT 'outside_buyer_precompute_v1_hourly',
  p_max_age_hours INTEGER DEFAULT 2
) RETURNS BOOLEAN AS $$
DECLARE
  v_last_success TIMESTAMPTZ;
  v_last_run TIMESTAMPTZ;
  v_now TIMESTAMPTZ := NOW();
  v_max_age INTERVAL := make_interval(hours => p_max_age_hours);
BEGIN
  SELECT last_success_end_time, last_run_end_time
  INTO v_last_success, v_last_run
  FROM public.outside_buyer_cron_jobs_v1
  WHERE jobname = p_jobname;

  -- If job not found, alert.
  IF v_last_success IS NULL AND v_last_run IS NULL THEN
    INSERT INTO public.audit_logs(type, action, status, metadata, created_at)
    VALUES (
      'outside_buyer_alert',
      'cron_stale',
      'warning',
      jsonb_build_object(
        'jobname', p_jobname,
        'reason', 'cron job not found or has never run'
      ),
      NOW()
    );
    RETURN TRUE;
  END IF;

  -- Prefer success time, fall back to last run.
  IF v_last_success IS NOT NULL THEN
    IF v_now - v_last_success > v_max_age THEN
      INSERT INTO public.audit_logs(type, action, status, metadata, created_at)
      VALUES (
        'outside_buyer_alert',
        'cron_stale',
        'warning',
        jsonb_build_object(
          'jobname', p_jobname,
          'max_age_hours', p_max_age_hours,
          'last_success_end_time', v_last_success,
          'now', v_now
        ),
        NOW()
      );
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END IF;

  IF v_last_run IS NOT NULL AND v_now - v_last_run > v_max_age THEN
    INSERT INTO public.audit_logs(type, action, status, metadata, created_at)
    VALUES (
      'outside_buyer_alert',
      'cron_stale',
      'warning',
      jsonb_build_object(
        'jobname', p_jobname,
        'max_age_hours', p_max_age_hours,
        'last_run_end_time', v_last_run,
        'now', v_now
      ),
      NOW()
    );
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_maybe_alert_cron_stale(TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_maybe_alert_cron_stale(TEXT, INTEGER) TO service_role;

