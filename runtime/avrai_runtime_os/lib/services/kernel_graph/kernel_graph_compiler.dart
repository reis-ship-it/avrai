import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';

import 'kernel_graph_primitive_registry.dart';

class KernelGraphCompiler {
  const KernelGraphCompiler();

  KernelGraphCompilationResult compile({
    required KernelGraphSpec spec,
    required KernelGraphPrimitiveRegistry registry,
  }) {
    final diagnostics = <KernelGraphCompilationDiagnostic>[];
    final nodeIds = <String>{};
    final nodeIndex = <String, int>{};
    final nodesById = <String, KernelGraphNodeSpec>{};

    for (var i = 0; i < spec.nodes.length; i++) {
      final node = spec.nodes[i];
      if (!nodeIds.add(node.id)) {
        diagnostics.add(
          KernelGraphCompilationDiagnostic(
            severity: KernelGraphDiagnosticSeverity.error,
            code: 'duplicate_node_id',
            message: 'Duplicate node id `${node.id}` found in graph spec.',
            nodeId: node.id,
          ),
        );
        continue;
      }
      nodeIndex[node.id] = i;
      nodesById[node.id] = node;
      if (!registry.contains(node.primitiveId)) {
        diagnostics.add(
          KernelGraphCompilationDiagnostic(
            severity: KernelGraphDiagnosticSeverity.error,
            code: 'unknown_primitive',
            message:
                'Primitive `${node.primitiveId}` is not registered for node `${node.id}`.',
            nodeId: node.id,
          ),
        );
      }
    }

    final adjacency = <String, Set<String>>{
      for (final node in spec.nodes) node.id: <String>{},
    };
    final indegree = <String, int>{
      for (final node in spec.nodes) node.id: 0,
    };

    for (final edge in spec.edges) {
      if (!nodesById.containsKey(edge.fromNodeId) ||
          !nodesById.containsKey(edge.toNodeId)) {
        diagnostics.add(
          KernelGraphCompilationDiagnostic(
            severity: KernelGraphDiagnosticSeverity.error,
            code: 'unknown_edge_endpoint',
            message:
                'Edge `${edge.ref}` references a node that does not exist in the graph spec.',
            edgeRef: edge.ref,
          ),
        );
        continue;
      }
      if (adjacency[edge.fromNodeId]!.add(edge.toNodeId)) {
        indegree[edge.toNodeId] = (indegree[edge.toNodeId] ?? 0) + 1;
      }
    }

    if (diagnostics.any(
      (entry) => entry.severity == KernelGraphDiagnosticSeverity.error,
    )) {
      return KernelGraphCompilationResult(
        isValid: false,
        diagnostics: diagnostics,
      );
    }

    final queue = spec.nodes
        .where((node) => (indegree[node.id] ?? 0) == 0)
        .toList(growable: true)
      ..sort(
        (left, right) => (nodeIndex[left.id] ?? 0).compareTo(
          nodeIndex[right.id] ?? 0,
        ),
      );
    final orderedNodes = <KernelGraphNodeSpec>[];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      orderedNodes.add(current);

      final neighbors = adjacency[current.id]!.toList(growable: false)
        ..sort(
          (left, right) => (nodeIndex[left] ?? 0).compareTo(
            nodeIndex[right] ?? 0,
          ),
        );

      for (final neighborId in neighbors) {
        final nextIndegree = (indegree[neighborId] ?? 0) - 1;
        indegree[neighborId] = nextIndegree;
        if (nextIndegree == 0) {
          queue.add(nodesById[neighborId]!);
          queue.sort(
            (left, right) => (nodeIndex[left.id] ?? 0).compareTo(
              nodeIndex[right.id] ?? 0,
            ),
          );
        }
      }
    }

    if (orderedNodes.length != spec.nodes.length) {
      diagnostics.add(
        const KernelGraphCompilationDiagnostic(
          severity: KernelGraphDiagnosticSeverity.error,
          code: 'graph_cycle_detected',
          message:
              'KernelGraph compilation failed because the node graph contains a cycle.',
        ),
      );
      return KernelGraphCompilationResult(
        isValid: false,
        diagnostics: diagnostics,
      );
    }

    if (spec.executionPolicy.maxStepCount != null &&
        orderedNodes.length > spec.executionPolicy.maxStepCount!) {
      diagnostics.add(
        KernelGraphCompilationDiagnostic(
          severity: KernelGraphDiagnosticSeverity.error,
          code: 'step_budget_exceeded',
          message:
              'KernelGraph contains ${orderedNodes.length} steps but policy allows only ${spec.executionPolicy.maxStepCount}.',
        ),
      );
      return KernelGraphCompilationResult(
        isValid: false,
        diagnostics: diagnostics,
      );
    }

    final compiledPlan = KernelGraphCompiledPlan(
      specId: spec.id,
      title: spec.title,
      kind: spec.kind,
      version: spec.version,
      executionPolicy: spec.executionPolicy,
      metadata: spec.metadata,
      steps: orderedNodes
          .asMap()
          .entries
          .map(
            (entry) => KernelGraphCompiledStep(
              nodeId: entry.value.id,
              primitiveId: entry.value.primitiveId,
              label: entry.value.label,
              order: entry.key,
              config: entry.value.config,
              metadata: entry.value.metadata,
            ),
          )
          .toList(growable: false),
    );

    return KernelGraphCompilationResult(
      isValid: true,
      diagnostics: diagnostics,
      compiledPlan: compiledPlan,
    );
  }
}
