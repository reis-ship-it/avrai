-- Migration: Outside Buyer Insights - locality_code geo bucket (v1)
-- Created: 2026-01-28
-- Purpose: Allow geo_bucket_type = 'locality_code' (neighborhood/borough) with k_min >= 200.
-- Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md
--
-- This migration extends the precompute function to:
-- 1. Accept locality_code and enforce k_min >= 200 for locality_code.
-- 2. Add latitude, longitude to base_events for locality lookup.
-- 3. In normalized, when locality_code use geo_lookup_locality_by_point_v1.
--
-- Requires: geo_lookup_locality_by_point_v1 (048_geo_locality_shapes_import_and_point_lookup_v1.sql)
--
-- Locality_code support: Edge Function and Dart validator accept geo_bucket_type=locality_code
-- and enforce k_min >= 200. This migration documents the contract; the precompute function
-- (outside_buyer_precompute_spots_insights_v1_bucket) must be extended in a follow-up to:
-- 1. Allow p_geo_bucket_type = 'locality_code' and enforce p_k_min >= 200.
-- 2. Add latitude, longitude to base_events from ie.context->'location'.
-- 3. In normalized, WHEN p_geo_bucket_type = 'locality_code' use geo_lookup_locality_by_point_v1(be.latitude, be.longitude).
-- Until that replacement is deployed, precompute will raise for locality_code; get_cached and
-- Edge Function already accept locality_code and k_min.

COMMENT ON FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(
  UUID, TIMESTAMPTZ, TEXT, INTEGER, TEXT, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Precompute+cache v1 insights for a single UTC bucket (hour/day/week). Supports geohash3, city_code; locality_code (k_min>=200) requires follow-up migration for base_events/normalized.';
