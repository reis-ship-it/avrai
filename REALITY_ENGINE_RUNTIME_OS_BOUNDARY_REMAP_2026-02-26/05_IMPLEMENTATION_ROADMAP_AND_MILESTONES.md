# 05 - Implementation Roadmap and Milestones

## 1) Delivery Strategy

No big-bang rewrite.
Run boundary hardening and extraction in parallel with active Master Plan execution.

## 2) 30 / 60 / 90 Plan

### Day 0-30: Boundary Stabilization

1. Add boundary CI checks and forbidden import matrix.
2. Publish engine/runtime/app contract skeleton.
3. Start decomposition of `ContinuousLearningSystem` into port-based modules.
4. Add capability profile contract and basic runtime negotiation path.

Exit criteria:
- checks wired and running in CI
- initial contract docs merged
- decomposition workstream started with test baseline

### Day 31-60: Runtime and Engine Extraction

1. Move first engine modules behind runtime contracts.
2. Create runtime adapter stubs for all target OSs.
3. Add headless engine smoke test lane.
4. Implement host adapter mappers for AVRAI app.

Exit criteria:
- engine module path has no app imports
- runtime adapters compile and pass interface tests
- headless smoke passes in CI

### Day 61-90: Cross-OS and Lifecycle Hardening

1. Fill capability matrix with validated adapter behavior.
2. Split runtime/app artifact versioning and rollback policy.
3. Add cross-OS interop test matrix.
4. Switch boundary checks from baseline to tighter mode.

Exit criteria:
- cross-OS contract matrix green for supported lanes
- rollback policy documented and tested
- strict boundary policy active for target paths

## 3) Suggested Milestone Blocks (Execution Board)

1. `M?-P10-?` Runtime/Engine boundary guard enablement
2. `M?-P1-?` Continuous learning extraction to contracts
3. `M?-P7-?` Runtime lifecycle + artifact split
4. `M?-P8-?` Cross-OS transport/capability conformance
5. `M?-P10-?` Host adapter conformance and monitoring split

## 4) Risk Controls

1. Behavior drift risk
- Mitigate with no-drift regression suite and replay comparison.

2. Cross-OS inconsistency risk
- Mitigate with capability-tier planning and explicit downgrade behavior.

3. Velocity risk
- Mitigate by phased extraction, not freeze/rewrite.

4. Governance drift risk
- Mitigate by adding milestone-level acceptance and CI gates.

