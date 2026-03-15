# BHAM Replay Normalized Observations

- Pack: `bham-2023-seed-pack-v1`
- Replay year: `2023`
- Datasets: `7`
- Ingested sources: `7`
- Skipped sources: `27`

## Ingested Sources

- `ALDOT Long-Term Construction Projects` [`aggregate_metric_replay_source_adapter`] records `1` observations `1`
- `ALDOT Traffic Data` [`aggregate_metric_replay_source_adapter`] records `1` observations `1`
- `BEA / U.S. Census Bureau Economic Series` [`aggregate_metric_replay_source_adapter`] records `1` observations `1`
- `City of Birmingham OpenGov` [`spatial_feature_replay_source_adapter`] records `2` observations `2`
- `NWS / NOAA Weather API` [`aggregate_metric_replay_source_adapter`] records `1` observations `1`
- `U.S. Census ACS` [`aggregate_metric_replay_source_adapter`] records `2` observations `2`
- `UAB Academic, Clinical, and Event Calendars` [`calendar_event_replay_source_adapter`] records `2` observations `2`

## Skipped Sources

- `BHM Airport / TSA Throughput`
- `Bureau of Labor Statistics / State DOL`
- `Jefferson / Shelby / Regional GIS and Assessors`
- `LEHD / OnTheMap`
- `MAX Transit GTFS`
- `BJCC / Legacy Arena / Protective Stadium Calendars`
- `SEC / College Football Broadcast Schedules`
- `Samford University Calendars and Campus Map`
- `UAB / Samford Enrollment Origin Reports`
- `Data Axle / InfoGroup Business Listings`
- `Delivery / Ordering Platform Aggregates`
- `Google Places / Yelp`
- `OpenStreetMap POI Data`
- `Real Estate and Rent Index`
- `Resy / OpenTable / Venue Reservation Exports`
- `Birmingham Public Library Network`
- `County / Municipal Courts and Police Dispatch`
- `Eventbrite / Meetup`
- `IN Birmingham (CVB Calendar)`
- `Major Venue Calendars (Saturn / Iron City / The Nick)`
- `Neighborhood Association Calendars`
- `Bham Now / AL.com / Birmingham Business Journal`
- `Bhamwiki`
- `Birmingham Public Library Archives`
- `James Beard / Garden & Gun / Michelin`
- `REV Birmingham Updates`
- `WBHM 90.3 Public Radio`

## Observation Summary

- `obs:aldot-construction-2023-redmountain` -> `movement_flow` `Red Mountain Corridor`
- `obs:aldot-2023-280-pm-peak` -> `movement_flow` `US-280 Corridor`
- `obs:bea-2023-jefferson-income` -> `economic_signal` `Birmingham Metro`
- `obs:opengov-avondale-locality` -> `locality` `Avondale`
- `obs:opengov-southside-community` -> `community` `Southside`
- `obs:noaa-2023-heat-advisory` -> `environmental_signal` `Birmingham Metro`
- `obs:acs-2023-southside-population` -> `population_cohort` `Southside`
- `obs:acs-2023-avondale-housing` -> `housing_signal` `Avondale`
- `obs:uab-2023-spring-concert` -> `event` `Southside`
- `obs:uab-2023-medical-lecture` -> `event` `Southside`
