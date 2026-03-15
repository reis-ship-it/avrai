# Beta Event-Planning iOS Smoke Runbook

**Purpose:** Canonical human-run closeout flow for `Beta Event Truth + Air-Gapped Agent Learning + Creator Debrief`  
**Scenario name:** `event_planning_beta_smoke_v1`  
**Platform:** iOS first  
**Artifact required for final phase completion:** exported proof-run receipt bundle

---

## Preconditions

- Run a debug build of `apps/avrai_app` on an iOS simulator or device.
- Use a beta-capable test account that can access:
  - personal-agent chat
  - quick event builder
  - event publish flow
  - event success dashboard
  - debug proof-run page
- Ensure the event-planning feature flag is enabled in the current beta build.

---

## Canonical Flow

1. Open the debug proof-run page.
2. In `Event Planning Smoke (iOS manual)`, tap `Start iOS smoke`.
3. Open personal-agent chat.
4. Ask the personal agent to draft an event.
   The path is only valid if the personal-agent draft handoff appears.
5. Tap `Draft Event In Builder`.
6. In the quick builder:
   - confirm the draft banner is present
   - review `Event Truth`
   - enter or refine planning details as needed
7. Tap `Cross Air Gap & Review`.
8. Confirm the review screen shows sanitized event truth and source/provenance.
9. Publish the event.
10. From the publish screen, open the safety checklist CTA.
11. Open the event success dashboard for the published event.
12. Record a host debrief note and submit it.
13. Return to the debug proof-run page.

---

## Required Milestones

Record every milestone on the proof-run page by tapping the matching chip:

- `Event truth`
- `Air gap`
- `Suggestion`
- `Publish`
- `Safety`
- `Debrief`

All six chips must be selected before export.

---

## Expected Truth Signals

During the run, confirm these behaviors:

- The personal agent can draft, but the draft is not canonical by itself.
- Event planning crosses the air gap before review/publish.
- Review and persistence show sanitized planning truth only.
- Safety opens after publish.
- Debrief notes cross the air gap before learning.

Stop the run if any raw planning text appears in persisted/review-only event truth, or if the personal-agent draft bypasses the air gap.

---

## Export Artifact

1. On the proof-run page, tap `Finish & export`.
2. Capture the exported directory path shown by the app.
3. Preserve the entire receipt bundle directory.

Minimum required files:

- `ledger_rows.jsonl`
- `ledger_rows.csv`

The JSONL bundle must contain:

- `event_planning_beta_smoke_v1`
- `proof_event_planning_smoke_started`
- `proof_event_planning_event_truth_entered`
- `proof_event_planning_air_gap_crossed`
- `proof_event_planning_suggestion_shown`
- `proof_event_planning_publish_completed`
- `proof_event_planning_safety_checklist_opened`
- `proof_event_planning_debrief_completed`

---

## Gate Usage

After exporting the receipt bundle, run:

```bash
EVENT_PLANNING_SMOKE_RECEIPT_DIR="/absolute/path/to/proof_runs/<run_id>" \
  bash work/scripts/run_event_planning_phase1_closeout_gate.sh
```

The phase is only ready to mark `✅ Complete` when:

- the targeted automated checks pass
- the exported receipt bundle exists
- the receipt bundle contains the canonical manual smoke scenario and all required milestones

Until then, the phase remains in progress.
