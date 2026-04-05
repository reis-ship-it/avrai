import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';

class KernelGraphAdminDigestProjector {
  const KernelGraphAdminDigestProjector();

  KernelGraphAdminDigest project({
    required KernelGraphCompiledPlan plan,
    required KernelGraphExecutionReceipt receipt,
  }) {
    final completedNodeCount = receipt.nodeReceipts
        .where((entry) => entry.status == KernelGraphNodeStatus.completed)
        .length;
    final activeNodeId = receipt.status == KernelGraphRunStatus.running
        ? receipt.nodeReceipts.lastOrNull?.nodeId
        : null;
    final summary = receipt.status == KernelGraphRunStatus.completed
        ? '${plan.title} completed $completedNodeCount/${plan.steps.length} steps.'
        : '${plan.title} ${receipt.status.name} after '
            '$completedNodeCount/${plan.steps.length} steps.';

    return KernelGraphAdminDigest(
      runId: receipt.runId,
      specId: receipt.specId,
      graphTitle: plan.title,
      kind: plan.kind,
      status: receipt.status,
      summary: summary,
      requiresHumanReview: plan.executionPolicy.requiresHumanReview,
      completedNodeCount: completedNodeCount,
      totalNodeCount: plan.steps.length,
      activeNodeId: activeNodeId,
      lineageRefs: _stringList(plan.metadata['lineageRefs']),
      rollbackRefs: receipt.rollbackDescriptor?.refs ?? const <String>[],
      metadata: <String, dynamic>{
        'environment': plan.executionPolicy.environment.name,
        'simulationFirst': plan.executionPolicy.simulationFirst,
        'allowedMutableSurfaces': plan.executionPolicy.allowedMutableSurfaces,
      },
    );
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}
