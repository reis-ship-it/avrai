# BHAM Single-Year Replay Pass

- Environment: `bham-replay-world-2023`
- Replay year: `2023`
- Branch: `canonical`
- Run: `wave8_bham_truth_year`
- Executed observations: `1295`
- Forecast evaluated: `87`
- Virtual nodes: `1180`
- Rollups: `281`
- Higher-agent actions: `606`
- Daily agendas: `25000`
- Daily actor actions: `116676`
- Closure overrides: `142`
- Action explanations: `1206`
- Training action records: `257898`
- Counterfactual choices: `423666`
- Outcome labels: `257898`
- Truth decision records: `389`
- Higher-agent intervention traces: `128367`
- Holdout evaluation passed: `true`

## Forecast Kernel

- Selected kernel: `native_forecast_kernel`
- Execution mode: `native`

## Replay Isolation

- `live_runtime_state_attached`: `false`
- `mesh_runtime_state_attached`: `false`
- `ai2ai_runtime_state_attached`: `false`
- `isolation_gate_passed`: `true`

## Population Realism

- Total population: `669744`
- Agent eligible: `562585`
- Active agents: `558046`
- Dormant agents: `103253`
- Deleted agents: `20577`
- Under-13 dependent mobility: `107159`
- Modeled actors: `25000`
- Locality coverage: `100.0%`
- Population model kind: `dense_weighted_synthetic_city`

## Place Graph Coverage

- Graph nodes: `2615`
- Venue profiles: `825`
- Club profiles: `564`
- Organization profiles: `415`
- Community profiles: `827`
- Event profiles: `1774`
- Localities: `215`

## Kernel Participation

- Active kernels: `9` / `9`

- `when` `active` `1295` evidence refs
- `where` `active` `1180` evidence refs
- `what` `active` `1180` evidence refs
- `who` `active` `178418` evidence refs
- `why` `active` `13091` evidence refs
- `how` `active` `13010` evidence refs
- `forecast` `active` `12485` evidence refs
- `governance` `active` `12399` evidence refs
- `higher_agent_truth` `active` `129305` evidence refs

## Actor Kernel Coverage

- Actor count: `25000`
- Actors with full bundle: `25000`
- Activation traces: `128418`

## Connectivity And Exchange

- Actors with connectivity profiles: `25000`
- Connectivity transitions: `100000`
- Exchange threads: `11691`
- Exchange events: `11691`
- AI2AI records: `11691`
- Actors with any exchange: `12805`
- Actors with personal AI threads: `10231`
- Actors with admin support: `926`
- Actors with group threads: `2472`
- Offline queued exchanges: `1874`

## Calibration

- Passed: `true`
- Metric count: `12`
- Unresolved metrics: `0`

- `city_population_total` target `669744.0` actual `669744.0` variance `0.00%` passed `true`
- `city_housing_total` target `309542.0` actual `309542.0` variance `0.00%` passed `true`
- `metro_core_locality_coverage_pct` target `100.0` actual `100.0` variance `0.00%` passed `true`
- `weighted_actor_count` target `25000.0` actual `25000.0` variance `0.00%` passed `true`
- `venue_profile_count` target `700.0` actual `825.0` variance `0.00%` passed `true`
- `club_profile_count` target `120.0` actual `564.0` variance `0.00%` passed `true`
- `community_profile_count` target `500.0` actual `827.0` variance `0.00%` passed `true`
- `organization_profile_count` target `300.0` actual `415.0` variance `0.00%` passed `true`
- `event_profile_count` target `1000.0` actual `1774.0` variance `0.00%` passed `true`
- `active_kernel_count` target `9.0` actual `9.0` variance `0.00%` passed `true`
- `daily_behavior_locality_coverage_pct` target `100.0` actual `100.0` variance `0.00%` passed `true`
- `daily_behavior_action_density` target `25000.0` actual `50000.0` variance `0.00%` passed `true`

## Realism Gates

- Ready for Monte Carlo base year: `true`
- Open gaps: `0`

- `isolation` `passed` Replay world is isolated from live runtime and app mutation.
- `population_realism` `passed` Dense Birmingham population, locality coverage, and AVRAI-agent split are present.
- `place_venue_graph` `passed` Canonical Birmingham place graph is dense enough for city movement.
- `event_community_club` `passed` Meaningful citywide 2023 activity coverage is present.
- `kernel_participation` `passed` All replay-participating kernels are materially active.
- `higher_agent_behavior` `passed` Personal, locality, city, and top-level agents all act in the replay year.
- `explainability` `passed` Replay outputs include explicit action explanations and evidence.
- `calibration` `passed` Replay metrics are calibrated against Birmingham truth-year targets.
- `actor_kernel_bundle` `passed` All modeled actors carry the full replay kernel bundle.
- `connectivity` `passed` All modeled actors have replay-only device and connectivity timelines.
- `exchange_sparsity` `passed` Messaging and group participation are selective rather than universal.
- `ai2ai_simulation` `passed` Replay AI2AI and transport records are simulated inside the isolated replay world.
- `routine_realism` `passed` Exchange and attendance behavior remains bounded by actor routine and life-stage.
- `training_readiness` `passed` Replay outputs are complete enough to export for storage and Monte Carlo preparation.

## Entity Type Counts

- `venue`: `383`
- `community`: `364`
- `housing_signal`: `189`
- `population_cohort`: `189`
- `event`: `32`
- `locality`: `11`
- `movement_flow`: `6`
- `club`: `5`
- `economic_signal`: `1`

## Forecast Disposition Counts

- `admittedWithCaution`: `48`
- `admitted`: `39`

## Notes

- This is a replay-only single-year pass summary inside the isolated BHAM virtual world.
- No live runtime mutation or app-facing surface is allowed from this pass.
- Higher-agent behavior remains bounded and replay-internal.
- Every modeled actor is evaluated for full attached kernel coverage.
- Replay-only exchange, AI2AI, and connectivity behavior are simulated without live runtime reuse.
- All current realism gates are passed for the 2023 truth-year.
