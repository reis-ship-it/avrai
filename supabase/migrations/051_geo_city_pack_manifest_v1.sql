-- Migration: Geo packs - city pack manifest (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Provide a single authoritative manifest per `city_code` describing the latest downloadable city pack.
-- - Supports onboarding + map usage pre-auth (anon read via RPC).

CREATE TABLE IF NOT EXISTS public.geo_city_pack_manifest_v1 (
  city_code TEXT PRIMARY KEY REFERENCES public.city_definitions(city_code) ON DELETE CASCADE,
  latest_pack_version INTEGER NOT NULL DEFAULT 0,
  storage_path TEXT NOT NULL DEFAULT '',
  sha256 TEXT NOT NULL DEFAULT '',
  size_bytes BIGINT NOT NULL DEFAULT 0,
  built_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_city_pack_manifest_v1_updated_at
  ON public.geo_city_pack_manifest_v1(updated_at DESC);

ALTER TABLE public.geo_city_pack_manifest_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo_city_pack_manifest_v1" ON public.geo_city_pack_manifest_v1;
CREATE POLICY "Service role can manage geo_city_pack_manifest_v1"
  ON public.geo_city_pack_manifest_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Public read via security definer RPC (avoids exposing table directly).
CREATE OR REPLACE FUNCTION public.geo_get_city_pack_manifest_v1(p_city_code TEXT)
RETURNS TABLE (
  city_code TEXT,
  latest_pack_version INTEGER,
  storage_path TEXT,
  sha256 TEXT,
  size_bytes BIGINT,
  built_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.city_code,
    m.latest_pack_version,
    m.storage_path,
    m.sha256,
    m.size_bytes,
    m.built_at,
    m.updated_at
  FROM public.geo_city_pack_manifest_v1 m
  WHERE m.city_code = p_city_code
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_get_city_pack_manifest_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_get_city_pack_manifest_v1(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.geo_get_city_pack_manifest_v1(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_get_city_pack_manifest_v1(TEXT) TO service_role;

COMMENT ON TABLE public.geo_city_pack_manifest_v1 IS
  'Latest downloadable city pack metadata per city_code (v1).';
COMMENT ON FUNCTION public.geo_get_city_pack_manifest_v1(TEXT) IS
  'Public-safe read of city pack manifest per city_code (v1).';

