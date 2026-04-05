import 'package:avrai_runtime_os/config/supabase_config.dart';

/// Replay/simulation storage config.
///
/// This namespace must remain isolated from live app buckets and public-schema
/// tables so BHAM replay artifacts cannot cross wires with production data.
class ReplayStorageConfig {
  const ReplayStorageConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_REPLAY_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_REPLAY_ANON_KEY',
    defaultValue: '',
  );
  static const String serviceRoleKey = String.fromEnvironment(
    'SUPABASE_REPLAY_SERVICE_ROLE_KEY',
    defaultValue: '',
  );

  static const String schema = String.fromEnvironment(
    'SUPABASE_REPLAY_SCHEMA',
    defaultValue: 'replay_simulation',
  );

  static const String sourcePacksBucket = 'replay-source-packs';
  static const String normalizedObservationsBucket =
      'replay-normalized-observations';
  static const String worldSnapshotsBucket = 'replay-world-snapshots';
  static const String trainingExportsBucket = 'replay-training-exports';
  static const String exchangeLogsBucket = 'replay-exchange-logs';

  static const List<String> buckets = <String>[
    sourcePacksBucket,
    normalizedObservationsBucket,
    worldSnapshotsBucket,
    trainingExportsBucket,
    exchangeLogsBucket,
  ];

  static const List<String> metadataTables = <String>[
    'replay_runs',
    'replay_artifacts',
    'replay_artifact_partitions',
    'replay_lineage',
    'replay_calibration_reports',
    'replay_realism_gate_reports',
    'replay_training_exports',
    'replay_actor_profiles',
    'replay_actor_kernel_bundles',
    'replay_kernel_activation_traces',
    'replay_actor_connectivity_profiles',
    'replay_actor_connectivity_transitions',
    'replay_actor_tracked_locations',
    'replay_actor_untracked_windows',
    'replay_actor_movements',
    'replay_actor_flights',
    'replay_exchange_threads',
    'replay_exchange_participations',
    'replay_exchange_events',
    'replay_ai2ai_exchange_records',
  ];

  static const int stagingRetentionTtlDays = 30;
  static const int partitionRetentionTtlDays = 30;
  static const bool cleanupStagingOnSuccessfulUpload = true;

  static bool get usesDedicatedProject =>
      url.isNotEmpty &&
      SupabaseConfig.url.isNotEmpty &&
      url != SupabaseConfig.url;

  static bool get sharesProjectWithApp =>
      url.isEmpty ||
      (SupabaseConfig.url.isNotEmpty && url == SupabaseConfig.url);
}
