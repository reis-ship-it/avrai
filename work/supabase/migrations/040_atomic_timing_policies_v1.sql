-- Migration: Atomic Timing - policy registry (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Provide a single place to store “timing policies” that drive scheduling behavior
-- - Allows the “quantum atomic timing” system to learn and update schedules centrally
--
-- Design:
-- - `policy_key` identifies the job/feature (e.g., outside buyer precompute)
-- - `payload` holds parameters (JSON) so we can evolve without schema churn
-- - Service role manages policies; clients may be granted read access later per need

CREATE TABLE IF NOT EXISTS public.atomic_timing_policies_v1 (
  policy_key TEXT PRIMARY KEY,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.atomic_timing_policies_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage atomic_timing_policies_v1" ON public.atomic_timing_policies_v1;
CREATE POLICY "Service role can manage atomic_timing_policies_v1"
  ON public.atomic_timing_policies_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Helper: read policy (service role; optionally broaden later)
CREATE OR REPLACE FUNCTION public.atomic_timing_get_policy_v1(p_policy_key TEXT)
RETURNS JSONB AS $$
DECLARE
  v_payload JSONB;
BEGIN
  SELECT payload INTO v_payload
  FROM public.atomic_timing_policies_v1
  WHERE policy_key = p_policy_key;

  RETURN COALESCE(v_payload, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.atomic_timing_get_policy_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.atomic_timing_get_policy_v1(TEXT) TO service_role;

COMMENT ON TABLE public.atomic_timing_policies_v1 IS 'Central timing policy registry (v1).';
COMMENT ON FUNCTION public.atomic_timing_get_policy_v1(TEXT) IS 'Fetch timing policy payload by key (service role).';

-- Seed: outside buyer precompute defaults (policy-driven, can be updated later)
INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'outside_buyer_precompute_v1',
  jsonb_build_object(
    'include_hour', true,
    'include_day', true,
    'include_week', true,
    'max_keys', 500,
    'day_buckets', 3,
    'hour_buckets', 6,
    'week_buckets', 2
  )
)
ON CONFLICT (policy_key) DO UPDATE SET
  payload = EXCLUDED.payload,
  updated_at = NOW();

