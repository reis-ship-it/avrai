# BHAM Source Registry And Replay Intake Plan

**Date:** March 9, 2026  
**Status:** Active build-order document  
**Goal:** Create the strongest possible BHAM seeding list before large-scale ingestion starts.

## 1. Why This Comes First

The BHAM simulation will fail if it starts as random scraping.

The source registry comes first because it:

- prevents future-data leakage
- forces source trust and timing to be explicit
- separates foundational truth from enrichment
- creates the ingestion backlog in the right order

## 2. Registry Fields

Every source entry should eventually include:

- source name
- source owner
- source URL or access point
- source type
- access method
- trust tier
- legal/usage notes
- entity coverage
- temporal coverage
- update cadence
- structured export availability
- planned ingest fields
- replay role
- dedupe keys
- current status
- agent-seeding eligibility
- age-safety notes

## 3. Initial Source Classes To Register

### Population and movement

- U.S. Census ACS
- LEHD / OnTheMap
- any Birmingham or regional commuting/public mobility data that is legally available

Use for:

- population priors
- neighborhood density
- commuter flows
- work-hour/day-night movement priors

### Spatial and civic truth

- City of Birmingham OpenGov / open-data datasets
- regional GIS / planning datasets
- neighborhood, district, and locality layers
- public permits / civic event announcements when available

Use for:

- place grounding
- boundary grounding
- civic event truth
- locality geometry

### Official event and venue truth

- official venue calendars
- official organizer calendars
- official civic calendars
- tourism calendars
- structured event feeds / ICS / Eventbrite / Meetup where allowed
- reservation platforms such as Resy / OpenTable where allowed
- delivery and ordering platforms where legally available in structured or partner-export form

Use for:

- event truth
- recurrence
- cancellation/edit history
- venue activity density
- dining demand windows
- reservation pressure and table scarcity
- meal-period popularity and locality food rhythm

### Local reporting and public narrative

- Bham Now
- AL.com
- Birmingham Business Journal
- local arts/food/culture reporting

Use for:

- event cross-verification
- venue openings/closures
- organizer/community visibility
- major city rhythm detection

### Recognition and editorial prestige

- Garden & Gun
- James Beard
- Michelin
- other recognized Birmingham-specific editorial or award signals

Use for:

- prestige and attention enrichment after actual award/publication dates

### Historical and archival sources

- library archives
- local history sites
- city history sources
- public announcement archives

Use for:

- recurring event history
- long-lived place memory
- neighborhood identity context

### Reservation and delivery demand signals

- Resy
- OpenTable
- venue-operated reservation exports
- delivery/order platforms or partner exports where legally available

Use for:

- seat-demand and booking-pressure windows
- dining popularity shifts over time
- launch/decline curves for new restaurants
- neighborhood meal-delivery demand
- timing of food-traffic surges versus in-person attendance

Rules:

- do not treat reservation or delivery data as sole proof that a venue is open, closed, healthy, or culturally important
- do not let these sources override official venue truth, locality evidence, or admin/governance truth by themselves
- use these sources as high-value demand and occupancy signals after venue identity is normalized
- require explicit legal/access review before ingestion
- if item-level order data is ever available, store only governed aggregate behavioral patterns, not raw personal order histories

## 4. Temporal Intake Rule

Every record must be stored so replay can answer:

- when was this fact first knowable?
- when was it true in the world?
- when did it stop being true?
- how certain is the timing?

Minimum timing fields:

- `observed_at`
- `published_at`
- `valid_from`
- `valid_to`
- `event_start_at`
- `event_end_at`
- `last_verified_at`
- `simulation_branch_id`
- `monte_carlo_run_id`
- `temporal_authority_source`
- `uncertainty_window`

## 5. Ingestion Order

1. register all candidate sources
2. mark trust tier and legal/access status
3. define normalized entities and dedupe keys
4. ingest Tier 1 sources
5. ingest Tier 2 sources and link them to existing entities
6. ingest Tier 3 enrichment only after the core entity graph exists

## 6. What Not To Do Yet

- do not start with Facebook scraping as the foundation
- do not use Instagram mentions as a primary venue/event truth layer
- do not use financial/earnings estimates as core event or gathering truth
- do not use reservation/delivery ranking as a substitute for locality truth or community significance
- do not mix undated or weakly dated facts into the replay timeline without explicit uncertainty handling
- do not let youth- or child-adjacent sources create under-13 personal AVRAI agents
- do not treat city-population sources as proof that every simulated human has an AVRAI personal agent

## 7. Next Practical Step

Turn this document into a concrete registry table and start filling it with:

1. source
2. trust tier
3. entity coverage
4. time coverage
5. ingest priority

That is the strongest next move before building the replay schema implementation.
