-- Migration: Outside Buyer Insights - scheduled precompute (pg_cron)
-- Created: 2026-01-01
-- Purpose:
-- - Automate generation of cached “release slices” (hour/day/week) so buyers hit warm cache
-- - Keep compute/budget spend bounded and predictable (idempotent precompute)
--
-- Notes:
-- - `pg_cron` is available on Supabase but may not be installed yet in a given project.
-- - Jobs are created idempotently (no duplicates on re-run).

-- Enable pg_cron (Supabase typically uses schema `extensions` for extensions)
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- A small helper that precomputes the most recent eligible buckets per outside-buyer key.
CREATE OR REPLACE FUNCTION public.outside_buyer_run_scheduled_precompute_v1(
  p_include_hour BOOLEAN DEFAULT true,
  p_include_day BOOLEAN DEFAULT true,
  p_include_week BOOLEAN DEFAULT true,
  p_max_keys INTEGER DEFAULT 500,
  p_day_buckets INTEGER DEFAULT 3,   -- precompute N most recent eligible days
  p_hour_buckets INTEGER DEFAULT 6,  -- precompute N most recent eligible hours
  p_week_buckets INTEGER DEFAULT 2   -- precompute N most recent eligible weeks
) RETURNS JSONB AS $$
DECLARE
  v_key RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_keys_processed INTEGER := 0;
  v_rows_inserted BIGINT := 0;
  v_rows BIGINT := 0;
  v_i INTEGER;

  -- Most recent eligible bucket starts (based on enforced delay per granularity):
  -- day/week: 72h delay  -> last eligible bucket end <= now-72h
  -- hour:     168h delay -> last eligible bucket end <= now-168h
  v_day_start TIMESTAMPTZ := date_trunc('day', v_now - interval '72 hours') - interval '1 day';
  v_week_start TIMESTAMPTZ := date_trunc('week', v_now - interval '72 hours') - interval '1 week';
  v_hour_start TIMESTAMPTZ := date_trunc('hour', v_now - interval '168 hours') - interval '1 hour';
BEGIN
  FOR v_key IN
    SELECT id
    FROM public.api_keys
    WHERE partner_id LIKE 'outside_buyer\_%'
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > NOW())
    ORDER BY created_at DESC
    LIMIT p_max_keys
  LOOP
    v_keys_processed := v_keys_processed + 1;

    IF p_include_day THEN
      FOR v_i IN 0..GREATEST(p_day_buckets - 1, 0) LOOP
        v_rows := public.outside_buyer_precompute_spots_insights_v1_day(
          v_key.id,
          v_day_start - make_interval(days => v_i)
        );
        v_rows_inserted := v_rows_inserted + COALESCE(v_rows, 0);
      END LOOP;
    END IF;

    IF p_include_week THEN
      FOR v_i IN 0..GREATEST(p_week_buckets - 1, 0) LOOP
        v_rows := public.outside_buyer_precompute_spots_insights_v1_week(
          v_key.id,
          v_week_start - make_interval(days => (7 * v_i))
        );
        v_rows_inserted := v_rows_inserted + COALESCE(v_rows, 0);
      END LOOP;
    END IF;

    IF p_include_hour THEN
      FOR v_i IN 0..GREATEST(p_hour_buckets - 1, 0) LOOP
        v_rows := public.outside_buyer_precompute_spots_insights_v1_hour(
          v_key.id,
          v_hour_start - make_interval(hours => v_i)
        );
        v_rows_inserted := v_rows_inserted + COALESCE(v_rows, 0);
      END LOOP;
    END IF;
  END LOOP;

  -- Best-effort: log a single audit entry (service role / cron user should be allowed).
  BEGIN
    INSERT INTO public.audit_logs(type, metadata, created_at)
    VALUES (
      'outside_buyer_precompute_cron_v1',
      jsonb_build_object(
        'keys_processed', v_keys_processed,
        'rows_inserted', v_rows_inserted,
        'day_start', v_day_start,
        'week_start', v_week_start,
        'hour_start', v_hour_start,
        'include_hour', p_include_hour,
        'include_day', p_include_day,
        'include_week', p_include_week,
        'day_buckets', p_day_buckets,
        'hour_buckets', p_hour_buckets,
        'week_buckets', p_week_buckets
      ),
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    -- ignore audit failure (cron should still run)
    NULL;
  END;

  RETURN jsonb_build_object(
    'keys_processed', v_keys_processed,
    'rows_inserted', v_rows_inserted,
    'day_start', v_day_start,
    'week_start', v_week_start,
    'hour_start', v_hour_start
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1(
  BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1(
  BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER
) TO service_role;

COMMENT ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1(
  BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER
) IS 'Scheduled cache precompute for outside-buyer insights (hour/day/week). Intended for pg_cron.';

-- Create cron job (hourly). If it already exists, do nothing.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'outside_buyer_precompute_v1_hourly'
  ) THEN
    PERFORM cron.schedule(
      'outside_buyer_precompute_v1_hourly',
      '17 * * * *',
      $cmd$select public.outside_buyer_run_scheduled_precompute_v1();$cmd$
    );
  END IF;
END $$;

