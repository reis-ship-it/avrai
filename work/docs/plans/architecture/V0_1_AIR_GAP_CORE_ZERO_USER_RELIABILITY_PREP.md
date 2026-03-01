# AVRAI v0.1 Prep: Air Gap as Core + Zero User Reliability

**Date:** March 1, 2026  
**Status:** Planning  
**Depends On:** [Three-Repo Analysis Roadmap](../../agents/reports/THREE_REPO_ANALYSIS_IMPROVEMENTS_ROADMAP.md)

---

## What This Document Is

This is the v0.1 preparation blueprint. It defines:

1. How the air gap becomes the core feature of AVRAI
2. How zero user reliability works (the app learns without the user doing anything)
3. How optional onboarding and social media connections accelerate the experience
4. How the "soul doc" (User Reality Document) gives users real-time transparency into what the AI knows
5. How chat with the AI lets users refine their profile at any time
6. The complete build list in dependency order

---

## Core Design Principle

**The user doesn't have to give any information, but can for a better experience.**

Both paths produce the same output: `SemanticTuple`s in the knowledge store. Both paths go through the same air gap. The difference is speed — active participation accelerates what passive observation eventually achieves on its own.

---

## Part 1: The Two-Track Architecture

### How Data Flows

Every piece of data in AVRAI — whether passively observed or actively provided by the user — follows the same path:

```
Raw data → Intake Adapter → Air Gap (scrubAndExtract) → SemanticTuples → Knowledge Store → Learning Engine → Personality → Soul Doc
                                  |
                                  ├→ PII Scanner (reject if contaminated)
                                  |
                                  └→ ALL EXTRACTION IS 100% ON-DEVICE
                                     Structured data: deterministic extractors (pure Dart)
                                     Free-form text: local LLM or rule-based NLP fallback
                                     NEVER cloud. Raw data NEVER leaves the device.
```

There are no shortcuts. Social media data does not skip the air gap. Onboarding answers do not skip the air gap. Chat messages do not skip the air gap. The air gap is the single gateway between the raw world and the AI's understanding.

**Non-negotiable:** The air gap extraction pipeline is entirely on-device. No cloud LLM is used for extraction. Raw user data never leaves the device. This is not a v0.1 shortcut to be fixed later — it is a permanent architectural constraint.

### Two Tracks, One Pipeline

```
PASSIVE TRACK (zero user reliability — no user action required)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  GPS location        → LocationIntakeAdapter       → Air Gap → Tuples
  Calendar events     → CalendarIntakeAdapter       → Air Gap → Tuples
  Health data         → HealthIntakeAdapter         → Air Gap → Tuples
  App usage patterns  → AppUsageIntakeAdapter       → Air Gap → Tuples
  BLE encounters      → BLEProximityIntakeAdapter   → Air Gap → Tuples
  In-app behavior     → InteractionIntakeAdapter    → Air Gap → Tuples

ACTIVE TRACK (user-initiated, optional, additive)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Onboarding answers  → OnboardingIntakeAdapter     → Air Gap → Tuples
  Social media OAuth  → SocialMediaIntakeAdapter    → Air Gap → Tuples
  Chat with AI        → ChatIntakeAdapter           → Air Gap → Tuples

BOTH TRACKS CONVERGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SemanticKnowledgeStore
    → TupleDrivenLearningEngine
    → PersonalityLearning
    → User Reality Document (soul doc)
```

---

## Part 2: Zero User Reliability

### What It Means

The AI works even if the user does absolutely nothing beyond installing the app. No surveys. No ratings. No feedback forms. No preference picks. No manual input. The user just lives their life; the AI observes, learns, and delivers value purely from passive signals.

### What Currently Exists (Passive)

| Source | Status | Notes |
|---|---|---|
| EventLogger (spot views, dwell, scroll, search, respect taps) | Working | Only fires when app is open |
| Time context | Working | `DateTime.now()` |
| Weather | Working | OpenWeatherMap API |
| Social graph | Working | Supabase `user_respects`, `user_follows` |
| Community data | Working | Trending spots, respected lists |
| GPS (on-demand) | Working | `Geolocator.getCurrentPosition()`, foreground only |
| BLE scanning | Working | Device discovery for AI2AI, battery-adaptive |

### What's Missing (Must Build for Zero User Reliability)

| Gap | What Exists | What's Missing |
|---|---|---|
| Background location | Foreground-only GPS | Background location service, significant location change events |
| Visit recording | `LocationPatternAnalyzer.recordVisit()` + `OrganicSpotDiscoveryService` exist | Nothing calls them — the trigger is missing |
| Geofence registration | `LocalityGeofencePlannerV1` + `OsGeofenceRegistrarV1` exist | Registrar is `NoopOsGeofenceRegistrarV1` — it does nothing |
| BLE → visit inference | BLE scanning works | Encounters don't create visit records |
| `collectUserActions()` | Method exists in `LearningDataCollector` | Returns empty list — no behavioral data reaches the learning loop |
| `ComprehensiveDataCollector` | Exists | Uses hardcoded sample data instead of real data |
| Learning state persistence | `ContinuousLearningOrchestrator._saveLearningState()` | Is a TODO — learning resets on app restart |
| Inferred outcome detection | Outcome quality depends on explicit feedback | No return-visit, avoidance, or affinity inference |

### The Visit Recording Chain (Designed But Not Connected)

Every link in this chain exists as code. No link is connected to the next:

```
GPS/Geofence trigger
  → AutomaticCheckInService.handleGeofenceTrigger()   [exists, only called in tests]
  → LocationPatternAnalyzer.recordVisit()              [exists, never called in production]
  → OrganicSpotDiscoveryService                        [exists, infers categories from dwell/time/day]
```

Connecting this chain is one of the highest-impact items for zero user reliability.

### Inferred Outcomes (Replacing Explicit Feedback)

For zero user reliability, outcomes must be inferred from subsequent behavior, not from star ratings or feedback forms:

| Inferred Signal | Meaning | Confidence |
|---|---|---|
| User returns to same spot within 2 weeks | Positive outcome | High |
| User never returns after visiting | Neutral-to-negative | Low |
| User visits spots similar to one they visited | Positive category signal | Medium |
| User follows/respects someone met at event | Positive social outcome | High |
| Dwell time increases on repeat visits | Growing affinity | Medium |
| User attends another event by same host | Positive outcome | High |

---

## Part 3: The Air Gap as Core Feature

### The Current Problem

AVRAI has two completely parallel data pipelines that never connect:

**Pipeline A (Air Gap):**
```
Raw data → RawDataPayload → AirGapContract.scrubAndExtract() → SemanticTuple → SemanticKnowledgeStore → [dead end]
```

**Pipeline B (Learning):**
```
EventLogger → ContinuousLearningSystem.processUserInteraction() → PersonalityLearning.evolveFromUserAction() → profile updates
```

Pipeline A produces `SemanticTuple`s. Nothing reads them for learning.  
Pipeline B consumes raw interaction events. It never touches the air gap.

For the air gap to be core, these two pipelines must merge. The air gap must be the **only** pathway for data to reach the AI's brain.

### After v0.1: One Pipeline

```
Raw data → Intake Adapters → Air Gap → SemanticTuples → Knowledge Store → TupleDrivenLearning → PersonalityLearning
                                |
                                ├→ PII Scanner (reject if contaminated)
                                |
                                └→ Extraction is 100% ON-DEVICE
                                   (deterministic for structured data,
                                    local LLM for free-form text,
                                    rule-based NLP as fallback — NEVER cloud)
```

### Current Air Gap Components and Their Status

| Component | Location | Status |
|---|---|---|
| `AirGapContract` | `shared/avrai_core/lib/contracts/air_gap_contract.dart` | Real interface |
| `RawDataPayload` | Same file | Real abstract class |
| `PrivacyBreachException` | Same file | Real |
| `SemanticTuple` | `shared/avrai_core/lib/schemas/semantic_tuple.dart` | Real, but schema is too thin |
| `TupleExtractionEngine` | `engine/reality_engine/lib/memory/air_gap/tuple_extraction_engine.dart` | Mock — returns fake tuples |
| `SemanticKnowledgeStore` | `engine/reality_engine/lib/memory/semantic_knowledge_store.dart` | In-memory only — data lost on restart |
| `DeviceIntakeRouter` | `runtime/.../endpoints/intake/device_intake_router.dart` | Real, but never called from OS listener |
| `SocialMediaIntakeAdapter` | `runtime/.../endpoints/intake/social_media_intake_adapter.dart` | Real, but only handles JSON exports |

### Intake Adapters Needed

Currently only 2 intake adapters exist (notifications and social media exports). Zero user reliability + social media + onboarding + chat requires these additional adapters:

| Adapter | What It Ingests | Example Tuple Output |
|---|---|---|
| `LocationIntakeAdapter` | GPS coordinates + timestamps + dwell | `(user_self, frequents, morning_coffee_neighborhood, 0.87)` |
| `CalendarIntakeAdapter` | Calendar events (titles, times, attendees) | `(user_self, attends_regularly, weekly_group_activity, 0.91)` |
| `HealthIntakeAdapter` | HealthKit/Google Fit (steps, sleep, heart rate) | `(user_self, energy_pattern, high_morning_low_evening, 0.78)` |
| `AppUsageIntakeAdapter` | Screen time, app categories | `(user_self, digital_behavior, content_creation_heavy, 0.72)` |
| `BLEProximityIntakeAdapter` | Nearby devices, signal strength, duration | `(user_self, social_pattern, frequent_group_encounters, 0.65)` |
| `InteractionIntakeAdapter` | In-app events (spot views, dwell, search) | `(user_self, interest_signal, food_and_dining, 0.67)` |
| `OnboardingIntakeAdapter` | Dimension question answers, preference picks | `(user_self, venue_preference, intimate_small, 0.92)` |
| `ChatIntakeAdapter` | User messages to their AI agent | `(user_self, self_identifies_as, socially_reserved, 0.92)` |

The existing `SocialMediaIntakeAdapter` needs to be extended to handle OAuth API responses (profile, follows, posts, places), not just raw JSON exports.

### SemanticTuple Schema Enrichment

The current tuple is a bare subject-predicate-object triple. For the air gap to drive learning, tuples need:

| New Field | Type | Purpose |
|---|---|---|
| `dimensionHints` | `Map<String, double>` | Which personality dimensions this tuple informs and by how much |
| `signalStrength` | `double` | How informative this observation is (high for novel, low for redundant) |
| `observationCount` | `int` | How many raw observations were consolidated into this tuple |
| `sourceType` | `String` | Data source category (location, calendar, health, social, chat, onboarding, etc.) |
| `freshness` | `DateTime` | When the underlying observation happened (not when the tuple was created) |

### SemanticKnowledgeStore Requirements

The in-memory store must become persistent with real query capabilities:

- Persistent local storage via **Drift (SQLite)** — the foundational decision for all new persistent storage (per `FOUNDATIONAL_DECISIONS.md`, Decision 5). Drift is already in the dependency tree with migrations, DAOs, and patterns for other tables.
- Query by category, dimension, time range, source type (not just subject)
- Tuple consolidation (merge redundant tuples into high-confidence ones)
- Freshness decay (old tuples lose influence over time)
- Observation counting (how many raw observations support this knowledge)

### Extraction Strategy: Deterministic First, Local LLM as Enhancement

**The `TupleExtractionEngine` is NOT an LLM wrapper. It is a router with multiple extraction strategies.**

The current mock implementation assumes a single LLM call for all extraction. This is wrong. Most data sources produce structured data that can be converted to tuples with deterministic logic — no LLM required, no cloud dependency, no device capability gate. The air gap works on every device, immediately.

```
TupleExtractionEngine.scrubAndExtract(payload)
  │
  ├── DETERMINISTIC EXTRACTORS (pure Dart, no LLM, works on all devices)
  │   ├── sourceId: 'location'        → Reverse geocode + dwell analysis + category lookup
  │   ├── sourceId: 'calendar'         → Parse event fields + recurrence detection + categorize
  │   ├── sourceId: 'health'           → Statistical patterns on numeric time series
  │   ├── sourceId: 'app_usage'        → Categorical aggregation of screen time
  │   ├── sourceId: 'ble_proximity'    → Proximity duration + frequency statistics
  │   ├── sourceId: 'interaction'      → Category mapping + frequency analysis on structured events
  │   ├── sourceId: 'onboarding'       → Direct dimension mapping (question → dimension)
  │   └── sourceId: 'social_follows'   → Category distribution analysis on structured lists
  │
  ├── LOCAL LLM EXTRACTORS (on-device only, enhances quality for free-form text)
  │   ├── sourceId: 'social_text'      → Local LLM interprets bios, captions, post text
  │   ├── sourceId: 'agent_chat'       → Local LLM extracts personality signals from conversation
  │   └── sourceId: 'notification'     → Local LLM interprets notification body text
  │
  ├── RULE-BASED NLP FALLBACK (when local LLM not available on device)
  │   ├── sourceId: 'social_text'      → Keyword extraction + sentiment + regex patterns
  │   ├── sourceId: 'agent_chat'       → Keyword extraction + pattern matching
  │   └── sourceId: 'notification'     → Regex + category inference from app name
  │
  THEN → PII Scanner → SemanticKnowledgeStore
  THEN → Destroy raw payload
```

**Why this matters:**

- **No data ever leaves the device.** Deterministic extractors are pure local computation. Local LLM is local computation. There is no cloud LLM in the extraction pipeline. Period.
- **No device capability gate for core functionality.** GPS, calendar, health, in-app events, onboarding, BLE — all use deterministic extractors that run on any device. The air gap works without an LLM.
- **Zero latency for structured data.** Deterministic extraction is instant — milliseconds, not seconds. Batch 50 events, extract 50 tuples, no inference wait.
- **Zero cost.** No cloud API calls for extraction. All on-device.
- **Local LLM enhances, doesn't gate.** When the on-device LLM is available (Android via `llama_flutter_android`, iOS/macOS via CoreML), free-form text extraction is richer. When it's not available, rule-based NLP still produces useful tuples — less nuanced, but functional.
- **The soul doc synthesis is the one place where local LLM is genuinely needed** for quality output (turning tuples into readable prose). But even that can start as structured templates before LLM synthesis is available.

**Non-negotiable rule: raw user data NEVER leaves the device for extraction. No cloud LLM fallback for the air gap pipeline. The air gap is local-only.**

### PII Post-Extraction Scanner

All tuples — whether from deterministic extractors, local LLM, or rule-based NLP — pass through a deterministic PII scanner before reaching the knowledge store. The scanner is pure Dart (regex + pattern matching), no LLM:

- Proper names (first, last)
- Addresses (street, city, zip)
- Phone numbers, emails
- Specific business names (unless in public spots database)

Rejected tuples are dropped. For deterministic extractors, PII risk is low (the extractor controls the output vocabulary). For LLM-based extraction, PII risk is higher (the LLM could accidentally include raw text), making the scanner essential.

---

## Part 4: Optional Onboarding (Acceleration, Not Requirement)

### Design Philosophy

Onboarding is optional acceleration. Every onboarding step provides information that passive observation would eventually produce on its own. Users who complete onboarding get better recommendations faster. Users who skip it get the same quality — it just takes longer.

### How Each Onboarding Step Maps

| Onboarding Step | If Skipped | If Completed |
|---|---|---|
| Dimension questions (12) | Passive observation bootstraps in 24-48h | Immediate dimension seeding with high confidence |
| Favorite places | GPS + visit patterns fill this in over time | Faster location-aware recommendations |
| Preference survey ("What do you love?") | Social media + behavior infers categories | Immediate category seeding |
| Social media OAuth | AI builds profile from offline behavior only | Rich online + offline picture from day one |
| Cross-app data consent | Only in-app + GPS observation | Calendar, health, media, app usage all contribute |

### All Onboarding Goes Through the Air Gap

When a user answers "I prefer cozy intimate venues over big crowded ones," that is raw personal data. It goes through the air gap:

```
User answer: "I prefer cozy intimate venues"
  → OnboardingIntakeAdapter wraps as RawDataPayload (sourceId: 'onboarding_dimension_question')
  → Air Gap scrubs and extracts:
     (user_self, venue_preference, intimate_small, 0.92, dimensionHints: {social_energy: -0.3})
     (user_self, energy_comfort, low_moderate, 0.85, dimensionHints: {energy_pattern: -0.2})
  → SemanticKnowledgeStore
  → TupleDrivenLearningEngine
```

Onboarding answers are treated identically to social media data and passive observation. They are all just tuples with different source types and confidence levels.

### Minimum Required Onboarding (Legal Only)

For v0.1, the only hard requirements are:

1. Terms of Service acceptance (legally required)
2. Age verification — 18+ (legally required)
3. Single consent screen: "Allow AVRAI to learn from your device?" (replaces per-source toggles)

Everything else — name, homebase, dimension questions, social media, cross-app data — is optional and can be done later (or never).

- Display name: auto-generate or defer ("set it whenever you want")
- Homebase: auto-detect from GPS with fallback

---

## Part 5: Social Media Through the Air Gap

### Current State

AVRAI has OAuth flows for 11 platforms:

| Platform | OAuth | Data Collected |
|---|---|---|
| Google | Real | Profile, saved places, reviews, photos |
| Instagram | Real | Profile, followers/follows, media, captions, interests |
| Facebook | Real | Profile, friends |
| Twitter/X | Real | Profile, following |
| Reddit | Real | Profile (id, name) |
| TikTok | Real | Profile (display name, avatar) |
| LinkedIn | Real | Profile, connections count |
| YouTube | Real | Via Google OAuth |
| Pinterest | Real | Via AppAuth |
| Tumblr | Real | Via AppAuth |
| Are.na | Real | Via AppAuth |

OAuth is disabled by default (`USE_REAL_OAUTH=false`). Enabled via `--dart-define=USE_REAL_OAUTH=true` + platform credentials.

### Current Problem: Social Data Bypasses the Air Gap

The `SocialMediaVibeAnalyzer` receives raw API data and directly maps it to personality dimensions. The air gap is not involved:

```
CURRENT (wrong):
  OAuth → Platform API → Raw data → SocialMediaVibeAnalyzer → Direct dimension updates
```

### Correct Flow: Social Data Through the Air Gap

```
CORRECT:
  OAuth → Platform API → Raw data
    → SocialMediaIntakeAdapter → RawDataPayload
    → Air Gap (scrubAndExtract) → SemanticTuples
    → SemanticKnowledgeStore → TupleDrivenLearning
```

The `SocialMediaVibeAnalyzer`'s mapping logic (which platform data maps to which dimensions) becomes the **extraction prompt template** for the LLM inside the air gap, rather than being hardcoded Dart logic.

### What the Air Gap Extracts From Social Data

| Data Type | Raw Input | Example Tuple Output |
|---|---|---|
| Profile bio | "Adventure seeker, coffee lover, dog dad" | `(user_self, self_describes_as, adventure_oriented, 0.88)` |
| Follows/interests | List of followed accounts with categories | `(user_self, interest_pattern, food_and_travel_heavy, 0.82)` |
| Post captions | "Beautiful sunset hike with the crew" | `(user_self, activity_preference, outdoor_group_activities, 0.79)` |
| Liked content | Categories of liked posts | `(user_self, content_affinity, nature_photography, 0.71)` |
| Google saved places | Saved locations with reviews | `(user_self, frequents, casual_dining_establishments, 0.85)` |
| Reddit subscriptions | List of subreddits | `(user_self, intellectual_interest, technology_and_science, 0.77)` |

The raw data — bios, captions, follower lists, post text — is destroyed after extraction. Tuples carry no usernames, no post content, no platform-specific identifiers.

### Amazon

Not currently supported as a platform. Adding it means building an `AmazonPlatformService` with OAuth. Amazon's consumer API surface is limited (purchase categories, wishlists). Lower priority than the 11 platforms already integrated.

---

## Part 6: The Soul Doc (User Reality Document)

### What It Is

A natural-language document synthesized by the local LLM from accumulated `SemanticTuple`s in the knowledge store. It's the "reverse air gap" — abstract mathematical tuples rendered back into readable prose, without ever referencing the destroyed raw data.

The user can read it at any time to see exactly what the AI knows about them, how it knows it, and how confident it is.

### Example Output

```
Your AVRAI Reality

Who You Are (confidence: high — 847 observations over 4 months)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're someone who thrives on routine with bursts of exploration. Your mornings
follow a consistent pattern, but your weekends are unpredictable — you seek out
new neighborhoods and food experiences regularly.

You're socially selective. You maintain a small, tight circle rather than a wide
network. When you do socialize, you prefer smaller group settings over large
events.

You have a strong affinity for food and dining — it's your primary way of
experiencing new places. Nature and outdoor activities appear in your patterns
but aren't dominant.

Your energy peaks in the morning and early afternoon. Evening activities are rare
unless they're food-related.

How I Know This
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Location patterns       312 observations    high confidence
  Social media interests  2 platforms         high confidence
  In-app behavior         143 observations    medium confidence
  Calendar patterns       89 observations     medium confidence
  Health data             not connected
  BLE encounters          12 observations     low confidence — still learning
```

### How It Stays Current

Every time the `SemanticKnowledgeStore` receives new tuples, the soul doc can be regenerated or incrementally updated. It's not a static document — it's a live view over the tuple store, rendered to prose by the LLM.

When the user connects a new social platform and 200 new tuples flow in, the soul doc immediately reflects them. When passive observation accumulates over weeks, the doc gets richer.

### Where It Lives Architecturally

| Component | Prong | Purpose |
|---|---|---|
| `RealityDocumentSynthesizer` | Engine | Takes tuples, produces prose document |
| Reality doc API/service | Runtime | Serves the doc, triggers regeneration |
| Soul doc UI page | Apps | Displays to user with source attribution |

### Source Attribution and Confidence

The soul doc always shows:

- What the AI knows (the prose)
- How it knows it (which data sources contributed)
- How confident it is (observation counts, time span)
- What it doesn't know (intelligence gaps — which sources aren't connected)

This is progressive confidence display (item #11 from the three-repo roadmap) built into the soul doc.

---

## Part 7: Chat as a Learning Channel

### The Current Problem

`PersonalityAgentChatService` handles user-to-AI conversation, but chat does not feed into personality learning. Only language style and ratings are captured. If a user says "I'm actually more of an introvert" or "I've been really into hiking lately," that information goes nowhere.

### How Chat Feeds Into the Air Gap

User messages in agent chat are raw personal data. They go through the air gap like any other source:

```
User types: "I've been really into hiking lately, especially morning hikes"
  → ChatIntakeAdapter wraps message as RawDataPayload (sourceId: 'agent_chat')
  → Air Gap scrubs and extracts:
     (user_self, emerging_interest, hiking, 0.85, dimensionHints: {discovery_orientation: +0.2})
     (user_self, time_preference, morning_activity, 0.78, dimensionHints: {temporal_flexibility: -0.1})
  → Raw message stays in encrypted chat storage (for conversation continuity)
  → Tuples go to SemanticKnowledgeStore
  → TupleDrivenLearningEngine picks them up
  → Personality dimensions update
  → Soul doc regenerates
```

The user sees the effect in real time: they told their AI something, and the soul doc reflects it. Recommendations start shifting. Immediate feedback loop.

### User Corrections Via Chat

The user reads their soul doc and sees something off. They chat with the AI to correct it:

```
User: "That's not right, I'm actually more spontaneous — I don't like rigid routines"
  → ChatIntakeAdapter → Air Gap
  → (user_self, corrects, routine_preference, 0.95)
     (user_self, self_identifies_as, spontaneous, 0.90)
  → Correction tuples carry high confidence (user explicitly stated this)
  → TupleDrivenLearningEngine weighs user-stated tuples higher
  → Soul doc updates
```

### Confidence Hierarchy

Tuples from different sources carry different base confidence:

| Source | Base Confidence | Rationale |
|---|---|---|
| User-stated (chat corrections) | 0.90 - 0.95 | User explicitly declared this about themselves |
| Onboarding answers | 0.85 - 0.92 | User deliberately answered a question |
| Social media (profile bio) | 0.80 - 0.88 | User curated this public identity |
| Social media (behavior) | 0.70 - 0.82 | Inferred from follows/likes/posts |
| Direct observation (GPS, calendar) | 0.70 - 0.85 | Observed but not declared |
| In-app behavior | 0.60 - 0.75 | Implicit signal, lower certainty |
| BLE proximity | 0.50 - 0.65 | Proximity doesn't imply intent |

A user saying "I'm spontaneous" (confidence 0.90) overrides a pattern of visiting the same coffee shop (confidence 0.75). But if the behavior persists and contradicts the stated preference, the AI can surface that tension in the soul doc:

> "You describe yourself as spontaneous, but your morning patterns are highly consistent. You might be spontaneous in some areas but routine-oriented in others."

This is the AI being genuinely intelligent — noticing contradictions between stated and observed reality and surfacing them honestly.

### Chat Messages vs. Tuples

| Data | Storage | Lifespan | Purpose |
|---|---|---|---|
| Encrypted chat messages | GetStorage (conversation history) | Session-based, scrollable | Conversation continuity — the AI needs prior messages to respond coherently |
| Extracted tuples | SemanticKnowledgeStore (persistent) | Permanent (with consolidation) | Personality knowledge — abstract facts that drive learning |

The chat history is ephemeral conversation context. The tuples are permanent knowledge. They're separated by the air gap.

---

## Part 8: How a Real User Experiences This

### User A: Does Nothing (Zero User Reliability)

**Day 0 — Install + legal-only onboarding:**
- GPS auto-detects location → `(user_self, located_in, urban_residential, 0.95)`
- Soul doc: "I'm still getting to know you. So far I know you're in [city area]."

**Day 1-7 — Passive observation:**
- GPS dwell patterns → morning routine tuples
- In-app browsing → interest signal tuples
- Soul doc grows: "You seem drawn to food and dining spots."

**Day 14:**
- 200+ tuples accumulated
- 12 dimensions have moved off defaults
- Recommendations are meaningfully personalized
- User never answered a question

**Day 30:**
- 400+ tuples
- Soul doc is substantive and accurate
- System is fully functional

### User B: Connects Everything on Day 1

**Day 0 — Install + full onboarding + social media:**
- Accepts legal, answers dimension questions, connects Instagram + Reddit + Google
- 150+ tuples from social media alone
- 12 dimension questions produce 24 more high-confidence tuples
- Soul doc is already rich: "You're drawn to food, travel, and photography. You follow creative and tech communities. You describe yourself as adventurous."

**Day 0 — Chats with AI:**
- "I'm actually pretty introverted despite my Instagram"
- Correction tuple overrides social media inference
- Soul doc updates: "You describe yourself as introverted, though your social media presence suggests otherwise."

**Day 1:**
- Recommendations are highly personalized
- User sees real changes in real time
- Every chat message refines the soul doc further

### Both Users

Both end up with a functioning, learning AI. Both have soul docs. Both have private, air-gap-protected data. One just got there faster. The architecture treats them identically.

---

## Part 9: Federated Learning Compatibility

None of the items in this document conflict with the federated learning system. The federated pipeline is a consumer of personality state. Everything in this document improves the producer of that state. Better tuples → better personality profiles → better federated deltas → better network priors.

The one coordination point: when model math moves from runtime to engine (items #20/#21 from the three-repo roadmap), `OnnxDimensionScorer.updateWithDeltas()` needs to move behind an `EngineContract`, and the federated hooks need to call the contract instead of the concrete class.

---

## Part 10: Complete Build List (Dependency Order)

### Layer 0: Foundation

| # | Item | What | Why It's First |
|---|---|---|---|
| 1 | Enrich `SemanticTuple` schema | Add `dimensionHints`, `signalStrength`, `observationCount`, `sourceType`, `freshness` | Everything downstream needs richer tuples |
| 2 | Persistent `SemanticKnowledgeStore` | Drift (SQLite) with query by category, dimension, time range, source type | In-memory store kills knowledge on restart. Drift is the foundational decision for new storage. |
| 3 | Build `TupleExtractionEngine` as a router with deterministic extractors | Source-specific extractors: reverse geocode for location, field parsing for calendar, statistics for health, category mapping for interactions, direct mapping for onboarding. Pure Dart, no LLM, works on all devices. | The air gap must work immediately on every device without waiting for local LLM. Deterministic extractors are the foundation — they handle the majority of data sources. |
| 4 | PII post-extraction scanner | Deterministic regex + pattern matching validator, no LLM | All tuples pass through before storage. Essential for LLM-extracted tuples; defense-in-depth for deterministic tuples. |

### Layer 1: Passive Track (Zero User Reliability)

| # | Item | What | Dependency |
|---|---|---|---|
| 5 | `LocationIntakeAdapter` | GPS → air gap → tuples | Layer 0 |
| 6 | `InteractionIntakeAdapter` | EventLogger in-app events → air gap → tuples | Layer 0 |
| 7 | Background location service | Significant location change + periodic snapshots | Layer 0 + native platform code |
| 8 | Wire visit recording chain | Geofence/BLE trigger → `AutomaticCheckInService` → `LocationPatternAnalyzer.recordVisit()` | #5, #7 |
| 9 | Implement `OsGeofenceRegistrarV1` | Native iOS/Android geofence registration | #8 |
| 10 | `CalendarIntakeAdapter` + `HealthIntakeAdapter` + `AppUsageIntakeAdapter` | Cross-app data sources → air gap → tuples | Layer 0 |
| 11 | `BLEProximityIntakeAdapter` | BLE encounter data → air gap → tuples | Layer 0 |
| 12 | Wire `collectUserActions()` | Read from `interaction_events` instead of returning empty | Layer 0 |
| 13 | Wire `ComprehensiveDataCollector` | Real data instead of hardcoded samples | Layer 0 |
| 14 | Persist learning state | `_saveLearningState()` TODO → real persistence | Layer 0 |
| 15 | Build inferred outcome detection | Return visits, social follows, category affinity, dwell trends | #5, #6, #8 |

### Layer 1.5: Local LLM Extraction (Enhancement, Not Gate)

| # | Item | What | Dependency |
|---|---|---|---|
| 15.1 | Wire local LLM into `TupleExtractionEngine` for free-form text | Android: `llama_flutter_android` (GGUF). iOS: build Swift handler for `spots/local_llm` (CoreML). Used for social media bios/captions, chat messages, notification text. | Layer 0 (deterministic extractors work without this) |
| 15.2 | Rule-based NLP fallback for free-form text | Keyword extraction, sentiment analysis, regex patterns. Used when local LLM is not available on device. | Layer 0 |
| 15.3 | `RealityDocumentSynthesizer` with local LLM | Synthesize soul doc prose from tuples using on-device LLM. Template-based fallback when LLM unavailable. | #15.1 or template fallback |

### Layer 2: Active Track (User-Initiated, Optional)

| # | Item | What | Dependency |
|---|---|---|---|
| 16 | Reroute social media through air gap | `SocialMediaDataCollectionController` → `SocialMediaIntakeAdapter` → air gap | Layer 0 |
| 17 | Social media extraction — structured + text | Structured data (follows, likes, subscriptions): deterministic category mapping. Free-form text (bios, captions): local LLM when available, rule-based NLP otherwise. All on-device. | #3 for structured, #15.1/#15.2 for text, #16 |
| 18 | `OnboardingIntakeAdapter` | Onboarding answers → air gap → tuples (deterministic — questions map directly to dimensions) | Layer 0 |
| 19 | `ChatIntakeAdapter` | Agent chat messages → air gap → tuples (local LLM when available, keyword extraction otherwise) | Layer 0, #15.1/#15.2 |
| 20 | Chat → personality learning | `ContinuousLearningSystem` processes chat-derived tuples | #19 |

### Layer 3: Learning Engine

| # | Item | What | Dependency |
|---|---|---|---|
| 21 | `TupleDrivenLearningEngine` | Subscribes to knowledge store, reads new tuples, drives personality evolution | Layer 0 + at least one intake adapter |
| 22 | `PersonalityLearning.evolveFromTuples()` | New method that evolves personality from tuples with dimension hints | #21 |
| 23 | Confidence hierarchy | User-stated > observed > inferred weighting in learning engine | #22 |
| 24 | Tuple consolidation | Hard memory budgets applied to knowledge store | #2, #21 |
| 25 | Cold-start bootstrap | Initial personality from first 24-48h of passive tuples | #21, #22, passive track items |

### Layer 4: Soul Doc

| # | Item | What | Dependency |
|---|---|---|---|
| 26 | `RealityDocumentSynthesizer` | Engine component: tuples → readable document. Uses local LLM for prose synthesis when available, structured template output otherwise. Never cloud. | #2, #15.3 (or template fallback) |
| 27 | Soul doc UI page | Display soul doc with source attribution + confidence | #26 |
| 28 | Chat → soul doc feedback loop | User reads doc, chats corrections, corrections flow back through air gap | #19, #20, #26 |
| 29 | Progressive confidence display | Observation counts, time span, source gaps shown in doc | #26 |

### Layer 5: Onboarding Streamlining

| # | Item | What | Dependency |
|---|---|---|---|
| 30 | Reduce onboarding to legal-only minimum | ToS + age + single consent screen | Independent |
| 31 | Make all other onboarding steps skippable | Dimension questions, preferences, social — all optional | #30 |
| 32 | "Continue setup later" option | User can return to any onboarding step from settings | #31 |

---

## Part 11: What This Unlocks

When this is complete:

1. **The air gap is real, not conceptual.** Every data source flows through it. No shortcuts.
2. **The user doesn't have to do anything.** Passive observation bootstraps personality in 24-48 hours.
3. **But users who engage get more.** Onboarding, social media, and chat accelerate learning.
4. **The soul doc makes it tangible.** Users see what the AI knows, how it knows it, and can correct it in real time through conversation.
5. **Privacy is structural, not policy.** Raw data is destroyed at the air gap boundary. Only abstract tuples survive. The soul doc proves this — it's readable prose with no raw source data. Extraction is 100% on-device — raw data never leaves.
6. **The architecture is clean.** One pipeline, one data format (`SemanticTuple`), one gateway (air gap), one knowledge store, one learning engine.
7. **No LLM dependency for core functionality.** Deterministic extractors handle structured data (GPS, calendar, health, in-app events, onboarding, BLE) on every device without an LLM. The local LLM enhances free-form text extraction when available but does not gate the system.
8. **Zero cloud cost for extraction.** All extraction is on-device computation. No API calls. No per-user inference cost.

---

## Reference: Three-Repo Roadmap Items That Integrate Here

| Roadmap Item | How It Connects |
|---|---|
| #3 Hard memory budgets | Tuple consolidation in the knowledge store (build list #24) |
| #4 User-Readable Reality Document | The soul doc (build list #26-29) |
| #8 Intelligence gap tracking | `sourceType` on tuples tracks which sources are blind (build list #1) |
| #10 Baseline anomaly detection | Runs on tuple streams for behavioral baseline (future enhancement) |
| #11 Progressive confidence display | Built into the soul doc (build list #29) |
| #12 Regime-aware signal scaling | Determines `signalStrength` during deterministic extraction (build list #1, #3) |
| #17 Wire LLM into air gap | Build list #15.1 — local LLM only, for free-form text. Deterministic extractors handle structured data without LLM (build list #3). |
| #18 PII scanner | Build list #4 |

---

*This document supersedes individual mentions of zero user reliability and air gap in other planning documents. It is the canonical source for v0.1 air gap architecture.*

*Corrected March 1, 2026: Extraction strategy updated. The air gap uses deterministic extractors for structured data (no LLM dependency) and local-only LLM for free-form text (with rule-based NLP fallback). Raw user data never leaves the device for extraction. No cloud LLM is used in the extraction pipeline — this is a permanent architectural constraint, not a future optimization.*
