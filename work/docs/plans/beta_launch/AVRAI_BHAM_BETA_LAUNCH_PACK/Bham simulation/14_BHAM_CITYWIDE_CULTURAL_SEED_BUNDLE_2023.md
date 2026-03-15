# BHAM Citywide Cultural Seed Bundle

- Replay year: `2023`
- Bundle id: `bham-citywide-cultural-seed-2023-4`
- Entry count: `4`
- Populated on: `2026-03-11`

## Sources

- `Birmingham Public Library Network` -> raw key `birmingham_public_library_network`
  targets: community, event, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, classes, events, branch_locations
  record count: `4`
  notes: Uses current public branch-location pages to seed citywide public-space and community anchors. These rows are structural venue seeds, not authoritative historical event truth for 2023.
- `Major Venue Calendars (Saturn / Iron City / The Nick)` -> raw key `major_venue_calendars_saturn_iron_city_the_nick`
  targets: club, community, event, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, event_calendar, venue_status, ticketed_events
  record count: `3`
  notes: Uses current venue sites to seed BHAM nightlife club and venue structure. Historical 2023 event extraction remains pending.
- `City of Birmingham Play Pages` -> raw key `city_of_birmingham_play_pages`
  targets: community, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, venue_name, address, category, seed_scope
  record count: `5`
  notes: Seeds long-lived civic cultural anchors like museums, theatres, and gardens from City of Birmingham public culture pages.
- `Birmingham365.org` -> raw key `birmingham365_org`
  targets: club, community, locality, venue
  required fields: record_id, entity_type, entity_id, observed_at, published_at, community_name, address, category, seed_scope
  record count: `1`
  notes: Seeds the citywide culture/community discovery network as structural context only.

## Guardrails

- This bundle is intentionally `seed_only`.
- Current public pages may seed structural BHAM place, venue, club, and community truth.
- Current public pages may **not** be treated as authoritative historical 2023 event truth without archival or year-specific extraction.
