# BHAM Source Reality Audit 2023

**Date:** March 12, 2026  
**Purpose:** distinguish sources that are truly feeding the BHAM replay from sources that are only registered, scaffolded, or gated

## Summary

- Total registry sources: `37`
- Approved: `33`
- Candidate: `4`
- Unique sources actually applied in replay artifacts so far: `19`
- Automated in pull plan: `7`
- Real automated puller classes implemented: `8`
- Historical replay-safe automated pullers: `4`
- API-key-required: `1`
- Review-gated: `4`

## Applied Now

These sources are already feeding governed replay artifacts, even if some are still seed-grade or partial:

- `ALDOT Long-Term Construction Projects`
- `ALDOT Traffic Data`
- `BEA / U.S. Census Bureau Economic Series`
- `Bhamwiki`
- `Birmingham Public Library Archives`
- `Birmingham Public Library Network`
- `Birmingham365.org`
- `City of Birmingham OpenGov`
- `City of Birmingham Play Pages`
- `BJCC / Legacy Arena / Protective Stadium Calendars`
- `Eventbrite / Meetup`
- `IN Birmingham (CVB Calendar)`
- `Jefferson / Shelby / Regional GIS and Assessors`
- `Major Venue Calendars and Historical Venue Calendars`
- `NWS / NOAA Weather API`
- `Neighborhood Association Calendars`
- `OpenStreetMap POI Data`
- `U.S. Census ACS`
- `UAB Academic, Clinical, and Event Calendars`

## Operational Now

These sources are not only in artifacts, but also have actual runtime puller/adapter support behind them:

- `BEA / U.S. Census Bureau Economic Series`
  - real automated puller exists
  - currently operational for the validated `CAINC1 line 3` county aggregate lane
- `NWS / NOAA Weather API`
  - real automated puller exists
  - current endpoint is useful for current-state calibration, not yet authoritative historical 2023 replay weather
- `OpenStreetMap POI Data`
  - real automated puller exists
  - currently operational as a replay-year date-constrained historical 2023 spatial snapshot
- `U.S. Census ACS`
  - real automated puller exists
  - historical replay-ready tract population and housing series
- `ALDOT Long-Term Construction Projects`
  - manual-import path works
- `ALDOT Traffic Data`
  - manual-import path works
- `City of Birmingham OpenGov`
  - manual-import path works
- `UAB Academic, Clinical, and Event Calendars`
  - manual-import path works
- `Bhamwiki`
  - historical archive adapter works
- `Birmingham Public Library Network`
  - spatial/manual path works
- `Birmingham Public Library Archives`
  - real automated puller exists
  - official `cobpl.org` fallback chain now validates in the live automated pull batch
- `City of Birmingham Play Pages`
  - manual official-event path works
- `BJCC / Legacy Arena / Protective Stadium Calendars`
  - manual official-event path works
- `Birmingham365.org`
  - calendar/manual path works
- `Major Venue Calendars and Historical Venue Calendars`
  - spatial/manual path works
- `Jefferson / Shelby / Regional GIS and Assessors`
  - real automated puller now exists
  - currently operational as a public spatial catalog lane after live automated pull validation
  - first safe-subset governed 2023 historical locality anchors now exist in `31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.*` and `32_BHAM_PUBLIC_CATALOG_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.*`
- `IN Birmingham (CVB Calendar)`
  - real automated puller now exists
  - currently operational as a public tourism/community catalog lane after live automated pull validation
  - first safe-subset governed 2023 structural community rows now exist in `31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.*` and `32_BHAM_PUBLIC_CATALOG_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.*`
- `Eventbrite / Meetup`
  - real automated puller now exists
  - currently operational as a public community-event catalog lane after live automated pull validation, not yet as governed 2023 historical event truth
- `Neighborhood Association Calendars`
  - first governed archival-reconstruction source pack now exists
  - current lane now contributes 2023 community-cadence truth for East Avondale, Glen Iris, and Wylam through `33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.*` and `34_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_NORMALIZED_OBSERVATIONS_2023.*`

## Scaffolded But Waiting On Raw 2023 Data

These are governed and correctly categorized, but still need real 2023 rows:

- `Jefferson / Shelby / Regional GIS and Assessors`
- `IN Birmingham (CVB Calendar)`
- `Eventbrite / Meetup`
- `Samford University Calendars and Campus Map`
- `UAB / Samford Enrollment Origin Reports`
- `SEC / College Football Broadcast Schedules`
- `BHM Airport / TSA Throughput`
- `MAX Transit GTFS`
- `LEHD / OnTheMap`
- `Bureau of Labor Statistics / State DOL`
- `Municipal Budgets and Revenue Reports`
- `Real Estate and Rent Index`
- `Google Places / Yelp`
- `Bham Now / AL.com / Birmingham Business Journal`
- `WBHM 90.3 Public Radio`
- `James Beard / Garden & Gun / Michelin`
- `REV Birmingham Updates`

## Review-Gated

These should not be treated as replay-ready yet:

- `Resy / OpenTable / Venue Reservation Exports`
- `Delivery / Ordering Platform Aggregates`
- `Data Axle / InfoGroup Business Listings`
- `County / Municipal Courts and Police Dispatch`

## Audit Conclusion

Not every source is "real" for the simulation yet.

The source stack currently has three different states:

1. **applied now**
2. **operational now**
3. **scaffolded or gated**

The BHAM replay is already real enough to run on a meaningful subset of sources, but the remaining realism gap is concentrated in:

- true citywide OSM/GIS place truth
- broader archived event/calendar extraction
- historical weather/archive truth instead of current-alert calibration
- neighborhood/community row population
- broader tourism/event archive extraction beyond official city and BJCC rows
- major-institution and transport flow enrichment
- historical GIS parcel/building truth beyond the OSM replay snapshot
- richer replay-world dynamics beyond the first isolated single-year replay pass

## Immediate Next Moves

1. deepen 2023 historical GIS parcel/building truth beyond the current safe-subset `RPCGB` locality anchors
2. expand true archived 2023 event and group coverage beyond the current historicalized `Eventbrite / Meetup` community-anchor safe subset
3. populate the remaining citywide 2023 manual lanes:
   - `Eventbrite / Meetup`
   - richer `Jefferson / Shelby / Regional GIS and Assessors`
   - richer `IN Birmingham (CVB Calendar)` beyond structural community anchors
4. use the isolated single-year replay pass as the quality gate for new 2023 truth additions before any multi-year ingestion
