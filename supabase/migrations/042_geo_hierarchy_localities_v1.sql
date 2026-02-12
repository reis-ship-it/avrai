-- Migration: Geo hierarchy - localities registry (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Make city buckets compatible with the expert system’s geographic hierarchy:
--   city → locality (borough/district) → neighborhood (optional)
-- - Provide a single DB-backed mapping layer we can reuse across:
--   - expert scope validation
--   - outside-buyer city_code bucketing
--   - analytics / discovery gating
--
-- Notes:
-- - We treat `public.city_definitions.city_code` as the canonical city identifier.
-- - Localities are children of a city_code.
-- - Neighborhoods are children of a locality_code.

CREATE TABLE IF NOT EXISTS public.geo_localities_v1 (
  locality_code TEXT PRIMARY KEY,         -- ex: 'us-nyc-brooklyn'
  display_name TEXT NOT NULL,             -- ex: 'Brooklyn'
  city_code TEXT NOT NULL REFERENCES public.city_definitions(city_code) ON DELETE CASCADE,
  parent_locality_code TEXT REFERENCES public.geo_localities_v1(locality_code) ON DELETE SET NULL,
  is_neighborhood BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_localities_v1_city_code
  ON public.geo_localities_v1(city_code);

CREATE INDEX IF NOT EXISTS idx_geo_localities_v1_parent
  ON public.geo_localities_v1(parent_locality_code);

ALTER TABLE public.geo_localities_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo_localities_v1" ON public.geo_localities_v1;
CREATE POLICY "Service role can manage geo_localities_v1"
  ON public.geo_localities_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Helper: list localities for a city (service-role; can be opened later for clients if needed).
CREATE OR REPLACE FUNCTION public.geo_list_city_localities_v1(p_city_code TEXT)
RETURNS TABLE (
  locality_code TEXT,
  display_name TEXT,
  parent_locality_code TEXT,
  is_neighborhood BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT l.locality_code, l.display_name, l.parent_locality_code, l.is_neighborhood
  FROM public.geo_localities_v1 l
  WHERE l.city_code = p_city_code
  ORDER BY l.is_neighborhood ASC, l.display_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_list_city_localities_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_list_city_localities_v1(TEXT) TO service_role;

COMMENT ON TABLE public.geo_localities_v1 IS 'Geo hierarchy localities registry (v1): city → locality → neighborhood.';

-- Seed NYC borough structure (ties to expertise “city expert can host in all boroughs”).
-- Ensure the city exists in city_definitions.
SELECT public.upsert_city_definition('us-nyc', 'New York City', 40.7128, -74.0060, 35, 5);

INSERT INTO public.geo_localities_v1(locality_code, display_name, city_code, parent_locality_code, is_neighborhood)
VALUES
  ('us-nyc-manhattan', 'Manhattan', 'us-nyc', NULL, false),
  ('us-nyc-brooklyn', 'Brooklyn', 'us-nyc', NULL, false),
  ('us-nyc-queens', 'Queens', 'us-nyc', NULL, false),
  ('us-nyc-bronx', 'Bronx', 'us-nyc', NULL, false),
  ('us-nyc-staten_island', 'Staten Island', 'us-nyc', NULL, false)
ON CONFLICT (locality_code) DO NOTHING;

-- Seed Brooklyn neighborhoods as neighborhood-localities under the Brooklyn locality.
INSERT INTO public.geo_localities_v1(locality_code, display_name, city_code, parent_locality_code, is_neighborhood)
VALUES
  ('us-nyc-brooklyn-greenpoint', 'Greenpoint', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-williamsburg', 'Williamsburg', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-dumbo', 'DUMBO', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-park_slope', 'Park Slope', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-red_hook', 'Red Hook', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-carroll_gardens', 'Carroll Gardens', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-sunset_park', 'Sunset Park', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-bath_beach', 'Bath Beach', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-bushwick', 'Bushwick', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-bedford_stuyvesant', 'Bedford-Stuyvesant', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-crown_heights', 'Crown Heights', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-prospect_heights', 'Prospect Heights', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-fort_greene', 'Fort Greene', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-boerum_hill', 'Boerum Hill', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-cobble_hill', 'Cobble Hill', 'us-nyc', 'us-nyc-brooklyn', true),
  ('us-nyc-brooklyn-gowanus', 'Gowanus', 'us-nyc', 'us-nyc-brooklyn', true)
ON CONFLICT (locality_code) DO NOTHING;

-- Rebuild city_code geohash3 coverage after ensuring city definitions exist.
SELECT public.populate_city_geohash3_map_from_definitions();

