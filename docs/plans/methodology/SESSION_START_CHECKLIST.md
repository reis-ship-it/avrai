# Session Start Checklist (v2)

**Updated:** February 10, 2026  
**Purpose:** Quick reference card for the tiered context protocol  
**Full Protocol:** `docs/plans/methodology/START_HERE_NEW_TASK.md`

---

## Step 0: What Kind of Task Is This?

| Tier | Context Time | When |
|------|-------------|------|
| **Quick** | 0-2 min | Fix, rename, small tweak, question |
| **Targeted** | 5-10 min | Specific task in a known plan phase |
| **Phase** | 15-20 min | Starting a new phase or major section |
| **Architectural** | 25-35 min | Cross-phase work, new entity types, major refactors |

**When in doubt, go one tier UP.**

---

## Quick Tier Checklist

- [ ] Find the file(s)
- [ ] Read the code
- [ ] Make the change
- [ ] Check lints

---

## Targeted Tier Checklist

- [ ] Read Master Plan task section (`docs/MASTER_PLAN.md` → Phase X.Y)
- [ ] Read phase rationale (`docs/plans/rationale/PHASE_X_RATIONALE.md`)
- [ ] Search for existing implementations
- [ ] Check pre-flight checklist in rationale
- [ ] Implement, test, verify

---

## Phase Tier Checklist

- [ ] Read Foundational Decisions (`docs/plans/rationale/FOUNDATIONAL_DECISIONS.md` → quick reference table)
- [ ] Read Phase Rationale (`docs/plans/rationale/PHASE_X_RATIONALE.md`) -- full document
- [ ] Read Cross-Phase Connections (`docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md`) -- this phase's section
- [ ] Read Master Plan section (`docs/MASTER_PLAN.md` → Phase X)
- [ ] Check status (`docs/EXECUTION_BOARD.csv` + `docs/STATUS_WEEKLY.md`; optional context in `docs/agents/status/status_tracker.md`)
- [ ] If targeting a completed section, plan a reopen milestone (`change_type=reopen`, `reopens_milestone=<done id>`) and add a weekly log entry
- [ ] Search for existing implementations
- [ ] Create TODO list
- [ ] Communicate plan to user
- [ ] Get approval

---

## Architectural Tier Checklist

- [ ] Read Foundational Decisions -- full document
- [ ] Read DOORS.md -- answer all four questions
- [ ] Read Phase Rationale for EVERY affected phase
- [ ] Read Cross-Phase Connections -- especially "Critical Cross-Cutting Contracts"
- [ ] Read Master Plan sections for all affected phases
- [ ] Check Master Plan Tracker for related plans
- [ ] Search ALL affected existing implementations
- [ ] Read AVRAI Philosophy for alignment
- [ ] Create detailed TODO with dependency ordering
- [ ] Communicate plan with chain-reaction analysis
- [ ] Get approval

---

## Status Query Protocol

When user asks "where are we with X":
- [ ] Search for ALL related docs (plan + complete + progress + status)
- [ ] Read ALL found documents (never just one)
- [ ] Check `docs/EXECUTION_BOARD.csv` + `docs/STATUS_WEEKLY.md`
- [ ] Synthesize comprehensive answer

---

## Document Quick Reference

| Need | Document |
|------|----------|
| What to build | `docs/MASTER_PLAN.md` |
| Why it's designed this way | `docs/plans/rationale/PHASE_X_RATIONALE.md` |
| Decisions that apply everywhere | `docs/plans/rationale/FOUNDATIONAL_DECISIONS.md` |
| What flows between phases | `docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md` |
| Current status | `docs/EXECUTION_BOARD.csv` + `docs/STATUS_WEEKLY.md` |
| Where plans live | `docs/MASTER_PLAN_TRACKER.md` |
| Core philosophy | `docs/plans/philosophy_implementation/DOORS.md` |
| Code standards | `.cursorrules` |

---

## Red Flags -- STOP

- [ ] Pre-flight checklist has unchecked items
- [ ] Cross-phase connections show contract changes
- [ ] Plans contradict each other
- [ ] Can't answer the doors questions
- [ ] Don't know where code should live

**Ask for clarification. Do not proceed.**

---

**Version:** 2.0  
**Status:** Active
