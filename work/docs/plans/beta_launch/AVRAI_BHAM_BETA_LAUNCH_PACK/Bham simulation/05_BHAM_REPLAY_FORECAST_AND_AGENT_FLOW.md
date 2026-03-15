# BHAM Replay, Forecast Kernel, And Agent Flow

**Date:** March 10, 2026  
**Status:** Active Wave 8 authority  
**Purpose:** Lock the authoritative BHAM replay shape, the forecast-kernel placement, and the runtime/engine/app/agent flow for Wave 8.

## 1. Normative Status

This document is explicit authority for Wave 8 architectural direction.

It defines:

1. what the authoritative BHAM replay path is
2. where the forecast or prediction kernel belongs
3. how governance interacts with prediction
4. how runtime OS, engine, app, and the agent hierarchy should cooperate

## 2. BHAM-Only Authoritative Replay

The authoritative replay path for Wave 8 is Birmingham-only.

Rules:

1. the canonical replay/training run is BHAM-only
2. Birmingham is the only geography that may be used for authoritative Wave 8 replay signoff
3. other cities may remain as legacy or research-only experiments
4. other-city runs must not be treated as the BHAM launch training baseline
5. the first governed replay year must be a Birmingham year selected by completeness scoring

This means:

1. replay artifacts used for BHAM launch must come from Birmingham
2. Wave 8 code paths presented as the authoritative replay path must no longer be multi-city by default
3. future cross-city transfer is allowed only after the BHAM replay and forecast contract is stable

## 3. Forecast Kernel Placement

Wave 8 should introduce a real forecast or prediction kernel, but it should not be a governance kernel.

Correct placement:

1. forecast or prediction kernel belongs to the Reality Engine lane
2. runtime OS consumes forecast outputs under governance
3. app does not call forecast internals directly

The forecast kernel is responsible for:

1. replay-derived priors
2. Monte Carlo branches
3. Markov or other transition structures
4. route, attendance, venue, and locality expectation generation
5. counterfactuals
6. uncertainty and confidence-bearing forward expectations
7. branch and run lineage

The forecast kernel must produce:

1. forecast outputs
2. uncertainty
3. provenance
4. branch ID
5. run ID
6. validity window
7. contradiction hooks for governance

## 4. Governance Over Prediction

Governance must supervise prediction rather than absorb it.

Governance owns:

1. forecast validity and freshness
2. contradiction handling
3. actionability thresholds
4. promotion and rollback of prediction logic
5. quarantine and downgrade of risky prediction outputs
6. admin inspection and auditability

Prediction owns:

1. forecasting
2. scenario branching
3. probability and uncertainty
4. counterfactual reasoning

The operating rule is:

1. prediction forecasts
2. governance judges
3. reality decides

Live user behavior, live locality evidence, and human-admin correction outrank forecast outputs immediately.

## 5. Prong Placement

### 5.1 Engine

Engine should own:

1. personal reality-agent cognition
2. locality-agent cognition
3. Birmingham city-agent cognition
4. top-level reality-agent cognition
5. forecast kernel logic
6. replay evaluation
7. truth formation
8. explanation and conviction logic

### 5.2 Runtime OS

Runtime OS should own:

1. kernel hosting
2. governance enforcement
3. transport and device mediation
4. operational execution
5. headless bootstrap
6. receipts, audits, and intervention mechanics
7. the bounded upward and downward flow between agents and governed runtime actions

### 5.3 App

App should own:

1. rendering
2. user input
3. route and page presentation
4. human-facing chat display

The app should not own:

1. truth authority
2. forecast authority
3. governance authority
4. raw engine internals

## 6. Agent Flow

The operating flow should be:

1. the app captures user action, request, or observed event
2. runtime OS builds governed kernel context
3. the personal reality agent performs first-order human-facing reasoning
4. if needed, truth or conflict escalates upward:
   - personal agent
   - locality agent
   - Birmingham city agent
   - top-level reality agent
5. higher agents return bounded guidance or conflict results downward
6. runtime OS decides whether and how the result may be surfaced or executed
7. the personal agent is the only layer that speaks to the human
8. the app renders the final governed result

Higher agents may speak to:

1. lower agents
2. admin

Higher agents may not speak directly to the human user.

## 7. Wave 8 Immediate Build Order

The next Wave 8 implementation order should be:

1. finish native authority for the beta-used governance lanes
2. keep `when` as the single timing authority
3. keep the authoritative replay path BHAM-only
4. add replay contracts:
   - replay temporal envelope
   - branch/run context
   - source provenance
   - validity window
   - replay-year completeness score
5. add the forecast kernel in the engine lane
6. add governance projections over forecast outputs
7. connect replay outputs into forecast training and evaluation
8. wire higher-agent inspection and admin visibility over replay and forecast lineage

Implementation note:

1. the first replay-contract slice should begin with four spine contracts:
   - `ReplayTemporalEnvelope`
   - `MonteCarloRunContext`
   - `ReplayYearCompletenessScore`
   - `GroundTruthOverrideRecord`
2. those four are enough to start real replay truth and the first engine forecast-kernel interface
3. a second tranche should follow immediately after:
   - `ReplaySourceDescriptor`
   - `ReplayEntityIdentity`
   - `ReplayTruthResolution`
   - `ReplayBranchLineage`
   - `ForecastEvaluationTrace`
   - `AgentLifecycleTransition`

## 8. Non-Goals

This document does not authorize:

1. returning to a canonical multi-city replay baseline for BHAM
2. making prediction itself a governance kernel
3. app-layer direct forecast or engine authority
4. user-facing higher-agent speech
