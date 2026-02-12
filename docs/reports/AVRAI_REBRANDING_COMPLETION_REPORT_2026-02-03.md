# AVRAI Rebranding Completion Report

**Date:** February 3, 2026  
**Scope:** Removal of SPOTS app-name references from the avrai codebase (lib/)  
**Context:** iOS TestFlight investor demo preparation

---

## Executive Summary

All references to "SPOTS" as the app/platform name were removed from the `lib/` directory and replaced with "avrai" or "AVRAI". The work encompassed legal text, UI copy, map themes, environment flags, doc comments, and crypto identifiers. Domain terms like "spots" (places/locations) and related code symbols (e.g., `SpotsBloc`, `searchSpots`) were intentionally left unchanged.

---

## Changes by Category

### 1. Legal Text

| File | Change |
|------|--------|
| `lib/core/legal/event_waiver.dart` | All waiver text: "Release SPOTS" → "Release avrai", "SPOTS is a platform" → "avrai is a platform", etc. (6 instances) |

### 2. Map Theme Branding

| File | Change |
|------|--------|
| `lib/core/theme/map_themes.dart` | Theme constant `spotsBlue` → `avraiBlue`, display name `'SPOTS Blue'` → `'avrai Blue'` |
| `lib/core/theme/map_theme_manager.dart` | Default theme string and fallback updated to `avrai Blue` |
| `lib/presentation/widgets/map/map_view.dart` | Default theme reference updated to `MapThemes.avraiBlue` |

### 3. Environment Flags

| File | Old | New |
|------|-----|-----|
| `lib/presentation/pages/onboarding/ai_loading_page.dart` | `SPOTS_INTEGRATION_TEST` | `AVRAI_INTEGRATION_TEST` |
| `lib/core/services/ledgers/ledger_audit_v0.dart` | `SPOTS_LEDGER_AUDIT` | `AVRAI_LEDGER_AUDIT` |
| `lib/core/services/ledgers/ledger_audit_v0.dart` | `SPOTS_LEDGER_AUDIT_CORRELATION_ID` | `AVRAI_LEDGER_AUDIT_CORRELATION_ID` |

### 4. Crypto Identifier

| File | Change |
|------|--------|
| `lib/core/crypto/key_exchange.dart` | HKDF info string `'SPOTS-EncryptionKey'` → `'AVRAI-EncryptionKey'` |

**Note:** Existing data encrypted with the old info string may require a migration path if backward compatibility is needed.

### 5. User-Facing and High-Visibility Doc/Strings

| File | Change |
|------|--------|
| `lib/presentation/pages/onboarding/welcome_page.dart` | "SPOTS minimalist aesthetic" → "avrai minimalist aesthetic" |
| `lib/presentation/pages/social/friend_discovery_page.dart` | "friends who use SPOTS" → "friends who use avrai" |
| `lib/presentation/pages/business/business_attraction_profile_page.dart` | "12 SPOTS dimensions" → "12 avrai dimensions" |
| `lib/presentation/pages/group/group_formation_page.dart` | "nearby SPOTS users" → "nearby avrai users" |
| `lib/presentation/pages/settings/cross_app_settings_page.dart` | "SPOTS privacy philosophy" → "avrai privacy philosophy" |
| `lib/presentation/pages/supabase_test_page.dart` | "SPOTS Account controls" → "avrai Account controls" |
| `lib/presentation/widgets/reservations/pricing_display_widget.dart` | "SPOTS fee display" → "avrai fee display" |

### 6. Payment, Tax, and Legal Compliance

| File | Change |
|------|--------|
| `lib/core/services/irs_filing_service.dart` | "Payer TIN (SPOTS EIN)" → "avrai EIN" |
| `lib/core/services/payment_service.dart` | "10% to SPOTS" → "10% to avrai" |
| `lib/core/services/tax_compliance_service.dart` | "SPOTS MUST report" / "SPOTS must report" → "avrai" (4 instances) |
| `lib/core/models/product_tracking.dart` | "Platform fee (SPOTS 10%)" → "avrai 10%" |
| `lib/core/models/revenue_split.dart` | "10% to SPOTS" → "10% to avrai" (2 instances) |

### 7. Core Services (Doc Comments)

| Area | Files Updated |
|------|---------------|
| Discovery / Social | `social_media_discovery_service.dart`, `usage_pattern_tracker.dart`, `cross_app_consent_service.dart`, `location_obfuscation_service.dart`, `media_tracking_service.dart`, `geographic_scope_service.dart`, `calendar_tracking_service.dart`, `app_usage_service.dart`, `health_learning_adapter.dart` |
| Onboarding / Dimensions | `onboarding_dimension_mapper.dart`, `onboarding_question_bank.dart`, `onboarding_dimension_computer.dart`, `locality_agent_models_v1.dart` |
| Compatibility / Matching | `vibe_compatibility_service.dart`, `partnership_service.dart`, `multi_path_expertise_service.dart` |
| Behavior | `behavior_assessment_service.dart` |
| AI2AI | `battery_adaptive_ble_scheduler.dart` |
| Data Sources | `openstreetmap_datasource_impl.dart`, `google_places_datasource_new_impl.dart` |

### 8. AI / ML / Quantum

| File | Change |
|------|--------|
| `lib/core/ai/ai_master_orchestrator.dart` | "Master AI Orchestrator for SPOTS" → "avrai" |
| `lib/core/ai/continuous_learning_system.dart` | "Continuous AI Learning System for SPOTS" → "avrai" |
| `lib/core/ai/collaboration_networks.dart` | "SPOTS discovery platform" → "avrai" |
| `lib/core/ai/advanced_communication.dart` | "SPOTS discovery platform" → "avrai" |
| `lib/core/ai/list_generator_service.dart` | "for SPOTS" → "for avrai" |
| `lib/core/ai/perpetual_list/utils/category_taxonomy.dart` | "SPOTS category" → "avrai category" (8 instances) |
| `lib/core/ai/quantum/quantum_ml_optimizer.dart` | "12 SPOTS dimensions" → "12 avrai dimensions" |
| `lib/core/ai/quantum/quantum_entanglement_ml_service.dart` | "SPOTS dimensions" → "avrai dimensions" (2 instances) |
| `lib/core/ml/inference_orchestrator.dart` | System prompt: "assistant for SPOTS" → "assistant for avrai" |
| `lib/core/ml/feedback_processor.dart` | "Your feedback shapes SPOTS" → "avrai" |
| `lib/core/ml/social_context_analyzer.dart` | "SPOTS is about bringing people together" → "avrai" |
| `lib/core/ml/preference_learning.dart` | "Your feedback shapes SPOTS" → "avrai" |
| `lib/core/ml/predictive_analytics.dart` | "SPOTS discovery platform" → "avrai" |
| `lib/core/ml/pattern_recognition.dart` | "SPOTS discovery platform" → "avrai" |

### 9. Cloud / Deployment

| File | Change |
|------|--------|
| `lib/core/cloud/production_readiness_manager.dart` | "SPOTS platform" → "avrai platform" |
| `lib/core/cloud/microservices_manager.dart` | "SPOTS deployment" / "core SPOTS services" → "avrai" |
| `lib/core/cloud/realtime_sync_manager.dart` | "SPOTS cloud infrastructure" → "avrai" |
| `lib/core/cloud/edge_computing_manager.dart` | "SPOTS processing" → "avrai processing" |
| `lib/core/deployment/production_manager.dart` | "SPOTS platform" (2 instances) → "avrai" |

### 10. Models

| File | Change |
|------|--------|
| `lib/core/models/unified_models.dart` | "Unified Models for SPOTS" → "avrai" |
| `lib/core/models/reservation.dart` | "event in SPOTS" → "avrai" |
| `lib/core/models/usage_pattern.dart` | "engage with SPOTS" (2 instances) → "avrai" |
| `lib/core/models/unified_user.dart` | "SPOTS community" → "avrai community" |
| `lib/core/models/user_role.dart` | "SPOTS community" → "avrai community" |
| `lib/core/models/locality.dart` | "bread and butter of SPOTS" → "avrai" |
| `lib/core/models/multi_path_expertise.dart` | "SPOTS platform influence" → "avrai" |

### 11. Injection / Orchestration

| File | Change |
|------|--------|
| `lib/injection_container_ai.dart` | "SPOTS ecosystem" → "avrai ecosystem" |

---

## Intentionally Unchanged

- **Domain terms:** `SpotsBloc`, `searchSpots`, `matchedSpots`, `softBorderSpots`, `candidateSpots`, "Find Spots", "Load Spots", and similar refer to places/locations, not the app name.
- **Outside lib/:** docs, scripts, integration tests, and config (e.g., `demo@spots.com`, `signaling.spots.app`, `api.spots.com`) were out of scope and may be updated in a separate docs/config pass.

---

## Follow-Up Actions

1. **Environment flags:** Scripts that pass `SPOTS_LEDGER_AUDIT` or `SPOTS_LEDGER_AUDIT_CORRELATION_ID` should be updated to `AVRAI_LEDGER_AUDIT` and `AVRAI_LEDGER_AUDIT_CORRELATION_ID`.
2. **Integration tests:** Any tests that define `SPOTS_INTEGRATION_TEST` should use `AVRAI_INTEGRATION_TEST`.
3. **Encryption migration:** If data was encrypted with `SPOTS-EncryptionKey`, consider supporting both info strings during a transition period.

---

## Verification

- **Grep:** `\bSPOTS\b` in `lib/` returns no matches.
- **Linter:** No linter errors in `lib/` after these changes.
