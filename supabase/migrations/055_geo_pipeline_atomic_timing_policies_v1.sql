-- Migration: Seed atomic timing policies for geo pipeline (v1)
-- Created: 2026-01-01

-- Boundary learning / pack pipeline defaults.
-- These are intentionally conservative and can be adjusted by learning systems later.

INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'geo_boundary_aggregate_v1',
  jsonb_build_object(
    'enabled', true,
    'days_back', 30,
    'min_total_votes', 50,
    'threshold', 0.60
  )
)
ON CONFLICT (policy_key) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW();

INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'geo_vibe_aggregate_v1',
  jsonb_build_object(
    'enabled', true,
    'days_back', 30,
    'max_rows', 5000
  )
)
ON CONFLICT (policy_key) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW();

INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'geo_knot_build_v1',
  jsonb_build_object(
    'enabled', true,
    'mode', 'placeholder_v1'
  )
)
ON CONFLICT (policy_key) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW();

INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'geo_synco_summaries_build_v1',
  jsonb_build_object(
    'enabled', true,
    'audience', 'general_synco',
    'min_sample_count', 50,
    'mode', 'deterministic_v1'
  )
)
ON CONFLICT (policy_key) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW();

INSERT INTO public.atomic_timing_policies_v1(policy_key, payload)
VALUES (
  'geo_city_pack_build_v1',
  jsonb_build_object(
    'enabled', true,
    'include_vibes', true,
    'include_knots', true,
    'include_summaries', true,
    'simplify_tolerance', 0.01
  )
)
ON CONFLICT (policy_key) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW();

