-- Migration: Fix Security Definer Views and RLS Issues
-- Created: 2026-01-29
-- Purpose:
-- - Convert all public views from SECURITY DEFINER to SECURITY INVOKER
--   so that RLS policies of the querying user apply, not the view creator
-- - Enable RLS on spatial_ref_sys or move it to non-public schema
--
-- Addresses Supabase linter warnings:
-- - 0010_security_definer_view (26 views)
-- - 0013_rls_disabled_in_public (spatial_ref_sys)
--
-- Reference: https://supabase.com/docs/guides/database/database-linter

-- ============================================================================
-- SECTION 1: Fix Ledger Views (SECURITY INVOKER)
-- ============================================================================
-- These views should respect the RLS policies of the underlying ledger_events_v0
-- table based on the querying user's permissions.

-- ledger_current_v0
ALTER VIEW public.ledger_current_v0 SET (security_invoker = on);
-- ledger_expertise_events_v0
ALTER VIEW public.ledger_expertise_events_v0 SET (security_invoker = on);
-- ledger_expertise_current_v0
ALTER VIEW public.ledger_expertise_current_v0 SET (security_invoker = on);
-- ledger_payments_events_v0
ALTER VIEW public.ledger_payments_events_v0 SET (security_invoker = on);
-- ledger_payments_current_v0
ALTER VIEW public.ledger_payments_current_v0 SET (security_invoker = on);
-- ledger_moderation_events_v0
ALTER VIEW public.ledger_moderation_events_v0 SET (security_invoker = on);
-- ledger_moderation_current_v0
ALTER VIEW public.ledger_moderation_current_v0 SET (security_invoker = on);
-- ledger_identity_events_v0
ALTER VIEW public.ledger_identity_events_v0 SET (security_invoker = on);
-- ledger_identity_current_v0
ALTER VIEW public.ledger_identity_current_v0 SET (security_invoker = on);
-- ledger_security_events_v0
ALTER VIEW public.ledger_security_events_v0 SET (security_invoker = on);
-- ledger_security_current_v0
ALTER VIEW public.ledger_security_current_v0 SET (security_invoker = on);
-- ledger_geo_expansion_events_v0
ALTER VIEW public.ledger_geo_expansion_events_v0 SET (security_invoker = on);
-- ledger_geo_expansion_current_v0
ALTER VIEW public.ledger_geo_expansion_current_v0 SET (security_invoker = on);
-- ledger_model_lifecycle_events_v0
ALTER VIEW public.ledger_model_lifecycle_events_v0 SET (security_invoker = on);
-- ledger_model_lifecycle_current_v0
ALTER VIEW public.ledger_model_lifecycle_current_v0 SET (security_invoker = on);
-- ledger_data_export_events_v0
ALTER VIEW public.ledger_data_export_events_v0 SET (security_invoker = on);
-- ledger_data_export_current_v0
ALTER VIEW public.ledger_data_export_current_v0 SET (security_invoker = on);
-- ledger_device_capability_events_v0
ALTER VIEW public.ledger_device_capability_events_v0 SET (security_invoker = on);
-- ledger_device_capability_current_v0
ALTER VIEW public.ledger_device_capability_current_v0 SET (security_invoker = on);
-- ledger_receipts_v0
ALTER VIEW public.ledger_receipts_v0 SET (security_invoker = on);
-- ============================================================================
-- SECTION 2: Fix Outside Buyer Ops Views (SECURITY INVOKER)
-- ============================================================================
-- These views are admin/ops dashboards. Setting security_invoker ensures
-- only users with appropriate access can query them.

-- outside_buyer_cron_jobs_v1
ALTER VIEW public.outside_buyer_cron_jobs_v1 SET (security_invoker = on);
-- outside_buyer_cache_run_freshness_v1
ALTER VIEW public.outside_buyer_cache_run_freshness_v1 SET (security_invoker = on);
-- outside_buyer_city_code_coverage_v1
ALTER VIEW public.outside_buyer_city_code_coverage_v1 SET (security_invoker = on);
-- outside_buyer_privacy_budget_usage_v1
ALTER VIEW public.outside_buyer_privacy_budget_usage_v1 SET (security_invoker = on);
-- outside_buyer_export_request_stats_v1
ALTER VIEW public.outside_buyer_export_request_stats_v1 SET (security_invoker = on);
-- outside_buyer_query_fingerprint_stats_v1
ALTER VIEW public.outside_buyer_query_fingerprint_stats_v1 SET (security_invoker = on);
-- ============================================================================
-- SECTION 3: spatial_ref_sys (PostGIS system table)
-- ============================================================================
-- NOTE: spatial_ref_sys is owned by the postgres superuser and cannot be modified
-- via migrations. This table contains PostGIS coordinate reference system 
-- definitions - it's not sensitive user data.
--
-- To fix the RLS warning, you need to run the following SQL in the Supabase 
-- Dashboard SQL Editor (which runs as superuser):
--
-- ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY spatial_ref_sys_select_all ON public.spatial_ref_sys FOR SELECT USING (true);
-- CREATE POLICY spatial_ref_sys_service_role_all ON public.spatial_ref_sys FOR ALL TO service_role USING (true);
--
-- Alternatively, this is a low-risk issue since spatial_ref_sys only contains
-- public coordinate system definitions (EPSG codes, WKT strings, etc.)

-- ============================================================================
-- SECTION 4: Verification comments
-- ============================================================================

COMMENT ON VIEW public.ledger_current_v0 IS
  'v0 ledger current view (latest revision per logical_id). SECURITY INVOKER enabled.';
COMMENT ON VIEW public.outside_buyer_cron_jobs_v1 IS
  'Ops view: pg_cron job status. SECURITY INVOKER enabled.';
COMMENT ON VIEW public.outside_buyer_cache_run_freshness_v1 IS
  'Ops view: cache run freshness. SECURITY INVOKER enabled.';
COMMENT ON VIEW public.outside_buyer_city_code_coverage_v1 IS
  'Ops view: city_code coverage. SECURITY INVOKER enabled.';
