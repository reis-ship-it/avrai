/// Runtime API
/// Acts as the OS Proxy layer between the apps and the engine layer.
/// This enforces the 3-Prong architecture by preventing direct engine imports from apps.

library;

// Avrai Knot Models & Services
export 'package:avrai_knot/models/audio/musical_scales.dart';
export 'package:avrai_knot/models/audio/personality_audio_params.dart';
export 'package:avrai_knot/models/audio/personality_envelope.dart';
export 'package:avrai_knot/models/audio/wavetable.dart';
export 'package:avrai_knot/models/dynamic_knot.dart';
export 'package:avrai_knot/models/entity_knot.dart';
export 'package:avrai_knot/models/knot/anonymized_knot_data.dart';
export 'package:avrai_knot/models/knot/braided_knot.dart';
export 'package:avrai_knot/models/knot/bridge_strand.dart';
export 'package:avrai_knot/models/knot/community_metrics.dart';
export 'package:avrai_knot/models/knot/fabric_cluster.dart';
export 'package:avrai_knot/models/knot/fabric_evolution.dart';
export 'package:avrai_knot/models/knot/fabric_invariants.dart';
export 'package:avrai_knot/models/knot/fabric_snapshot.dart';
export 'package:avrai_knot/models/knot/hierarchical_layout.dart';
export 'package:avrai_knot/models/knot/knot_3d.dart';
export 'package:avrai_knot/models/knot/knot_community.dart';
export 'package:avrai_knot/models/knot/knot_distribution_data.dart';
export 'package:avrai_knot/models/knot/knot_fabric.dart';
export 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';
export 'package:avrai_knot/models/knot/knot_worldsheet.dart';
export 'package:avrai_knot/models/knot/worldsheet_4d_data.dart';
export 'package:avrai_knot/models/knot/worldsheet_similarity.dart';
export 'package:avrai_knot/services/audio/personality_wavetable_factory.dart';
export 'package:avrai_knot/services/audio/simple_reverb.dart';
export 'package:avrai_knot/services/audio/stereo_encoder.dart';
export 'package:avrai_knot/services/audio/wavetable_knot_audio_service.dart';
export 'package:avrai_knot/services/audio/wavetable_oscillator.dart';
export 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
export 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';
export 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
export 'package:avrai_knot/services/knot/dynamic_knot_service.dart';
export 'package:avrai_knot/services/knot/entity_knot_service.dart';
export 'package:avrai_knot/services/knot/glue_visualization_service.dart';
export 'package:avrai_knot/services/knot/hierarchical_layout_service.dart';
export 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
export 'package:avrai_knot/services/knot/knot_3d_converter_service.dart';
export 'package:avrai_knot/services/knot/knot_cache_service.dart';
export 'package:avrai_knot/services/knot/knot_community_service.dart';
export 'package:avrai_knot/services/knot/knot_data_api_service.dart';
export 'package:avrai_knot/services/knot/knot_evolution_coordinator_service.dart';
export 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
export 'package:avrai_knot/services/knot/knot_fabric_service.dart';
export 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
export 'package:avrai_knot/services/knot/knot_privacy_service.dart';
export 'package:avrai_knot/services/knot/knot_storage_service.dart';
export 'package:avrai_knot/services/knot/knot_weaving_service.dart';
export 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
export 'package:avrai_knot/services/knot/network_cross_pollination_service.dart';
export 'package:avrai_knot/services/knot/personality_knot_service.dart';
export 'package:avrai_knot/services/knot/prominence_calculator.dart';
export 'package:avrai_knot/services/knot/quantum_state_knot_service.dart';
export 'package:avrai_knot/services/knot/string_export_service.dart';
export 'package:avrai_knot/services/knot/worldsheet_4d_visualization_service.dart';
export 'package:avrai_knot/services/knot/worldsheet_analytics_service.dart';
export 'package:avrai_knot/services/knot/worldsheet_comparison_service.dart';

// Reality Engine Data
export 'package:reality_engine/memory/air_gap/tuple_extraction_engine.dart';
export 'package:reality_engine/memory/semantic_knowledge_store.dart';

// Avrai Quantum Models & Services
export 'package:avrai_quantum/services/quantum/dimensionality_reduction_service.dart';
export 'package:avrai_quantum/services/quantum/entanglement_coefficient_optimizer.dart';
export 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
export 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';

// Avrai AI Models & Services (Now native to runtime OS)
export 'package:avrai_runtime_os/ai2ai/models/community_chat_message.dart';
export 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
export 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
export 'package:avrai_ai/services/contextual_personality_service.dart';
