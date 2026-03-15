import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class HowKernelContract {
  const HowKernelContract();

  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope);

  Future<HowExecutionPlan> planHow(HowPlanningRequest request) async {
    return HowExecutionPlan(
      executionId: request.executionId,
      path:
          request.context['execution_path'] as String? ?? 'native_orchestrated',
      workflowStage:
          request.context['workflow_stage'] as String? ?? 'planned_execution',
      capabilityChain: ((request.context['capability_chain'] as List?) ??
              const <dynamic>['observe', 'rank', 'respond'])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  Future<HowExecutionTrace> executeHow(HowExecutionPlan plan) async {
    return HowExecutionTrace(
      executionId: plan.executionId,
      path: plan.path,
      completedAtUtc: DateTime.now().toUtc(),
      status: 'executed',
      capabilityChain: plan.capabilityChain,
    );
  }

  Future<HowExecutionTrace> traceHow(String executionId) async {
    final snapshot = await snapshotHow(executionId);
    return HowExecutionTrace(
      executionId: executionId,
      path: snapshot?.executionPath ?? 'native_orchestrated',
      completedAtUtc: DateTime.now().toUtc(),
      status: 'traced',
      capabilityChain: snapshot?.interventionChain ?? const <String>[],
    );
  }

  Future<HowRollbackReceipt> rollbackHow(HowRollbackRequest request) async {
    return HowRollbackReceipt(
      executionId: request.executionId,
      rolledBack: true,
      recordedAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<HowInterventionReceipt> interveneHow(
    HowInterventionDirective directive,
  ) async {
    return HowInterventionReceipt(
      executionId: directive.executionId,
      directive: directive.directive,
      accepted: true,
      recordedAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<HowKernelSnapshot?> snapshotHow(String subjectId) async {
    return resolveHow(
      KernelEventEnvelope(
        eventId: 'how_snapshot:$subjectId',
        occurredAtUtc: DateTime.now().toUtc(),
        agentId: subjectId,
        sourceSystem: 'how_kernel_snapshot',
        eventType: 'snapshot',
        actionType: 'resolve_execution',
      ),
    );
  }

  Future<List<KernelReplayRecord>> replayHow(
      KernelReplayRequest request) async {
    final snapshot = await snapshotHow(request.subjectId);
    if (snapshot == null) {
      return const <KernelReplayRecord>[];
    }
    return <KernelReplayRecord>[
      KernelReplayRecord(
        domain: KernelDomain.how,
        recordId: 'how:${request.subjectId}',
        occurredAtUtc: DateTime.now().toUtc(),
        summary: 'Execution replay for ${request.subjectId}',
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<HowRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.how ??
        await snapshotHow(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.eventId ??
              'unknown_execution',
        );
    return HowRealityProjection(
      summary:
          'Execution path ${snapshot?.executionPath ?? 'unknown'} in ${snapshot?.workflowStage ?? 'unknown_stage'}',
      confidence: snapshot?.mechanismConfidence ?? 0.0,
      features: <String, dynamic>{
        'transport_mode': snapshot?.transportMode,
        'planner_mode': snapshot?.plannerMode,
        'failure_mechanism': snapshot?.failureMechanism,
      },
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.how ??
        await snapshotHow(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.eventId ??
              'unknown_execution',
        );
    return KernelGovernanceProjection(
      domain: KernelDomain.how,
      summary:
          'Governance execution view for ${request.subjectId ?? 'unknown_execution'}',
      confidence: snapshot?.mechanismConfidence ?? 0.0,
      highlights: snapshot?.interventionChain ?? const <String>[],
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelHealthReport> diagnoseHow() async {
    return const KernelHealthReport(
      domain: KernelDomain.how,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary: 'how kernel is enforcing canonical execution tracing',
    );
  }
}

abstract class HowKernelFallbackSurface extends HowKernelContract {
  const HowKernelFallbackSurface();
}
