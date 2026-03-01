-- Migration: Fix Function Search Path Security Warnings
-- Created: 2026-01-29
-- Purpose:
-- - Set search_path = public for all functions to prevent search path injection attacks
-- - This addresses Supabase linter warning 0011_function_search_path_mutable
--
-- Reference: https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable

-- ============================================================================
-- SECTION 1: Aggregate Functions
-- ============================================================================

ALTER FUNCTION public.aggregate_ai2ai_insights(p_segment_id text)
  SET search_path = public;

ALTER FUNCTION public.aggregate_personality_profiles(p_segment_id text)
  SET search_path = public;

ALTER FUNCTION public.aggregate_real_world_behavior(p_segment_id text)
  SET search_path = public;

-- ============================================================================
-- SECTION 2: API & Auth Functions
-- ============================================================================

ALTER FUNCTION public.api_key_rate_limit_check_v1(p_key_hash text, p_limit_per_min integer)
  SET search_path = public;

ALTER FUNCTION public.generate_api_key(p_partner_id text, p_rate_limit_per_minute integer, p_rate_limit_per_day integer, p_expires_at timestamp with time zone)
  SET search_path = public;

ALTER FUNCTION public.handle_new_user()
  SET search_path = public;

-- ============================================================================
-- SECTION 3: Atomic Timing Functions
-- ============================================================================

ALTER FUNCTION public.atomic_timing_get_policy_v1(p_policy_key text)
  SET search_path = public;

ALTER FUNCTION public.get_server_time()
  SET search_path = public;

-- ============================================================================
-- SECTION 4: Geo Functions
-- ============================================================================

ALTER FUNCTION public.geo_boundary_aggregate_v1(p_city_code text, p_locality_code text, p_days_back integer)
  SET search_path = public;

ALTER FUNCTION public.geo_get_city_pack_manifest_v1(p_city_code text)
  SET search_path = public;

ALTER FUNCTION public.geo_get_locality_shape_geojson_v1(p_locality_code text, p_simplify_tolerance double precision)
  SET search_path = public;

ALTER FUNCTION public.geo_list_cities_v1()
  SET search_path = public;

ALTER FUNCTION public.geo_list_city_geohash3_bounds_v1(p_city_code text, p_limit integer)
  SET search_path = public;

ALTER FUNCTION public.geo_list_city_localities_v1(p_city_code text)
  SET search_path = public;

ALTER FUNCTION public.geo_lookup_city_code_v1(p_place_name text)
  SET search_path = public;

ALTER FUNCTION public.geo_lookup_locality_code_v1(p_city_code text, p_locality_name text)
  SET search_path = public;

ALTER FUNCTION public.geo_rebuild_locality_shape_from_boundary_field_v1(p_city_code text, p_locality_code text, p_geohash_precision integer, p_threshold double precision, p_source text)
  SET search_path = public;

ALTER FUNCTION public.populate_city_geohash3_map_circle(p_city_code text, p_center_lat double precision, p_center_lon double precision, p_radius_km double precision, p_step_km double precision)
  SET search_path = public;

ALTER FUNCTION public.populate_city_geohash3_map_from_definitions()
  SET search_path = public;

ALTER FUNCTION public.populate_geo_locality_shapes_v1(p_locality_code text)
  SET search_path = public;

ALTER FUNCTION public.upsert_city_definition(p_city_code text, p_display_name text, p_center_lat double precision, p_center_lon double precision, p_radius_km double precision, p_step_km double precision)
  SET search_path = public;

ALTER FUNCTION public.upsert_geo_locality_definition_v1(p_locality_code text, p_center_lat double precision, p_center_lon double precision, p_radius_km double precision, p_source text)
  SET search_path = public;

-- ============================================================================
-- SECTION 5: Outside Buyer Functions
-- ============================================================================

ALTER FUNCTION public.outside_buyer_budget_window_start(p_now timestamp with time zone, p_budget_window_days integer)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_consume_privacy_budget(p_api_key_id uuid, p_epsilon_cost double precision, p_budget_window_days integer, p_epsilon_budget double precision, p_delta double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_get_spots_insights_v1(p_api_key_id uuid, p_time_bucket_start_utc timestamp with time zone, p_time_bucket_end_utc timestamp with time zone, p_time_granularity text, p_reporting_delay_hours integer, p_geo_bucket_type text, p_geo_bucket_ids text[], p_door_types text[], p_categories text[], p_contexts text[], p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

-- Two overloads of outside_buyer_get_spots_insights_v1_cached
ALTER FUNCTION public.outside_buyer_get_spots_insights_v1_cached(p_api_key_id uuid, p_time_bucket_start_utc timestamp with time zone, p_time_bucket_end_utc timestamp with time zone, p_reporting_delay_hours integer, p_geo_bucket_type text, p_geo_bucket_ids text[], p_door_types text[], p_categories text[], p_contexts text[], p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_get_spots_insights_v1_cached(p_api_key_id uuid, p_time_bucket_start_utc timestamp with time zone, p_time_bucket_end_utc timestamp with time zone, p_time_granularity text, p_reporting_delay_hours integer, p_geo_bucket_type text, p_geo_bucket_ids text[], p_door_types text[], p_categories text[], p_contexts text[], p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_maybe_alert_budget(p_api_key_id uuid, p_threshold_fraction double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_maybe_alert_cron_stale(p_jobname text, p_max_age_hours integer)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_precompute_spots_insights_v1_bucket(p_api_key_id uuid, p_bucket_start_utc timestamp with time zone, p_time_granularity text, p_reporting_delay_hours integer, p_geo_bucket_type text, p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_precompute_spots_insights_v1_day(p_api_key_id uuid, p_day_start_utc timestamp with time zone, p_reporting_delay_hours integer, p_geo_bucket_type text, p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_precompute_spots_insights_v1_hour(p_api_key_id uuid, p_hour_start_utc timestamp with time zone, p_reporting_delay_hours integer, p_geo_bucket_type text, p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_precompute_spots_insights_v1_week(p_api_key_id uuid, p_week_start_utc timestamp with time zone, p_reporting_delay_hours integer, p_geo_bucket_type text, p_k_min integer, p_dominance_max_fraction double precision, p_dp_epsilon double precision, p_dp_delta double precision, p_budget_window_days integer, p_privacy_budget_total_epsilon double precision, p_budget_cost_epsilon double precision)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_record_query_fingerprint(p_api_key_id uuid, p_fingerprint text, p_max_distinct_per_day integer)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_run_scheduled_precompute_v1(p_include_hour boolean, p_include_day boolean, p_include_week boolean, p_max_keys integer, p_day_buckets integer, p_hour_buckets integer, p_week_buckets integer)
  SET search_path = public;

ALTER FUNCTION public.outside_buyer_run_scheduled_precompute_v1_policy()
  SET search_path = public;

-- ============================================================================
-- SECTION 6: Privacy & Differential Privacy Functions
-- ============================================================================

ALTER FUNCTION public.dp_laplace_noise(p_scale double precision)
  SET search_path = public;

ALTER FUNCTION public.get_agent_ids_for_segment(p_segment_definition jsonb)
  SET search_path = public;

-- ============================================================================
-- SECTION 7: Signal Protocol Functions
-- ============================================================================

ALTER FUNCTION public.cleanup_expired_signal_prekey_bundles_v2()
  SET search_path = public;

-- ============================================================================
-- SECTION 8: Trigger Functions (updated_at)
-- ============================================================================

ALTER FUNCTION public.update_admin_credentials_updated_at()
  SET search_path = public;

ALTER FUNCTION public.update_onboarding_aggregations_updated_at()
  SET search_path = public;

ALTER FUNCTION public.update_outside_buyer_privacy_budgets_updated_at()
  SET search_path = public;

ALTER FUNCTION public.update_structured_facts_updated_at()
  SET search_path = public;

ALTER FUNCTION public.update_updated_at_column()
  SET search_path = public;
