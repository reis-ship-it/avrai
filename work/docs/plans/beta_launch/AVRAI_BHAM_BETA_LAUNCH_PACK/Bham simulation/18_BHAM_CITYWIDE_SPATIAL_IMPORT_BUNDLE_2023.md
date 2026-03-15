# BHAM Priority Manual Import Bundle

- Replay year: `2023`
- Bundle id: `bham-priority-manual-import-2023-7`
- Entry count: `7`

## Priority Sources

- `Jefferson / Shelby / Regional GIS and Assessors` -> raw key `jefferson_shelby_regional_gis_and_assessors`
  targets: locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, parcel_geometry, building_footprints, zoning, addresses
  notes: Eligible to seed governed replay/entity priors.
- `OpenStreetMap POI Data` -> raw key `openstreetmap_poi_data`
  targets: club, community, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, poi_type, name, address, hours, geometry
  notes: Eligible to seed governed replay/entity priors.
- `Birmingham Public Library Network` -> raw key `birmingham_public_library_network`
  targets: community, event, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, classes, events, branch_locations
  notes: Eligible to seed governed replay/entity priors.
- `Eventbrite / Meetup` -> raw key `eventbrite_meetup`
  targets: club, community, event, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_name, organizer, venue, recurrence
  notes: Must be deduplicated against official venue truth before promotion. | Eligible to seed governed replay/entity priors.
- `IN Birmingham (CVB Calendar)` -> raw key `in_birmingham_cvb_calendar`
  targets: community, event, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_name, venue_name, event_dates, category
  notes: Eligible to seed governed replay/entity priors.
- `Major Venue Calendars and Historical Venue Calendars` -> raw key `major_venue_calendars_saturn_iron_city_the_nick`
  targets: club, community, event, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_calendar, venue_status, ticketed_events
  notes: Eligible to seed governed replay/entity priors.
- `Neighborhood Association Calendars` -> raw key `neighborhood_association_calendars`
  targets: club, community, event, locality
  required fields: record_id, entity_type, entity_id, observed_at, published_at, meeting_dates, community_topics, association_identity
  notes: Eligible to seed governed replay/entity priors.
