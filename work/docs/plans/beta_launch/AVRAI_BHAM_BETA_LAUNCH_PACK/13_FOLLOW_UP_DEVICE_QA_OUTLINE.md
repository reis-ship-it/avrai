# Follow-Up Device QA Outline

**Date:** March 15, 2026  
**Status:** Ready  
**Scope:** Follow-up manual beta QA once real phones are available for Birmingham wave-1

## Purpose

This document is the practical phone-availability QA outline for BHAM beta.

Use it after the current implementation and gate work is complete, when you have:
- approved iPhones
- approved Android devices
- test accounts
- enough time to run real-world manual flows

This is not a replacement for the existing launch packet or narrow smoke runbooks.
It is the follow-up execution outline for proving the beta behaves correctly on real phones.
That includes both visible product flows and the system-health behaviors the beta promises:
- on-device kernel stability
- AI2AI mesh/runtime health
- learning registration
- locality / spot truth movement from real behavior

For live phone testing, use the companion master checklist:
- [14_FOLLOW_UP_DEVICE_QA_FIELD_CHECKLIST.md](./14_FOLLOW_UP_DEVICE_QA_FIELD_CHECKLIST.md)

## What This Outline Is For

- turning the existing beta build work into a repeatable device-test plan
- making sure iPhone and Android behavior are both checked before broader tester use
- checking real-world flows that are hard to prove fully in simulator-only work
- collecting evidence and blockers in a consistent way

## Current Pre-Phone Baseline

Before real phones are available, BHAM beta now has a deterministic simulated smoke gate on both platforms.

- Canonical command:
  - `bash work/scripts/proof_run/run_simulated_headless_smoke.sh ios`
  - `bash work/scripts/proof_run/run_simulated_headless_smoke.sh android`
- Expected outputs:
  - proof bundle artifact folder + zip
  - `simulated_smoke_response.json`
  - `validation_summary.json`
- Current expectation before any live-phone QA pass starts:
  - latest iOS simulator smoke is green
  - latest Android emulator smoke is green
  - both validation summaries are `is_valid: true`

This does not replace live-phone QA.
It means live-phone QA should begin from a boring baseline instead of discovering basic orchestration, proof-export, or artifact-shape regressions for the first time on physical devices.

## What This Outline Is Not For

- replacing automated test gates
- replacing the event-planning iOS smoke runbook
- expanding scope into post-beta organizer/business/admin products

## Core Rule

Phase-1 event planning is already complete. That closeout used a real iOS integration smoke plus the targeted gate.

But BHAM wave-1 scope still includes both `iPhone + Android on approved devices only`.

That means:
- Android was acceptable to leave out of the phase-1 completion gate
- Android is not acceptable to leave untested once real phones are available for active beta use

## Minimum Device Matrix

Run at least this set:

1. one approved iPhone
2. one approved Android phone
3. one cross-platform pair for iPhone ↔ Android interaction checks

If available, also run:

1. two iPhones for same-platform AI2AI comparison
2. two Android phones for same-platform AI2AI comparison

Capture for every device:
- device model
- OS version
- app build identifier / git commit if known
- tester account used
- date/time of run

## Preflight Checklist

Before manual QA starts:

- confirm the latest simulated smoke gate is green on both platforms:
  - `bash work/scripts/proof_run/run_simulated_headless_smoke.sh ios`
  - `bash work/scripts/proof_run/run_simulated_headless_smoke.sh android`
- capture the latest artifact folders and validation summaries for both simulated runs
- install the intended beta build on every test phone
- confirm required feature flags/defaults are enabled
- confirm admin oversight surfaces are reachable
- prepare at least:
  - one fresh user account
  - one returning user account
  - one second nearby-user account for AI2AI checks
- prepare evidence capture:
  - screenshots
  - screen recordings if useful
  - log notes
  - proof-run receipts where applicable
  - latest simulated smoke artifact paths
- confirm the relevant oversight/debug views are reachable for:
  - AI2AI activity / mesh health
  - kernel health
  - learning / recommendation audit trail
  - locality / spot truth movement where exposed
- if this QA cycle includes admin/autoresearch, confirm the private control-plane preflight is complete:
  - Supabase migration history aligned with repo
  - private admin gateway deployed on a controlled private host/VM
  - private-mesh-only access with no public ingress
  - gateway-issued sessions with OIDC + MFA and managed-device enforcement
  - server-side redaction and audit logging active
  - brokered open-web blocked by default unless explicitly approved
- confirm the event-planning runbook is available:
  - [BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md](./../easy_event_hosting/BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md)

## Recommended Execution Order

### Pass 1: Install, Launch, Sign-In Sanity

On each device:

1. cold install or clean app state
2. launch app
3. sign up or sign in
4. confirm no blocker crash, broken shell, or permanent spinner

Pass if:
- app launches
- account entry works
- home shell appears

Block if:
- crash on launch
- auth unusable
- app stuck before usable state

### Pass 2: Onboarding, Permissions, Identity

On at least one fresh account per platform:

1. complete onboarding
2. grant expected permissions
3. verify permissions failure paths are understandable
4. confirm user reaches a meaningful first-use state

Pass if:
- onboarding completes end to end
- permissions behave intentionally
- first-use experience is coherent

Focus evidence:
- permission prompts
- denied-permission fallback behavior
- first knot / DNA state exists if surfaced
- first daily drop / first meaningful recommendation
- personal-agent learning has visibly started if a bounded user/debug surface exists

### Pass 3: Core Consumer Discovery

On each platform:

1. open explore
2. inspect spots, lists, clubs, communities, and events
3. save/respect/hide where relevant
4. open at least one detail page per object type
5. verify obvious regressions in route/navigation/state restore
6. confirm the first daily drop is coherent rather than generic or broken
7. save or dismiss enough items to create obvious learning input

Pass if:
- discovery surfaces load
- detail flows work
- user actions stick correctly
- daily drop / recommendation behavior is directionally coherent for a new or lightly-trained user

### Pass 4: Event Planning Slice

Run the current in-app event flow on real phones.

Required path:

1. optional personal-agent event draft handoff
2. quick builder event truth step
3. `Cross Air Gap & Review`
4. publish event
5. safety handoff
6. host debrief after completion state

Priority:
- iPhone first using the existing runbook
- Android follow-up with the same conceptual milestone set

Must confirm:
- raw event-planning text does not become canonical persisted truth
- edits force re-crossing the air gap
- review/publish uses sanitized planning truth only
- debrief path still respects the air gap

Block if:
- raw planning text appears where only sanitized truth should survive
- publish fails
- safety handoff fails
- debrief path breaks or bypasses sanitation

### Pass 5: Offline, Resume, And Delayed-Sync Behavior

On each platform:

1. enter airplane mode or otherwise remove connectivity
2. reopen app
3. verify useful degraded behavior still exists
4. create or modify something expected to reconcile later if safe to do so
5. restore connectivity
6. verify recovery is understandable

Pass if:
- app remains usable in degraded mode
- state does not silently disappear
- reconnect behavior is coherent

### Pass 6: AI2AI Nearby And Cross-Platform Pairing

Run three classes when possible:

1. iPhone ↔ iPhone
2. Android ↔ Android
3. iPhone ↔ Android

Check:
- nearby detection behavior
- exchange/release behavior where expected
- no obvious cross-platform regression
- no broken recovery after devices separate and re-encounter
- mesh/runtime state does not enter a visibly bad loop after pairing attempts
- buffered vs applied learning counts move in a believable direction where surfaced

Pass if:
- pair behavior is directionally correct
- cross-platform path is not materially worse than same-platform in a launch-blocking way
- mesh health remains stable enough that nearby beta behavior can be trusted

Block if:
- iPhone ↔ Android is broken in a way that invalidates nearby beta behavior
- mesh/runtime health collapses after pairing or never recovers

### Pass 7: Notifications, Background, And Return Flow

On each platform:

1. send app to background
2. return after short delay
3. verify notifications/reminders if applicable
4. verify app can recover to a meaningful state

Pass if:
- background/foreground transitions are stable
- user is not dropped into broken state

### Pass 8: Admin / Oversight Confirmation

For at least one test cycle:

1. create real user-side activity
2. verify required admin or debug truth surfaces reflect it appropriately
3. confirm pseudonymous/default-safe visibility still holds
4. verify AI2AI activity appears where expected
5. verify user-agent / kernel health surfaces are present and directionally sane
6. verify learning / recommendation audit trail is visible without raw private text leakage

Pass if:
- oversight is present where expected
- privacy boundaries remain intact
- kernel/agent/runtime health can be inspected without ambiguity

If admin/autoresearch is part of the same cycle, also pass only if:
- the private control plane is reachable only over the intended private path
- privileged actions are enforced server-side rather than by client-only UI state
- no raw external payload or direct human identifier appears in admin surfaces

### Pass 9: Learning Registration And Directional Movement

Run at least one short cycle per platform using actions that should obviously teach the system:

1. save, dismiss, or interact with several recommendation objects
2. complete at least one event-planning flow or event interaction where available
3. if AI2AI pairing occurred, confirm learning consequences register after the exchange
4. inspect bounded debug/admin/user-visible surfaces for learning registration
5. verify recommendation or daily-drop behavior moves directionally rather than remaining frozen

Pass if:
- expected actions create visible learning evidence where the beta exposes it
- learning registration is bounded and privacy-safe
- the system can move from prior to updated understanding without looking random

Block if:
- meaningful user actions do not register learning at all
- learning appears to register but produces contradictory or obviously broken next-step behavior
- raw private text or identity leaks through the learning/audit surfaces

### Pass 10: Spot DNA / Locality Truth Update Checks

This pass is not asking for perfect long-horizon convergence.
It is asking whether the beta can update truth directionally from real behavior.

1. pick a spot, locality, or object cluster with a clear expected preference signal
2. create a small but meaningful sequence of real interactions around that preference
3. inspect any bounded truth/debug/admin surface that exposes spot DNA, locality movement, or recommendation rationale
4. confirm the system can shift from prior assumptions toward observed behavior
5. confirm the update remains privacy-safe and does not depend on raw free-text leakage

Pass if:
- spot/locality truth can move directionally from behavior
- the change is plausible rather than arbitrary
- privacy boundaries still hold

Major if:
- truth movement exists but is delayed, noisy, or hard to interpret

Block if:
- spot/locality truth never updates despite repeated strong signals
- spot/locality truth updates in an obviously wrong direction
- truth movement requires unsafe exposure of raw personal data

### Pass 11: Locality-Agent Generation And Hierarchical Pathflow

This pass checks whether the beta's active hierarchy behaves like the declared Birmingham model:

1. personal reality agent
2. locality agents
3. Birmingham city agent
4. top-level reality agent

On at least one meaningful test cycle:

1. confirm normal BHAM activity resolves into a seeded locality path rather than a null or ambiguous scope
2. inspect admin/debug surfaces for locality movement or higher-agent rollup evidence where available
3. confirm upward truth flow is privacy-bounded and does not expose direct human identity by default
4. confirm downward guidance, if visible, reaches the human only through the personal agent
5. if a controlled unmapped-zone or unseeded-locality test is available, confirm the system escalates for seeding/authorization rather than silently creating unconstrained geography truth

Pass if:
- BHAM activity lands in the expected seeded locality path
- locality/city/higher-agent flow is directionally visible and bounded
- no higher agent speaks directly to the human
- seeding behavior, if exercised, is governed and auditable

Major if:
- hierarchy signals exist but are hard to interpret or appear partially disconnected

Block if:
- BHAM activity cannot be associated with locality flow at all
- higher agents appear to bypass the personal-agent speech boundary
- unseeded geography behavior silently creates unconstrained truth instead of escalating

### Pass 12: Kernel-By-Kernel Learning And Simulation-Vs-Live Truth

This pass should verify both exposed kernel-family learning behavior and the beta rule that simulation/replay remains prior, not live truth.

For any surfaced kernel family or learning lane, inspect and record whether learning is healthy, bounded, and believable.
If a family is intentionally not exposed in the current beta build, mark it `N/A`.

Priority kernel families / lanes:

1. personal-agent / knot / DNA learning
2. surface-kernel truth path where exposed: `who`, `what`, `when`, `where`, `why`, `how`
3. `mesh_runtime_governance`
4. `ai2ai_runtime_governance`
5. `mesh_learning_intake`
6. `ai2ai_learning_governance`
7. runtime OS operational-learning lane
8. event-planning learning path
9. locality / hierarchy learning path

Then verify the simulation/live boundary:

1. replay, preload, forecast, or simulation outputs are treated as priors only
2. live user behavior outranks stale simulated assumptions
3. contradictory live behavior causes update rather than stubborn prior reuse
4. no live phone build behaves like replay-only or simulation-training mode is active as production truth

Pass if:
- surfaced kernel families are healthy or honestly `N/A`
- learning evidence is directionally sane where it should exist
- simulation/replay remains clearly bounded from live truth

Major if:
- kernel-family learning exists but is hard to interpret or partially disconnected
- replay/forecast labels are ambiguous even though no clear false live truth is shown

Block if:
- a surfaced critical kernel family appears broken in its learning behavior
- replay or simulation output is presented as current live reality
- live evidence fails to override stale simulated assumptions

## Evidence Capture Template

For each session, capture:

- platform
- device model
- OS version
- build identifier
- account used
- scenario executed
- result: pass / fail / pass-with-notes
- screenshots or recordings
- receipt/log artifact paths if any
- issue IDs created
- mesh health snapshot if pairing/runtime was exercised
- kernel health snapshot if available
- learning-registration evidence
- pre/post recommendation or truth-state evidence if available

For event planning specifically, capture:

- proof-run receipt if used
- whether source was human or personal-agent draft
- whether air-gap review behaved correctly
- whether publish/safety/debrief all completed

For runtime / learning specifically, capture:

- whether first knot / DNA state was visible
- whether personal learning appeared to start
- whether daily drop moved after meaningful actions
- whether AI2AI exchange created bounded learning evidence
- whether spot/locality truth showed directional movement
- whether seeded-locality routing was visible
- whether higher-agent pathflow was visible and bounded
- whether any seeding/escalation event was exercised
- which kernel families were surfaced vs `N/A`
- whether surfaced kernel families showed learning
- whether replay/forecast/simulation surfaces stayed clearly prior-only

## Severity Rules

### Blocker

- launch crash
- auth broken
- onboarding cannot complete
- publish/create broken for core object types
- raw event-planning text survives past the air gap
- cross-platform AI2AI regression that breaks the beta promise
- admin cannot see required safety/truth signals
- kernel health is broken, unavailable, or clearly inconsistent during active beta flows
- mesh/runtime health is unstable enough that AI2AI behavior cannot be trusted
- meaningful user actions fail to register learning
- spot/locality truth cannot update from real behavior or updates in an obviously false direction
- hierarchy pathflow is broken enough that BHAM activity cannot be associated with locality/city oversight
- a higher agent appears to message the human directly
- unseeded-locality behavior creates unconstrained geography truth without governed escalation
- replay or simulation output is presented as current live truth
- a surfaced critical kernel-family learning lane is broken

### Major

- feature works only after retries
- degraded offline behavior loses important state
- notifications/background behavior unreliable
- major UI confusion in key beta flows
- learning eventually registers but only after confusing delay or inconsistent recovery
- daily drop / recommendation behavior remains frozen after multiple meaningful inputs
- agent/kernel/runtime health can be reached only through unreliable or ambiguous debug behavior
- locality or higher-agent movement exists but cannot be interpreted confidently during QA
- kernel-family learning appears partially disconnected or too ambiguous to trust confidently
- simulation or forecast labeling is muddy even though it does not appear to override live truth

### Minor

- copy issues
- layout issues with workaround
- low-severity polish defects

## Exit Conditions For “Phones Are Good Enough”

Call the phone-availability follow-up good enough for current beta use when:

1. at least one approved iPhone pass is complete
2. at least one approved Android pass is complete
3. one iPhone ↔ Android pair flow has been exercised
4. onboarding, discovery, event planning, offline/recovery, and return flows all pass without blocker issues
5. at least one test cycle confirms mesh/kernel oversight is available and directionally sane
6. at least one test cycle confirms learning registration and bounded recommendation movement
7. at least one test cycle confirms locality/hierarchy pathflow is bounded and directionally sane
8. at least one test cycle confirms surfaced kernel-family learning is sane and simulation/replay remains prior-only
9. any remaining issues are documented and non-blocking

## Related Documents

- [README.md](./README.md)
- [PLAN.md](./PLAN.md)
- [06_SUCCESS_GATES_FALLBACKS_AND_EDGE_CASES.md](./06_SUCCESS_GATES_FALLBACKS_AND_EDGE_CASES.md)
- [04_OFFLINE_AI2AI_AND_DATA_CONTRACT.md](./04_OFFLINE_AI2AI_AND_DATA_CONTRACT.md)
- [05_ADMIN_GOVERNANCE_TRUTH_AND_SAFETY.md](./05_ADMIN_GOVERNANCE_TRUTH_AND_SAFETY.md)
- [10_REALITY_MODEL_BUILD_CONTRACT.md](./10_REALITY_MODEL_BUILD_CONTRACT.md)
- [14_FOLLOW_UP_DEVICE_QA_FIELD_CHECKLIST.md](./14_FOLLOW_UP_DEVICE_QA_FIELD_CHECKLIST.md)
- [BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md](./../easy_event_hosting/BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md)
- [BETA_EVENT_TRUTH_AIR_GAPPED_AGENT_LEARNING_CREATOR_DEBRIEF_PLAN.md](./../easy_event_hosting/BETA_EVENT_TRUTH_AIR_GAPPED_AGENT_LEARNING_CREATOR_DEBRIEF_PLAN.md)
