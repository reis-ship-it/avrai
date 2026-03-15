# AVRAI BHAM Wave-1 Beta Master Execution Document

**Date:** March 9, 2026  
**Status:** Draft execution authority  
**Scope:** Birmingham, Alabama wave-1 closed beta only

## 1. Non-Implicit Build Rule

This document is the execution authority for the BHAM beta.

The operating rule is strict:

- if a requirement appears anywhere in the BHAM beta packet, it must appear here as:
  - a build item,
  - a launch blocker,
  - an explicit default,
  - or an explicit defer
- if something is not explicit here, it is not part of wave 1
- if the BHAM packet names an area but leaves lower-level details open, this document must either:
  - lock a default, or
  - mark launch as blocked until a named artifact exists

Nothing in BHAM wave 1 is allowed to remain "understood but unwritten."

## 2. Authority Stack

Use these documents together, with this file as the ordered execution authority:

- `README.md` in this folder for the BHAM beta contract and scope summary
- `01_SCOPE_AND_OPERATING_MODEL.md` for product goal, role model, promises, and non-promises
- `02_ONBOARDING_PERMISSIONS_AND_IDENTITY.md` for onboarding sequence and identity rules
- `03_USER_EXPERIENCE_OBJECTS_DISCOVERY_AND_MESSAGING.md` for user app structure, object model, notifications, and messaging rules
- `04_OFFLINE_AI2AI_AND_DATA_CONTRACT.md` for offline, AI2AI, and on-device data rules
- `05_ADMIN_GOVERNANCE_TRUTH_AND_SAFETY.md` for admin, truth, safety, falsity, and conviction rules
- `06_SUCCESS_GATES_FALLBACKS_AND_EDGE_CASES.md` for launch gates, fallbacks, and edge cases
- `07_IMPLEMENTATION_CLARIFICATIONS.md` for unresolved lower-level items
- `08_IMPLEMENTATION_CHECKLIST_AND_FILE_MAP.md` for the exhaustive file-aware map
- `09_ONBOARDING_QUESTIONNAIRE_AND_CONSENT_COPY.md` for explicit onboarding copy
- `13_FOLLOW_UP_DEVICE_QA_OUTLINE.md` for the manual phone-availability QA order, device matrix, evidence capture, and blocker rules
- `14_FOLLOW_UP_DEVICE_QA_FIELD_CHECKLIST.md` for the single live device-QA master checklist, including team/system/platform sections, kernel-by-kernel learning checks, and simulation-vs-live truth checks
- `Bham simulation/README.md` for BHAM simulation planning, source intake, and replay order
- `Bham simulation/05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md` for BHAM-only replay authority, forecast-kernel placement, and runtime/engine/app/agent flow
- `Bham simulation/70_BHAM_SIMULATION_IMPROVEMENT_ROADMAP_2026.md` for the phased roadmap of simulation improvements for beta, post-beta, and v1 launch
- `Bham simulation/12_BHAM_PROVIDED_SOURCE_INPUTS_2023.md` for the exact user-provided links, files, and access grants logged during Wave 8 intake
- `work/docs/agents/status/status_tracker.md` for canonical status and progress
- `work/docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md` for prong boundaries
- `work/docs/plans/rationale/PHASE_12_OS_RATIONALE.md` for what remains post-beta

For exhaustive file anchors, use `08_IMPLEMENTATION_CHECKLIST_AND_FILE_MAP.md`. This document focuses on ordered execution and explicit build requirements.

## 3. End Goal

Wave 1 exists to prove that AVRAI can:

- learn a human from real-world life plus app behavior
- exchange and propagate useful intelligence through AI2AI without requiring internet
- surface that learning safely through the user app and secure admin app
- help Birmingham users find more meaningful and fun real-world doors

The beta must ship a working app and runtime that provide these day-1 experiences:

1. a new user completes onboarding, gets a first knot or DNA state, receives a first meaningful daily drop, and the personal agent starts learning
2. nearby users exchange DNA, pheromones, and agent-safe signals through AI2AI while the runtime learns from those encounters
3. users can create and discover `spots`, `lists`, `clubs`, `communities`, and `events`
4. the secure admin app can observe AI2AI activity, agent health, kernel health, locality movement, creation flows, and beta feedback
5. the system remains useful without internet through on-device kernels, local caches, and AI2AI mesh or local relay

The core product promise is:

- find better spots, lists, events, clubs, and communities
- learn who the user is through real-world behavior, not phone addiction
- keep working and learning without internet through on-device kernels and AI2AI exchange
- contribute upward to locality and reality-model learning without leaking direct human identity to admin by default

The beta promises:

- offline-first personal learning
- daily meaningful discovery across all 5 discovery object types
- AI2AI nearby learning and relay
- user control over settings and permissions
- privacy-preserving agent visibility in the admin app
- easier event, community, club, and list creation
- a reason to get off the phone and into the real world

The beta does not promise:

- perfect recommendations
- guaranteed friendships, attendance, or outcomes
- zero false positives
- always-correct place or locality DNA on day 1
- perfect platform stability

The public positioning is a real-world social discovery system.
The internal positioning is a local-first behavioral learning system with AI2AI runtime exchange and admin-governed oversight.

## 4. Scope Lock

### Wave-1 target

- geography: Birmingham metro and suburbs
- initial cohort: 10-25 testers
- age floor: 16+
- platforms: iPhone and Android on approved devices only
- account model: one human, one account, one primary device
- core stance: offline-first via on-device learning plus AI2AI mesh and local relay, with internet as a secondary aid
- admin stance: secure separate admin app, always-on oversight, no direct human identity exposure by default

### Role model

- `Regular user`: default role for everyone in wave 1
- `Club leader`: capability added when a user creates a club
- `Community leader`: capability added when a user creates a community
- `Event host`: capability added when a user creates an event
- `Admin`: separate secure role through the admin app only
- `Business/venue owner`: deferred, but ownership can be noted for future rollout
- `Expert`: deferred, but future expert potential can be noted from repeated behavior

### Deferred from wave 1

- business accounts as a first-class role
- expert accounts as a first-class role
- business signup, login, dashboard, and analytics surfaces remain checked in but are disconnected from launch app paths
- partnership proposal, management, acceptance, checkout, and profile surfaces remain checked in but are disconnected from launch app paths
- business-business partnership discovery remains checked in but is disconnected from launch app paths
- full multi-device continuity
- public release claims beyond Birmingham wave 1

### Explicitly out of scope for this document

- Rust kernel extraction
- post-beta Phase 12 platform adapters
- external cognitive syscall APIs
- third-party SDK and distribution work
- broad whole-repo cleanup not required for BHAM beta

## 5. Architectural Guardrails

- Preserve the three-prong dependency direction: `apps -> runtime -> engine -> shared`.
- New cross-prong contracts land before the behaviors that depend on them.
- No beta-critical flow may bypass the existing headless OS mediation surfaces:
  - `HeadlessAvraiOsHost`
  - `ModelTruthPort`
  - `RuntimeExecutionPort`
  - `TrustGovernancePort`
- `locality` remains inside `where`. Do not add new public top-level `Locality*` beta APIs.
- Admin stays pseudonymous by default. Break-glass remains human-only and explicitly audited.
- Governance truth remains distinct from behavior truth:
  - real human behavior outranks priors for learning
  - safety, quarantine, rollback, abuse, and policy outrank behavior when governance requires it
- "OS-backed" in wave 1 means runtime-mediated internal flows through the existing headless host. It does not mean starting post-beta platformization.
- AVRAI remains `ai2ai-only` in transport authority. Direct human p2p is not the architectural authority.

## 5A. Code Placement Strategy

Wave 1 should be built into the **main product codebase**, not as a separate project.

### Build in the main code paths

- user beta behavior belongs in `apps/avrai_app/*`
- runtime beta behavior belongs in `runtime/avrai_runtime_os/*`
- reality-model beta behavior belongs in `engine/*`
- shared beta contracts belong in `shared/*`
- admin beta behavior belongs to the standalone admin app boundary in `apps/admin_app/*`

### Current admin-state reality

Right now the repo has:

- a real standalone desktop admin app shell in `apps/admin_app/*`
- a larger embedded admin implementation module in `apps/avrai_app/lib/apps/admin_app/*` that the standalone shell currently boots from

That means the current nested admin module is **transitional implementation state**, not the preferred long-term placement target.

### Do not create a separate beta app or separate beta repo

Reasons:

- BHAM wave 1 is the launch path for the real product, not a disposable experiment
- the required beta flows are core product flows: onboarding, daily drop, explore, creation, chat, offline runtime, AI2AI, admin oversight
- a separate project would duplicate contracts, duplicate runtime wiring, and create drift between "beta" and "real" AVRAI
- bug fixes found in beta need to harden the main product directly, not be backported later
- the admin and runtime contracts already live in the main architecture and should stay canonical there

### Where beta-specific material should live

Use dedicated BHAM-specific files and config inside the main repo when the content is locality-specific, temporary, or launch-ops-specific.

This includes:

- BHAM docs in `work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/*`
- BHAM simulation inputs and priors in the simulation/prediction areas of `runtime/avrai_runtime_os/*`
- BHAM-specific seed data, place-graph inputs, and launch constants in bounded config/data files
- BHAM-specific test fixtures and launch-gate tests in the existing test tree
- BHAM admin app packaging/bootstrap work in `apps/admin_app/*`
- BHAM admin shared implementation only where still required by the current transition path under `apps/avrai_app/lib/apps/admin_app/*`

### Separation rule

Separate by **configuration, data, and feature boundaries**, not by creating a second product.

Good separation:

- BHAM city profile files
- BHAM priors
- BHAM launch constants
- BHAM-specific tests
- BHAM-specific docs
- BHAM admin shell entry/bootstrap in `apps/admin_app/*`

Bad separation:

- second Flutter app for the same user beta
- second runtime implementation for beta only
- second admin implementation for beta only
- duplicate onboarding/discovery/chat stacks that later need merge-back

### Admin migration rule

For BHAM wave 1:

- treat `apps/admin_app/*` as the canonical admin application boundary
- avoid growing a second independent admin product inside the consumer app
- if a BHAM admin change must touch `apps/avrai_app/lib/apps/admin_app/*`, treat it as transitional implementation work that should converge toward the standalone admin app rather than stay permanently nested
- do not duplicate the same admin feature in both locations

### Exception rule

Only create a separate project if the beta were testing a fundamentally different product, backend, legal model, or architecture. BHAM wave 1 is not that. It is the same product under a tightly scoped launch contract, so it belongs in the main files.

### Post-beta return item

After BHAM wave 1 is built and stabilized, return to the admin and consumer bootstrap structure.

Required follow-up:

- extract the duplicated DI/bootstrap composition graph out of `apps/admin_app/*` and `apps/avrai_app/*`
- move shared service-registration/composition code into a lower shared repo boundary
- keep `apps/admin_app/*` as a thin admin-specific bootstrap and UI shell
- keep `apps/avrai_app/*` as a thin consumer-specific bootstrap and UI shell
- do not allow long-term parallel maintenance of two near-identical app bootstrap graphs

This is **not** a BHAM wave-1 blocker, but it is an explicit post-beta architecture return item.

## 6. Explicit Launch Blockers And Required Artifacts

Wave 1 is blocked until these items are explicit in checked-in form.

### 6.1 Copy and legal signoff

Required artifact:

- final onboarding and consent signoff that confirms the product draft copy can be implemented exactly or marks the approved changes explicitly

This includes:

- questionnaire prompt wording
- helper text
- loading copy
- walkthrough copy
- consent copy
- permissions explainer copy
- first daily-drop intro copy

### 6.2 Approved-device matrix

Required artifact:

- exact iPhone and Android model list approved for wave 1

Until the exact model list exists, the temporary execution rule is:

- unsupported devices may not be admitted to the beta
- capability failure in BLE, background execution, storage, or on-device model install is a beta-enrollment blocker

### 6.3 Relay policy constants

Required artifact:

- final BHAM relay policy

Execution default to build now:

- standard user-visible chat, creation, and mutation relay TTL: 24 hours
- event-scoped relay TTL: event end plus 2 hours, capped at 24 hours
- compatibility signals, admin receipts, kernel summaries, and similar control payloads: 6 hours
- retries on route change plus `1m / 5m / 15m / 60m` backoff
- relay queue cap: `256 payloads` or `16 MB` per device, whichever comes first
- trim oldest low-priority summary or control payloads before user-visible chat or creation payloads

### 6.4 Offline footprint budget

Required artifact:

- explicit storage budget for:
  - Birmingham map and place graph
  - model pack
  - cached objects
  - message history
  - queue state

### 6.5 Admin authentication and audit

Required artifact:

- secure admin app access control definition
- immutable audit handling for break-glass and quarantine

### 6.6 Contradiction, quarantine, and reset policy

Required artifact:

- explicit evidence weighting across peer, locality, and admin evidence
- explicit quarantine threshold
- explicit reset threshold

Execution default to build now:

- quarantine on malicious, impossible, contradictory, duplicated, spammy, or safety-risky relay or agent truth
- require human admin review for dangerous or ambiguous cases
- treat about 30% externally checkable false outward truth as reset-grade unless human admin intervenes sooner

### 6.7 BHAM simulation baseline

Required artifact:

- Birmingham city profile and friction assumptions
- Birmingham POI ingestion and place-graph seed inputs
- synthetic population mix representing the wave-1 cohort
- exported prior artifacts for runtime consumption
- acceptance criteria for locality and recommendation seed quality

### 6.8 BHAM launch-gate instrumentation

Required artifact:

- explicit metric definitions and data sources for:
  - AI2AI success-time percentage
  - offline-first flow completion
  - admin-view continuity
  - recommendation action rate
  - locality stability

## 7. Immediate Order Of Operations

Start here. This is the required order of operations for getting to a working BHAM beta with the least rework.

1. lock the authority set
2. resolve or explicitly default every launch blocker in Section 6
3. build the BHAM simulation baseline and export Birmingham priors
4. normalize shared contracts before new feature behavior lands
5. wire shell bootstrap as a hard prerequisite after auth
6. complete onboarding, consent, permissions, and first daily drop
7. complete discovery, objects, profile, settings, and recommendations
8. complete creation, messaging, offline runtime, and AI2AI transport
9. complete admin, governance, falsity, and break-glass behavior
10. run the BHAM-specific gate and treat it as the only launch-ready authority

What not to do first:

- do not start with post-beta OS platformization
- do not start with broad ontology work beyond beta needs
- do not polish admin visuals before readback contracts exist
- do not add more beta-critical flows on top of ad hoc result types
- do not tune BHAM locality or recommendations before Birmingham priors exist
- do not treat the existing broader beta gate as sufficient for BHAM wave 1

## 8. Ordered Build Plan

### Wave 0: Authority, blockers, and defaults

Objective:

- eliminate ambiguity before large implementation work starts

Build items:

- treat this document as ordered execution authority
- treat the BHAM packet as product contract
- treat `work/docs/agents/status/status_tracker.md` as progress authority
- resolve or explicitly default every blocker from Section 6
- define a BHAM-specific gate instead of relying only on the broader beta gate
- map all planned work to prong-specific milestones before parallel execution starts

Exit criteria:

- blockers are resolved or explicitly defaulted
- execution ownership is assigned
- BHAM gate definitions are written down

### Wave 1: BHAM simulation and seed truth

Objective:

- ensure Birmingham discovery, locality, and early learning are seeded from Birmingham-shaped priors rather than borrowed city priors

Explicit build items:

- add Birmingham as a first-class simulation city
- seed the Birmingham place graph from real BHAM POI inputs
- define the synthetic population mix around the intended BHAM cohort:
  - friends, family, and strangers
  - mixed life stages
  - Birmingham metro and suburban movement patterns
- run the BHAM simulation pass
- export reusable prior artifacts for runtime use
- wire those artifacts into runtime paths that depend on seeded priors
- keep all synthetic priors subordinate to real beta behavior once live observations accumulate

Exit criteria:

- Birmingham prior artifacts exist and are checked in or reproducibly generated
- runtime can consume BHAM priors without re-running simulation at app startup
- Birmingham locality and discovery seed quality no longer rely on non-Birmingham city priors

### Wave 2: Shared contracts and headless OS mediation

Objective:

- stop contract drift before more beta-critical flows are built

Explicit build items:

- introduce `OsBackedFlowResult<T>` for all beta-critical user and admin success paths
- extend `KernelEventEnvelope` with:
  - primary slice id
  - related slice ids
  - transport route metadata
  - BHAM-safe provenance fields for admin inspection
- add `TransportRouteReceipt`
- add `DailyDropSet`
- add typed message-thread and retention-policy models
- add `RealitySliceDescriptor`, but keep it minimal and beta-driven
- normalize beta-critical flows to the shared result shape:
  - onboarding
  - recommendations
  - discovery actions
  - creation
  - chat
  - feedback
  - recovery
  - admin inspect or readback
- expose restored-versus-live headless OS state app-wide after auth

Exit criteria:

- no new beta-critical flow uses an ad hoc result shape
- app shell can always report whether the headless host is restored or live

### Wave 3: onboarding, consent, permissions, and first daily drop

Objective:

- deliver the exact BHAM first-run experience and data contract

#### 3.1 Onboarding sequence

Build this exact order:

1. login and account creation
2. mandatory questionnaire
3. privacy and beta consent
4. permissions
5. optional bridges
6. knot or DNA generation
7. walkthrough
8. first daily drop

Supported entry paths:

- email
- Apple
- Google

Onboarding completion definition:

1. account exists
2. consent is recorded
3. minimum usable permissions are granted
4. optional bridges are either connected or skipped
5. knot or DNA is generated
6. walkthrough is completed or skipped
7. first daily-drop screen is shown

#### 3.2 Questionnaire build contract

Build these direct mandatory topics:

- goals
- interests
- values
- what the user wants more of
- what the user wants less of
- favorite places
- spending preference
- how the user gets around
- what the user does for fun or wants to do for fun
- whether the user is more introverted, extroverted, or in the middle
- final freeform bio

Do not ask directly in beta:

- exact routine
- exact time-of-day patterns
- exact social style beyond the broad introvert/extrovert positioning
- exact energy patterns
- who the user goes with
- comfort with strangers
- exact homebase if location inference is available

Off-limits prompts in beta:

- explicit routine interrogation
- illegal activity
- comfort with strangers
- sexuality
- exact address
- exact household composition

Hard max:

- 20 questions total

Target range:

- 10-12 direct prompts plus bridge or permission steps

Suggested direct question order to build:

1. `What do you want more of right now?`
2. `What do you want less of right now?`
3. `What matters most to you these days?`
4. `What are you naturally drawn to?`
5. `What do you do for fun, or wish you did more often?`
6. `Name a few places, kinds of places, or vibes you already enjoy.`
7. `What are you working toward right now?`
8. `How do you usually get around?`
9. `What kind of spending feels right for a normal plan?`
10. `Which feels most like you?`
11. `Tell AVRAI anything you want it to know about you.`

Build the helper text from `09_ONBOARDING_QUESTIONNAIRE_AND_CONSENT_COPY.md` exactly for these prompts.

The short bio must be the last questionnaire step before DNA sequencing and knot creation.

#### 3.3 Consent and permissions build contract

Consent requirements:

- user must scroll through and consent to privacy and beta terms
- consent is logged into agent knowledge
- consent surface is dedicated, not hidden behind generic legal copy

Privacy text must explain:

- what stays on device
- what flows through the air gap
- what admin can and cannot see
- break-glass conditions for dangerous or malicious behavior
- air-gap strength controls
- admin sharing as a necessary beta condition, not a full opt-out

Build these exact copy surfaces from the BHAM packet:

- loading title: `Building your knot`
- walkthrough framing: `AVRAI works best when you live your life, not when you stay on your phone.`
- walkthrough points for `Daily Drop`, `Explore`, `AI2AI`, `Your agent`, and `Privacy`
- consent title: `Birmingham beta consent`
- consent intro and all 8 consent sections
- consent checkbox copy
- continue button copy
- permissions title and intro
- per-permission explainer copy
- first daily-drop header `Your first doors`
- first daily-drop body copy

#### 3.4 Permissions model

Intended full beta mode:

- precise location
- background location
- Bluetooth
- calendar
- health/activity data
- passive dwell/movement sensing

Helpful but optional:

- notifications
- social bridges

Not required:

- contacts
- camera/photo library
- microphone

Permission behavior rules:

- show a permissions explainer page before the sheet
- show the permission sheet once
- no account-creation hard block for optional features
- if a permission is removed later, the app must adapt instead of breaking
- local-only personal learning never stops
- Bluetooth off disables Bluetooth AI2AI, but local Wi-Fi or other approved local transports can still carry exchange when available

#### 3.5 Identity rules

- one account per human in beta
- one primary device per account in wave 1
- pseudonymous toward admin by default
- display name is for user/community-facing surfaces, not default admin visibility
- admin must never see names, numbers, addresses, social handles, or linked account identity by default

Exit criteria:

- onboarding order matches BHAM exactly
- questionnaire content rules are enforced
- consent, permissions, and identity behavior match BHAM exactly
- first daily-drop screen is shown as the onboarding completion state

### Wave 4: discovery, objects, profile/settings, and recommendations

Objective:

- deliver the core everyday user loop after onboarding

#### 4.1 Primary app structure

Build this structure:

- `Daily Drop` as the first destination after onboarding
- `Explore` for map/list discovery across all 5 object types
- `Profile` as the top-left entry
- `Chat` as the top-right entry
- bottom navigation prioritizing `Daily Drop` and `Explore`
- `Explore` supporting map/list toggling across all 5 categories
- category reselection giving fast access to saved objects for that category

#### 4.2 Daily Drop contract

Build exactly:

- 5 items per drop
- exactly 1 item from each category:
  - `spot`
  - `list`
  - `event`
  - `club`
  - `community`
- if a category is empty:
  - the system may suggest creation
  - lists may be AI-generated
- drops refresh around the human's learned start-of-day
- old drops disappear when refreshed
- repetition window is at least 1 week unless new truth justifies repetition
- a good daily drop means the user saves at least one item

#### 4.3 Object model to build

`Spot`

- any place where humans can go and do things
- user, model, or future business origin
- public or private
- users can update lived vibe by going there and behaving there
- users can save/respect/share
- admin sees health, vibe/DNA/pheromones, and locality/kernel context

`List`

- collection of spots
- any user can create
- public or private
- discoverable through list surfaces, sharing, and AI suggestion
- learning updates from creation, viewing, saving, sharing, and real-world follow-through
- admin sees creation, uptake, trust/safety, and interaction patterns

`Club`

- recurring activity with place and time
- any user can create
- public or private
- members can join, chat, suggest branches, and participate
- leadership is a capability, not a separate account type
- admin sees participation, attendance patterns, success, and risks

`Community`

- shared-interest social group
- any user can create
- usually public, can be private
- supports conversation, meetups, and community-driven activity
- can host events
- admin sees community identity, member agents, growth, vibe, and safety posture

`Event`

- time-bound organized happening at a spot
- any user can create
- communities and clubs can also create
- users can RSVP, learn, attend, cancel, edit, and share based on permissions
- learning updates from RSVP, attendance, dwell, follow-up, and overlap with other humans
- admin sees attendance, actual turnout, safety warnings, and learning outcomes

#### 4.4 Profile and settings surfaces

Build settings controls for:

- AI2AI participation
- BLE discovery
- background sensing
- health/calendar/social bridges
- notification categories
- direct user matching
- online vs offline AI preference
- air-gap strength model

Build reset and cleanup actions for:

- reset recommendations
- reset agent from locality baseline
- disconnect bridges
- clear chat history
- leave clubs/communities
- delete saved items
- explicit delete-account semantics

Build profile surfaces for:

- knot/DNA avatar
- behavior timeline
- pheromone surfaces
- AI2AI daily success count
- short self-summary

#### 4.5 Recommendation behavior

Every recommendation card/detail must show:

- one-sentence why
- projected enjoyability percentage
- save
- dismiss
- more like this
- less like this
- why did you show this

Recommendation behavior rules:

- no low-confidence proactive baseline
- consult locality or higher-order model first when uncertain
- stay silent when still uncertain
- weight real-world attendance and repeat behavior above taps
- include a direct "meaningful/fun" ask-back loop tied to the recommendation/outcome pipeline

#### 4.6 Creation behavior

Build queue-safe creation for:

- `spot`
- `list`
- `club`
- `community`
- `event`

Creation rules:

- offline-first
- sync later when necessary
- immediate public create by default
- moderation pause or quarantine if dangerous, illegal, harmful, or trust-breaking
- future-note surfaces for business ownership and expert emergence may exist but must not turn them into wave-1 roles

Exit criteria:

- daily drop is exact
- `Explore` supports all 5 categories
- profile/settings controls exist and adapt correctly
- recommendation behavior matches BHAM
- creation flows are queue-safe and moderation-aware

### Wave 5: messaging, offline runtime, AI2AI, and data contract

Objective:

- make BHAM useful and trustworthy when the internet is absent

#### 5.1 Day-1 messaging surfaces

Build these threads:

- user ↔ personal AI chat
- user ↔ admin chat
- user ↔ matched-user direct chat
- club chat
- community chat
- event chat
- club/community leader announcements
- AI/admin summary surfaces in the admin app

#### 5.2 Message retention and visibility

Retention windows to build:

- personal AI chat: 4 weeks or until context reset
- user/admin chat: 2 weeks
- direct matched chat: 4 weeks
- club chat: 4 weeks; pinned message may remain
- community chat: 4 weeks; pinned message may remain
- event chat: ephemeral after the event; pinned leader message allowed until event ends

Messaging rules:

- human chats are human chats, not AI-authored content
- participants may leave chats
- matched-user chat begins with privacy-preserving presentation such as initials before fuller voluntary disclosure
- admin sees tuples and agent-safe operational context, not direct human identity by default

#### 5.3 Notification contract

Build this exact behavior:

- daily-drop, context-nudge, and AI2AI-compatibility notifications capped at 3 per day total
- human message notifications are not capped
- default quiet hours `10pm-6am`
- quiet hours later become personalized by agent learning
- if uncertain, prefer higher-level consultation, then silence/observation, then later daily-drop or explicit user ask

#### 5.4 Direct user matching rule

Build the exact rule:

- no casual direct 1:1 meetup baseline
- only extremely high-confidence compatibility may trigger a match flow
- threshold about `99.5%+`
- both users receive a privacy-preserving prompt
- both can say yes or no independently
- in-app chat opens only if both say yes
- if one says no, the other receives a gentle decline/encouragement response

#### 5.5 Offline and AI2AI transport contract

Offline means:

- not dependent on internet/service

Offline-first includes:

- on-device kernels and personal-agent learning
- BLE exchange
- local Wi-Fi bridge/relay
- true peer propagation and store-and-forward over local network paths
- later wide-area online sync as a secondary assist

Day-1 local transport paths:

- BLE
- local Wi-Fi
- nearby relay/store-and-forward through other devices
- wormholes as backup for longer-range message delivery

Routing policy to build:

- prefer BLE/local Wi-Fi for nearby live low-latency exchange
- prefer wormholes for longer-range or deferred store-forward when available
- if wormholes are unavailable, nearby relay/direct paths remain valid backup paths

#### 5.6 Relay rules

Build these exact behaviors:

- intermediate devices may relay data they did not originate
- user-to-user chat may travel through nearby agents when internet is unavailable
- all inbound data passes through air-gap intake
- all outbound data passes through air-gap export
- if a device is only relaying, export may pass directly from intake after policy checks

Payloads allowed to relay:

- spot updates
- event/club/community/list metadata
- place vibes/DNA/pheromones
- locality priors and updates
- chat messages
- compatibility signals
- admin receipts
- kernel summaries
- tuples and other learned agent-safe information

Payloads that must never be relayed raw:

- direct human private data
- names, numbers, addresses, social handles
- direct linked account identity
- any payload not air-gap filtered for device-to-device movement

Intermediate device storage rule:

- relay payloads live only long enough to reach the next path
- after successful relay, only tuple-like learning consequences may remain locally
- intermediate relay payloads are not durable user-visible history

#### 5.7 Required on-device data

Must live on device:

- Birmingham place graph priors and evolving place knowledge
- map data/tiles needed for Birmingham usage
- saved spots/lists/clubs/communities/events
- chats and message history
- kernel state
- learning history and tuples
- AI2AI receipts
- offline SLM/model pack
- locality priors and DNA/vibe baselines
- queued message and creation mutations

Daily-drop candidates should be remembered for learning and continuity, but do not need to remain a long-lived user-visible archive.

#### 5.8 Isolated single-device contract

If there is no internet, no nearby peers, and no local relay path, the device must still:

- continue personal learning
- serve recommendations from on-device kernels and routines
- show local map/discovery from what the device knows
- preserve and use saved objects
- support offline AI chat if the SLM is installed
- allow creation
- queue outbound messages and updates for later transport

When connectivity returns, the system should sync:

- agent state consequences
- locality updates
- tuples and learning receipts
- queued creation and messaging
- AI2AI/admin-visible receipts

#### 5.9 Conflict resolution

World change while offline:

- canceled events become canceled on sync
- edited events apply on sync
- place vibe changes become the new truth
- when possible, the app surfaces why/how the vibe changed
- if the change is older than 1 year, surface that time context when relevant

Conflicting agent learnings:

- conflicting learnings can coexist as parallel knowledge
- personal agents continue doing what is best for their own human
- conflicts rise upward to locality and above for abstraction or conviction formation
- resolved higher-order convictions may flow back down as learned lenses

Exit criteria:

- offline-first works without internet
- queueing and later sync work for create and chat
- AI2AI and relay policy are deterministic and enforced
- direct match and notification behavior match BHAM exactly

### Wave 6: admin, governance, truth, and safety

Objective:

- make the supervised beta safe, inspectable, pseudonymous-by-default, and operationally real

Explicit carry-forward note from Wave 5:

- Wave 5 already emits communication summaries, route receipts, delivery failures, and direct-match outcomes in runtime contracts
- those contracts do not count as complete launch work until the standalone admin app renders them in BHAM day-1 screens
- Wave 6 must consume those runtime outputs directly in `apps/admin_app`; this work is required, not optional follow-up

#### 6.1 Admin boundary

- the admin app is separate from the user app
- access is only through the secure admin app
- admin is required on day 1

#### 6.2 Day-1 admin surfaces

Build these exact surfaces:

- live Birmingham map
- AI2AI exchange map/layer
- user-agent health list
- single-agent detail view
- locality-agent detail view
- kernel health dashboard
- flagged content / flagged agent queue
- creation moderation queue
- iOS vs Android health dashboard
- beta feedback inbox
- reality-model chat
- learning/recommendation audit trail
- event/list/community/club explorer
- notifications / incidents center

#### 6.3 Admin visibility rule

Admin may see:

- agents
- kernels
- tuples
- operational math
- projections
- success rates
- locality and reality-model learning

Admin may not see by default:

- names
- phone numbers
- addresses
- social handles
- linked account identity

Beta consent must explicitly cover agent-level visibility.

#### 6.4 Break-glass rule

- break-glass exists only for dangerous, malicious, illegal, hacking, or trust-breaking situations
- AI cannot break glass
- human admin is the final authority
- break-glass must be explicitly audited

#### 6.5 Governance truth vs behavior truth

Governance truth has highest authority for:

- safety
- quarantine
- rollback
- abuse/trust decisions
- policy constraints

Order of governance authority:

1. human admin / reality-model governance
2. lower governance layers according to model hierarchy

Behavior truth has highest authority for learning what the human actually likes or does:

1. the human's direct real-world behavior
2. direct same-place/same-time nearby exchange
3. relayed agent-safe AI2AI information
4. locality priors
5. preload/simulation priors

Strong reality-model convictions may flow downward as learned lenses or constraints. They do not automatically force a user-facing behavior change unless safety or governance requires it.

#### 6.6 Public creation and moderation

- public lists/clubs/communities/events go live immediately
- the system may flag/pause dangerous, illegal, harmful, or trust-breaking creations
- if paused, the creator should be able to explain through admin chat
- admin may quarantine or remove users, agents, spots, lists, clubs, communities, or events as needed

#### 6.7 Quarantine rules

Relay or learned information must be quarantined when it is:

- malicious or a hacking attempt
- impossible or internally contradictory
- too far outside locality context without support
- duplicated/spammy
- safety-risky or suspicious enough to require admin review

#### 6.8 Agent falsity rule

An agent is materially false when its shared outward truth is false at meaningful scale in external kernel comparison.

Operational beta rule:

- peer/locality consensus can place an agent in quarantine
- human admin review can rollback or reset
- direct human report through admin chat counts as valid evidence
- about 30% of externally checkable shared information being false is reset-grade

Examples:

- invented places
- invented clubs/communities/events/lists
- fabricated outward knowledge shared through the network

If reset happens:

- trust for the false agent drops to zero
- the failed kernels/mind state remains available for study in admin

#### 6.9 Strong conviction rule

- sparse data is allowed
- strong conviction from sparse data is not
- grounded vibe/DNA for places/clubs/communities/events requires:
  - about 2 weeks of consistent real-world behavior, or
  - 3 real events/meetups/outings

Exit criteria:

- admin views exist and are continuously available
- pseudonymous default rendering is enforced
- break-glass audit is real
- quarantine, falsity, and conviction rules are built and testable

### Wave 7: testing, evidence, fallbacks, and launch gate

Objective:

- prove the BHAM beta is working, safe, and launch-ready

#### 7.1 Success signals

Usage:

- average open rate target: `1-2 times per day`
- real-world acted-on suggestion target: `0.5x-2x per week`

Positive outcomes:

- save/respect
- click-through
- route/open
- RSVP yes
- real attendance
- meaningful dwell
- return visits
- joining a club/community
- chat reply
- positive AI2AI exchange
- explicit positive user feedback

Negative outcomes:

- dismiss/hide
- RSVP no
- no-show
- leaving early
- muting or blocking
- unsafe report
- bad vibe or bad chat result
- excessive phone engagement caused by the app

Strongest truth signals:

- real-world attendance beats taps
- repeat visits beat one-time saves
- explicit user correction beats model guess

Meaningful/fun signal:

- ask the user directly
- combine that answer with pre-existing signals
- keep meaning/fun as an inference, not a permanent absolute fact

#### 7.2 Required tests and evidence

Add or align tests for:

- explicit Wave 6 carry-forward validation:
  - run full monorepo beta validation, not only targeted Wave 6 admin/runtime checks
  - treat any regression outside the touched Wave 6 surface as a Wave 7 launch blocker until resolved
  - do not mark launch-ready based only on targeted admin-app verification
- launch-pack onboarding path and mandatory questionnaire logic
- settings toggles and runtime adaptation behavior
- direct-match double-opt-in gating
- offline queueing and later relay/sync conflict handling
- relay quarantine and falsity thresholds
- admin-surface smoke coverage for BHAM must-have views
- every beta-critical flow emitting `KernelEventEnvelope` plus `RealityKernelFusionInput` or `KernelGovernanceReport`

Collect evidence for:

- offline-first flow completion
- AI2AI success-time percentage
- continuous admin-view uptime
- recommendation action rates
- locality stability

Explicit deferred execution note:

- the consumer Wave 7 gate and BHAM heavy consumer suite are passing, but final launch snapshot export is intentionally deferred until the standalone admin app is built and running in a real operator session
- when admin app build/run is available, the next required sequence is:
  - open `Launch Safety` in `apps/admin_app`
  - export `runtime_exports/bham_launch_snapshot.json`
  - run `dart run work/tools/generate_bham_launch_report.dart`
  - use the generated launch report as the canonical human go/no-go packet
- do not treat the launch report path as complete until that exported snapshot exists and the report has been generated from it

#### 7.3 Expansion gates

Do not expand beyond 25 users unless all of the following are true:

1. no Sev-1 incidents for 14 straight days
2. zero confirmed harmful/illegal/trust-breaking suggestions
3. AI2AI connections are successful for at least 80% of beta time and no cross-platform regression remains open
4. recommendation action rate stays in target band and at least 50% of testers engage with at least one recommendation weekly
5. personal agents are coherent for at least 80% of testers
6. Birmingham locality outputs stay directionally correct for 14 days
7. all critical admin views work continuously for 14 days without breaking
8. no flagged-item queue is older than 24 hours for 14 days
9. at least 70% of testers would keep using the app weekly
10. at least 60% say it helps them find better places/people/events
11. at least 80% of testers complete a meaningful offline-first flow

#### 7.4 Fallback matrix to build

On-device chat / SLM fails:

- fall back to online

AI2AI BLE/system-wide local exchange fails:

- full beta pause if system-wide and unexplained
- single-user/local dropouts tolerated as non-global incidents

Background sensing unreliable:

- pause only that feature
- if systemic across multiple users, pause globally and alert admin

Offline recommendation quality weak:

- keep place recommendations and discovery alive
- reduce/avoid direct social-match behavior
- prefer safer browse/daily-drop behavior until quality improves

Admin observability degraded:

- stop new learning in the affected scope
- preserve existing state

Public creation abused/flooded:

- quarantine creation until review

Locality learning unstable:

- pause locality learning
- keep on-device personal learning and admin oversight

Direct user-to-user compatibility looks risky:

- pause only that feature

#### 7.5 Edge cases that must be built for

Fully isolated user:

- still learns
- still suggests from on-device truth
- still preserves saved state
- still allows creation
- queues messages and sync work

Delayed sync conflict:

- the world can change while the device remains useful
- event cancellation/edit reconciles cleanly
- changed place vibe becomes the new truth with explanation
- conflicting learnings coexist until higher-order abstraction resolves them

Malicious or poisoned relay:

- quarantine locally
- share upward to locality/admin
- inspect why/how/when/where/what/who at admin
- reset trust if the agent is false enough to justify reset

Sparse-data wrong inference:

- do not treat sparse data as settled conviction
- require a grounding window before strong place/community/club/event DNA claims

Safety-sensitive social action:

- no casual direct 1:1 meetup suggestion baseline
- use public-place or public-event overlap as the safer default
- only the high-confidence double-opt-in path is allowed for direct contact

Exit criteria:

- BHAM-specific tests exist
- BHAM-specific evidence exists
- BHAM expansion gates are measurable
- fallback and edge-case behavior are implemented, not just documented

## 9. Explicit Wave-1 Done Definition

Wave 1 is ready when all of the following are true:

- onboarding follows the BHAM sequence and logs BHAM consent correctly
- questionnaire, consent, permissions, loading, walkthrough, and first daily-drop copy are implemented exactly as approved
- daily drop always returns exactly 5 items with 1 per category
- `Explore` supports all 5 object types
- create flows for all 5 object types work offline and reconcile later
- required AI and human chat surfaces exist and obey retention rules
- isolated single-device mode still learns, recommends, preserves state, and queues work
- Birmingham prior artifacts exist and BHAM locality/discovery are no longer borrowing non-Birmingham city priors
- admin surfaces remain pseudonymous by default and cover all BHAM day-1 views
- AI2AI reliability, recommendation action, admin continuity, and offline-first completion meet BHAM launch-gate thresholds
- business and expert features remain explicitly non-gating and out of the default beta path

## 10. Explicit Non-Goals

These items are not wave-1 goals:

- Phase 12 platformization
- third-party integrator APIs
- SDK/distribution work
- business/expert first-class role launch
- casual 1:1 direct social suggestion baseline
- internet-dependent architecture
- broad ontology work that does not serve beta admin/readback, routing, moderation, or audit
- whole-repo cleanup beyond the contract stabilization required to ship BHAM

## 11. Wave 8 Direction

Wave 8 is the next build wave after Wave 7 consumer gate completion.

Wave 8 should not begin with broad data scraping or a loose simulator. It should begin with the kernel/governance substrate and then move into the authoritative BHAM replay path.

### 11.1 Wave 8 scope

Wave 8 should lock:

1. `when` as the single timing authority
2. full native authority for the beta-used core kernels and required governance lanes
3. authoritative Birmingham-only replay
4. replay contracts, provenance, and completeness scoring
5. an engine-native forecast or prediction kernel
6. governance over prediction outputs
7. higher-agent upward and downward truth flow over replay and forecast results

### 11.2 Authoritative replay rule

For BHAM launch and Wave 8, the authoritative replay path is Birmingham-only.

Rules:

1. Birmingham is the canonical replay and training geography
2. legacy multi-city simulation work may remain only as research or future-expansion material
3. non-Birmingham simulations must not be treated as the BHAM launch replay baseline

### 11.3 Prediction placement rule

Prediction should exist as a real kernel, but it is not itself a governance kernel.

Correct placement:

1. forecast or prediction kernel belongs in the Reality Model / engine lane
2. runtime OS consumes and governs prediction outputs
3. governance evaluates validity, freshness, contradiction, and actionability
4. live reality remains the final authority

### 11.4 Operating flow

The product should operate as:

1. app captures input and renders results
2. runtime OS hosts and governs kernel execution
3. engine owns cognition, replay evaluation, forecast logic, and higher-agent reasoning
4. the personal reality agent is the only layer that speaks to the human
5. locality, city, and top-level reality agents reason upward and downward through runtime-governed flow

### 11.5 Immediate next build order

The next execution order is:

1. finish native-completing the beta-used governance lanes
2. keep replay and simulation timing under the `when` authority
3. keep the authoritative replay runner Birmingham-only
4. define replay contracts and completeness scoring
5. add the forecast kernel
6. add governance projections over forecast outputs
7. connect replay outputs into forecast training and admin inspection

Wave 8 seed-ingestion note:

1. the first governed 2023 source pack now exists at `Bham simulation/08_BHAM_REPLAY_SOURCE_PACK_2023_SEED.json`
2. the first normalized observation artifact now exists at `Bham simulation/08_BHAM_REPLAY_NORMALIZED_OBSERVATIONS_SEED_2023.md`
3. the first governed raw-source pull plan now exists at `Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.md`
4. the first manual-import template batch now exists at `Bham simulation/10_BHAM_REPLAY_MANUAL_IMPORT_TEMPLATES.md`
5. the first priority manual-import scaffold now exists at `Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_IMPORT_BUNDLE_2023.md`
6. the first populated priority manual source pack now exists at `Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_SOURCE_PACK_2023.json`
7. the first priority normalized observation artifact from real 2023 inputs now exists at `Bham simulation/13_BHAM_REPLAY_NORMALIZED_OBSERVATIONS_PRIORITY_2023.md`
8. the first citywide cultural seed bundle now exists at `Bham simulation/14_BHAM_CITYWIDE_CULTURAL_SEED_BUNDLE_2023.md`
9. the first citywide cultural normalized observation artifact now exists at `Bham simulation/15_BHAM_CITYWIDE_CULTURAL_NORMALIZED_OBSERVATIONS_2023.md`
10. the first historical citywide archive bundle now exists at `Bham simulation/16_BHAM_HISTORICAL_CITYWIDE_ARCHIVE_BUNDLE_2023.md`
11. the first historical citywide normalized observation artifact now exists at `Bham simulation/17_BHAM_HISTORICAL_CITYWIDE_NORMALIZED_OBSERVATIONS_2023.md`
12. the first citywide spatial import scaffold now exists at `Bham simulation/18_BHAM_CITYWIDE_SPATIAL_IMPORT_BUNDLE_2023.md`
13. the first partial citywide spatial source pack now exists at `Bham simulation/19_BHAM_CITYWIDE_SPATIAL_SOURCE_PACK_2023.json`
14. the first partial citywide spatial normalized observation artifact now exists at `Bham simulation/20_BHAM_CITYWIDE_SPATIAL_NORMALIZED_OBSERVATIONS_2023.md`
15. the first operational public-catalog historicalization candidate artifact now exists at `Bham simulation/29_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_CANDIDATES_2023.md`
16. the public-catalog historicalization bundle now exists at `Bham simulation/30_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_BUNDLE_2023.md`
17. the first safe-subset public-catalog historicalized source pack now exists at `Bham simulation/31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.md`
18. the first safe-subset public-catalog historicalized normalized observation artifact now exists at `Bham simulation/32_BHAM_PUBLIC_CATALOG_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.md`
19. the first neighborhood-association calendar source pack now exists at `Bham simulation/33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.md`
20. the first neighborhood-association calendar normalized observation artifact now exists at `Bham simulation/34_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_NORMALIZED_OBSERVATIONS_2023.md`
21. the first source-reality audit now exists at `Bham simulation/21_BHAM_SOURCE_REALITY_AUDIT_2023.md`
22. the first automated replay pull summary now exists at `Bham simulation/22_BHAM_REPLAY_AUTOMATED_PULL_SUMMARY_2023.md`
23. the first historicalized automated replay source pack now exists at `Bham simulation/23_BHAM_REPLAY_HISTORICALIZED_SOURCE_PACK_2023_AUTOMATED.json`
24. the first replay-admissible automated normalized observation artifact now exists at `Bham simulation/24_BHAM_REPLAY_AUTOMATED_NORMALIZED_OBSERVATIONS_2023.md`
25. the first official city and major-venue 2023 event bundle now exists at `Bham simulation/25_BHAM_OFFICIAL_CITY_EVENT_BUNDLE_2023.md`
26. the first normalized official city event replay artifact now exists at `Bham simulation/26_BHAM_OFFICIAL_CITY_EVENT_NORMALIZED_OBSERVATIONS_2023.md`
27. the historical community archive extension bundle now exists at `Bham simulation/27_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_2023.md`
28. the normalized historical community archive extension artifact now exists at `Bham simulation/28_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_NORMALIZED_OBSERVATIONS_2023.md`
29. the first consolidated BHAM replay-year source pack now exists at `Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.md`
30. the first consolidated BHAM replay-year normalized observation artifact now exists at `Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.md`
31. the first governed BHAM replay execution plan now exists at `Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.md`
32. the first governed BHAM replay execution summary now exists at `Bham simulation/38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.md`
33. the first governed BHAM replay forecast batch now exists at `Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.md`
34. the first replay-only BHAM virtual world environment now exists at `Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md`
35. the first higher-agent replay rollups now exist at `Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.md`
36. the first historicalized Eventbrite / Meetup community-anchor source pack now exists at `Bham simulation/42_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_SOURCE_PACK_2023.md`
37. the first historicalized Eventbrite / Meetup normalized observations now exist at `Bham simulation/43_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.md`
38. the first replay higher-agent behavior pass now exists at `Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.md`
39. the first full single-year BHAM replay pass now exists at `Bham simulation/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.md`
40. the replay now has finalized realism artifacts:
   - `Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.md`
   - `Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.md`
   - `Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.md`
   - `Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.md`
   - `Bham simulation/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.md`
   - `Bham simulation/55_BHAM_REPLAY_ACTION_EXPLANATIONS_2023.md`
   - `Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.md`
   - `Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md`
   - `Bham simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md`
   - `Bham simulation/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.md`
   - `Bham simulation/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.md`
   - `Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.md`
   - `Bham simulation/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json`
41. these are no longer only scaffolds; they are now the first finalized governed single-year BHAM replay outputs for 2023
42. the replay path now has an explicit isolation boundary:
   - replay namespace is distinct from live runtime namespace
   - runtime mutation is blocked
   - live ingress is blocked
   - app-facing surfaces are blocked
   - only replay-internal services and admin inspection may consume the replay world directly
43. the first full single-year replay pass is now replay-only all the way through:
   - no mesh runtime metadata is carried into the virtual world or single-year pass artifacts
   - no live runtime mutation or app-facing leak path is allowed from the replay world
   - higher-agent behavior is active, but bounded and replay-internal
44. the 2023 truth-year now passes all current realism, calibration, kernel participation, actor-kernel, connectivity, exchange, AI2AI, and training-readiness gates and is accepted as the current Monte Carlo base year, but multi-year expansion is still blocked on storage architecture
45. before any multi-year ingestion or decade Monte Carlo expansion begins, Wave 8 must return to storage architecture and move large replay artifacts out of docs-json-only handling
46. before that storage migration happens, replay storage must prove it does not cross wires with the live app Supabase namespace:
   - replay buckets must remain distinct from live app buckets
   - replay metadata tables must remain outside the app `public` schema
   - replay writes must remain tooling/admin-only and blocked from app-facing paths
47. the first storage implementation step should stage the accepted 2023 replay artifacts into a replay-only export root that mirrors the isolated bucket layout without writing to live Supabase:
   - `runtime_exports/replay_storage_staging/...`
   - replay-prefixed bucket directories only
   - replay export manifests and summaries generated from the accepted 2023 base year
48. the second storage implementation step should partition the largest replay artifacts into semantic chunk files before any real object-storage upload:
   - list-heavy artifacts should be split into chunked `NDJSON`
   - partitions should follow semantic sections such as actors, agendas, actions, traces, connectivity profiles, and exchange logs
   - originals should remain staged locally for provenance until the Supabase upload/index path is finalized
49. the third storage implementation step should build the replay-only Supabase upload/index pipeline on top of the partitioned output:
   - replay metadata must target the `replay_simulation` schema only
   - replay objects must target replay-prefixed buckets only
   - large partitioned artifacts should upload as semantic `NDJSON` chunks, not as one giant blob
   - the first pass may be dry-run only if replay credentials are not yet supplied, but it must still produce a complete upload/index manifest and summary
   - the first governed implementation is captured in `Bham simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md`
   - the required replay schema and bucket migrations are `work/supabase/migrations/091_replay_simulation_storage_v1.sql`, `work/supabase/migrations/092_replay_simulation_training_indices_v1.sql`, and `work/supabase/migrations/093_replay_simulation_training_grade_v1.sql`
50. the fourth storage implementation step should index the replay-only training surfaces into replay-only metadata tables:
   - actor profiles and per-actor full kernel bundles
   - kernel activation traces
   - connectivity profiles and transitions
   - tracked locations, untracked windows, movements, and flights
   - replay exchange threads, participations, events, and AI2AI records
   - action training records, counterfactual choices, outcome labels, truth-decision history, higher-agent intervention traces, variation profiles, and held-out evaluations
   - the first governed dry-run is captured in `Bham simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md`
   - the first movement artifact feeding that index is `Bham simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.md`
   - the first training-grade artifacts feeding that index are `Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.md` and `Bham simulation/69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.md`
51. the storage decision must explicitly define:
   - object storage for large source packs and normalized observation partitions
   - queryable metadata storage for manifests, lineage, completeness, and audit records
   - a viewing layer that is not itself the source of truth
52. multi-year ingestion is blocked until that storage path is explicit and approved

Wave 8 implementation note:

1. the first replay-contract slice should start with four spine contracts:
   - `ReplayTemporalEnvelope`
   - `MonteCarloRunContext`
   - `ReplayYearCompletenessScore`
   - `GroundTruthOverrideRecord`
2. those four are enough to start the real replay/time-truth layer and the first engine forecast-kernel interface
3. they are not the entire final replay system
4. the second tranche should follow immediately after forecast-kernel interface work:
   - `ReplaySourceDescriptor`
   - `ReplayEntityIdentity`
   - `ReplayTruthResolution`
   - `ReplayBranchLineage`
   - `ForecastEvaluationTrace`
   - `AgentLifecycleTransition`
5. once the first consolidated truth-year pack exists, the next best move is to generate a governed replay execution plan and dry-run summary before continuing to expand isolated source lanes
6. once the first governed replay execution plan exists, the next best move is to connect that truth year into forecast-governance and then higher-agent replay behavior rather than continue indefinite isolated source-pack generation
7. once the first governed forecast batch exists, the next best move is to build a replay-only virtual world environment and derive higher-agent rollups from that isolated namespace before attempting multi-year expansion
8. once the first replay-only virtual world and higher-agent rollups exist, the next best move is to activate higher-agent behavior and complete a full single-year replay pass before any multi-year or Monte Carlo expansion
9. once the first full single-year replay pass exists, the next best move is to attach the realism layer:
   - representative population profile
   - canonical place graph
   - isolation report
   - kernel participation report
   - action explanations
   - realism gate report
10. once that realism layer passes, the 2023 truth-year becomes the Monte Carlo base-year candidate
11. even after the realism layer passes, the next best move is still to keep filling 2023 city-truth gaps and finalize storage architecture before any multi-year ingestion
