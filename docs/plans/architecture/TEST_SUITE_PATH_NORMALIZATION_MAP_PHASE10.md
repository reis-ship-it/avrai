# Test Suite Path Normalization Map (Phase 10)

**Date:** February 13, 2026  
**Status:** Active prep artifact (no implementation changes)  
**Master Plan Mapping:** Phase 10 (`10.9`)  
**Backlog Mapping:** `MPA-P10-E1-S3`, `MPA-P10-E2-S3`, `MPA-P10-E3-S2`  
**Tracker Mapping:** `docs/MASTER_PLAN_TRACKER.md` Phase-Specific Plans (Phase 10 hardening)

---

## Purpose

This is the canonical mapping of grouped test-suite script paths from stale flat integration paths to current domain-organized integration paths.

Use this map before editing `test/suites/*_suite.sh` so grouped suite runs align with architecture phase gates and do not silently skip tests.

---

## Normalization Rules

1. `test/integration/<name>.dart` was reorganized to `test/integration/<domain>/<name>.dart`.
2. Domain folder must match architectural ownership where possible:
   - AI/ML -> `test/integration/ai/`
   - Business/brand/products -> `test/integration/brand/`, `test/integration/services/`, `test/integration/products/`
   - Events -> `test/integration/events/`
   - Expertise -> `test/integration/expertise/`
   - Infrastructure/connectivity/sync -> `test/integration/infrastructure/`
   - Onboarding -> `test/integration/onboarding/`
   - Partnerships -> `test/integration/partnerships/`
   - Payments/tax/disputes -> `test/integration/payments/`
   - Security -> `test/integration/security/`
   - Geographic -> `test/integration/geographic/`
3. Design regression coverage must be grouped explicitly via `test/widget/design/`.

---

## Path Mapping Table

| Suite | Old Path (stale) | New Path (canonical) |
|---|---|---|
| auth | `test/integration/admin_auth_integration_test.dart` | `test/integration/security/admin_auth_integration_test.dart` |
| ai_ml | `test/integration/ai2ai_complete_integration_test.dart` | `test/integration/ai/ai2ai_complete_integration_test.dart` |
| ai_ml | `test/integration/ai2ai_ecosystem_test.dart` | `test/integration/ai/ai2ai_ecosystem_test.dart` |
| ai_ml | `test/integration/ai2ai_learning_methods_integration_test.dart` | `test/integration/ai/ai2ai_learning_methods_integration_test.dart` |
| ai_ml | `test/integration/continuous_learning_integration_test.dart` | `test/integration/ai/continuous_learning_integration_test.dart` |
| ai_ml | `test/integration/ai_improvement_tracking_integration_test.dart` | `test/integration/ai/ai_improvement_tracking_integration_test.dart` |
| ai_ml | `test/integration/ui_llm_integration_test.dart` | `test/integration/ai/ui_llm_integration_test.dart` |
| business | `test/integration/business_flow_integration_test.dart` | `test/integration/services/business_flow_integration_test.dart` |
| business | `test/integration/business_expert_vibe_matching_integration_test.dart` | `test/integration/services/business_expert_vibe_matching_integration_test.dart` |
| business | `test/integration/product_tracking_services_integration_test.dart` | `test/integration/products/product_tracking_services_integration_test.dart` |
| business | `test/integration/product_tracking_flow_integration_test.dart` | `test/integration/products/product_tracking_flow_integration_test.dart` |
| business | `test/integration/brand_analytics_integration_test.dart` | `test/integration/brand/brand_analytics_integration_test.dart` |
| business | `test/integration/brand_discovery_services_integration_test.dart` | `test/integration/brand/brand_discovery_services_integration_test.dart` |
| business | `test/integration/brand_discovery_flow_integration_test.dart` | `test/integration/brand/brand_discovery_flow_integration_test.dart` |
| events | `test/integration/event_discovery_integration_test.dart` | `test/integration/events/event_discovery_integration_test.dart` |
| events | `test/integration/event_hosting_integration_test.dart` | `test/integration/events/event_hosting_integration_test.dart` |
| events | `test/integration/event_matching_integration_test.dart` | `test/integration/events/event_matching_integration_test.dart` |
| events | `test/integration/event_recommendation_integration_test.dart` | `test/integration/events/event_recommendation_integration_test.dart` |
| events | `test/integration/event_template_integration_test.dart` | `test/integration/events/event_template_integration_test.dart` |
| expertise | `test/integration/expertise_flow_integration_test.dart` | `test/integration/expertise/expertise_flow_integration_test.dart` |
| expertise | `test/integration/expertise_services_integration_test.dart` | `test/integration/expertise/expertise_services_integration_test.dart` |
| expertise | `test/integration/expertise_event_integration_test.dart` | `test/integration/expertise/expertise_event_integration_test.dart` |
| expertise | `test/integration/expansion_expertise_gain_integration_test.dart` | `test/integration/expertise/expansion_expertise_gain_integration_test.dart` |
| expertise | `test/integration/expertise_partnership_integration_test.dart` | `test/integration/expertise/expertise_partnership_integration_test.dart` |
| geographic | `test/integration/locality_value_integration_test.dart` | `test/integration/geographic/locality_value_integration_test.dart` |
| geographic | `test/integration/connectivity_integration_test.dart` | `test/integration/infrastructure/connectivity_integration_test.dart` |
| infrastructure | `test/integration/cloud_infrastructure_integration_test.dart` | `test/integration/infrastructure/cloud_infrastructure_integration_test.dart` |
| infrastructure | `test/integration/connectivity_integration_test.dart` | `test/integration/infrastructure/connectivity_integration_test.dart` |
| infrastructure | `test/integration/supabase_service_integration_test.dart` | `test/integration/infrastructure/supabase_service_integration_test.dart` |
| onboarding | `test/integration/onboarding_flow_integration_test.dart` | `test/integration/onboarding/onboarding_flow_integration_test.dart` |
| partnerships | `test/integration/partnership_flow_integration_test.dart` | `test/integration/partnerships/partnership_flow_integration_test.dart` |
| partnerships | `test/integration/partnership_profile_flow_integration_test.dart` | `test/integration/partnerships/partnership_profile_flow_integration_test.dart` |
| partnerships | `test/integration/profile_partnership_display_integration_test.dart` | `test/integration/partnerships/profile_partnership_display_integration_test.dart` |
| partnerships | `test/integration/brand_sponsorship_flow_integration_test.dart` | `test/integration/brand/brand_sponsorship_flow_integration_test.dart` |
| payment | `test/integration/payment_flow_integration_test.dart` | `test/integration/payments/payment_flow_integration_test.dart` |
| payment | `test/integration/stripe_payment_integration_test.dart` | `test/integration/payments/stripe_payment_integration_test.dart` |
| payment | `test/integration/tax_compliance_flow_integration_test.dart` | `test/integration/payments/tax_compliance_flow_integration_test.dart` |
| payment | `test/integration/revenue_split_services_integration_test.dart` | `test/integration/payments/revenue_split_services_integration_test.dart` |
| payment | `test/integration/dispute_resolution_integration_test.dart` | `test/integration/payments/dispute_resolution_integration_test.dart` |
| search | `test/integration/hybrid_search_performance_test.dart` | `test/integration/services/hybrid_search_performance_test.dart` |
| security | `test/integration/security_integration_test.dart` | `test/integration/security/security_integration_test.dart` |
| spots_lists | `test/integration/offline_online_sync_test.dart` | `test/integration/infrastructure/offline_online_sync_test.dart` |

---

## Design Grouping Requirement (Phase 10.9)

Grouped test-suite planning must explicitly include:

- `test/widget/design/design_playground_golden_test.dart`
- `test/widget/design/goldens/`
- `tool/design_guardrails.dart` as an always-on architectural gate

This closes the current gap where grouped suites omit design goldens.

---

## Acceptance Gate for Path Normalization

This prep artifact is considered complete when:

1. Every stale path in `test/suites/*_suite.sh` has a mapped canonical replacement in this file.
2. A path verification check reports `0 missing references`.
3. Architecture checklist Phase 10 exit gates for grouped testing are checked.
4. Tracker phase-specific references to this map are present.
