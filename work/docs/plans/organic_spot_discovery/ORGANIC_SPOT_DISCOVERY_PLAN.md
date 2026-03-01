# Organic Spot Discovery Plan

**Date:** February 10, 2026  
**Status:** 🟢 Active  
**Priority:** HIGH  
**Timeline:** 1-2 weeks  
**Phase:** Connects to Phase 1 (Outcome Data), Spot System, Perpetual List Orchestrator

---

## Philosophy Alignment

### Doors Questions (MANDATORY)

1. **What doors does this help users open?**
   - Doors to places that don't exist on any map -- hidden parks, favorite garages, rooftop views, secret spots that only locals know. These are the doors that matter most because they're *real* -- not curated by Google or Yelp, but discovered through living.

2. **When are users ready for these doors?**
   - From the very first visit. The system starts learning unregistered locations from day one. A user who visits the same unmarked park bench 3 times is ready to have that place surfaced as *their* spot.

3. **Is this being a good key?**
   - Yes. It doesn't force spot creation -- it gently suggests "You've been here 4 times. Want to save this as a spot?" The user decides. The key shows the door; the user opens it.

4. **Is the AI learning with the user?**
   - Absolutely. Every unmatched visit teaches the system. Every created spot from a discovery teaches it what kinds of places matter to this person. The mesh shares anonymized signals so the system collectively learns where hidden doors are.

---

## Problem Statement

Currently, when `LocationPatternAnalyzer.recordVisit()` encounters a location that doesn't match any known place (Google Places, Apple Maps, or community-created spots), the visit is recorded with `placeId: null` and `category: 'unknown'`. This data is stored but never analyzed for patterns.

This means:
- Users who repeatedly visit unmarked locations get no benefit from that behavior
- The system can't learn that a particular GPS cluster is meaningful
- Hidden gems (parks, garages, rooftops, informal gathering spots) never enter the system
- The community can't benefit from collective discovery of informal places

---

## Solution Architecture

### Core Concept: Learned Spots

A "learned spot" is a location the system discovers organically from user behavior, not from any external database. The lifecycle:

```
Unmatched visit (placeId: null)
    ↓
Cluster by geohash (precision 7, ~153m)
    ↓
Track cluster frequency + dwell time
    ↓
Threshold reached (3+ visits OR 2+ mesh users)
    ↓
DiscoveredSpotCandidate created
    ↓
User prompted to create spot (or auto-suggested)
    ↓
Full Spot created → enters quantum/knot/fabric pipeline
    ↓
Feeds back into recommendations for similar users
```

### Integration Map

| Existing Service | Integration Point | What Flows |
|-----------------|-------------------|------------|
| `LocationPatternAnalyzer` | `recordVisit()` hook | Unmatched visits → discovery service |
| `GeohashService` | Geohash clustering | Lat/lon → geohash at precision 7 |
| `AtomicClockService` | Timestamps | Atomic timestamps for all discovery events |
| `ContinuousLearningSystem` | Discovery events | Feeds discovery as learning signal |
| `PersonalityLearning` | Personality evolution | Spot creation from discovery → explorer/curator traits |
| `AnonymousCommunicationProtocol` | Mesh sharing | Anonymized cluster signals (geohash + visit count) |
| `LocalityAgentEngine` | Locality updates | Discovered spots update locality vectors |
| `ContextEngine` | Recommendation context | Include discoveries in list generation |
| `PerpetualListOrchestrator` | List suggestions | Surface discovered spots in perpetual list |
| `EpisodicMemory` | Outcome recording | (state, discover_spot, state_after, outcome) tuples |
| `AutomaticCheckInService` | Visit events | Geofence/Bluetooth triggers feed into discovery |
| `CreateSpotPage` | User spot creation | Pre-filled from discovery candidate |

### Key Design Decisions

1. **Geohash precision 7 (~153m)** -- Same as locality agents, appropriate for spot-level clustering
2. **Individual threshold: 3+ visits** -- Enough to establish pattern, not so high as to miss meaningful places
3. **Community threshold: 2+ unique users** -- If multiple people independently visit the same unmarked area, it's likely meaningful
4. **Never auto-create spots** -- Always prompt user or suggest; user decides (doors philosophy)
5. **Privacy-preserving mesh sharing** -- Only share geohash + anonymized visit count, never raw GPS or user identity
6. **Offline-first** -- All clustering and detection works on-device with zero connectivity

---

## Implementation Components

### 1. DiscoveredSpotCandidate Model
**File:** `lib/core/models/discovered_spot_candidate.dart`

Fields: id, centroid lat/lon, geohash, visit count, unique user count (from mesh), confidence score, suggested category (inferred from timing/dwell patterns), status (detected/prompted/created/dismissed), first/last visit timestamps, visit history summary.

### 2. OrganicSpotDiscoveryService
**File:** `lib/core/services/places/organic_spot_discovery_service.dart`

Core methods:
- `processUnmatchedVisit()` -- Called after each unmatched visit
- `getDiscoveryCandidates()` -- Get current candidates above threshold
- `processMeshDiscoverySignal()` -- Handle incoming mesh cluster signals
- `promptUserForDiscovery()` -- Surface discovery to user at right time
- `convertCandidateToSpot()` -- Create full Spot from candidate
- `dismissCandidate()` -- User rejected the suggestion

### 3. LocationPatternAnalyzer Integration
Hook into `recordVisit()` to call discovery service when `placeId` is null.

### 4. Mesh Integration
New mesh message type: `organic_spot_discovery` with scope 'locality', TTL 48 hours.

### 5. Learning Integration
Discovery events feed into ContinuousLearningSystem as `location_intelligence` learning dimension.

---

## Dependencies

- `LocationPatternAnalyzer` (existing -- hooks into it)
- `GeohashService` (existing -- uses for clustering)
- `AtomicClockService` (existing -- timestamps)
- `GetStorage` (existing -- persistence pattern matches LocationPatternAnalyzer)
- `AnonymousCommunicationProtocol` (existing -- mesh sharing)
- `ContinuousLearningSystem` (existing -- learning signals)
- `PersonalityLearning` (existing -- personality evolution)

No new external dependencies required.

---

## References

- **Doors Philosophy:** `docs/plans/philosophy_implementation/DOORS.md`
- **Spots System:** `docs/plans/spots/SPOTS_SYSTEM_COMPREHENSIVE_ORGANIZATION.md`
- **Master Plan Phase 1:** `docs/MASTER_PLAN.md` (Outcome Data & Memory)
- **Foundational Decision #1:** Intelligence-First (learned spots > hardcoded formulas)
- **Foundational Decision #7:** Chat-as-Accelerator (discovery works without user telling AI anything)
- **Foundational Decision #4:** On-Device Everything (all clustering on-device)

---

**Last Updated:** February 10, 2026
