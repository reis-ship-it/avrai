# Event System Integration Overview

**Created:** November 21, 2025  
**Updated:** March 14, 2026  
**Purpose:** Define the 3-phase event roadmap split across Birmingham beta, post-beta expansion, and public launch  
**Status:** 🎯 Integration Blueprint

---

## Summary

AVRAI event work now follows a 3-phase roadmap:

1. `Beta Event Truth + Air-Gapped Agent Learning + Creator Debrief`
2. `Post-Beta Event Ops Expansion + Human-Governed Outreach`
3. `Public Launch Event Ops + Partnerships + Civic Coordination`

Phase 1 is the current Birmingham beta baseline only. It stays inside the app and current easy-event-hosting flow. Phases 2 and 3 are future build tracks.

---

## Roadmap

### Phase 1: Beta Event Truth + Air-Gapped Agent Learning + Creator Debrief

**Role:** Current beta baseline, not a separate future platform

**What it does now**
- Keeps event creation inside the consumer app.
- Adds event-truth capture during creation.
- Forces event-planning input through the event-planning air gap before persistence or learning.
- Stores only sanitized event-planning abstractions on the event.
- Generates simple creator suggestions and a post-event debrief.
- Teaches the host personal agent, event entity baseline, and bounded locality/place summaries.

**What it explicitly does not do**
- No separate organizer/event-ops platform.
- No volunteer, vendor, band, or sponsor outreach queues.
- No contracts, deposits, payouts, or procurement planning.
- No live civic safety operations.

### Phase 2: Post-Beta Event Ops Expansion + Human-Governed Outreach

**Role:** First future organizer expansion after beta learning is validated

**What it adds**
- Organizer/event-ops workspace inside AVRAI.
- Reviewed candidate queues for volunteers, vendors, bands, sponsors, workers, and security.
- Human-approved outreach drafts and follow-up workflows.
- Richer timing and budget planning for lead times, staffing fill windows, deposits, and fallback paths.
- Expanded agent learning from staffing, outreach timing, and realized organizer decisions.

**Boundaries**
- High-impact sends remain human-approved.
- No autonomous contracting.
- No city-grade safety automation.
- No state/regional rollout.

### Phase 3: Public Launch Event Ops + Partnerships + Civic Coordination

**Role:** Public-launch event operating system

**What it adds**
- Full organizer/event-ops surface.
- Full business/partnership surfaces.
- Contracts, deposits, payouts, reporting, and live run-of-show workflows.
- Live incident workflows and civic coordination surfaces.
- Expanded learning from realized operations, partner execution, and event outcomes.

**Boundaries**
- Police, fire, EMS, and public-safety actions remain human-in-the-loop.
- No privileged organizer bypass around privacy or governance.
- Still not equivalent to Phase 12 AVRAI OS autonomy.

---

## Non-Negotiable Air-Gap Governance

- All event-planning inputs from humans, personal agents, and later organizer/operator surfaces must cross the event-planning air gap before persistence, learning, or higher-agent sharing.
- No event-planning field may bypass the air gap by being written directly from UI/controller state into persistent event models, learning payloads, or higher-agent summaries.
- Raw planning text is transient only.
- Only air-gap-produced abstractions may survive persistence or upward sharing.

This applies to:
- event intent
- vibe description
- audience description
- locality/date preference rationale
- host goal statements
- future organizer notes, vendor notes, and staffing notes

---

## Feature Matrix

| Capability | Phase 1: Beta baseline | Phase 2: Post-beta expansion | Phase 3: Public launch |
|-----------|------------------------|------------------------------|------------------------|
| Event creation | In-app quick builder | Organizer workspace + consumer flow | Full organizer/event-ops surface |
| Event truth | Docket-lite only | Richer planner inputs | Full event docket + ops inputs |
| Creator suggestions | Beta-grade, deterministic | Richer planning recommendations | Full planner-backed operations guidance |
| Creator debrief | Yes, in-app | Yes, with richer ops resolution | Yes, with partner/ops/civic outcome resolution |
| Volunteer/vendor/band/sponsor queues | No | Reviewed candidate queues | Full multi-sided operating queues |
| Outreach drafting | No | Human-approved drafts | Full workflow with governance tiers |
| Contracts / deposits / payouts | No | Budget/timing planning only | Yes |
| Partnerships / monetization | Deferred | Partial prep and reviewed workflows | Full launch surface |
| Civic coordination | No | No live civic ops | Yes, human-supervised |
| Air-Gap Governance | Event truth crosses air gap before persistence/learning | Organizer/outreach/staffing inputs also cross air gap | Contracts/ops/civic inputs remain air-gap-governed |
| Human-in-loop boundary | All planning and publishing decisions | Outreach and expensive actions | Civic/public-safety + high-impact commercial actions |

---

## Launch Strategy

### Beta now

Ship Phase 1 inside the app.

Goals:
- Make event creation clearer and more truthful.
- Teach AVRAI from air-gapped event intent and outcomes.
- Validate whether hosts actually use event-truth inputs and debriefs.

### Post-beta gate

Only start Phase 2 when:
- Phase 1 event-truth usage is validated.
- Creator debrief data is flowing.
- Birmingham beta confirms the in-app event slice is useful.

### Public launch gate

Only start Phase 3 when:
- Phase 2 organizer workflows are stable.
- Payment/partnership primitives are hardened.
- Human-in-loop civic boundaries are clearly enforced.

---

## Success Criteria

### Phase 1 success
- Hosts complete event-truth input without major drop-off.
- Planning snapshots persist only sanitized abstractions.
- Event creation generates bounded learning signals with no raw-text leakage.
- Hosts use post-event debriefs and compare prediction vs. outcome.

### Phase 2 success
- Reviewed outreach queues reduce organizer effort without unsafe automation.
- Timing/budget planning improves fill, staffing readiness, and fallback handling.
- Agent learning improves candidate ranking and outreach timing.

### Phase 3 success
- Organizer/event-ops surfaces can run real events end-to-end.
- Partnership and payout workflows are trusted and explainable.
- Civic coordination remains useful without violating human authority boundaries.

---

## Relationship To Other Plans

- [`../easy_event_hosting/EASY_EVENT_HOSTING_EXPLANATION.md`](../easy_event_hosting/EASY_EVENT_HOSTING_EXPLANATION.md): historical easy-event-hosting foundation
- [`EVENT_PARTNERSHIP_MONETIZATION_PLAN.md`](./EVENT_PARTNERSHIP_MONETIZATION_PLAN.md): deeper partnership and monetization plan
- [`../easy_event_hosting/BETA_EVENT_TRUTH_AIR_GAPPED_AGENT_LEARNING_CREATOR_DEBRIEF_PLAN.md`](../easy_event_hosting/BETA_EVENT_TRUTH_AIR_GAPPED_AGENT_LEARNING_CREATOR_DEBRIEF_PLAN.md): current phase-1 implementation authority
