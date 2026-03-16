# BHAM Event Scenario Pack

Internal Birmingham replay-only scenario pack for phase-1 simulation improvement work.

## Citywide Spring Event

- Scenario ID: `bham_citywide_spring_event`
- Kind: `eventOps`
- Scope: `city`
- Localities: `bham_downtown, bham_avondale, bham_lakeview`
- Interventions: `attendanceSurge, routeBlock`

## Neighborhood Activation Day

- Scenario ID: `bham_neighborhood_activation_day`
- Kind: `eventOps`
- Scope: `locality`
- Localities: `bham_avondale, bham_woodlawn, bham_homewood`
- Interventions: `attendanceSurge, localityCaution`

## Outdoor Weather Stress

- Scenario ID: `bham_outdoor_weather_stress`
- Kind: `weather`
- Scope: `city`
- Localities: `bham_downtown, bham_uptown`
- Interventions: `weatherShift, staffingLoss`

## Venue Overload

- Scenario ID: `bham_venue_overload`
- Kind: `venueOverload`
- Scope: `venue`
- Localities: `bham_downtown, bham_uptown`
- Interventions: `attendanceSurge, venueClosure`

## Transit Friction

- Scenario ID: `bham_transit_friction`
- Kind: `transitFriction`
- Scope: `corridor`
- Localities: `bham_southside, bham_five_points`
- Interventions: `transitDelay, routeBlock`

## Staffing Shortfall

- Scenario ID: `bham_staffing_shortfall`
- Kind: `staffingPressure`
- Scope: `city`
- Localities: `bham_downtown, bham_southside`
- Interventions: `staffingLoss, localityCaution`

