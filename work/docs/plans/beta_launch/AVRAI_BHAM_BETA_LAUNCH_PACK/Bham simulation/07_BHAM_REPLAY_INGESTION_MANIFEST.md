# BHAM Replay Ingestion Manifest

- Replay year: `2023`
- Generated at: `2026-03-12T06:10:00.618463Z`
- Overall completeness score: `0.723`
- Ready sources: `33`
- Pending review sources: `4`
- Blocked sources: `0`

## Canonical Entity Types

- `club`
- `community`
- `economic_signal`
- `environmental_signal`
- `event`
- `housing_signal`
- `locality`
- `movement_flow`
- `population_cohort`
- `venue`

## Source Plans

- `ALDOT Long-Term Construction Projects` [priority `1` / `ready`] -> event, locality, movement_flow
  dedupe: project_id, segment_id
  note: Eligible to seed governed replay/entity priors.
- `ALDOT Traffic Data` [priority `1` / `ready`] -> locality, movement_flow
  dedupe: segment_id, date
  note: Eligible to seed governed replay/entity priors.
- `BEA / U.S. Census Bureau Economic Series` [priority `1` / `ready`] -> economic_signal, population_cohort
  dedupe: county_fips, series_id, year
  note: Eligible to seed governed replay/entity priors.
  note: Aggregate-only source; never instantiate under-13 personal agents.
- `BHM Airport / TSA Throughput` [priority `1` / `ready`] -> event, locality, movement_flow
  dedupe: airport_code, date
  note: Eligible to seed governed replay/entity priors.
- `Bureau of Labor Statistics / State DOL` [priority `1` / `ready`] -> venue
  dedupe: metro_code, occupation_code, year_month
  note: Eligible to seed governed replay/entity priors.
  note: Adult labor patterns only; do not create under-13 personal agents.
- `City of Birmingham OpenGov` [priority `1` / `ready`] -> community, event, locality
  dedupe: dataset_id, neighborhood_name, revision_date
  note: Eligible to seed governed replay/entity priors.
- `Jefferson / Shelby / Regional GIS and Assessors` [priority `1` / `ready`] -> locality, venue
  dedupe: parcel_id, address, county
  note: Eligible to seed governed replay/entity priors.
- `LEHD / OnTheMap` [priority `1` / `ready`] -> locality, movement_flow
  dedupe: origin_geoid, destination_geoid, year
  note: Eligible to seed governed replay/entity priors.
  note: Aggregate mobility only.
- `MAX Transit GTFS` [priority `1` / `ready`] -> locality, movement_flow
  dedupe: route_id, trip_id, service_id
  note: Eligible to seed governed replay/entity priors.
- `Municipal Budgets and Revenue Reports` [priority `1` / `ready`] -> economic_signal, locality, venue
  dedupe: report_type, report_month, report_year
  note: Eligible to seed governed replay/entity priors.
  note: Aggregate municipal source; never instantiate under-13 personal agents.
- `NWS / NOAA Weather API` [priority `1` / `ready`] -> environmental_signal, event, locality, movement_flow
  dedupe: event_id, issued_at, zone
  note: Eligible to seed governed replay/entity priors.
- `U.S. Census ACS` [priority `1` / `ready`] -> housing_signal, population_cohort
  dedupe: tract_id, year
  note: Eligible to seed governed replay/entity priors.
  note: Use for aggregate dependent mobility only; never instantiate under-13 personal agents.
- `BJCC / Legacy Arena / Protective Stadium Calendars` [priority `2` / `ready`] -> community, event, locality, movement_flow, venue
  dedupe: venue, event_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `SEC / College Football Broadcast Schedules` [priority `2` / `ready`] -> community, event, locality, movement_flow
  dedupe: sport, game_id, broadcast_date
  note: Eligible to seed governed replay/entity priors.
- `Samford University Calendars and Campus Map` [priority `2` / `ready`] -> community, event, movement_flow, venue
  dedupe: calendar_uid, building_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `UAB / Samford Enrollment Origin Reports` [priority `2` / `ready`] -> community, movement_flow, population_cohort
  dedupe: institution, term, report_year
  note: Eligible to seed governed replay/entity priors.
- `UAB Academic, Clinical, and Event Calendars` [priority `2` / `ready`] -> community, event, locality, movement_flow, venue
  dedupe: calendar_uid, event_start, campus_location
  note: Eligible to seed governed replay/entity priors.
- `Data Axle / InfoGroup Business Listings` [priority `3` / `pendingReview`] -> club, venue
  dedupe: business_id, normalized_name, address
  note: Requires review or final approval before authoritative replay ingest.
  note: Use as enrichment or verification layer after base entity normalization.
- `Delivery / Ordering Platform Aggregates` [priority `3` / `pendingReview`] -> locality, venue
  dedupe: provider, delivery_zone, service_date, meal_period
  note: Requires review or final approval before authoritative replay ingest.
  note: Use as enrichment or verification layer after base entity normalization.
- `Google Places / Yelp` [priority `3` / `ready`] -> venue
  dedupe: provider_place_id, normalized_name, address
  note: Use as enrichment or verification layer after base entity normalization.
- `OpenStreetMap POI Data` [priority `3` / `ready`] -> club, community, locality, venue
  dedupe: osm_id, address, lat_lng
  note: Eligible to seed governed replay/entity priors.
- `Real Estate and Rent Index` [priority `3` / `ready`] -> housing_signal, locality, movement_flow, population_cohort
  dedupe: zip, month, provider
  note: Eligible to seed governed replay/entity priors.
- `Resy / OpenTable / Venue Reservation Exports` [priority `3` / `pendingReview`] -> event, venue
  dedupe: venue_name, service_date, service_period
  note: Requires review or final approval before authoritative replay ingest.
  note: Use as enrichment or verification layer after base entity normalization.
- `Birmingham Public Library Network` [priority `4` / `ready`] -> community, event, locality, venue
  dedupe: branch, event_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `Birmingham365.org` [priority `4` / `ready`] -> club, community, locality, venue
  dedupe: community_name, address
  note: Eligible to seed governed replay/entity priors.
  note: Directory/discovery source only; never instantiate under-13 personal agents.
- `City of Birmingham Play Pages` [priority `4` / `ready`] -> community, event, locality, venue
  dedupe: venue_name, address
  note: Eligible to seed governed replay/entity priors.
  note: Civic directory source only; never instantiate under-13 personal agents.
- `County / Municipal Courts and Police Dispatch` [priority `4` / `pendingReview`] -> event, locality, movement_flow
  dedupe: incident_id, timestamp, location
  note: Requires review or final approval before authoritative replay ingest.
  note: Eligible to seed governed replay/entity priors.
- `Eventbrite / Meetup` [priority `4` / `ready`] -> club, community, event, venue
  dedupe: platform_event_id, event_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `IN Birmingham (CVB Calendar)` [priority `4` / `ready`] -> community, event, locality, venue
  dedupe: event_name, venue_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `Major Venue Calendars and Historical Venue Calendars` [priority `4` / `ready`] -> club, community, event, locality, venue
  dedupe: venue, event_name, event_start
  note: Eligible to seed governed replay/entity priors.
- `Neighborhood Association Calendars` [priority `4` / `ready`] -> club, community, event, locality
  dedupe: association_name, meeting_date, neighborhood
  note: Eligible to seed governed replay/entity priors.
- `Bham Now / AL.com / Birmingham Business Journal` [priority `5` / `ready`] -> club, community, event, locality, venue
  dedupe: headline, published_at, normalized_entity
  note: Use as enrichment or verification layer after base entity normalization.
- `Bhamwiki` [priority `5` / `ready`] -> community, event, locality, venue
  dedupe: page_title, normalized_entity, last_revision
  note: Eligible to seed governed replay/entity priors.
- `Birmingham Public Library Archives` [priority `5` / `ready`] -> community, event, locality, venue
  dedupe: archive_id, collection_name, date
  note: Eligible to seed governed replay/entity priors.
- `James Beard / Garden & Gun / Michelin` [priority `5` / `ready`] -> venue
  dedupe: venue_name, award_name, award_year
  note: Use as enrichment or verification layer after base entity normalization.
- `REV Birmingham Updates` [priority `5` / `ready`] -> community, event, locality, venue
  dedupe: headline, published_at, district
  note: Use as enrichment or verification layer after base entity normalization.
- `WBHM 90.3 Public Radio` [priority `5` / `ready`] -> community, event, locality
  dedupe: headline, published_at
  note: Use as enrichment or verification layer after base entity normalization.

## Notes

- Manifest generated from governed BHAM replay source registry wave8-phase1b.
- 33 sources are ready for replay-year intake.
- 4 sources remain pending review before full replay-year authority.
- Normalization targets are canonical entity types derived from source coverage and replay role.
