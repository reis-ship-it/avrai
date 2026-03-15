import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
export 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart'
    show WhereKernelContract, WhereKernelFallbackSurface;
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

/// Extraction-ready where-kernel boundary.
///
/// Syscall mapping:
/// - `resolve_where`
/// - `observe_locality`
/// - `sync_locality`
/// - `project_locality`
/// - `snapshot_locality`
/// - `explain_why`
abstract class LocalityWhereProviderContract {
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

  WhySnapshot explainWhy(WhyKernelRequest request);

  Future<WhereRealityProjection> projectForRealityModel(
    LocalityProjectionRequest request,
  );

  Future<KernelGovernanceProjection> projectForGovernance(
    LocalityProjectionRequest request,
  );

  Future<KernelHealthReport> diagnoseWhere();
}

typedef LocalityKernelContract = LocalityWhereProviderContract;

/// Explicit Dart fallback boundary for when the native where kernel
/// cannot handle or load a syscall path.
///
/// This keeps fallback ownership anchored to the concrete runtime kernel
/// instead of routing fallback behavior back through the native-first
/// public contract.
abstract class LocalityWhereProviderFallbackSurface
    implements LocalityWhereProviderContract {}

typedef LocalityKernelFallbackSurface = LocalityWhereProviderFallbackSurface;
