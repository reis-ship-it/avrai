# Hyperrealistic BHAM Simulation Plan

**Date:** March 9, 2026  
**Status:** Execution-planning authority  
**Goal:** Build a Birmingham replay and simulation system that is historically grounded, time-coherent, and still useful for current and future AVRAI behavior.

## 0. Scope lock

The authoritative Wave 8 replay/simulation path is Birmingham-only.

Rules:

1. Birmingham is the only canonical replay and training geography for BHAM beta
2. other-city simulation work may exist only as legacy research or future expansion material
3. NYC, Denver, Atlanta, Savannah, or any other city must not remain part of the authoritative BHAM replay gate
4. if a code path or training artifact is presented as the BHAM replay baseline, it must be Birmingham-only

## 1. End State

The BHAM simulation should eventually be able to:

1. replay Birmingham over a full decade-scale timeline using real dated events, venues, communities, neighborhoods, and movement priors, then run Monte Carlo branches across that temporal base
2. run under one atomic simulation clock so no future information leaks backward into earlier simulated time
3. drive real AVRAI app/runtime/engine decision paths rather than a disconnected toy simulator
4. feed a real forecast/prediction kernel with governed replay outputs rather than produce isolated simulation-only artifacts
5. produce training and evaluation outputs that remain useful for 2026 and beyond

The simulation is not just a history archive.
It is a temporally grounded training and evaluation system.
It is also the governed replay/training substrate for the future forecast kernel.

## 2. Non-Negotiable Rules

- one atomic simulation clock is authoritative
- every ingested record must carry real-world timing fields
- every source must carry provenance and trust tier
- every event/place/community/club/venue record must be normalized across sources
- no feature may train on future facts relative to the current simulated timestamp
- awards, rankings, recognitions, closures, openings, and news bursts only affect the simulation after their actual dates
- city population and AVRAI-agent population are not the same thing
- no personal AVRAI agent should exist in simulation for anyone under age 13
- prediction outputs derived from replay are priors until live reality and governance accept them

## 3. How To Avoid Getting Stuck In Time

The simulation must learn from the past without freezing the product in the past.

To do that, separate the system into four layers:

### 3.1 Historical replay layer

This layer replays what actually happened on the Birmingham timeline.

Use it for:

- event density
- neighborhood rhythms
- commuting patterns
- seasonality
- venue recurrence
- cancellation/edit behavior
- real-world activity cadence

This should ultimately span a decade-scale Birmingham window where sources allow, not just a single launch-year slice.

### 3.2 Current-state refresh layer

This layer updates the simulation starting point with current-source refreshes.

Use it for:

- currently operating venues
- current communities and clubs
- current venue reputational signals
- current public event calendars
- current locality shifts

### 3.3 Structural learning layer

This layer learns durable patterns that survive beyond one exact year.

Use it for:

- weekly and seasonal cycles
- commute and neighborhood flow tendencies
- venue-type demand curves
- repeat-attendance patterns
- discovery-to-attendance pathways
- community growth and decay dynamics

### 3.4 Forward scenario layer

This layer generates plausible current/future state from durable patterns plus refreshed live inputs.

Use it for:

- current Birmingham seeding
- launch-era recommendation tuning
- route and locality stress tests
- event-surge and lull simulations

The key design rule is:

- historical replay teaches structure
- current refresh keeps the world current
- forward scenarios keep the output useful after the replay window ends

### 3.5 Population and agent-lifecycle layer

The simulation should model a city, not pretend the entire city uses AVRAI.

Rules:

1. many humans may exist in the simulated city without personal AVRAI agents
2. only a subset of humans should carry AVRAI personal agents
3. personal agents may appear when a user is created or adopts AVRAI
4. personal agents may go dormant when a user stalls
5. personal agents must terminate when a user deletes
6. locality, city, and reality agents are system agents and follow separate lifecycle rules
7. no under-13 personal AVRAI agents may exist
8. under-13 humans may exist only as dependent-mobility influences on household, school, youth-sports, and locality rhythms

## 4. Priors, Ground Truth, And Transferability

The BHAM simulation should make AVRAI wiser, not arrogant.

The governing rule is:

1. Birmingham replay teaches priors, not current reality
2. live user behavior, live locality evidence, and live admin correction remain the authority
3. the simulation should teach the universal logistics of cities, not trap the system inside Birmingham facts

What should transfer:

- cause and effect in human logistics
- scarcity and budget friction
- commute and neighborhood rhythms
- weather and event influence on movement
- attendance, recurrence, and cancellation patterns
- discovery-to-attendance pathways

What must not transfer as assumed truth:

- whether a specific venue is open right now
- whether a specific community is active right now
- whether a specific place still has the same vibe right now
- whether a locality claim is current without fresh local support

For new-city bootstraps such as Savannah:

1. AVRAI should arrive with structural common sense learned from Birmingham and other governed replay sources
2. AVRAI must still request fresh locality seeding and live-source attachment before it behaves as if it knows the new city
3. fresh locality evidence must outrank imported priors immediately

## 5. Best Order Of Operations

### Phase 1: Source registry

Log every planned source before ingesting it.

Required source categories:

- census and LEHD movement priors
- city/open-data spatial and civic datasets
- official venue and event calendars
- tourism and city-guide event sources
- local news/event coverage
- awards and recognition sources
- historical archives and local-history sources

### Phase 2: Temporal schema

Create one replay schema with at least:

- source id
- source trust tier
- entity type
- normalized entity id
- observed at
- published at
- valid from
- valid to
- event start at
- event end at
- recurrence rule
- last verified at
- ingestion timestamp
- simulation branch id
- Monte Carlo run id
- temporal authority source
- uncertainty window

### Phase 3: Entity normalization

Build canonical Birmingham entity identity for:

- venues
- places
- events
- organizers
- communities
- clubs
- neighborhoods

This step is mandatory before large ingestion.

Storage gate:

Before any multi-year ingestion or decade-scale Monte Carlo expansion begins, the replay system must return to storage architecture and stop relying on large docs-folder JSON artifacts as the long-term destination.

Requirements:

1. large replay source packs and normalized observations move to a scalable artifact store
2. manifests, lineage, completeness scores, and audit metadata move to a queryable metadata store
3. any web viewer or dashboard remains a presentation layer, not the source of truth
4. multi-year ingestion remains blocked until this storage decision is explicit

### Phase 4: Historical intake

Ingest the highest-trust sources first.

Order:

1. official/public data
2. official venue calendars
3. trusted local event/news coverage
4. awards/recognition enrichment
5. secondary enrichment sources

### Phase 5: Replay harness

Run the replay through real AVRAI logic:

- app-visible object formation
- runtime recommendation and routing decisions
- engine/reality-model learning paths
- AI2AI and locality effects where applicable

This should become a decade-scale Monte Carlo replay harness, not a single deterministic pass.

### Phase 6: Current-state calibration

Refresh the simulated world with current-source truth so the resulting training outputs are not frozen at the end of the replay year.

### Phase 7: Forward-useful output generation

Produce outputs intended for current and future use:

- BHAM priors
- locality priors
- event expectation priors
- venue/community/club density priors
- seasonality priors
- route-timing and activity-window priors

## 6. Source Priority Model

### Tier 1: primary truth

Use as foundational truth when available:

- official city/public announcements
- official venue calendars
- official organizer calendars
- city/open-data/GIS layers
- Census / ACS / LEHD / OnTheMap

### Tier 2: secondary truth

Use for coverage expansion and cross-checking:

- Bham Now
- AL.com
- Birmingham Business Journal
- direct venue pages without structured exports
- tourism and guide calendars

### Tier 3: enrichment

Use only as influence/enrichment, never core truth:

- Garden & Gun recognition
- James Beard recognition
- Michelin recognition
- editorial lists and features
- social buzz/mention signals

### Tier 4: fallback-only

Use cautiously and only when compliant and necessary:

- brittle scraping targets
- low-structure social/event posts
- sources with weak provenance or difficult deduplication

## 7. What The Simulation Still Needs

- decade-scale BHAM historical event and venue history where sources allow
- canonical BHAM venue/place graph
- neighborhood and locality boundaries tied to replay entities
- recurrence/cancellation/edit history
- organizer/community/club identity linking
- provenance-preserving deduplication
- time-aware training and evaluation harness
- explicit population-to-agent adoption and lifecycle model
- explicit under-13 exclusion policy for personal agents

## 8. Immediate Next Artifact

The next artifact after this document is the explicit source registry and replay intake plan.

That registry should be exhaustive enough that future ingestion work is governed by it rather than driven ad hoc.
