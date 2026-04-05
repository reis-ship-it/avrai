# ML Model Training Checklist

Generated Source Digest: `797da5754aed804c`

## Purpose
This file is generated. Do not edit manually.
It is the canonical, uniform checklist for model training readiness and completion across all entity models.

## Registry

| Model ID | Entity | AVRAI Native Type | Status | Last Trained (UTC) | Dataset Snapshot | Run ID | Auto Train | Milestone | Master Plan Refs |
|---|---|---|---|---|---|---|---|---|---|
| mdl-atomic-temporal-sync-v1 | atomic_temporal | avrai.quantum.atomic_temporal.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.1.3|3.1.7|3.1A.2|patent_30 |
| mdl-brand-sponsor-energy-v1 | brand | avrai.entity.brand.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.2.21|4.4.9|4.4.12 |
| mdl-business-energy-v1 | business | avrai.entity.business.frame.v1 | trained | 2026-02-16T02:05:18Z | ds_business_seed_20260216 | run_business_seed_20260216_001 | true | M0-P10-1 | 1.2.22|1.2.26|4.4.8|4.4.11 |
| mdl-community-energy-v1 | community | avrai.entity.community.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.2.5|4.4.1|4.4.6 |
| mdl-event-energy-v1 | event | avrai.entity.event.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.2.6|1.2.20|4.4.2 |
| mdl-knot-string-worldsheet-v1 | knot_string_worldsheet | avrai.knot.worldsheet.frame.v1 | planned | - | - | - | true | M0-P10-1 | 3.3.14|3.4.5|patent_31 |
| mdl-list-curation-energy-v1 | list | avrai.entity.list.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.2.7|1.2.8|4.4.4|4.4.7 |
| mdl-locality-advisory-v1 | locality | avrai.entity.locality.frame.v1 | planned | - | - | - | true | M0-P10-1 | 8.9A|8.9B|8.9C |
| mdl-quantum-entanglement-v1 | quantum_entanglement | avrai.quantum.entanglement.frame.v1 | simulated | - | - | - | true | M0-P10-1 | 3.3.5|scripts/ml/train_entanglement_model.py |
| mdl-quantum-optimization-v1 | quantum_optimization | avrai.quantum.optimization.frame.v1 | planned | - | - | - | true | M0-P10-1 | 3|scripts/ml/train_quantum_optimization_model.py |
| mdl-spot-energy-v1 | spot | avrai.entity.spot.frame.v1 | planned | - | - | - | true | M0-P10-1 | 1.2.18|1.7.12|4.1 |

## Uniform Training Contract

Required common fields:
- `event_id`
- `agent_id`
- `entity_type`
- `entity_id`
- `action_type`
- `state_before`
- `next_state`
- `outcome`
- `timestamp_utc`
- `consent_scope`
- `feature_spec_version`
- `label_spec_version`

Required location fields:
- `geohash`
- `locality_code`
- `city_code`
- `timezone`

Uniform stages:
- `offline_replay`
- `shadow`
- `limited_rollout`

## Entity Data Requirements

### mdl-atomic-temporal-sync-v1

- Entity: `atomic_temporal`
- Feature spec: `atomic-temporal-v1`
- Minimum data gate: episodes >= 2500, positives >= 250, null rate <= 0.03, freshness <= 24h
- Location fields:
  - `geohash`, `locality_code`, `city_code`, `timezone`
- Type fields:
  - `clock_source`, `sync_mode`, `temporal_state_family`
- Event Scale fields:
  - `sync_events_24h`, `cross_device_sync_count`, `entanglement_sync_samples`
- Outcomes fields:
  - `timestamp_drift_ms`, `entanglement_sync_accuracy`, `timezone_operation_accuracy`

### mdl-brand-sponsor-energy-v1

- Entity: `brand`
- Feature spec: `brand-v1`
- Minimum data gate: episodes >= 2500, positives >= 250, null rate <= 0.05, freshness <= 96h
- Location fields:
  - `target_locality_codes`, `campaign_geohash_coverage`
- Type fields:
  - `brand_category`, `values_vector`, `reach_tier`
- Event Scale fields:
  - `sponsored_event_count_30d`, `avg_sponsorship_amount`, `audience_reach`
- Outcomes fields:
  - `engagement_lift`, `renewal_rate_90d`, `brand_event_fit_score`, `roi_index`

### mdl-business-energy-v1

- Entity: `business`
- Feature spec: `business-v1`
- Minimum data gate: episodes >= 5000, positives >= 500, null rate <= 0.05, freshness <= 72h
- Location fields:
  - `geohash`, `locality_code`, `business_hours`, `foot_traffic_band`
- Type fields:
  - `business_category`, `price_tier`, `verification_status`, `service_modality`
- Event Scale fields:
  - `hosted_event_count_30d`, `avg_event_capacity`, `avg_event_attendance`, `no_show_rate`
- Outcomes fields:
  - `reservation_conversion_rate`, `repeat_patron_rate_30d`, `partnership_longevity_90d`, `refund_or_dispute_rate`

### mdl-community-energy-v1

- Entity: `community`
- Feature spec: `community-v1`
- Minimum data gate: episodes >= 4000, positives >= 400, null rate <= 0.05, freshness <= 72h
- Location fields:
  - `primary_geohash`, `locality_code`, `activity_timeband_histogram`
- Type fields:
  - `community_type`, `topic_tags`, `moderation_tier`, `privacy_mode`
- Event Scale fields:
  - `active_member_count`, `event_count_30d`, `avg_event_attendance`, `attendance_fill_rate`
- Outcomes fields:
  - `join_to_retained_30d`, `member_churn_30d`, `event_repeat_attendance`, `moderation_incident_rate`

### mdl-event-energy-v1

- Entity: `event`
- Feature spec: `event-v1`
- Minimum data gate: episodes >= 6000, positives >= 600, null rate <= 0.05, freshness <= 72h
- Location fields:
  - `venue_geohash`, `locality_code`, `timeband`
- Type fields:
  - `event_type`, `host_type`, `ticketing_type`, `age_gate`
- Event Scale fields:
  - `planned_capacity`, `actual_attendance`, `waitlist_count`, `no_show_rate`
- Outcomes fields:
  - `attendance_conversion_rate`, `post_event_quality_score`, `repeat_attendance_60d`, `sponsor_fit_score`

### mdl-knot-string-worldsheet-v1

- Entity: `knot_string_worldsheet`
- Feature spec: `knot-string-worldsheet-v1`
- Minimum data gate: episodes >= 2500, positives >= 250, null rate <= 0.05, freshness <= 120h
- Location fields:
  - `geohash`, `locality_code`, `city_code`, `timezone`
- Type fields:
  - `knot_type`, `string_evolution_mode`, `worldsheet_slice_type`
- Event Scale fields:
  - `crossing_number`, `worldsheet_snapshot_count`, `evolution_window_hours`
- Outcomes fields:
  - `knot_stability_score`, `string_interpolation_error`, `worldsheet_prediction_error`

### mdl-list-curation-energy-v1

- Entity: `list`
- Feature spec: `list-v1`
- Minimum data gate: episodes >= 3500, positives >= 350, null rate <= 0.05, freshness <= 72h
- Location fields:
  - `geographic_spread`, `dominant_locality_code`
- Type fields:
  - `list_type`, `collaboration_mode`, `curation_tags`
- Event Scale fields:
  - `item_count`, `follower_count`, `collaborator_count`
- Outcomes fields:
  - `save_to_action_rate`, `follow_through_rate`, `retention_30d`, `composition_stability`

### mdl-locality-advisory-v1

- Entity: `locality`
- Feature spec: `locality-v1`
- Minimum data gate: episodes >= 3000, positives >= 300, null rate <= 0.05, freshness <= 96h
- Location fields:
  - `locality_code`, `city_code`, `geohash_clusters`
- Type fields:
  - `locality_type`, `mobility_profile`, `language_cluster`
- Event Scale fields:
  - `events_per_7d`, `avg_attendance`, `category_supply_gap_index`
- Outcomes fields:
  - `locality_happiness_score`, `trend_shift_14d`, `advisory_success_rate`

### mdl-quantum-entanglement-v1

- Entity: `quantum_entanglement`
- Feature spec: `quantum-entanglement-v1`
- Minimum data gate: episodes >= 4000, positives >= 400, null rate <= 0.05, freshness <= 96h
- Location fields:
  - `geohash`, `locality_code`, `city_code`, `timezone`
- Type fields:
  - `dimension_pair_id`, `correlation_family`, `state_topology_type`
- Event Scale fields:
  - `pair_observation_count_30d`, `cross_domain_signal_count_30d`, `mesh_exchange_count_30d`
- Outcomes fields:
  - `correlation_prediction_error`, `entanglement_stability_score`, `compatibility_lift_vs_baseline`

### mdl-quantum-optimization-v1

- Entity: `quantum_optimization`
- Feature spec: `quantum-optimization-v1`
- Minimum data gate: episodes >= 3000, positives >= 300, null rate <= 0.05, freshness <= 96h
- Location fields:
  - `geohash`, `locality_code`, `city_code`, `timezone`
- Type fields:
  - `optimization_use_case`, `measurement_basis_type`, `weight_policy_version`
- Event Scale fields:
  - `optimization_trials_7d`, `candidate_policy_count`, `eval_window_size`
- Outcomes fields:
  - `policy_lift`, `calibration_error`, `constraint_violation_rate`

### mdl-spot-energy-v1

- Entity: `spot`
- Feature spec: `spot-v1`
- Minimum data gate: episodes >= 8000, positives >= 800, null rate <= 0.05, freshness <= 48h
- Location fields:
  - `geohash`, `locality_code`, `open_hours_reliability`
- Type fields:
  - `spot_category`, `venue_type`, `price_tier`, `safety_tier`
- Event Scale fields:
  - `peak_occupancy_band`, `checkin_volume_30d`
- Outcomes fields:
  - `visit_conversion_rate`, `return_visit_30d`, `dismiss_rate`, `explicit_rating_mean`

## Simulation Contract

Spec: `sim-standard-v1` - Universal staged experiment contract for all entity models.

| Stage | Metric | Direction | Threshold |
|---|---|---|---|
| offline_replay | auc | gte | 0.72 |
| offline_replay | calibration_error | lte | 0.08 |
| shadow | policy_violation_rate | lte | 0.005 |
| shadow | decision_lift_vs_baseline | gte | 0.01 |
| limited_rollout | negative_outcome_delta | lte | 0.0 |
| limited_rollout | target_outcome_lift | gte | 0.015 |

## Source Files

- `configs/ml/model_training_registry.csv`
- `configs/ml/feature_label_contracts.json`
- `configs/ml/avrai_native_type_contracts.json`
- `configs/ml/simulation_experiment_contracts.json`
- `configs/ml/simulation_experiment_runs.csv`
- `configs/ml/learning_cycle_recovery_queue.csv`
- `scripts/ml/auto_recover_learning_cycles.py`
- `scripts/ml/build_training_dataset.py`
- `scripts/generate_ml_training_checklist.py`

