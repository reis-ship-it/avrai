# Follow-Up Device QA Master Checklist

**Date:** March 14, 2026  
**Status:** Ready  
**Use:** Single operational checklist for real-phone QA once approved devices are available

Use this as the live execution sheet.
Use [13_FOLLOW_UP_DEVICE_QA_OUTLINE.md](./13_FOLLOW_UP_DEVICE_QA_OUTLINE.md) for the fuller explanatory order and blocker logic.

## How To Use

- Mark each item `pass`, `fail`, `N/A`, or `note`.
- If a debug/admin surface is not intentionally exposed in the current beta build, mark it `N/A`, not `fail`.
- If a surface is exposed but gives ambiguous, false, or privacy-unsafe results, mark it `fail`.
- If simulation/replay behavior appears to leak into live truth, treat it as a blocker.

## Session Info

- Build / commit:
- Date / time:
- Test lead:
- Admin observer:
- iPhone operator:
- Android operator:
- Nearby-pair operator:
- Notes / evidence location:

## Team Checklist

### Roles And Readiness

- [ ] One person owns the iPhone pass
- [ ] One person owns the Android pass
- [ ] One person owns admin/debug observation
- [ ] One person owns note-taking / issue capture
- [ ] Nearby-pair test accounts are prepared
- [ ] Fresh-account test accounts are prepared
- [ ] Returning-account test accounts are prepared

### Test Logistics

- [ ] Approved iPhone is available
- [ ] Approved Android device is available
- [ ] One iPhone ↔ Android pairing session is scheduled
- [ ] Screenshots / recordings can be captured
- [ ] Receipt / log destinations are prepared
- [ ] Event-planning smoke runbook is available
- [ ] Blocker escalation path is understood before testing starts

### Team Signoff

- [ ] Team agrees on current build under test
- [ ] Team agrees on issue severity rules
- [ ] Team agrees which debug/admin surfaces are expected vs optional

## System Checklist

### Oversight / Debug Availability

- [ ] Admin / debug oversight surfaces are reachable
- [ ] AI2AI activity view is reachable if exposed
- [ ] Mesh health view is reachable if exposed
- [ ] Kernel / agent health view is reachable if exposed
- [ ] Learning / recommendation audit trail is reachable if exposed
- [ ] Locality / higher-agent movement view is reachable if exposed

### Kernel-By-Kernel Learning Verification

Check every kernel family or learning lane that is actually surfaced in the beta build.
If a family is intentionally hidden, mark `N/A`.

- [ ] Personal-agent / knot / DNA learning activates from real user actions if surfaced
- [ ] Surface-kernel truth path is sane if surfaced: `who`, `what`, `when`, `where`, `why`, `how`
- [ ] `mesh_runtime_governance` is healthy when nearby exchange is exercised if surfaced
- [ ] `ai2ai_runtime_governance` is healthy when AI2AI exchange is exercised if surfaced
- [ ] `mesh_learning_intake` registers governed learning from mesh exchange if surfaced
- [ ] `ai2ai_learning_governance` applies or safely buffers governed learning if surfaced
- [ ] Runtime OS operational-learning lane is directionally active if surfaced
- [ ] Event-planning learning path registers sanitized planning and outcome learning if exercised
- [ ] Locality / hierarchy learning path is directionally active if surfaced
- [ ] No surfaced kernel family appears stalled, contradictory, or unsafe in its learning behavior

### Simulation / Replay / Live Boundary

The beta contract is explicit: simulation and replay are priors, not reality.

- [ ] Live user behavior outranks preload, replay, or simulation assumptions
- [ ] Any surfaced replay / forecast / simulation output is clearly labeled as prior or non-live
- [ ] No live phone surface presents replay or simulation output as current reality
- [ ] Contradictory live behavior causes the system to adapt instead of clinging to stale priors
- [ ] No live phone build appears to run replay-only or simulation-training functionality as production truth
- [ ] If any internal simulation or forecast surface is exercised, it remains bounded and does not auto-promote to live truth

### Learning Registration And Truth Movement

- [ ] Meaningful user actions register learning
- [ ] AI2AI exchange creates bounded learning evidence if surfaced
- [ ] Recommendation or daily-drop behavior moves directionally after meaningful inputs
- [ ] Spot or locality truth can move directionally from behavior
- [ ] Raw private text or direct human identity does not leak through learning or audit surfaces

### Locality Agent Generation And Hierarchical Pathflow

The Birmingham beta hierarchy is:
1. personal reality agent
2. locality agents
3. Birmingham city agent
4. top-level reality agent

- [ ] Normal BHAM activity resolves into a seeded locality path
- [ ] Locality movement is visible in bounded form if surfaced
- [ ] Upward flow appears privacy-bounded by default
- [ ] Downward guidance reaches the human only through the personal agent
- [ ] No higher agent appears to message the human directly
- [ ] Optional controlled unseeded-locality test:
  - [ ] N/A
  - [ ] If exercised, seeding escalates for authorization and does not silently create unconstrained geography truth

### Admin / Privacy / Governance

- [ ] AI2AI activity is visible where expected
- [ ] Agent / kernel health is visible where expected
- [ ] Learning / recommendation audit trail is visible where expected
- [ ] Creation flows are visible where expected
- [ ] Privacy boundary remains pseudonymous by default
- [ ] No governance boundary appears bypassed during testing

## Platform Checklist

### iPhone

- [ ] Clean launch works
- [ ] Sign-in / sign-up works
- [ ] Onboarding completes
- [ ] Permissions behave intentionally
- [ ] First knot / DNA state is visible if surfaced
- [ ] First daily drop is meaningful enough to test
- [ ] Explore and core object detail flows work
- [ ] Save / respect / dismiss actions stick
- [ ] Event-planning path works if exercised
- [ ] Offline / reconnect behavior is coherent
- [ ] Background / foreground return is stable

### Android

- [ ] Clean launch works
- [ ] Sign-in / sign-up works
- [ ] Onboarding completes
- [ ] Permissions behave intentionally
- [ ] First knot / DNA state is visible if surfaced
- [ ] First daily drop is meaningful enough to test
- [ ] Explore and core object detail flows work
- [ ] Save / respect / dismiss actions stick
- [ ] Event-planning path works if exercised
- [ ] Offline / reconnect behavior is coherent
- [ ] Background / foreground return is stable

### Cross-Platform And Nearby

- [ ] iPhone ↔ Android nearby detection is directionally correct
- [ ] Exchange / release behavior is directionally correct
- [ ] Mesh/runtime state does not collapse after pairing
- [ ] Buffered vs applied learning counts move believably if surfaced
- [ ] Cross-platform path is not materially worse than same-platform in a launch-blocking way

### Event Planning Slice

- [ ] Optional personal-agent draft handoff can be exercised
- [ ] Event Truth step works
- [ ] `Cross Air Gap & Review` works
- [ ] Publish works
- [ ] Safety handoff works
- [ ] Host debrief works
- [ ] Raw planning text does not survive past the air gap
- [ ] Re-edit forces re-crossing the air gap

## Evidence Checklist

- [ ] Device / OS / build logged
- [ ] Accounts used logged
- [ ] Screenshots or recordings captured
- [ ] Receipt / log artifact paths captured
- [ ] Mesh health snapshot captured if pairing was exercised
- [ ] Kernel health snapshot captured if exposed
- [ ] Learning-registration evidence captured
- [ ] Pre / post recommendation or truth-state evidence captured if visible
- [ ] Event-planning receipt captured if used
- [ ] Issue IDs created for failures

## Blocker Check

- [ ] No launch or auth blocker
- [ ] No raw event-planning text survives the air gap
- [ ] No cross-platform AI2AI failure that breaks the beta promise
- [ ] No kernel or mesh instability that invalidates runtime trust
- [ ] No kernel-family learning lane that appears broken in an exposed critical surface
- [ ] No simulation or replay output presented as live truth
- [ ] No learning-registration failure after meaningful actions
- [ ] No false or frozen locality / spot truth movement
- [ ] No hierarchy-pathflow failure that breaks locality / city oversight
- [ ] No higher-agent direct-to-human speech

## Final Call

- [ ] Pass
- [ ] Pass with notes
- [ ] Fail

## Related Docs

- [13_FOLLOW_UP_DEVICE_QA_OUTLINE.md](./13_FOLLOW_UP_DEVICE_QA_OUTLINE.md)
- [04_OFFLINE_AI2AI_AND_DATA_CONTRACT.md](./04_OFFLINE_AI2AI_AND_DATA_CONTRACT.md)
- [05_ADMIN_GOVERNANCE_TRUTH_AND_SAFETY.md](./05_ADMIN_GOVERNANCE_TRUTH_AND_SAFETY.md)
- [10_REALITY_MODEL_BUILD_CONTRACT.md](./10_REALITY_MODEL_BUILD_CONTRACT.md)
- [12_REALITY_MODEL_AND_OS_BUILD_AUDIT.md](./12_REALITY_MODEL_AND_OS_BUILD_AUDIT.md)
