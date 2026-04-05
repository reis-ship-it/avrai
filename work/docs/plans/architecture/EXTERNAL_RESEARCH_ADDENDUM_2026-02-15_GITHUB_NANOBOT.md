# External Research Addendum: HKUDS/nanobot (Lightweight Memory Core)

**Date:** February 15, 2026  
**Status:** Active research reference  
**Source:** https://github.com/HKUDS/nanobot

---

## Summary (Why It Matters to AVRAI)

`nanobot` highlights a lightweight, deterministic memory approach (`MEMORY.md`, `HISTORY.md`, grep-style retrieval) that is highly useful as a fallback and audit layer. For AVRAI, this is best used as a complementary memory core for self-healing and autonomous research governance.

---

## AVRAI Mapping

| Nanobot Pattern | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| Deterministic text memory | Append-only `FactsJournal` + `HistoryJournal` | `docs/MASTER_PLAN.md` Phase 1.1E |
| Lightweight retrieval | Fallback retrieval when semantic confidence is low | `docs/MASTER_PLAN.md` Phase 1.1E.3, 7.9.15 |
| Windowed memory consolidation | Journal summarization + critical-fact retention | `docs/MASTER_PLAN.md` Phase 1.1E.4 |
| Audit-friendly change trace | Promotion/rollback decision ledger | `docs/MASTER_PLAN.md` Phase 7.7.9-7.7.11 |

---

## Federated Learning Fit

- Keep raw deterministic journals on-device.
- Federate only DP-safe aggregates:
  - failure-signature counts,
  - hypothesis-class success rates,
  - rollback incidence.
- Use contradiction feedback to quarantine suspect global updates before rollout.

Mapped to:
- `docs/MASTER_PLAN.md` Phase 8.1.6-8.1.8

---

## Self-Healing Fit

- Journal-backed rollback forensics improves root-cause clarity.
- Known-bad signature suppression prevents repeating failure loops.
- Deterministic fallback preserves basic reasoning when semantic retrieval is uncertain.

Mapped to:
- `docs/MASTER_PLAN.md` Phase 7.7.10-7.7.11
- `docs/MASTER_PLAN.md` Phase 7.9.14-7.9.16

---

## Implementation Guardrails

- Deterministic memory is a fallback and governance layer, not replacement for learned memory.
- No raw journal text leaves device in federated flow.
- Promotion remains evidence-gated, rollback-first, and privacy-bound.
