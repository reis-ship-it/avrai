# SPOTS Manual Testing Results

| Test Area         | Steps Taken | Expected Result | Actual Result | Pass/Fail | Notes/Screenshots |
|-------------------|-------------|-----------------|--------------|-----------|-------------------|
| Onboarding        | Launched app, completed all steps | User lands on main app, baseline lists created | As expected | Pass |  |
| Spot Creation     | Created spot from Lists tab | Spot appears in Spots tab | As expected | Pass |  |
| Offline Mode      | Disabled network, created spot | Spot saved locally, syncs when online | As expected | Pass |  |
| Homebase Selection | Fixed center marker, thoroughfare extraction | Shows specific street names (6th Ave) instead of boroughs | ✅ PASS | Fixed center marker works, thoroughfare extraction successful | homebase_selection_debug_logs.txt |

*Add more rows as you test. Attach screenshots or detailed notes for any failures or issues.* 

## Automated suite runs (playbook)

| Date | Suite | Command | Result | Notes |
|---|---|---|---|---|
| 2026-01-01 | infrastructure_suite | `bash /Users/reisgordon/SPOTS/test/suites/infrastructure_suite.sh -j 1` | ✅ PASS | Completed in ~9 minutes. Supabase integration tests attempted and logged 400s but tests still passed. |
| 2026-01-01 | auth_suite | `bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh -j 1` | ✅ PASS | Fixed missing Mockito stubs in `test/unit/data/repositories/auth_repository_impl_test.dart`; clarified offline sign-up behavior (remote-only) and updated test accordingly. |
| 2026-01-01 | auth_suite | `bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh -j 1` | ❌ FAIL | Failing widget test: `test/widget/pages/auth/login_page_test.dart` expected error text not found. Working on fix. |
| 2026-01-01 | auth_suite | `bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh -j 1` | ✅ PASS | Fixed login/signup widget tests (listener-driven snackbars + loading UI) and repo unit tests (`AuthRepositoryImpl` offline/online expectations). |
| 2026-01-01 | onboarding_suite | `bash /Users/reisgordon/SPOTS/test/suites/onboarding_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). Stabilized widget/integration tests by skipping side-effectful flows in widget tests (`AILoadingPage`) and making social OAuth placeholders deterministic (no artificial delays; no `FlutterSecureStorage` dependency in tests). |
| 2026-01-01 | security_suite | `bash /Users/reisgordon/SPOTS/test/suites/security_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run. Includes Signal/GDPR/CCPA/security integration coverage; all passed in this run. |
| 2026-01-01 | events_suite | `bash /Users/reisgordon/SPOTS/test/suites/events_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). |
| 2026-01-01 | payment_suite | `bash /Users/reisgordon/SPOTS/test/suites/payment_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). |
| 2026-01-01 | partnership_suite | `bash /Users/reisgordon/SPOTS/test/suites/partnership_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). |
| 2026-01-01 | expertise_suite | `bash /Users/reisgordon/SPOTS/test/suites/expertise_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). |
| 2026-01-01 | business_suite | `bash /Users/reisgordon/SPOTS/test/suites/business_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run (tool output saved). |
| 2026-01-01 | search_suite | `bash /Users/reisgordon/SPOTS/test/suites/search_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run. Note: some repository methods log MissingStubError (handled internally); tests still pass. |
| 2026-01-01 | geographic_suite | `bash /Users/reisgordon/SPOTS/test/suites/geographic_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run. |
| 2026-01-01 | spots_lists_suite | `bash /Users/reisgordon/SPOTS/test/suites/spots_lists_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run. Fixed offline-first unit tests by stubbing local reads (`getLists`) in online cases and aligning expectations for double local writes on update (local-first + sync). |
| 2026-01-01 | ai_ml_suite | `bash /Users/reisgordon/SPOTS/test/suites/ai_ml_suite.sh -j 1 -r expanded` | ✅ PASS | Verified suite run. Stabilized AI/network widget tests (scroll-to-visible taps; GetIt re-registration) and fixed AI2AI integration tests by registering `AgentIdService` in GetIt. |
| 2026-01-01 | all_suites (run 1) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified full suite run (background terminal log). |
| 2026-01-01 | all_suites (run 2) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified back-to-back full suite run (background terminal log). |
| 2026-01-01 | all_suites (run 3) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified after scanWindow/continuous scan + AuthBloc AI2AI orchestration tests. Output saved (agent-tools log). |
| 2026-01-01 | all_suites (run 4) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified back-to-back after latest changes. Output saved (agent-tools log). |
| 2026-01-01 | all_suites (run 5) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified after latest changes (LLM cloud failover + AI2AI UI test stabilization). Output saved: `agent-tools/7a46116c-c1fc-4b1e-9095-790b1eab0d63.txt`. |
| 2026-01-01 | all_suites (run 6) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified back-to-back (exit criterion satisfied). Output saved: `agent-tools/659f8750-7f99-4e39-98af-c8e9ced229ca.txt`. |
| 2026-01-02 | all_suites (run 7) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified after ledger DI registration (`LedgerRecorderServiceV0`). Output saved: `agent-tools/bb16c56e-1242-4cee-9e7a-d1b2cbbb9410.txt`. |
| 2026-01-02 | all_suites (run 8) | `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1 -r expanded` | ✅ PASS | Verified back-to-back after ledger DI change (exit criterion satisfied). Output saved: `agent-tools/7541c322-d167-4942-8ffc-100791a9f236.txt`. |

> Note: Only log ✅ PASS rows after the suite has been run and confirmed green.