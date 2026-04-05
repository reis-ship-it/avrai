# BHAM Replay Manual Import Templates

- Replay year: `2023`
- Template count: `31`

## Templates

- `ALDOT Long-Term Construction Projects` -> raw key `aldot_long_term_construction_projects`
  targets: event, locality, movement_flow
  dedupe: project_id, segment_id
  required fields: record_id, entity_type, entity_id, observed_at, published_at, project_timeline, closures, detours, affected_segments
- `ALDOT Traffic Data` -> raw key `aldot_traffic_data`
  targets: locality, movement_flow
  dedupe: segment_id, date
  required fields: record_id, entity_type, entity_id, observed_at, published_at, counts, travel_speed, artery_load
- `BHM Airport / TSA Throughput` -> raw key `bhm_airport_tsa_throughput`
  targets: event, locality, movement_flow
  dedupe: airport_code, date
  required fields: record_id, entity_type, entity_id, observed_at, published_at, departures, arrivals, holiday_throughput
- `Bureau of Labor Statistics / State DOL` -> raw key `bureau_of_labor_statistics_state_dol`
  targets: venue
  dedupe: metro_code, occupation_code, year_month
  required fields: record_id, entity_type, entity_id, observed_at, published_at, occupation_mix, industry_sectors, shift_hours
- `City of Birmingham OpenGov` -> raw key `city_of_birmingham_opengov`
  targets: community, event, locality
  dedupe: dataset_id, neighborhood_name, revision_date
  required fields: record_id, entity_type, entity_id, observed_at, published_at, neighborhood_polygons, districts, civic_datasets, budget_reports, crime_precinct_exports, planning_archives, civic_contracts
- `Jefferson / Shelby / Regional GIS and Assessors` -> raw key `jefferson_shelby_regional_gis_and_assessors`
  targets: locality, venue
  dedupe: parcel_id, address, county
  required fields: record_id, entity_type, entity_id, observed_at, published_at, parcel_geometry, building_footprints, zoning, addresses
- `LEHD / OnTheMap` -> raw key `lehd_onthemap`
  targets: locality, movement_flow
  dedupe: origin_geoid, destination_geoid, year
  required fields: record_id, entity_type, entity_id, observed_at, published_at, origin_destination_flow, daytime_population, worker_concentration
- `MAX Transit GTFS` -> raw key `max_transit_gtfs`
  targets: locality, movement_flow
  dedupe: route_id, trip_id, service_id
  required fields: record_id, entity_type, entity_id, observed_at, published_at, routes, stops, trips, service_calendar
- `BJCC / Legacy Arena / Protective Stadium Calendars` -> raw key `bjcc_legacy_arena_protective_stadium_calendars`
  targets: community, event, locality, movement_flow, venue
  dedupe: venue, event_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_calendar, capacity, doors_open, venue_status
- `SEC / College Football Broadcast Schedules` -> raw key `sec_college_football_broadcast_schedules`
  targets: community, event, locality, movement_flow
  dedupe: sport, game_id, broadcast_date
  required fields: record_id, entity_type, entity_id, observed_at, published_at, game_time, broadcast_window, team_affinity_pressure
- `Samford University Calendars and Campus Map` -> raw key `samford_university_calendars_and_campus_map`
  targets: community, event, movement_flow, venue
  dedupe: calendar_uid, building_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_calendar, campus_map, term_schedule
- `UAB / Samford Enrollment Origin Reports` -> raw key `uab_samford_enrollment_origin_reports`
  targets: community, movement_flow, population_cohort
  dedupe: institution, term, report_year
  required fields: record_id, entity_type, entity_id, observed_at, published_at, origin_states, international_mix, term_count
- `UAB Academic, Clinical, and Event Calendars` -> raw key `uab_academic_clinical_and_event_calendars`
  targets: community, event, locality, movement_flow, venue
  dedupe: calendar_uid, event_start, campus_location
  required fields: record_id, entity_type, entity_id, observed_at, published_at, academic_calendar, event_calendar, clinical_schedule
- `Data Axle / InfoGroup Business Listings` -> raw key `data_axle_infogroup_business_listings`
  targets: club, venue
  dedupe: business_id, normalized_name, address
  required fields: record_id, entity_type, entity_id, observed_at, published_at, naics, entity_status, business_name, address
- `Delivery / Ordering Platform Aggregates` -> raw key `delivery_ordering_platform_aggregates`
  targets: locality, venue
  dedupe: provider, delivery_zone, service_date, meal_period
  required fields: record_id, entity_type, entity_id, observed_at, published_at, demand_density, cuisine_timing, delivery_heat
- `Google Places / Yelp` -> raw key `google_places_yelp`
  targets: venue
  dedupe: provider_place_id, normalized_name, address
  required fields: record_id, entity_type, entity_id, observed_at, published_at, operating_hours, category, rating_count
- `OpenStreetMap POI Data` -> raw key `openstreetmap_poi_data`
  targets: club, community, locality, venue
  dedupe: osm_id, address, lat_lng
  required fields: record_id, entity_type, entity_id, observed_at, published_at, poi_type, name, address, hours, geometry
- `Real Estate and Rent Index` -> raw key `real_estate_and_rent_index`
  targets: housing_signal, locality, movement_flow, population_cohort
  dedupe: zip, month, provider
  required fields: record_id, entity_type, entity_id, observed_at, published_at, rent_index, home_price_index, inventory
- `Resy / OpenTable / Venue Reservation Exports` -> raw key `resy_opentable_venue_reservation_exports`
  targets: event, venue
  dedupe: venue_name, service_date, service_period
  required fields: record_id, entity_type, entity_id, observed_at, published_at, reservation_windows, seat_pressure, table_scarcity
- `Birmingham Public Library Network` -> raw key `birmingham_public_library_network`
  targets: community, event, locality, venue
  dedupe: branch, event_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, classes, events, branch_locations
- `County / Municipal Courts and Police Dispatch` -> raw key `county_municipal_courts_and_police_dispatch`
  targets: event, locality, movement_flow
  dedupe: incident_id, timestamp, location
  required fields: record_id, entity_type, entity_id, observed_at, published_at, incident_type, time, location, disposition
- `Eventbrite / Meetup` -> raw key `eventbrite_meetup`
  targets: club, community, event, venue
  dedupe: platform_event_id, event_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_name, organizer, venue, recurrence
- `IN Birmingham (CVB Calendar)` -> raw key `in_birmingham_cvb_calendar`
  targets: community, event, locality, venue
  dedupe: event_name, venue_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_name, venue_name, event_dates, category
- `Major Venue Calendars (Saturn / Iron City / The Nick)` -> raw key `major_venue_calendars_saturn_iron_city_the_nick`
  targets: club, community, event, locality, venue
  dedupe: venue, event_name, event_start
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_calendar, venue_status, ticketed_events
- `Neighborhood Association Calendars` -> raw key `neighborhood_association_calendars`
  targets: club, community, event, locality
  dedupe: association_name, meeting_date, neighborhood
  required fields: record_id, entity_type, entity_id, observed_at, published_at, meeting_dates, community_topics, association_identity
- `Bham Now / AL.com / Birmingham Business Journal` -> raw key `bham_now_al_com_birmingham_business_journal`
  targets: club, community, event, locality, venue
  dedupe: headline, published_at, normalized_entity
  required fields: record_id, entity_type, entity_id, observed_at, published_at, article_date, venue_name, event_mentions, closure_signal
- `Bhamwiki` -> raw key `bhamwiki`
  targets: community, event, locality, venue
  dedupe: page_title, normalized_entity, last_revision
  required fields: record_id, entity_type, entity_id, observed_at, published_at, entity_history, opening_closure_history, neighborhood_links
- `Birmingham Public Library Archives` -> raw key `birmingham_public_library_archives`
  targets: community, event, locality, venue
  dedupe: archive_id, collection_name, date
  required fields: record_id, entity_type, entity_id, observed_at, published_at, archival_reference, event_dates, location_history
- `James Beard / Garden & Gun / Michelin` -> raw key `james_beard_garden_and_gun_michelin`
  targets: venue
  dedupe: venue_name, award_name, award_year
  required fields: record_id, entity_type, entity_id, observed_at, published_at, award_date, venue_name, recognition_type
- `REV Birmingham Updates` -> raw key `rev_birmingham_updates`
  targets: community, event, locality, venue
  dedupe: headline, published_at, district
  required fields: record_id, entity_type, entity_id, observed_at, published_at, district_news, opening_signal, closure_signal
- `WBHM 90.3 Public Radio` -> raw key `wbhm_90_3_public_radio`
  targets: community, event, locality
  dedupe: headline, published_at
  required fields: record_id, entity_type, entity_id, observed_at, published_at, story_date, entity_mentions, civic_signal
