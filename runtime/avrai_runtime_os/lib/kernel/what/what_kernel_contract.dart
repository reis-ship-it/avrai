import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show
        KernelAuthorityLevel,
        KernelDomain,
        KernelGovernanceProjection,
        KernelHealthReport,
        KernelHealthStatus,
        WhatRealityProjection;
import 'package:avrai_runtime_os/kernel/what/what_models.dart';

abstract class WhatKernelContract {
  const WhatKernelContract();

  Future<WhatState> resolveWhat(WhatPerceptionInput input);

  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation);

  WhatProjection projectWhat(WhatProjectionRequest request);

  WhatKernelSnapshot? snapshotWhat(String agentId);

  Future<WhatSyncResult> syncWhat(WhatSyncRequest request);

  Future<WhatRecoveryResult> recoverWhat(WhatRecoveryRequest request);

  Future<WhatRealityProjection> projectForRealityModel(
    WhatProjectionRequest request,
  ) async {
    final projection = projectWhat(request);
    return WhatRealityProjection(
      summary: 'Semantic state for ${projection.baseEntityRef}',
      confidence: projection.confidence,
      features: <String, dynamic>{
        'projected_types': projection.projectedTypes,
        'adjacent_opportunities': projection.adjacentOpportunities,
      },
      payload: projection.toJson(),
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    WhatProjectionRequest request,
  ) async {
    final projection = projectWhat(request);
    return KernelGovernanceProjection(
      domain: KernelDomain.what,
      summary: 'Governance semantic view for ${projection.baseEntityRef}',
      confidence: projection.confidence,
      highlights: projection.projectedTypes,
      payload: projection.toJson(),
    );
  }

  Future<KernelHealthReport> diagnoseWhat() async {
    return const KernelHealthReport(
      domain: KernelDomain.what,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary:
          'what kernel exposes semantic authority, recovery, and projection surfaces',
    );
  }
}

abstract class WhatKernelFallbackSurface extends WhatKernelContract {
  const WhatKernelFallbackSurface();
}
