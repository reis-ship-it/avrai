# BHAM Replay Realism Gate Report

- Environment: `bham-replay-world-2023`
- Replay year: `2023`
- Ready for Monte Carlo base year: `true`

## Gate Records

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
