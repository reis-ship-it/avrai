import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

/// Extraction-ready locality boundary.
///
/// Syscall mapping:
/// - `resolve_where`
/// - `observe_locality`
/// - `sync_locality`
/// - `project_locality`
/// - `snapshot_locality`
abstract class LocalityKernelContract {
  Future<LocalityState> resolveWhere(LocalityPerceptionInput input);

  Future<LocalityState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source,
  });

  Future<LocalityUpdateReceipt?> observeVisit({
    required String userId,
    required Visit visit,
    required String source,
  });

  Future<LocalityUpdateReceipt> observe(LocalityObservation observation);

  Future<LocalitySyncResult> sync(LocalitySyncRequest request);

  LocalityProjection project(LocalityProjectionRequest request);

  Future<LocalityPointResolution> resolvePoint(LocalityPointQuery request);

  Future<bool> observeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  });

  Future<LocalityZeroReliabilityReport> evaluateZeroLocalityReadiness({
    required String cityProfile,
    String modelFamily,
    int localityCount,
  });

  LocalityKernelSnapshot? snapshot(String agentId);

  Future<LocalityRecoveryResult> recover(LocalityRecoveryRequest request);
}
