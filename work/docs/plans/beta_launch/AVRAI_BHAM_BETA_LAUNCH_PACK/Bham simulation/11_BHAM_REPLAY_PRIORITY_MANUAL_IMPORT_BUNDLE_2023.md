# BHAM Priority Manual Import Bundle

- Replay year: `2023`
- Bundle id: `bham-priority-manual-import-2023-4`
- Entry count: `4`
- Populated on: `2026-03-11`

## Priority Sources

- `ALDOT Long-Term Construction Projects` -> raw key `aldot_long_term_construction_projects`
  targets: event, locality, movement_flow
  required fields: record_id, entity_type, entity_id, observed_at, published_at, project_timeline, closures, detours, affected_segments
  record count: `3`
  notes: Eligible to seed governed replay/entity priors. Populated with Pratt Highway, 19th Street Ensley, and 13th Street South/UAB corridor construction-friction rows from the ALDOT STIP 2024 Original program window.
- `ALDOT Traffic Data` -> raw key `aldot_traffic_data`
  targets: locality, movement_flow
  required fields: record_id, entity_type, entity_id, observed_at, published_at, counts, travel_speed, artery_load
  record count: `2`
  notes: Eligible to seed governed replay/entity priors. Current rows are planning-grade Birmingham bottleneck and corridor-pressure summaries pending direct ALDOT count exports.
- `City of Birmingham OpenGov` -> raw key `city_of_birmingham_opengov`
  targets: community, event, locality
  required fields: record_id, entity_type, entity_id, observed_at, published_at, neighborhood_polygons, districts, civic_datasets, budget_reports, crime_precinct_exports, planning_archives, civic_contracts
  record count: `2`
  notes: Eligible to seed governed replay/entity priors. Populated with locality/finance/crime/planning/civic-contract rows using FY23 budget metrics and December 2023 precinct export structure.
- `UAB Academic, Clinical, and Event Calendars` -> raw key `uab_academic_clinical_and_event_calendars`
  targets: community, event, locality, movement_flow, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, academic_calendar, event_calendar, clinical_schedule
  record count: `3`
  notes: Eligible to seed governed replay/entity priors. Populated with Spring 2023, Fall 2023, and New Year's Holiday campus rhythm rows from the public UAB calendars.
