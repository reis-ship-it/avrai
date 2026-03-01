-- Migration: Dual city tracking fields for area evolution (v1)
-- Created: 2026-01-02
-- Purpose:
-- - Add reported vs inferred city tracking to area-cluster memberships (persistent per-city views)
-- - Add reported vs inferred city tracking to device update stream (best-effort enrichment)
--
-- Notes:
-- - Existing `city_code` columns remain for backward compatibility.
-- - New `primary_city_code` is a generated column to simplify query scoping:
--   primary_city_code = COALESCE(inferred_city_code, reported_city_code, city_code)

-- 1) Device update stream enrichment (locality agent updates)
ALTER TABLE public.locality_agent_updates_v1
  ADD COLUMN IF NOT EXISTS reported_city_code TEXT,
  ADD COLUMN IF NOT EXISTS inferred_city_code TEXT;

-- Backfill best-effort for existing rows (treat legacy city_code as reported).
UPDATE public.locality_agent_updates_v1
SET reported_city_code = COALESCE(reported_city_code, city_code)
WHERE reported_city_code IS NULL
  AND city_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_locality_agent_updates_v1_reported_city_created_at
  ON public.locality_agent_updates_v1(reported_city_code, created_at DESC);

-- 2) Area cluster memberships dual city tracking
ALTER TABLE public.geo_area_cluster_memberships_v1
  ADD COLUMN IF NOT EXISTS reported_city_code TEXT,
  ADD COLUMN IF NOT EXISTS inferred_city_code TEXT;

-- Generated “primary city” projection for stable per-city slicing.
ALTER TABLE public.geo_area_cluster_memberships_v1
  ADD COLUMN IF NOT EXISTS primary_city_code TEXT
  GENERATED ALWAYS AS (COALESCE(inferred_city_code, reported_city_code, city_code)) STORED;

-- Backfill best-effort for existing rows (treat legacy city_code as reported).
UPDATE public.geo_area_cluster_memberships_v1
SET reported_city_code = COALESCE(reported_city_code, city_code)
WHERE reported_city_code IS NULL
  AND city_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_memberships_v1_primary_city_precision_area
  ON public.geo_area_cluster_memberships_v1(primary_city_code, geohash_precision, area_id);

COMMENT ON COLUMN public.geo_area_cluster_memberships_v1.reported_city_code IS
  'City code as reported by device/source buckets (may be mis-scoped).';
COMMENT ON COLUMN public.geo_area_cluster_memberships_v1.inferred_city_code IS
  'Best-effort city code inferred from geo hierarchy lookup.';
COMMENT ON COLUMN public.geo_area_cluster_memberships_v1.primary_city_code IS
  'Computed city scope: COALESCE(inferred_city_code, reported_city_code, city_code).';

