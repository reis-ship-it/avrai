# Patent Risk Claim Checklist (2026-02-15)

**Date:** February 15, 2026  
**Status:** Active risk checklist (architecture planning artifact)  
**Scope:** Claim-sensitive modules in AVRAI (`matching`, `mesh`, `federated`, `crypto`)  
**Companion backlog:** `docs/plans/architecture/EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`

---

## 1) Purpose

Provide an element-by-element checklist for high-risk patent families and map each element to AVRAI status:
- `Present`,
- `Absent`,
- `Unknown`.

This artifact is used for design-around planning and legal review preparation.

---

## 2) Family A: `US8019692B2` (Location/Behavior/Profile Matching)

| Claim Element (paraphrased) | AVRAI Status | Owner | Required Action |
|---|---|---|---|
| Profile includes user-specified info | Present | AIC | Keep as-is; maintain contract docs |
| Observed behavior auto-derived | Present | AIC | Keep passive signal governance + privacy |
| Confidence derived from observed behavior | Present/Partial | AIC | Make confidence derivation explicit in matching contract |
| Confidence associated with profile data | Present/Partial | DPL | Add field-level traceability in schema docs |
| Second user specifies matching criteria | Unknown | APP | Clarify bilateral criteria/consent flow docs |
| Location-based matching performed | Present/Partial | AIC | Keep outcome-first framing, not promotion framing |
| Match notification to second user | Present/Partial | APP | Enforce user-agency and anti-spam controls |

---

## 3) Family B: `US11283885B2` (Geo-Visit Contextual Matching/Content)

| Claim Element (paraphrased) | AVRAI Status | Owner | Required Action |
|---|---|---|---|
| User behavior tied to visited geolocation/time | Present | AIC | Keep on-device location constraints |
| Relevance/factor/confidence analysis | Present/Partial | AIC | Document explicit factor lineage |
| External source tied to location/visit characteristics | Unknown | DPL | Clarify external data usage boundaries |
| Confidence verification with profile + external source | Unknown/Partial | AIC | Define verification path or explicitly exclude |
| Current location from mobile | Present | APP | Keep privacy-policy linkage |
| Distance-to-prior-geo condition for matching/display | Unknown/Partial | AIC | Avoid claim-like show/remove distance behavior unless justified |
| Programmable filter criteria and auto-adjust by context | Present/Partial | AIC | Keep as planner contract, not ad-targeting stack |
| Content tied to geolocation/context and auto messaging | Partial | APP | Separate discovery planning from content promotion semantics |

---

## 4) Review Cadence

1. Monthly review of this checklist by `ARC` + `SEC` + `PMO`.
2. Update status fields when architecture contracts change.
3. Attach checklist snapshot to phase exit packages for Phases 3, 6, 10, and 11.

---

## 5) Escalation Rules

1. Any `Present` element in a red-risk family requires design-around note in the relevant phase story.
2. Any `Unknown` element requires explicit resolution (`map`, `exclude`, or `defer`) before phase exit.
3. Security/privacy-affecting changes must include `SEC` approval and evidence links.
