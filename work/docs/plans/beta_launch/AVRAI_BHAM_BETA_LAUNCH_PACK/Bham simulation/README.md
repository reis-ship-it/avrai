# BHAM Simulation

**Date:** March 9, 2026  
**Status:** Active execution workspace; 2023 single-year truth-year accepted as the current Monte Carlo base year  
**Scope:** Birmingham historical replay, current-state calibration, and forward-useful simulation

## Purpose

This folder is the single home for BHAM simulation planning, source intake, replay contracts, and future simulation artifacts.

The operating rule is:

- all BHAM simulation work goes here
- all historical and current data sources must be explicitly logged
- all replay logic must respect one atomic simulation clock
- the timing governance kernel is the source of truth for timing
- the authoritative Wave 8 replay path is Birmingham-only
- no source may influence simulation state before its real-world valid time
- simulation outputs are priors, not self-justifying truth
- the simulation must remain useful for 2026 and beyond, not freeze the product in the year of the training data

## Current State

- the isolated 2023 BHAM single-year replay is accepted as the current Monte Carlo base year
- the 2023 truth-year now passes:
  - isolation
  - calibration
  - kernel participation
  - higher-agent behavior
  - dense-city realism gates
  - actor-kernel bundle coverage
  - connectivity and exchange sparsity
  - AI2AI simulation
  - training-readiness
  - training-signal generation
  - held-out evaluation
  - replay storage boundary validation
  - replay-only Supabase upload/index dry-run validation
- multi-year ingestion and decade Monte Carlo remain blocked until storage architecture is finalized

## Contents

- [01 Hyperrealistic BHAM Simulation Plan](./01_HYPERREALISTIC_BHAM_SIMULATION_PLAN.md)
- [02 BHAM Source Registry And Replay Intake Plan](./02_BHAM_SOURCE_REGISTRY_AND_REPLAY_INTAKE_PLAN.md)
- [03 BHAM Source Registry](./03_BHAM_SOURCE_REGISTRY.md)
- [03 BHAM Source Registry Data](./03_BHAM_SOURCE_REGISTRY_DATA.json)
- [04 AVRAI Governance Kernels](./04_AVRAI_GOVERNANCE_KERNELS.md)
- [05 BHAM Replay, Forecast Kernel, And Agent Flow](./05_BHAM_REPLAY_FORECAST_AND_AGENT_FLOW.md)
- [06 BHAM Replay Year Selection](./06_BHAM_REPLAY_YEAR_SELECTION.md)
- [07 BHAM Replay Ingestion Manifest](./07_BHAM_REPLAY_INGESTION_MANIFEST.md)
- [08 BHAM Replay Source Pack 2023 Seed](./08_BHAM_REPLAY_SOURCE_PACK_2023_SEED.json)
- [08 BHAM Replay Normalized Observations Seed 2023](./08_BHAM_REPLAY_NORMALIZED_OBSERVATIONS_SEED_2023.md)
- [09 BHAM Replay Pull Plan 2023](./09_BHAM_REPLAY_PULL_PLAN_2023.md)
- [10 BHAM Replay Manual Import Templates](./10_BHAM_REPLAY_MANUAL_IMPORT_TEMPLATES.md)
- [11 BHAM Replay Priority Manual Import Bundle 2023](./11_BHAM_REPLAY_PRIORITY_MANUAL_IMPORT_BUNDLE_2023.md)
- [11 BHAM Replay Priority Manual Source Pack 2023](./11_BHAM_REPLAY_PRIORITY_MANUAL_SOURCE_PACK_2023.json)
- [12 BHAM Provided Source Inputs 2023](./12_BHAM_PROVIDED_SOURCE_INPUTS_2023.md)
- [13 BHAM Replay Normalized Observations Priority 2023](./13_BHAM_REPLAY_NORMALIZED_OBSERVATIONS_PRIORITY_2023.md)
- [14 BHAM Citywide Cultural Seed Bundle 2023](./14_BHAM_CITYWIDE_CULTURAL_SEED_BUNDLE_2023.md)
- [14 BHAM Citywide Cultural Source Pack 2023](./14_BHAM_CITYWIDE_CULTURAL_SOURCE_PACK_2023.json)
- [15 BHAM Citywide Cultural Normalized Observations 2023](./15_BHAM_CITYWIDE_CULTURAL_NORMALIZED_OBSERVATIONS_2023.md)
- [16 BHAM Historical Citywide Archive Bundle 2023](./16_BHAM_HISTORICAL_CITYWIDE_ARCHIVE_BUNDLE_2023.md)
- [16 BHAM Historical Citywide Archive Source Pack 2023](./16_BHAM_HISTORICAL_CITYWIDE_ARCHIVE_SOURCE_PACK_2023.json)
- [17 BHAM Historical Citywide Normalized Observations 2023](./17_BHAM_HISTORICAL_CITYWIDE_NORMALIZED_OBSERVATIONS_2023.md)
- [18 BHAM Citywide Spatial Import Bundle 2023](./18_BHAM_CITYWIDE_SPATIAL_IMPORT_BUNDLE_2023.md)
- [19 BHAM Citywide Spatial Source Pack 2023](./19_BHAM_CITYWIDE_SPATIAL_SOURCE_PACK_2023.json)
- [20 BHAM Citywide Spatial Normalized Observations 2023](./20_BHAM_CITYWIDE_SPATIAL_NORMALIZED_OBSERVATIONS_2023.md)
- [21 BHAM Source Reality Audit 2023](./21_BHAM_SOURCE_REALITY_AUDIT_2023.md)
- [22 BHAM Replay Automated Pull Summary 2023](./22_BHAM_REPLAY_AUTOMATED_PULL_SUMMARY_2023.md)
- [23 BHAM Replay Historicalized Source Pack 2023 Automated](./23_BHAM_REPLAY_HISTORICALIZED_SOURCE_PACK_2023_AUTOMATED.json)
- [24 BHAM Replay Automated Normalized Observations 2023](./24_BHAM_REPLAY_AUTOMATED_NORMALIZED_OBSERVATIONS_2023.md)
- [25 BHAM Official City Event Bundle 2023](./25_BHAM_OFFICIAL_CITY_EVENT_BUNDLE_2023.md)
- [25 BHAM Official City Event Source Pack 2023](./25_BHAM_OFFICIAL_CITY_EVENT_SOURCE_PACK_2023.json)
- [26 BHAM Official City Event Normalized Observations 2023](./26_BHAM_OFFICIAL_CITY_EVENT_NORMALIZED_OBSERVATIONS_2023.md)
- [27 BHAM Historical Community Archive Extension 2023](./27_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_2023.md)
- [27 BHAM Historical Community Archive Extension Source Pack 2023](./27_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_SOURCE_PACK_2023.json)
- [28 BHAM Historical Community Archive Extension Normalized Observations 2023](./28_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_NORMALIZED_OBSERVATIONS_2023.md)
- [29 BHAM Public Catalog Historicalization Candidates 2023](./29_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_CANDIDATES_2023.md)
- [30 BHAM Public Catalog Historicalization Bundle 2023](./30_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_BUNDLE_2023.md)
- [31 BHAM Public Catalog Historicalized Source Pack 2023](./31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.md)
- [32 BHAM Public Catalog Historicalized Normalized Observations 2023](./32_BHAM_PUBLIC_CATALOG_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.md)
- [33 BHAM Neighborhood Association Calendar Source Pack 2023](./33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.md)
- [34 BHAM Neighborhood Association Calendar Normalized Observations 2023](./34_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_NORMALIZED_OBSERVATIONS_2023.md)
- [35 BHAM Consolidated Replay Source Pack 2023](./35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.md)
- [36 BHAM Consolidated Replay Normalized Observations 2023](./36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.md)
- [37 BHAM Replay Execution Plan 2023](./37_BHAM_REPLAY_EXECUTION_PLAN_2023.md)
- [38 BHAM Replay Execution Summary 2023](./38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.md)
- [39 BHAM Replay Governed Forecast Batch 2023](./39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.md)
- [40 BHAM Replay Virtual World Environment 2023](./40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md)
- [41 BHAM Replay Higher-Agent Rollups 2023](./41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.md)
- [42 BHAM Eventbrite Meetup Historicalized Source Pack 2023](./42_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_SOURCE_PACK_2023.md)
- [43 BHAM Eventbrite Meetup Historicalized Normalized Observations 2023](./43_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_NORMALIZED_OBSERVATIONS_2023.md)
- [44 BHAM Replay Higher-Agent Behavior Pass 2023](./44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.md)
- [45 BHAM Single-Year Replay Pass 2023](./45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.md)
- [50 BHAM Replay Population Profile 2023](./50_BHAM_REPLAY_POPULATION_PROFILE_2023.md)
- [51 BHAM Replay Place Graph 2023](./51_BHAM_REPLAY_PLACE_GRAPH_2023.md)
- [52 BHAM Replay Isolation Report 2023](./52_BHAM_REPLAY_ISOLATION_REPORT_2023.md)
- [53 BHAM Replay Kernel Participation 2023](./53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.md)
- [54 BHAM Replay Realism Gate Report 2023](./54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.md)
- [55 BHAM Replay Action Explanations 2023](./55_BHAM_REPLAY_ACTION_EXPLANATIONS_2023.md)
- [56 BHAM Replay Daily Behavior 2023](./56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.md)
- [57 BHAM Replay Calibration Report 2023](./57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md)
- [58 BHAM Replay Training Export Manifest 2023](./58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md)
- [59 BHAM Replay Actor Kernel Coverage 2023](./59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.md)
- [60 BHAM Replay Connectivity Profiles 2023](./60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.md)
- [61 BHAM Replay Exchange Summary 2023](./61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.md)
- [62 BHAM Replay Exchange Event Log 2023](./62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json)
- [63 BHAM Replay Storage Boundary Report 2023](./63_BHAM_REPLAY_STORAGE_BOUNDARY_REPORT_2023.md)
- [64 BHAM Replay Storage Export Summary 2023](./64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.md)
- [65 BHAM Replay Storage Partition Summary 2023](./65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.md)
- [66 BHAM Replay Supabase Upload And Index Summary 2023](./66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md)
- [67 BHAM Replay Physical Movement 2023](./67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.md)
- [68 BHAM Replay Training Signals 2023](./68_BHAM_REPLAY_TRAINING_SIGNALS_2023.md)
- [69 BHAM Replay Holdout Evaluation 2023](./69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.md)
- [70 BHAM Simulation Improvement Roadmap 2026](./70_BHAM_SIMULATION_IMPROVEMENT_ROADMAP_2026.md)
- [71 BHAM Replay Scenario Packets 2023](./71_BHAM_REPLAY_SCENARIO_PACKETS_2023.json)
- [72 BHAM Event Scenario Pack 2023](./72_BHAM_EVENT_SCENARIO_PACK_2023.md)
- [73 BHAM Replay Comparison Report 2023](./73_BHAM_REPLAY_COMPARISON_REPORT_2023.md)
- [74 BHAM Replay Contradiction Report 2023](./74_BHAM_REPLAY_CONTRADICTION_REPORT_2023.md)
- [75 BHAM Replay Calibration Report 2023](./75_BHAM_REPLAY_CALIBRATION_REPORT_2023.md)
- [46 BHAM Official Arts Museums Extension Source Pack 2023](./46_BHAM_OFFICIAL_ARTS_MUSEUMS_EXTENSION_SOURCE_PACK_2023.md)
- [47 BHAM Official Arts Museums Extension Normalized Observations 2023](./47_BHAM_OFFICIAL_ARTS_MUSEUMS_EXTENSION_NORMALIZED_OBSERVATIONS_2023.md)
- [48 BHAM Mesh Runtime State Frame 2023](./48_BHAM_MESH_RUNTIME_STATE_FRAME_2023.json)
- [49 BHAM AI2AI Runtime State Frame 2023](./49_BHAM_AI2AI_RUNTIME_STATE_FRAME_2023.json)

## Build Rule

The BHAM simulation should be built in this order:

1. source registry
2. temporal/replay schema
3. entity normalization and provenance model
4. historical dataset ingestion
5. seed source-pack ingestion and normalized observation generation
6. governed raw-source pull planning
7. manual-import template and priority-bundle scaffolding
8. explicit provided-input and access-state logging
9. populated priority manual-import bundle and replay-source-pack conversion
10. priority normalized-observation generation from real 2023 inputs
11. first citywide cultural seed bundle and normalized observation generation
12. first historical citywide archive bundle and normalized observation generation
13. first citywide spatial import bundle scaffolding for OSM/GIS and whole-city venue/community rows
14. first partial citywide spatial source pack and normalized observation generation
15. first automated/API replay pull batch generation
16. historicalized automated-source-pack filtering for replay-admissible sources
17. automated normalized-observation generation from replay-admissible automated sources
18. official city and major-venue 2023 event-bundle ingestion
19. historical community-archive extension ingestion
20. operational public-catalog historicalization candidate generation
21. public-catalog historicalization bundle generation
22. safe-subset public-catalog historicalized source-pack generation
23. safe-subset public-catalog historicalized normalized-observation generation
24. neighborhood-association calendar archival-reconstruction source-pack generation
25. neighborhood-association calendar normalized-observation generation
26. first consolidated BHAM replay-year source-pack generation
27. first consolidated BHAM replay-year normalized-observation generation
28. first governed BHAM replay execution-plan generation from the consolidated truth year
29. first governed BHAM replay dry-run execution summary
30. first governed replay-forecast batch generation from the consolidated truth year
31. first replay-only virtual world environment generation from the governed truth year
32. first higher-agent replay rollup generation from the replay-only virtual world
33. first historicalized Eventbrite/Meetup community-anchor source-pack generation
34. first historicalized Eventbrite/Meetup normalized-observation generation
35. first higher-agent replay behavior pass over the isolated virtual world
36. first full single-year BHAM replay pass inside the isolated virtual world
37. representative Birmingham population profile generation from the consolidated truth year
38. canonical Birmingham place, venue, community, and event graph generation
39. replay isolation report generation as a hard gate against live-runtime leakage
40. replay kernel participation report generation proving all replay-participating kernels are materially active
41. replay action explanation generation for operator-readable auditability
42. replay realism gate evaluation for base-year readiness
43. finalized single-year BHAM replay pass with realism and explainability attached
44. authoritative Birmingham replay path
45. forecast-kernel and governance integration
46. dense-city realism layer for population, place graph, calibration, and explainability
47. full-kernel actor bundle attachment for all 25k modeled AVRAI users
48. replay-only connectivity, chat, AI, admin, group, and AI2AI exchange simulation
49. actor-kernel coverage, connectivity, exchange, and training export artifacts
50. replay storage boundary validation against live app Supabase buckets and schemas
51. local staged replay export into isolated replay-storage bucket paths
52. semantic partitioning of large replay artifacts into chunked replay-only NDJSON sections
53. replay-only Supabase upload/index manifest generation, replay schema migration definition, and dry-run index validation on top of the partitioned export
54. replay physical movement artifact covering tracked locations, untracked windows, movement, and flights
55. replay-only backend indexing plan and dry-run upload/index counts for actor kernels, connectivity, exchange, and movement
56. storage architecture checkpoint before multi-year expansion
57. decade-scale replay and Monte Carlo harness
58. current-state calibration and forward-useful training outputs

Do not start broad scraping or large-scale ingestion before the source registry and temporal schema are explicit.
