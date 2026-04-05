# AVRAI Rebranding Phase 2 Completion Report

**Date:** February 3, 2026  
**Scope:** Infra/config, automated tests, scripts, developer documentation, and protocol updates required to finish the SPOTS → avrai rebrand.

---

## Executive Summary

- All remaining runtime references to `spots.com`, `spots.app`, and `com.spots.app` that affect configuration, signaling, or automation now point to their `avrai` equivalents.
- Integration/unit tests no longer refer to "SPOTS" in user-facing expectations and no longer write to user-specific log paths.
- Developer tooling (scripts, Cursor skills) now point to the avrai bundle ID and MethodChannel names, eliminating onboarding confusion.
- Investor/demo protocol docs reflect the "Ask avrai" wording so messaging matches the app.
- A handful of tests still fail because of pre-existing `path_provider` plugin constraints; these failures were verified as unchanged and documented under Known Issues.

---

## Changes by Track

### 1. Infra & Config
| File | Update |
|------|--------|
| `packages/avrai_core/lib/utils/constants.dart` | `https://api.spots.com` → `https://api.avrai.app` |
| `packages/avrai_network/lib/network/webrtc_signaling_config.dart` | Default signaling server → `wss://signaling.avrai.app` |
| `ios/SignalNative*.podspec` | Homepage & author metadata moved from `spots.app` / `dev@spots.app` to `avrai.app` / `dev@avrai.app` |

### 2. Packages / Lib Minor Fixes
| File | Update |
|------|--------|
| `lib/firebase_options.dart` | Comment updated to “avrai app” |
| `packages/avrai_knot` (audio services/models) | “12 SPOTS personality dimensions” → “12 avrai personality dimensions” |

### 3. Automated Tests
- **Integration tests**: `demo@spots.com` → `demo@avrai.app`, app titles now `AvraiApp`, onboarding/basic integration text aligned with new UI copy.
- **Hardcoded paths**: All `/Users/reisgordon/SPOTS/.cursor/debug.log` references replaced with `/tmp/avrai_debug.log` or `Directory.systemTemp.createTemp(...)`.
- **QR / device discovery**: Tests now expect `AVRAI:FRIEND:CONNECT` prefixes and “avrai-enabled devices”.
- **Doc headers**: Bulk replacement of `/// SPOTS ...` → `/// avrai ...` across unit, widget, integration, and QA templates.
- **QA scripts/templates** (documentation standards, automated quality checker, deployment validator, etc.) now say “avrai test suite”.

### 4. Scripts & Tooling
| File | Update |
|------|--------|
| `scripts/proof_run/run_proof_run_bundle.sh` | Default `APP_BUNDLE_ID` → `com.avrai.app` |
| `scripts/emulator_manager.sh` | ADB stop/clear uses `com.avrai.app` |
| `scripts/proof_run/README.md` | All instructions updated to `com.avrai.app` |
| `.cursor/skills/*integration-patterns*` | MethodChannel strings now `com.avrai.app/...` |

### 5. Protocol Docs
| File | Update |
|------|--------|
| `docs/agents/protocols/INVESTOR_DEMO_CHECKLIST.md` | “Ask SPOTS” → “Ask avrai” throughout |
| `docs/agents/protocols/RELEASE_GATE_CHECKLIST_CORE_APP_V1.md` | App references + “Ask SPOTS” gates updated to “avrai” |

---

## Verification

1. `flutter analyze lib/ packages/avrai_core/ packages/avrai_network/ packages/avrai_knot/` → no new errors (pre-existing warnings remain).
2. `flutter test test/core/services/friend_qr_service_test.dart` → **PASS** confirming the new `AVRAI:FRIEND:CONNECT` prefix.
3. `grep -R "SPOTS" lib/` → no app-name matches (only domain terms such as `SpotsBloc` remain).

---

## Known Issues / Follow-ups

| Area | Details | Owner |
|------|---------|-------|
| `path_provider` in tests | `test/integration/basic_integration_test.dart` and `test/unit/services/local_llm_post_install_bootstrap_service_test.dart` still emit `MissingPluginException` because `GetStorage` requires `path_provider` in VM mode. Pre-existing issue, unchanged by rebranding. | Platform/Test infra |
| Firebase project IDs | `spots-app-adea5` still used for Firebase project ID/storage bucket. Changing requires creating a new Firebase project and migrating configs (out of scope for this pass). | Infra |
| Docs backlog | Several long-form docs (`docs/plans/**`, `test/testing/**`, compliance PDFs) still reference `spots.com/spots.app`. Plan Phase 7 queues a dedicated docs sweep. | Documentation |

---

## Outstanding Risks

- **Script consumers:** Any external automation referencing `SPOTS_LEDGER_AUDIT` or old MethodChannel names must be updated to the new env vars / channels.
- **Encryption migration:** Systems that decrypted data using `SPOTS-EncryptionKey` must either re-encrypt or support both info strings during transition.
- **Signal podspec metadata:** CocoaPods caches may require `pod repo update` to pick up the new homepage/author metadata.

---

## Next Steps

1. Schedule the Phase 7 documentation sweep to remove `spots.app` references from archived plans and testing guides.
2. Coordinate with infra to migrate Firebase project naming when new `avrai` backends are ready.
3. Add path-provider shims/fakes for VM tests so the integration/unit suites can run cleanly without plugins.
