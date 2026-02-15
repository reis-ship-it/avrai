# START HERE -- New Task Protocol (v2)

**Updated:** February 15, 2026  
**Purpose:** Entry point for every new task. Replaces the flat 40-minute protocol with a tiered system that matches context depth to task complexity.

---

## Step 0: Classify the Task (30 seconds)

Every task falls into one of four tiers. Pick the right one and follow ONLY that tier's protocol.

| Tier | Trigger | Context Time | Example |
|------|---------|-------------|---------|
| **Quick** | Fix typo, rename variable, small UI tweak, answer a question | 0-2 min | "Fix the linter error in auth_service.dart" |
| **Targeted** | Implement a specific task within a known phase, bug fix, extend existing service | 5-10 min | "Implement task 1.2.5 (add community_join interaction type)" |
| **Phase** | Start a new phase or major section of the Master Plan | 15-20 min | "Start Phase 3.1 (unified feature extraction)" |
| **Architectural** | New feature that touches multiple phases, major refactor, new plan integration | 25-35 min | "Add a new entity type to the quantum system" |

**When in doubt, go one tier UP, not down.** Under-preparing costs more than over-preparing.

---

## Tier: Quick (0-2 minutes)

**For:** Small, contained changes with obvious scope.

1. Search for the file(s) involved
2. Read the relevant code
3. Make the change
4. Check lints

**That's it.** No plan documents, no philosophy review. The change is too small to warrant it.

---

## Tier: Targeted (5-10 minutes)

**For:** A specific task within a phase that's already scoped in the Master Plan.

### Protocol:

1. **Read the Master Plan section** for the task's phase (e.g., Phase 1.2 for outcome collection tasks)
   ```
   docs/MASTER_PLAN.md → find the specific task (e.g., 1.2.5)
   ```

2. **Read the phase rationale** to understand WHY the task exists and what it connects to
   ```
   docs/plans/rationale/PHASE_X_RATIONALE.md
   ```

3. **Search for existing implementations** of the specific service/model being modified
   ```
   Search: class name, file name, service name
   ```

4. **Check the pre-flight checklist** in the rationale file -- is this task's phase actually ready to start?

5. **Implement, test, verify lints**

---

## Tier: Phase (15-20 minutes)

**For:** Starting a new phase or a major section (e.g., all of Phase 3.1, or all of Phase 4.2).

### Protocol:

1. **Read the Foundational Decisions** that apply to this phase
   ```
   docs/plans/rationale/FOUNDATIONAL_DECISIONS.md
   → Check the "Quick Reference" table at the bottom for which decisions apply
   ```

2. **Read the Phase Rationale** cover-to-cover
   ```
   docs/plans/rationale/PHASE_X_RATIONALE.md
   → Key decisions, pre-flight checklist, common pitfalls
   ```

3. **Read the Cross-Phase Connections** for this phase
   ```
   docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md
   → What does this phase consume? What does it produce?
   → What are the breaking change risks?
   ```

4. **Read coherence gate contract and identify scenario IDs**
   ```
   docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md
   → Which `RCM-*` scenarios apply?
   → What evidence is required for phase gates?
   ```

5. **Read the Master Plan section** for the specific work
   ```
   docs/MASTER_PLAN.md → Phase X section
   ```

6. **Check status** to understand what's already done
   ```
   docs/agents/status/status_tracker.md
   ```

7. **Search for existing implementations** in the codebase
   ```
   Search for class names, services, models mentioned in the plan tasks
   ```

8. **Create a TODO list** and communicate the plan to the user

9. **Get user approval** before starting

---

## Tier: Architectural (25-35 minutes)

**For:** Work that crosses phase boundaries, introduces new entities, or changes foundational contracts.

### Protocol:

1. **Read the Foundational Decisions** fully
   ```
   docs/plans/rationale/FOUNDATIONAL_DECISIONS.md
   ```

2. **Read DOORS.md** and answer the four questions for this work
   ```
   docs/plans/philosophy_implementation/DOORS.md
   → What doors does this open?
   → When are users ready?
   → Is this being a good key?
   → Is the AI learning with the user?
   ```

3. **Read the Phase Rationale** for every phase this work touches
   ```
   docs/plans/rationale/PHASE_X_RATIONALE.md (for each affected phase)
   ```

4. **Read the Cross-Phase Connections** -- specifically the "Critical Cross-Cutting Contracts" section
   ```
   docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md
   → Which contracts does this work affect?
   → What is the chain reaction?
   ```

5. **Read coherence gate contract and map required scenarios**
   ```
   docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md
   → Map scope to required `RCM-*` scenarios and evidence
   ```

6. **Read the Master Plan** sections for all affected phases

7. **Check the Master Plan Tracker** for related active plans
   ```
   docs/MASTER_PLAN_TRACKER.md
   ```

8. **Search for ALL existing implementations** that will be affected

9. **Read the AVRAI Philosophy** for alignment check
   ```
   docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md
   ```

10. **Create a detailed TODO list** with dependency ordering

11. **Communicate plan** including:
    - Which phases are affected
    - Which cross-cutting contracts change
    - Which `RCM-*` scenarios are required
    - Chain reaction analysis
    - Risk assessment

12. **Get user approval** before starting

---

## Status/Progress Queries

When the user asks about status ("where are we with X", "what's complete in Phase Y"):

1. **Find ALL related documents:**
   - Plan documents: `glob('**/*[topic]*plan*.md')`
   - Completion documents: `glob('**/*[topic]*complete*.md')`
   - Progress documents: `glob('**/*[topic]*progress*.md')`
   - Status tracker: `docs/agents/status/status_tracker.md`
   - Master Plan Tracker: `docs/MASTER_PLAN_TRACKER.md`

2. **Read ALL found documents** (never answer from just one)

3. **Synthesize a comprehensive answer** covering:
   - What was planned
   - What's complete
   - What's in progress
   - What's remaining
   - Any blockers
   - Timeline status

---

## Document Reference Map

Instead of reading 6+ overlapping documents, use this map to find what you need:

| Question | Go To |
|----------|-------|
| "What should I build?" | `docs/MASTER_PLAN.md` (the specific phase/task) |
| "Why is it designed this way?" | `docs/plans/rationale/PHASE_X_RATIONALE.md` |
| "What decisions apply everywhere?" | `docs/plans/rationale/FOUNDATIONAL_DECISIONS.md` |
| "What flows between phases?" | `docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md` |
| "What proves inter-app/coherence behavior is validated?" | `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` |
| "What's the status?" | `docs/agents/status/status_tracker.md` |
| "Where do all the plans live?" | `docs/MASTER_PLAN_TRACKER.md` |
| "What's the core philosophy?" | `docs/plans/philosophy_implementation/DOORS.md` |
| "How does the architecture work?" | `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md` |
| "What are the code standards?" | `.cursorrules` |
| "Where should I put new files?" | `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md` |

---

## Red Flags -- STOP and Clarify

**Stop and ask the user if:**
- [ ] The task's phase pre-flight checklist has unchecked items (dependencies not met)
- [ ] The cross-phase connections show this work changes a critical contract
- [ ] Required `RCM-*` scenario IDs/evidence are not identified for cross-system scope
- [ ] Multiple plans contradict each other
- [ ] The task doesn't answer at least one of the four doors questions
- [ ] You can't find where the code should live

**DO NOT proceed until clarified.**

---

## Why This Protocol Works

The old protocol applied 40 minutes of context gathering to every task. That was correct for the problem it solved (agents wasting days building duplicates), but it treated every task the same.

The tiered protocol matches effort to complexity:
- **Quick**: A linter fix doesn't need philosophy review
- **Targeted**: A specific plan task needs the plan section + rationale, not every plan in the system
- **Phase**: Starting a whole phase needs dependency checking and pre-flight validation
- **Architectural**: Cross-cutting work needs the full picture

The rationale files (`docs/plans/rationale/`) consolidate the "why" that was previously scattered across 6+ documents. One rationale file per phase replaces reading the ML Roadmap, philosophy docs, methodology, and multiple plan files to piece together the reasoning.

---

## Proven ROI (Still Valid)

| Phase | Context Time | Saved |
|-------|-------------|-------|
| Phase 1 Integration | 40 min → 15 min (with rationale files) | 5 days (99%) |
| Targeted task in known phase | 5-10 min | Hours of wrong-direction work |
| Architectural cross-phase work | 25-35 min | Days of rework from missed connections |

**The golden rule still holds: context gathering saves more time than it costs. The tiered system just makes the investment proportional to the task.**

---

**Version:** 2.0  
**Status:** Active -- Mandatory reference for every new task
