# Beta Event Truth + Air-Gapped Agent Learning + Creator Debrief

**Created:** March 14, 2026  
**Status:** ✅ Complete  
**Scope:** Birmingham beta implementation authority for the in-app event-truth slice

---

## Summary

This plan defines the Birmingham beta event slice that stays inside the app and current easy-event-hosting flow.

It adds four things:
- event-truth capture during creation
- a non-bypassable event-planning air gap
- bounded agent/entity learning from creation and outcome
- a creator debrief after the event

This is the current beta build slice. It is not the future organizer/event-ops platform.

Current truth:
- engineering implementation is in place
- automated closeout coverage exists
- iOS integration smoke receipt captured on March 14, 2026
- closeout gate passed against reconstructed host receipt bundle at `/tmp/event_planning_phase1_receipts/c3dafc3d-9ea1-4e19-8769-d851bee8655f`
- the manual iOS smoke runbook remains the canonical future human QA path

---

## Non-Negotiable Air-Gap Rule

- All event-planning inputs from humans, personal agents, and later other entity surfaces must pass through the event-planning air gap.
- No event-planning field may bypass the air gap by being written directly from UI/controller state into persistent event models, learning payloads, or higher-agent summaries.
- Raw event-planning text is transient only.
- Only air-gap-produced abstractions may survive persistence or upward sharing.

This applies to:
- event intent
- vibe description
- audience description
- locality/date preference rationale
- host goal statements
- future organizer notes, vendor notes, and staffing notes

Phase-1 source rule:
- human and personal-agent planning input both go through the same intake adapter
- higher layers may receive only privacy-bounded summaries after the air-gap crossing

---

## Build Scope

### In-app event truth
- Add a compact `Event Truth` step/card to the quick event builder.
- Collect transient raw planning input while the host is editing.
- Convert raw input into a sanitized `EventDocketLite` before review/publish.
- Show only sanitized planning truth downstream.

### In-app suggestions
- Use deterministic beta-grade suggestions from the sanitized docket only.
- Always return an explanation and confidence.
- Return honest low-confidence output when event truth is sparse.

### In-app creator debrief
- Reuse the host success dashboard flow as the debrief entry point.
- Compare planned vs actual attendance and feedback.
- Emit concise insight lines.
- Route outcome notes through the air gap before learning.

---

## Public Types

### Transient only
- `RawEventPlanningInput`
  - `sourceKind`
  - `purposeText`
  - `vibeText`
  - `targetAudienceText`
  - `candidateLocalityLabel`
  - `preferredStartDate`
  - `preferredEndDate`
  - `sizeIntent`
  - `priceIntent`
  - `hostGoal`

This type must never be persisted.

### Persisted / learning-safe
- `EventDocketLite`
- `EventPlanningAirGapResult`
- `EventCreationSuggestion`
- `EventPlanningSnapshot`
- `EventCreationLearningSignal`
- `HostEventDebrief`

Hard rule:
- `planningSnapshot` may contain only air-gap-safe abstractions
- no raw text from `RawEventPlanningInput` may exist in persisted event JSON

---

## Runtime Services

### `EventPlanningIntakeAdapter`
- sole ingress for event-planning information
- accepts `RawEventPlanningInput`
- routes raw input through the air gap
- emits only sanitized docket output

### `BetaEventPlanningSuggestionService`
- consumes `EventDocketLite`, never raw input
- produces deterministic beta-grade suggestions with explanation + confidence

### `EventLearningSignalService`
- consumes `EventPlanningSnapshot`, never raw input
- records event-created learning
- records event-outcome learning
- writes personal-agent learning plus bounded event/locality/place summaries only

### `EventHostDebriefService`
- resolves predicted vs actual outcomes
- triggers outcome learning after the host debrief

---

## Controller And UX Rules

### Event flow
1. User or personal agent provides raw planning input.
2. `EventPlanningIntakeAdapter` converts it into `EventDocketLite`.
3. Raw input is discarded after conversion.
4. Suggestions are generated from `EventDocketLite`.
5. Review/publish stores only `EventPlanningSnapshot`.
6. `EventLearningSignalService.recordEventCreated(...)` learns from the sanitized snapshot.
7. After the event completes, `recordEventOutcome(...)` resolves predictions against actuals.

### UX rules
- The app may render raw text while the user is editing.
- Once the air-gap step completes, downstream surfaces use the sanitized docket only.
- If the user re-edits the plan, it must re-cross the air gap.
- The user should feel like they are clarifying the event, not performing “training work.”

---

## Learning Scope

### Teach now
- host personal agent
- event entity baseline
- locality summary
- selected place/business protoagent summaries when available

### Do not teach yet
- state/regional layers
- volunteer/band/vendor outreach policies
- contract/payment agent behavior
- live police/fire/EMS operational policies

---

## Explicit Exclusions

Do not include in this beta slice:
- volunteer, vendor, band, or sponsor candidate queues
- sponsor-seeking UI
- outreach drafting or autonomous sending
- contracts, deposits, payouts, or procurement
- separate organizer/event-ops platform
- live public-safety or city-ops automation

---

## Verification Requirements

- `RawEventPlanningInput` is never serialized into event persistence.
- `EventDocketLite` and `EventPlanningSnapshot` round-trip correctly.
- Event persistence stores only sanitized planning data.
- Suggestions consume sanitized docket only.
- Event creation writes learning payloads with no raw planning text.
- Locality/entity summaries contain only bounded abstractions.
- Editing planning info forces re-crossing the air gap.
- Debrief/outcome notes also cross the air gap before learning.
- Birmingham beta keeps business/partnership surfaces disconnected.

---

## Phase-1 Closeout Gate

- Manual smoke scenario: `event_planning_beta_smoke_v1`
- Runbook: [`BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md`](./BETA_EVENT_PLANNING_IOS_SMOKE_RUNBOOK.md)
- Gate script: [`../../scripts/run_event_planning_phase1_closeout_gate.sh`](../../scripts/run_event_planning_phase1_closeout_gate.sh)

This phase is now `✅ Complete`.

Closeout evidence:
- targeted analyze/tests in the closeout gate passed on March 14, 2026
- one canonical iOS smoke receipt bundle was exported through the proof-run scenario
- the receipt bundle contains the required event-planning smoke milestones
- receipt provenance for this closeout: iOS integration smoke (`receipt_mode: ios_integration_smoke`), reconstructed to a host-visible bundle for gate validation

The manual iOS smoke runbook remains the canonical future human QA path for repeated release checks.

---

## Relationship To Future Work

- Phase 2 and Phase 3 are future roadmap entries only.
- This beta slice is the precursor that validates truthful event creation, bounded learning, and creator debrief behavior before organizer/event-ops expansion.
