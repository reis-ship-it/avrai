-- Migration: API key rate limit helper (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Provide a minimal, server-enforced per-minute rate limit primitive for API keys.
-- - Used by Edge Functions that accept `x-api-key`.

CREATE TABLE IF NOT EXISTS public.api_key_rate_limits_v1 (
  key_hash TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  request_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (key_hash, window_start)
);

ALTER TABLE public.api_key_rate_limits_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage api_key_rate_limits_v1" ON public.api_key_rate_limits_v1;
CREATE POLICY "Service role can manage api_key_rate_limits_v1"
  ON public.api_key_rate_limits_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.api_key_rate_limits_v1 IS
  'Per-minute request counters for api_keys_v1 (v1). Service role only.';

-- Atomic check+increment rate limit counter (service role).
CREATE OR REPLACE FUNCTION public.api_key_rate_limit_check_v1(
  p_key_hash TEXT,
  p_limit_per_min INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  v_window TIMESTAMPTZ := date_trunc('minute', NOW());
  v_count INTEGER;
BEGIN
  IF p_key_hash IS NULL OR trim(p_key_hash) = '' THEN
    RETURN FALSE;
  END IF;
  IF p_limit_per_min IS NULL OR p_limit_per_min <= 0 THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.api_key_rate_limits_v1(key_hash, window_start, request_count, updated_at)
  VALUES (p_key_hash, v_window, 1, NOW())
  ON CONFLICT (key_hash, window_start) DO UPDATE SET
    request_count = public.api_key_rate_limits_v1.request_count + 1,
    updated_at = NOW()
  RETURNING request_count INTO v_count;

  RETURN v_count <= p_limit_per_min;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.api_key_rate_limit_check_v1(TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.api_key_rate_limit_check_v1(TEXT, INTEGER) TO service_role;

COMMENT ON FUNCTION public.api_key_rate_limit_check_v1(TEXT, INTEGER)
IS 'Rate limit check+increment for API keys (per minute) (v1).';

