# BHAM Simulation Improvement Roadmap 2026

**Date:** March 14, 2026  
**Status:** Planning authority for simulation improvements after the accepted 2023 BHAM truth-year base  
**Scope:** What AVRAI should borrow from simulation-first systems like MiroFish, what it should reject, and what to add in three phases:
- now for beta
- now for pre-beta training from simulation
- directly post beta
- v1 launch

## Purpose

This document turns the MiroFish comparison into an AVRAI execution roadmap.

The goal is not to make AVRAI "more like MiroFish."
The goal is to make AVRAI's BHAM simulation lane:

- easier to author
- easier to inspect
- easier to compare across branches
- more useful for real event and locality planning
- more responsive to contradiction from live Birmingham behavior

## Current BHAM Baseline

BHAM is already far beyond a toy simulation demo.

The current simulation workspace has:

- one accepted Birmingham-only truth-year base in [README.md](./README.md#L1)
- explicit replay/forecast/kernel authority in [05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md](./05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md#L1)
- an isolated replay world with blocked live ingress in [40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md](./40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md#L1)
- all 9 required replay-participating kernels active in [53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.md](./53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.md#L1)
- realism, calibration, higher-agent behavior, and training-readiness all passing in [54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.md](./54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.md#L1)
- a training-grade export with `257898` action records and `423666` counterfactual choices in [58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md](./58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md#L1)
- holdout evaluation passing on 2023 windows in [69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.md](./69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.md#L1)

The current replay base is therefore strong on:

- isolation
- provenance
- kernel participation
- hierarchy
- calibration
- training export readiness

It is weaker on:

- scenario authoring ergonomics
- branch comparison ergonomics
- actor richness visible to humans
- intervention vocabulary breadth
- locality readability for operators
- clear operator-facing simulation receipts

## AVRAI Advantages Over MiroFish

AVRAI is stronger than MiroFish in the areas that matter for a real civic and product system.

1. AVRAI has the correct truth contract.
   Simulation is prior and live evidence is ground truth in [10_REALITY_MODEL_BUILD_CONTRACT.md](./../10_REALITY_MODEL_BUILD_CONTRACT.md#L28).
2. AVRAI has a governed hierarchy.
   Birmingham beta is explicitly personal -> locality -> Birmingham city -> top-level reality in [10_REALITY_MODEL_BUILD_CONTRACT.md](./../10_REALITY_MODEL_BUILD_CONTRACT.md#L69).
3. AVRAI separates human-reality learning from execution-reality learning.
   That separation is explicit in [10_REALITY_MODEL_BUILD_CONTRACT.md](./../10_REALITY_MODEL_BUILD_CONTRACT.md#L228).
4. AVRAI is locality-first.
   The authoritative replay and launch baseline is BHAM-only, not generic multi-city simulation, in [05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md](./05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md#L18).
5. AVRAI is already training-grade.
   BHAM replay has full kernel bundles, higher-agent traces, counterfactuals, outcomes, and holdout passes in [58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md](./58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md#L1).

So the operating stance is:

- borrow MiroFish's simulation usability
- do not borrow MiroFish's temptation to let simulation become self-justifying reality

## What To Borrow From MiroFish

AVRAI should borrow these patterns:

1. seed -> scenario -> branch -> report flow
2. variable injection through bounded intervention cards
3. side-by-side branch comparison
4. readable agent/world reports for humans
5. easier narrative inspection of why a branch changed

## What To Reject From MiroFish

AVRAI should reject these patterns:

1. simulation output presented as if it were current live truth
2. unconstrained seed-to-world generation without strong provenance and timing controls
3. generic “predict anything” framing detached from locality and governance
4. free-floating agent worlds with weak operational connection to runtime OS
5. reportability without contradiction receipts and confidence lineage

## BHAM-Specific Weak Spots To Improve

These are the clearest current BHAM improvement areas.

### 1. Forecast coverage is still too narrow

The virtual world has `1295` observations, but only `87` forecast-evaluated observations in [40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md](./40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md#L1).

That is enough to prove the lane exists.
It is not enough to make the simulation feel like a rich planning lab.

### 2. Representative actors are still too archetypal

The population base is strong at `25000` modeled actors in [50_BHAM_REPLAY_POPULATION_PROFILE_2023.md](./50_BHAM_REPLAY_POPULATION_PROFILE_2023.md#L1), but visible actor types are still coarse templates such as:

- `student_shared_agent`
- `working_commuter_agent`

Those are useful scaffolding, but they are too thin for robust event planning or locality stress tests.

### 3. Daily behavior is still too schedule-heavy

Daily behavior is dominated by:

- `routine_anchor`
- `weekday_routine`
- `weekend_anchor`

in [56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.md](./56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.md#L1).

That makes the replay legible, but not yet human-messy enough.

### 4. Higher-agent action vocabulary is still narrow

The higher-agent behavior pass is real and useful, but the action family is still concentrated around:

- `handoffLocalityDigestToPersonalAgents`
- `stabilizeLocalityTruth`
- `personalPlanDailyCircuit`

in [44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.md](./44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.md#L1).

That is not yet enough for citywide event and operational simulation richness.

### 5. Locality representation is accurate but not operator-friendly enough

BHAM has real locality coverage, but many surfaces still read like tract-heavy engineering outputs.

AVRAI should preserve tract precision while also exposing neighborhood-readable operator overlays such as:

- Avondale
- Southside
- Downtown
- Uptown
- Lakeview

### 6. Calibration is stronger on counts than on dynamic behavior quality

The calibration report passes cleanly in [57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md](./57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md#L1), but the visible metrics are still dominated by coverage and count targets.

The next step is richer calibration of:

- uncertainty quality
- transition plausibility
- intervention reliability
- contradiction response speed
- locality-to-locality flow realism

## Phase 1: Add Now For Beta And Pre-Beta Simulation Training

This phase is the immediate next move.
It should improve beta usefulness without changing the core truth contract.

### 1A. Add Now For Beta

These additions should help operators and admins during beta itself.

1. Add `ScenarioPacket` authoring for replay-only use.
   A human should be able to define:
   - scenario goal
   - locality scope
   - branch assumptions
   - intervention card set
   - expected contradiction points
2. Add branch comparison outputs.
   Every governed simulation run should be able to show:
   - baseline branch
   - intervention branch
   - delta summary
   - confidence/uncertainty
   - contradiction risk
3. Add simulation receipts that explicitly say:
   - what came from replay prior
   - what came from live evidence
   - what came from locality consensus
   - what came from admin correction
4. Add an internal event scenario pack for Birmingham beta.
   First scenarios should cover:
   - citywide event attendance surge
   - venue closure
   - weather degradation
   - traffic / transit friction
   - staffing shortfall
   - locality caution spike
5. Add a contradiction dashboard.
   This should show where live BHAM beta behavior is diverging from replay priors.
6. Add neighborhood-readable locality overlays for operator views.
   Do not replace tract precision. Add an interpretable overlay above it.

### 1B. Add Now For Pre-Beta Training From Simulation

These additions should improve the quality of the pre-beta training lane before more live data arrives.

1. Expand representative actor latent factors.
   Add at least:
   - budget pressure
   - transport dependence
   - household friction
   - accessibility constraints
   - nightlife tolerance
   - weather sensitivity
   - volunteer / organizer reliability
   - social follow-through probability
2. Expand the intervention vocabulary beyond current replay actions.
   Add scenario verbs for:
   - reroute
   - overflow redirect
   - caution burst
   - turnout downgrade
   - turnout upgrade
   - locality saturation
   - staffing depletion
   - recovery recommendation
3. Increase forecast-evaluated observation coverage.
   The goal is not “simulate everything.”
   The goal is to cover a much wider set of event, locality, and movement outcomes than the current `87`.
4. Add branch templates for:
   - small neighborhood event
   - multi-locality festival
   - weather-disrupted weekend
   - major venue overload
   - campus / downtown split attendance
5. Add calibration dimensions for:
   - uncertainty honesty
   - branch divergence realism
   - event turnout plausibility under stress
   - locality pressure and recovery
   - actor routine breakage realism
6. Add cleaner operator-ready simulation reports.
   Replay artifacts should already be good enough for machines.
   Now they need to be easier for humans to inspect quickly.

### Phase 1 Non-Goals

Do not do these now:

1. do not let replay or simulation become live app truth
2. do not add user-facing higher-agent speech
3. do not re-open multi-city baseline authority
4. do not make prediction a governance kernel
5. do not introduce uncontrolled generative worldbuilding just because it looks impressive

## Phase 2: Directly Post Beta

This phase begins once real Birmingham beta behavior has accumulated enough weight to critique the simulation.

### Core Goal

Turn replay priors into a self-correcting Birmingham simulation lane that is trained against actual beta contradiction and outcome data.

### Additions

1. Add `SimVsLiveContradictionLedger`.
   Every meaningful live contradiction to replay priors should be recorded and explainable.
2. Reweight replay priors using live beta behavior.
   This should happen at:
   - personal level
   - locality level
   - event level
   - runtime operational level
3. Add locality-specific correction loops.
   If one neighborhood behaves unlike its replay prior, that should not globally corrupt Birmingham.
4. Add runtime operational-learning feedback from beta.
   Feed in:
   - recovery outcomes
   - queue behavior
   - transport reliability
   - BLE / local Wi-Fi quality
   - notification timing quality
5. Expand higher-agent action vocabulary from observed beta contradictions.
   The simulation should learn better verbs from actual Birmingham mismatches.
6. Add post-beta event packs trained from real event outcomes.
   That should include:
   - actual turnout vs predicted turnout
   - staffing gaps
   - weather response quality
   - locality overflow behavior
   - post-event satisfaction by event shape
7. Add simulation-to-ops report loops.
   The output should become useful not just for model training but for:
   - admin decisions
   - event planning
   - locality diagnostics

### Phase 2 Gate

This phase is ready when:

1. live contradiction patterns can be measured cleanly
2. beta behavior is rich enough to expose replay blind spots
3. simulation reports can be scored against real observed outcomes

## Phase 3: V1 Launch

This phase turns the BHAM simulation lane from a strong internal training rig into a first-class governed planning capability.

### Core Goal

Make simulation a trustworthy, bounded, city/use-case planning layer inside AVRAI without ever confusing it with live reality.

### Additions

1. Build a real internal scenario lab for:
   - admin
   - locality operators
   - governed event planning
2. Add production-grade branch libraries for:
   - event operations
   - locality shifts
   - weather and movement stress
   - safety and staffing preparation
   - venue and corridor planning
3. Add dynamic locality twins refreshed by live evidence.
   These are not permanent fantasies.
   They are governed, bounded, evidence-bearing simulation views.
4. Add uncertainty-calibrated planning outputs.
   Operators should see:
   - expected outcome
   - uncertainty band
   - reason provenance
   - contradiction risk
   - live override conditions
5. Expand actor realism with richer household, life-stage, constraint, and participation dynamics.
6. Add multi-run comparison packs for real use cases.
   First-class examples:
   - citywide spring festival
   - downtown sports spillover
   - weather-disrupted weekend
   - locality activation weekend
   - volunteer shortage recovery
7. Add stronger simulation-to-live calibration service.
   The system should continuously score whether scenario predictions were directionally useful once reality arrived.
8. Only after BHAM is stable, consider cautious cross-city transfer.
   Even then:
   - BHAM remains the launch-grounded authority
   - other cities are transfer candidates, not replacement baselines

### V1 Launch Non-Goal

Do not position AVRAI as an unconstrained “predict anything” machine.

The correct position is:

- governed locality and event simulation
- bounded scenario planning
- evidence-bearing forecast support
- live-truth override always preserved

## Recommended Immediate Build Order

If this roadmap is followed, the next implementation order should be:

1. `ScenarioPacket`
2. branch diff + simulation receipt surfaces
3. event and locality intervention pack templates
4. richer actor latent-factor model
5. forecast coverage expansion beyond the current narrow evaluated set
6. contradiction dashboard
7. post-beta `SimVsLiveContradictionLedger`
8. simulation-to-ops report loop

## Decision Rule

Any change inspired by MiroFish must answer:

1. Does this make AVRAI simulation more usable?
2. Does it preserve the rule that simulation is prior and live evidence is truth?
3. Does it strengthen BHAM locality realism?
4. Does it improve branch comparison, contradiction handling, or operator understanding?
5. Does it avoid turning AVRAI into a flashy but ungoverned worldbuilding demo?

If the answer to `2` is ever `no`, the change should not ship.

## External Comparison References

- [MiroFish demo](https://mirofish-demo.pages.dev)
- [MiroFish repository](https://github.com/666ghj/MiroFish)
- [BettaFish repository pointer to MiroFish](https://github.com/666ghj/BettaFish)
- [Public repository analysis gist](https://gist.github.com/passeth/9387e4fd5fd91d69778c7f4df076f62c)
