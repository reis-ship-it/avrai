# BHAM Public Catalog Historicalization Bundle

- Replay year: `2023`
- Bundle id: `bham-public-catalog-historicalization-2023`
- Entry count: `3`

## Jefferson / Shelby / Regional GIS and Assessors

- Source URI: `https://www.rpcgb.org/data-and-maps-downloads`
- Coverage status: `current_spatial_catalog`
- Current catalog records: `29`

### Required Historical Fields

- `historical_source_url`
- `historical_capture_method`
- `record_id`
- `entity_id`
- `entity_type`
- `name`
- `observed_at`
- `published_at`
- `valid_from`
- `valid_to`
- `historical_validation_note`

### Source-Specific Actions

- Replace current catalog rows with year-valid 2023 geometry, parcel, building, or zoning exports.
- Prefer official 2023 downloads, snapshots, or archived RPCGB/ArcGIS items over current landing-page links.
- Convert structural catalog items into locality, parcel, building, housing, or economic replay rows only when year validity is explicit.

### Notes

- Current lane is operational, but still structural spatial catalog truth rather than governed 2023 parcel/building truth.

### Sample Candidates

- `locality` Regional Transportation Plan (`greater_birmingham_region`)
- `locality` Building Communities Program (`greater_birmingham_region`)
- `economic_signal` Employment (`greater_birmingham_region`)
- `locality` RPCGB Open Data Portal (`greater_birmingham_region`)
- `locality` Regional Trends, 2023 (2025) (`greater_birmingham_region`)

## Eventbrite / Meetup

- Source URI: `https://www.eventbrite.com/d/al--birmingham/events/`
- Coverage status: `current_community_event_catalog`
- Current catalog records: `89`

### Required Historical Fields

- `historical_source_url`
- `historical_capture_method`
- `record_id`
- `entity_id`
- `entity_type`
- `name`
- `observed_at`
- `published_at`
- `valid_from`
- `valid_to`
- `historical_validation_note`

### Source-Specific Actions

- Replace current discovery pages with archived or year-valid 2023 event/group rows.
- Dedupe against official venue calendars and city event truth before promotion.
- Keep only event, community, or club rows with explicit Birmingham locality and date validity.

### Notes

- Current lane is operational, but still public community-event catalog truth rather than governed 2023 historical event truth.

### Sample Candidates

- `event` Find Events (`bham_metro_regional`)
- `event` Get Started (`bham_metro_regional`)
- `event` Birmingham Speed Dating for Singles Age 23-39 ♥ Alabama at Denim On 7th (`bham_metro_regional`)
- `event` Stand on Business Steppas Ball (`bham_metro_regional`)
- `event` R&B & SOUTHERN SOUL MONTHLY PARTY SERIES: MIKE CLARK JR. PERFORMING LIVE!! (`bham_metro_regional`)

## IN Birmingham (CVB Calendar)

- Source URI: `https://inbirmingham.com/festivals-and-events/`
- Coverage status: `current_tourism_catalog`
- Current catalog records: `28`

### Required Historical Fields

- `historical_source_url`
- `historical_capture_method`
- `record_id`
- `entity_id`
- `entity_type`
- `name`
- `observed_at`
- `published_at`
- `valid_from`
- `valid_to`
- `historical_validation_note`

### Source-Specific Actions

- Replace current guides and tourism landing pages with archived 2023 event or neighborhood/community rows.
- Prefer official 2023 CVB event pages or archived captures with explicit date validity.
- Dedupe venue and event truth against official city pages, BJCC, and major venue calendars before promotion.

### Notes

- Current lane is operational, but still tourism/community catalog truth rather than governed 2023 historical event truth.

### Sample Candidates

- `locality` Birmingham Guides (`bham_metro_regional`)
- `community` Avondale / Crestwood Visit Avondale / Crestwood (`bham_avondale`)
- `community` Bessemer Visit Bessemer (`bham_metro_regional`)
- `community` Downtown Visit Downtown (`bham_downtown`)
- `community` Fultondale Visit Fultondale (`bham_metro_regional`)

