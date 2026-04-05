# BHAM Replay Pull Plan

- Replay year: `2023`
- Automated sources: `7`
- API-key-required sources: `1`
- Manual-import sources: `25`
- Review-gated sources: `4`

## Source Pull Plans

- `ALDOT Long-Term Construction Projects` [`manualImport`] -> raw key `aldot_long_term_construction_projects`
- `ALDOT Traffic Data` [`manualImport`] -> raw key `aldot_traffic_data`
- `BEA / U.S. Census Bureau Economic Series` [`apiKeyRequired`] -> raw key `bea_u_s_census_bureau_economic_series`
  sourceUrl: https://apps.bea.gov/api/data
  endpointRef: https://apps.bea.gov/api/data
  note: Public economic series; safe for aggregate seeding.
  note: Aggregate-only source; never instantiate under-13 personal agents.
- `BHM Airport / TSA Throughput` [`manualImport`] -> raw key `bhm_airport_tsa_throughput`
- `Bureau of Labor Statistics / State DOL` [`manualImport`] -> raw key `bureau_of_labor_statistics_state_dol`
  note: Public labor data; use as aggregate role prior.
  note: Adult labor patterns only; do not create under-13 personal agents.
- `City of Birmingham OpenGov` [`manualImport`] -> raw key `city_of_birmingham_opengov`
  sourceUrl: https://data.birminghamal.gov/dataset/
  endpointRef: https://data.birminghamal.gov/dataset/
- `Jefferson / Shelby / Regional GIS and Assessors` [`automated`] -> raw key `jefferson_shelby_regional_gis_and_assessors`
  sourceUrl: https://www.rpcgb.org/data-and-maps-downloads
  endpointRef: https://www.rpcgb.org/data-and-maps-downloads
- `LEHD / OnTheMap` [`manualImport`] -> raw key `lehd_onthemap`
  note: Aggregate mobility only.
- `MAX Transit GTFS` [`manualImport`] -> raw key `max_transit_gtfs`
- `Municipal Budgets and Revenue Reports` [`manualImport`] -> raw key `municipal_budgets_and_revenue_reports`
  sourceUrl: https://data.birminghamal.gov/dataset/comprehensive-annual-financial-reports
  endpointRef: https://data.birminghamal.gov/dataset/comprehensive-annual-financial-reports
  note: Aggregate municipal source; never instantiate under-13 personal agents.
- `NWS / NOAA Weather API` [`automated`] -> raw key `nws_noaa_weather_api`
  sourceUrl: https://api.weather.gov
  endpointRef: https://api.weather.gov
- `U.S. Census ACS` [`automated`] -> raw key `u_s_census_acs`
  sourceUrl: https://api.census.gov/data/2023/acs/acs5
  endpointRef: https://api.census.gov/data/2023/acs/acs5
  note: Use for aggregate dependent mobility only; never instantiate under-13 personal agents.
- `BJCC / Legacy Arena / Protective Stadium Calendars` [`manualImport`] -> raw key `bjcc_legacy_arena_protective_stadium_calendars`
- `SEC / College Football Broadcast Schedules` [`manualImport`] -> raw key `sec_college_football_broadcast_schedules`
- `Samford University Calendars and Campus Map` [`manualImport`] -> raw key `samford_university_calendars_and_campus_map`
- `UAB / Samford Enrollment Origin Reports` [`manualImport`] -> raw key `uab_samford_enrollment_origin_reports`
- `UAB Academic, Clinical, and Event Calendars` [`manualImport`] -> raw key `uab_academic_clinical_and_event_calendars`
- `Data Axle / InfoGroup Business Listings` [`partnerReview`] -> raw key `data_axle_infogroup_business_listings`
  note: Source remains pending review before authoritative ingestion.
- `Delivery / Ordering Platform Aggregates` [`partnerReview`] -> raw key `delivery_ordering_platform_aggregates`
  note: Source remains pending review before authoritative ingestion.
  note: Aggregate-only patterns; never retain raw personal order history.
- `Google Places / Yelp` [`manualImport`] -> raw key `google_places_yelp`
  note: Respect provider terms; use as enrichment after identity normalization.
- `OpenStreetMap POI Data` [`automated`] -> raw key `openstreetmap_poi_data`
  sourceUrl: https://download.geofabrik.de/north-america/us/alabama.html
  endpointRef: https://overpass-api.de/api/interpreter
- `Real Estate and Rent Index` [`manualImport`] -> raw key `real_estate_and_rent_index`
- `Resy / OpenTable / Venue Reservation Exports` [`partnerReview`] -> raw key `resy_opentable_venue_reservation_exports`
  note: Source remains pending review before authoritative ingestion.
  note: Use only after legal and partner access review. Never sole venue truth.
- `Birmingham Public Library Network` [`manualImport`] -> raw key `birmingham_public_library_network`
- `Birmingham365.org` [`manualImport`] -> raw key `birmingham365_org`
  sourceUrl: https://www.birmingham365.org/
  endpointRef: https://www.birmingham365.org/
  note: Use for cultural discovery and structural seeding. Deduplicate against venue truth before promotion.
  note: Directory/discovery source only; never instantiate under-13 personal agents.
- `City of Birmingham Play Pages` [`manualImport`] -> raw key `city_of_birmingham_play_pages`
  sourceUrl: https://www.birminghamal.gov/play/arts-museums
  endpointRef: https://www.birminghamal.gov/play/arts-museums
  note: Use for structural BHAM cultural seed rows and official city event-page history when a dated 2023 page is directly available.
  note: Civic directory source only; never instantiate under-13 personal agents.
- `County / Municipal Courts and Police Dispatch` [`partnerReview`] -> raw key `county_municipal_courts_and_police_dispatch`
  note: Source remains pending review before authoritative ingestion.
- `Eventbrite / Meetup` [`automated`] -> raw key `eventbrite_meetup`
  sourceUrl: https://www.eventbrite.com/d/al--birmingham/events/
  endpointRef: https://www.eventbrite.com/d/al--birmingham/events/
  note: Must be deduplicated against official venue truth before promotion.
- `IN Birmingham (CVB Calendar)` [`automated`] -> raw key `in_birmingham_cvb_calendar`
  sourceUrl: https://inbirmingham.com/festivals-and-events/
  endpointRef: https://inbirmingham.com/festivals-and-events/
- `Major Venue Calendars and Historical Venue Calendars` [`manualImport`] -> raw key `major_venue_calendars_and_historical_venue_calendars`
- `Neighborhood Association Calendars` [`manualImport`] -> raw key `neighborhood_association_calendars`
- `Bham Now / AL.com / Birmingham Business Journal` [`manualImport`] -> raw key `bham_now_al_com_birmingham_business_journal`
- `Bhamwiki` [`manualImport`] -> raw key `bhamwiki`
  sourceUrl: https://www.bhamwiki.com/
  endpointRef: https://www.bhamwiki.com/
- `Birmingham Public Library Archives` [`automated`] -> raw key `birmingham_public_library_archives`
  sourceUrl: https://www.cobpl.org/resources/archives/collections.aspx
  endpointRef: https://www.cobpl.org/resources/archives/collections.aspx
- `James Beard / Garden & Gun / Michelin` [`manualImport`] -> raw key `james_beard_garden_and_gun_michelin`
- `REV Birmingham Updates` [`manualImport`] -> raw key `rev_birmingham_updates`
- `WBHM 90.3 Public Radio` [`manualImport`] -> raw key `wbhm_90_3_public_radio`
