-- Migration: Geo hierarchy - public read RPCs (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Allow authenticated clients to read the geo hierarchy in a controlled way
-- - Supports expert system UX (city/locality selection) and offline caching
--
-- Security model:
-- - Underlying tables remain service-role only via RLS.
-- - Clients read through SECURITY DEFINER functions with limited fields.

-- List available cities
CREATE OR REPLACE FUNCTION public.geo_list_cities_v1()
RETURNS TABLE (
  city_code TEXT,
  display_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT cd.city_code, cd.display_name
  FROM public.city_definitions cd
  ORDER BY cd.city_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_list_cities_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_list_cities_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_list_cities_v1() TO service_role;

COMMENT ON FUNCTION public.geo_list_cities_v1() IS 'List city_code + display_name for geo hierarchy (authenticated read).';

-- Allow authenticated to list localities for a city
REVOKE ALL ON FUNCTION public.geo_list_city_localities_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_list_city_localities_v1(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_list_city_localities_v1(TEXT) TO service_role;

