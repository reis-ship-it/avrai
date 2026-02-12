# Production-like Mode Setup (Phase 8.10): Real Places + Real OAuth

**Goal:** Run SPOTS in a “production-like” configuration where onboarding can:
- generate **real places** via **Google Places API (New)**, and
- perform **real social pulls** via provider OAuth credentials,
- while staying consistent with the existing geo stack (homebase → locality/city → geo-grounded list generation).

This document is the **single canonical setup** for local dev + CI build secrets.  
It intentionally **does not** include any real secrets.

---

## Quickstart (one command)

```bash
flutter run \
  --dart-define=GOOGLE_PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY \
  --dart-define=USE_REAL_OAUTH=true \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=YOUR_GOOGLE_OAUTH_CLIENT_ID \
  --dart-define=INSTAGRAM_OAUTH_CLIENT_ID=YOUR_INSTAGRAM_CLIENT_ID \
  --dart-define=INSTAGRAM_OAUTH_CLIENT_SECRET=YOUR_INSTAGRAM_CLIENT_SECRET \
  --dart-define=FACEBOOK_OAUTH_CLIENT_ID=YOUR_FACEBOOK_CLIENT_ID \
  --dart-define=FACEBOOK_OAUTH_CLIENT_SECRET=YOUR_FACEBOOK_CLIENT_SECRET
```

Notes:
- `GOOGLE_PLACES_API_KEY` is consumed by `lib/data/datasources/remote/google_places_datasource_new_impl.dart` (HTTP headers).
- OAuth credentials are consumed by `lib/core/config/oauth_config.dart`.
- The OAuth redirect scheme is `spots://oauth/<platform>/callback` (already wired on Android + iOS).

---

## iOS: Google Maps SDK key (native maps)

iOS reads `GMSApiKey` from `ios/Runner/Info.plist` via the build setting `$(GOOGLE_MAPS_IOS_API_KEY)`.

Create an **untracked** file `ios/Flutter/Secrets.xcconfig`:

```xcconfig
GOOGLE_MAPS_IOS_API_KEY=YOUR_IOS_GOOGLE_MAPS_API_KEY
```

Why this is safe:
- `ios/Flutter/{Debug,Profile,Release}.xcconfig` uses `#include? "Secrets.xcconfig"` (optional include).
- No real keys should ever be committed.

---

## Android: Google Maps SDK key (native maps)

Android injects `@string/google_maps_api_key` at build time via Gradle `resValue`.

Preferred local dev option (untracked): add to `android/local.properties`:

```properties
google.maps.apiKey=YOUR_ANDROID_GOOGLE_MAPS_API_KEY
```

Alternative: set an environment variable for CI/build machines:

```bash
export GOOGLE_MAPS_ANDROID_API_KEY=YOUR_ANDROID_GOOGLE_MAPS_API_KEY
```

---

## What “real mode” changes in behavior

- **Places**: onboarding list generation will call Google Places API (New) and return non-empty lists **when** `GOOGLE_PLACES_API_KEY` is set.
- **OAuth**: connect flows will execute real provider OAuth **when** `USE_REAL_OAUTH=true` and the corresponding provider credentials are present.
- **Geo grounding**: onboarding uses the cached homebase lat/lon and resolves locality/city through the geo hierarchy, so generated lists are consistent with geohash/locality pack logic.

---

## Verification checklist (fast + deterministic)

- **Places**
  - **Expect logs**
    - `OnboardingPlaceListGenerator`: `Found X places for category: ...`
  - **If failing**
    - `injection_container.dart` will warn: `GOOGLE_PLACES_API_KEY is not set`

- **OAuth**
  - **Expect logs**
    - `SocialMediaConnectionService`: `OAuth mode: USE_REAL_OAUTH=true`
    - `SocialMediaConnectionService`: `✅ Connected to <platform> successfully`

- **Geo grounding**
  - **Expect logs**
    - `AgentInitializationController`: `🧭 Using cached homebase coords for place generation: ...`
    - `AgentInitializationController`: `✅ Place list geoContext attached (city=..., locality=...)`

---

## Locality Agents (v1) verification

**Prereqs:**
- Your Supabase project must include migration `supabase/migrations/061_locality_agents_v1.sql`.
- For area evolution correctness, also include `supabase/migrations/062_geo_area_cluster_evolution_v1.sql`.

**What to verify:**
- **Onboarding seed**
  - **Expect logs**
    - `LocalityAgentIngestionServiceV1`: `Seeded homebase locality agent: gh7:...`
  - **Backend (optional)**
    - A row inserted into `public.locality_agent_updates_v1` with `source='onboarding_seed'` (requires auth + RLS).

- **Visit learning (automatic check-in checkout)**
  - **Expect logs**
    - `LocalityAgentEngineV1`: `Updated locality delta for gh7:... (visitCount=...)`
    - `LocalityAgentUpdateEmitterV1`: `Emitted locality agent update for gh7:...`

- **OS geofence planning (planner only; registrar is no-op in v1)**
  - **Expect logs**
    - `LocalityGeofencePlannerV1`: `Planned OS geofences: N (precision=...)`
    - `NoopOsGeofenceRegistrarV1`: `No-op registerGeofences called (count=...)`

- **Area evolution correctness (backend)**
  - Run (service role): `select public.geo_area_cluster_rebuild_v1('nyc', 7, 30, 3);`
  - Inspect:
    - `public.geo_area_cluster_memberships_v1` (stable_key → area_id mapping)
    - `public.geo_area_cluster_events_v1` (split/merge events when they occur)
    - `public.geo_area_cluster_runs_v1` (audit runs + mapping_version)

---

## Troubleshooting (fast checks)

- **Places empty / API errors**
  - Confirm `GOOGLE_PLACES_API_KEY` is present in your run configuration.
  - Confirm “Places API” is enabled for that key in Google Cloud.

- **OAuth doesn’t open / callback fails**
  - Confirm `USE_REAL_OAUTH=true`
  - Confirm provider credentials are present via `--dart-define`.
  - Confirm redirect URIs are configured in the provider console as `spots://oauth/<platform>/callback`.

