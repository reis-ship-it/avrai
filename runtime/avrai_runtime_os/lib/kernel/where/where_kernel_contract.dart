import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class WhereKernelContract {
  const WhereKernelContract();

  Future<WhereState> resolveWhere(WhereKernelInput input);

  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source,
  });

  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  });

  Future<WhereObservationReceipt> observe(WhereObservation observation);

  Future<WhereSyncResult> sync(WhereSyncRequest request);

  WhereProjection project(WhereProjectionRequest request);

  Future<WherePointResolution> resolvePoint(WherePointQuery request);

  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  });

  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily,
    int localityCount,
  });

  WhereSnapshot? snapshot(String agentId);

  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request);

  WhereWhySnapshot explainWhy(WhereWhyRequest request);

  Future<WhereRealityProjection> projectForRealityModel(
    WhereProjectionRequest request,
  ) async {
    final projection = project(request);
    return WhereRealityProjection(
      summary: projection.primaryLabel,
      confidence: request.state.confidence,
      features: <String, dynamic>{
        'active_token_id': projection.activeTokenId,
        'confidence_bucket': projection.confidenceBucket,
        'near_boundary': projection.nearBoundary,
        'locality_contained_in_where': true,
      },
      payload: <String, dynamic>{
        'primary_label': projection.primaryLabel,
        'confidence_bucket': projection.confidenceBucket,
        'near_boundary': projection.nearBoundary,
        'active_token_id': projection.activeTokenId,
        'active_token_kind': projection.activeTokenKind,
        'active_token_alias': projection.activeTokenAlias,
        'metadata': projection.metadata,
      },
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    WhereProjectionRequest request,
  ) async {
    final projection = project(request);
    return KernelGovernanceProjection(
      domain: KernelDomain.where,
      summary: 'Governance spatial view for ${projection.primaryLabel}',
      confidence: request.state.confidence,
      highlights: <String>[
        projection.confidenceBucket,
        if (projection.nearBoundary) 'boundary_volatile' else 'stable',
        'locality_inside_where',
      ],
      payload: <String, dynamic>{
        'primary_label': projection.primaryLabel,
        'confidence_bucket': projection.confidenceBucket,
        'near_boundary': projection.nearBoundary,
        'active_token_id': projection.activeTokenId,
        'active_token_kind': projection.activeTokenKind,
        'active_token_alias': projection.activeTokenAlias,
        'metadata': projection.metadata,
      },
    );
  }

  Future<KernelHealthReport> diagnoseWhere() async {
    return const KernelHealthReport(
      domain: KernelDomain.where,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary:
          'where kernel exposes public spatial truth while keeping locality internal',
    );
  }
}

abstract class WhereKernelFallbackSurface extends WhereKernelContract {
  const WhereKernelFallbackSurface();
}
