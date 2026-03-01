-- Migration: Outside Buyer precompute - read from atomic timing policy
-- Created: 2026-01-01
-- Purpose:
-- - Route scheduling behavior through atomic timing policy registry (v1)
-- - This is the first concrete “all timing goes through atomic timing” integration for backend jobs.

-- Policy-driven wrapper. Cron should call THIS function.
CREATE OR REPLACE FUNCTION public.outside_buyer_run_scheduled_precompute_v1_policy()
RETURNS JSONB AS $$
DECLARE
  v_policy JSONB := public.atomic_timing_get_policy_v1('outside_buyer_precompute_v1');
BEGIN
  RETURN public.outside_buyer_run_scheduled_precompute_v1(
    COALESCE((v_policy->>'include_hour')::boolean, true),
    COALESCE((v_policy->>'include_day')::boolean, true),
    COALESCE((v_policy->>'include_week')::boolean, true),
    COALESCE((v_policy->>'max_keys')::integer, 500),
    COALESCE((v_policy->>'day_buckets')::integer, 3),
    COALESCE((v_policy->>'hour_buckets')::integer, 6),
    COALESCE((v_policy->>'week_buckets')::integer, 2)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1_policy() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1_policy() TO service_role;

COMMENT ON FUNCTION public.outside_buyer_run_scheduled_precompute_v1_policy()
IS 'Policy-driven outside-buyer precompute entrypoint. Reads atomic_timing_policies_v1 then calls outside_buyer_run_scheduled_precompute_v1.';

-- Update cron job command to call policy hook (if job exists).
DO $$
BEGIN
  -- Supabase often restricts altering existing cron jobs. The most compatible approach
  -- is to unschedule and re-schedule with the same jobname.
  BEGIN
    PERFORM cron.unschedule('outside_buyer_precompute_v1_hourly');
  EXCEPTION WHEN OTHERS THEN
    -- ignore if job does not exist or cannot be unscheduled
    NULL;
  END;

  BEGIN
    PERFORM cron.schedule(
      'outside_buyer_precompute_v1_hourly',
      '17 * * * *',
      $cmd$select public.outside_buyer_run_scheduled_precompute_v1_policy();$cmd$
    );
  EXCEPTION WHEN OTHERS THEN
    -- ignore if schedule fails (job may already exist and be immutable in this env)
    NULL;
  END;
END $$;

