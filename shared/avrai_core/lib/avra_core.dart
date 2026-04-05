// AVRA Core Library
// Main export file for core models, enums, and interfaces

// Enums
export 'enums/user_enums.dart';
export 'enums/spot_enums.dart';
export 'enums/list_enums.dart';

// Models
export 'models/user.dart';
export 'models/spot.dart';
export 'models/spot_list.dart';
export 'models/user_vibe.dart';
export 'models/community.dart';
export 'models/mood_state.dart';
export 'models/unified_location_data.dart';
export 'models/social_context.dart';

// Repository interfaces
export 'repositories/auth_repository.dart';
export 'repositories/spots_repository.dart';
export 'repositories/lists_repository.dart';

// Common utilities
export 'utils/validation.dart';
export 'utils/constants.dart';
export 'utils/vibe_constants.dart';
export 'utils/attraction_dimensions.dart';

// Core services
export 'services/atomic_clock_service.dart';
export 'services/community_reader.dart';
export 'services/key_value_store.dart';
export 'services/logger.dart';
export 'services/clock_source.dart';
export 'services/air_gap_compression_kernel.dart';
export 'services/event_planning_evidence_factory.dart';
export 'services/temporal_lineage_sink.dart';
export 'services/truth_scope_registry.dart';

// Core models
export 'models/atomic_timestamp.dart';
export 'models/temporal/semantic_time_band.dart';
export 'models/temporal/forecast_temporal_claim.dart';
export 'models/temporal/forecast_outcome_kind.dart';
export 'models/truth/forecast_representation_component.dart';
export 'models/temporal/forecast_decision_spec.dart';
export 'models/temporal/forecast_predictive_distribution.dart';
export 'models/temporal/forecast_strength_diagnostics.dart';
export 'models/temporal/forecast_calibration_snapshot.dart';
export 'models/temporal/forecast_resolution_record.dart';
export 'models/temporal/forecast_evaluation_trace.dart';
export 'models/temporal/ground_truth_override_record.dart';
export 'models/temporal/historical_temporal_evidence.dart';
export 'models/temporal/monte_carlo_run_context.dart';
export 'models/temporal/replay_actor_kernel_coverage_report.dart';
export 'models/temporal/replay_agent_kernel_bundle.dart';
export 'models/temporal/replay_branch_lineage.dart';
export 'models/temporal/replay_connectivity_profile.dart';
export 'models/temporal/replay_entity_identity.dart';
export 'models/temporal/replay_exchange.dart';
export 'models/temporal/replay_physical_movement.dart';
export 'models/temporal/replay_historicalization_bundle.dart';
export 'models/temporal/replay_ingestion_manifest.dart';
export 'models/temporal/replay_ingestion_source_plan.dart';
export 'models/temporal/replay_manual_import_bundle.dart';
export 'models/temporal/replay_normalized_observation.dart';
export 'models/temporal/replay_source_descriptor.dart';
export 'models/temporal/replay_source_dataset.dart';
export 'models/temporal/replay_source_pack.dart';
export 'models/temporal/replay_source_pull_plan.dart';
export 'models/temporal/replay_source_record.dart';
export 'models/temporal/replay_temporal_envelope.dart';
export 'models/temporal/replay_truth_resolution.dart';
export 'models/temporal/replay_world_isolation_boundary.dart';
export 'models/temporal/replay_virtual_world_environment.dart';
export 'models/temporal/replay_virtual_world_node.dart';
export 'models/temporal/replay_higher_agent_rollup.dart';
export 'models/temporal/replay_higher_agent_action.dart';
export 'models/temporal/replay_higher_agent_behavior_pass.dart';
export 'models/temporal/replay_single_year_pass_summary.dart';
export 'models/temporal/replay_storage_boundary_report.dart';
export 'models/temporal/replay_storage_export_manifest.dart';
export 'models/temporal/replay_storage_partition_manifest.dart';
export 'models/temporal/replay_storage_upload_manifest.dart';
export 'models/temporal/replay_population_profile.dart';
export 'models/temporal/replay_population_generator.dart';
export 'models/temporal/replay_place_graph.dart';
export 'models/temporal/replay_action_explanation.dart';
export 'models/temporal/replay_action_training_record.dart';
export 'models/temporal/replay_daily_behavior.dart';
export 'models/temporal/replay_calibration_report.dart';
export 'models/temporal/replay_kernel_participation_report.dart';
export 'models/temporal/replay_isolation_report.dart';
export 'models/temporal/replay_higher_agent_intervention_trace.dart';
export 'models/temporal/replay_holdout_evaluation_report.dart';
export 'models/temporal/replay_outcome_label.dart';
export 'models/temporal/replay_realism_gate_report.dart';
export 'models/temporal/replay_stochastic_run_config.dart';
export 'models/temporal/replay_training_export_manifest.dart';
export 'models/temporal/replay_truth_decision_record.dart';
export 'models/temporal/replay_year_completeness_score.dart';
export 'models/temporal/runtime_temporal_event.dart';
export 'models/temporal/agent_lifecycle_transition.dart';
export 'models/temporal/temporal_cadence.dart';
export 'models/temporal/temporal_freshness_policy.dart';
export 'models/temporal/temporal_instant.dart';
export 'models/temporal/temporal_interval.dart';
export 'models/temporal/temporal_ordering_policy.dart';
export 'models/temporal/temporal_provenance.dart';
export 'models/temporal/temporal_snapshot.dart';
export 'models/temporal/temporal_uncertainty.dart';
export 'models/truth/truth_scope_descriptor.dart';
export 'models/truth/truth_evidence_envelope.dart';
export 'models/air_gap/air_gap_compression_models.dart';
export 'models/truth/partner_outcome_receipt.dart';
export 'models/governance/governed_run_models.dart';
export 'models/security/security_scope_channels.dart';
export 'models/security/security_countermeasure_bundle.dart';
export 'models/security/security_immune_models.dart';
export 'models/interpretation/interpretation_models.dart';
export 'models/boundary/boundary_models.dart';
export 'models/expression/expression_models.dart';
export 'models/vibe/vibe_models.dart';
export 'models/user/language_profile.dart';
export 'models/user/language_profile_diagnostics.dart';
export 'models/research/governed_autoresearch_models.dart';
export 'models/reality/reality_model_contracts.dart';
export 'models/reality/governed_learning_envelope.dart';
export 'models/reality/governed_learning_adoption_receipt.dart';
export 'models/reality/governed_learning_chat_observation_receipt.dart';
export 'models/reality/governed_learning_usage_receipt.dart';
export 'models/reality/user_visible_governed_learning.dart';
export 'models/kernel_graph/kernel_graph_models.dart';
export 'contracts/air_gap_compression_contract.dart';

// Quantum models (moved from avrai_quantum)
export 'models/quantum_entity_type.dart';
export 'models/quantum_entity_state.dart';

// Personality models (moved from avrai_ai/avrai_knot)
export 'models/contextual_personality.dart';
export 'models/personality_knot.dart';
export 'models/personality_profile.dart';
