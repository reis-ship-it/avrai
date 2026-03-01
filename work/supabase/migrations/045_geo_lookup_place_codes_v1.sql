-- Migration: Geo hierarchy - lookup RPCs for place → codes (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Make geo hierarchy “first-class” by enabling canonical code resolution from
--   user-facing names (e.g., 'Brooklyn' → city_code 'us-nyc', locality_code 'us-nyc-brooklyn')
-- - Used by app event creation, map filtering, and future geo-based enforcement.
--
-- Security:
-- - Read-only helpers; safe to expose to authenticated clients.

CREATE OR REPLACE FUNCTION public.geo_lookup_city_code_v1(p_place_name TEXT)
RETURNS TEXT AS $$
DECLARE
  v_name TEXT := lower(trim(coalesce(p_place_name, '')));
  v_city_code TEXT;
BEGIN
  IF v_name = '' THEN
    RETURN NULL;
  END IF;

  -- 1) Direct city_code match
  SELECT cd.city_code INTO v_city_code
  FROM public.city_definitions cd
  WHERE lower(cd.city_code) = v_name
  LIMIT 1;
  IF v_city_code IS NOT NULL THEN
    RETURN v_city_code;
  END IF;

  -- 2) Match against city display_name (contains either direction)
  SELECT cd.city_code INTO v_city_code
  FROM public.city_definitions cd
  WHERE lower(cd.display_name) = v_name
     OR lower(cd.display_name) LIKE ('%' || v_name || '%')
     OR v_name LIKE ('%' || lower(cd.display_name) || '%')
  ORDER BY length(cd.display_name) ASC
  LIMIT 1;
  IF v_city_code IS NOT NULL THEN
    RETURN v_city_code;
  END IF;

  -- 3) Match against a locality display_name; return its parent city_code
  SELECT gl.city_code INTO v_city_code
  FROM public.geo_localities_v1 gl
  WHERE lower(gl.display_name) = v_name
     OR lower(gl.locality_code) = v_name
  ORDER BY gl.is_neighborhood ASC
  LIMIT 1;
  RETURN v_city_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_lookup_city_code_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_lookup_city_code_v1(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_lookup_city_code_v1(TEXT) TO service_role;

COMMENT ON FUNCTION public.geo_lookup_city_code_v1(TEXT) IS 'Lookup helper: resolve a place name to city_code (v1).';

CREATE OR REPLACE FUNCTION public.geo_lookup_locality_code_v1(
  p_city_code TEXT,
  p_locality_name TEXT
)
RETURNS TEXT AS $$
DECLARE
  v_city TEXT := lower(trim(coalesce(p_city_code, '')));
  v_name TEXT := lower(trim(coalesce(p_locality_name, '')));
  v_code TEXT;
BEGIN
  IF v_city = '' OR v_name = '' THEN
    RETURN NULL;
  END IF;

  SELECT gl.locality_code INTO v_code
  FROM public.geo_localities_v1 gl
  WHERE gl.city_code = p_city_code
    AND (lower(gl.display_name) = v_name OR lower(gl.locality_code) = v_name)
  ORDER BY gl.is_neighborhood DESC, length(gl.display_name) DESC
  LIMIT 1;

  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_lookup_locality_code_v1(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_lookup_locality_code_v1(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_lookup_locality_code_v1(TEXT, TEXT) TO service_role;

COMMENT ON FUNCTION public.geo_lookup_locality_code_v1(TEXT, TEXT) IS 'Lookup helper: resolve locality name to locality_code within a city_code (v1).';

