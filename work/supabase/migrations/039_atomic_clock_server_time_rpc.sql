-- Migration: Atomic Clock - server time RPC
-- Created: 2026-01-01
-- Purpose:
-- - Provide a minimal, safe RPC for clients to fetch server time
-- - Used by AtomicClockService to estimate device↔server offset (NTP-style)
--
-- Security:
-- - Returns ONLY `now()` (no user data).
-- - Safe to expose to authenticated clients.

CREATE OR REPLACE FUNCTION public.get_server_time()
RETURNS TIMESTAMPTZ AS $$
BEGIN
  RETURN NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.get_server_time() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_server_time() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_server_time() TO service_role;

COMMENT ON FUNCTION public.get_server_time() IS 'Atomic clock helper: returns server time (timestamptz) for client time sync.';

