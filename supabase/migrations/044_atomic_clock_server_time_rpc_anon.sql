-- Migration: Atomic Clock - allow anon access to get_server_time()
-- Created: 2026-01-01
-- Purpose:
-- - Allow atomic clock sync before login (improves consistency across app startup flows)
-- - Safe: function returns only server `now()`

GRANT EXECUTE ON FUNCTION public.get_server_time() TO anon;

