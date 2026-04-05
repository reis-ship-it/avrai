import 'dart:developer' as developer;

import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';

import 'kernel_graph_admin_digest_projector.dart';
import 'kernel_graph_compiler.dart';
import 'kernel_graph_primitive_registry.dart';
import 'kernel_graph_run_ledger.dart';

class KernelGraphRunResult {
  const KernelGraphRunResult({
    required this.compilation,
    required this.receipt,
    required this.adminDigest,
  });

  final KernelGraphCompilationResult compilation;
  final KernelGraphExecutionReceipt receipt;
  final KernelGraphAdminDigest adminDigest;
}

class KernelGraphRunner {
  static const String _logName = 'KernelGraphRunner';

  KernelGraphRunner({
    required KernelGraphPrimitiveRegistry primitiveRegistry,
    KernelGraphCompiler? compiler,
    KernelGraphAdminDigestProjector? adminDigestProjector,
    KernelGraphRunLedger? runLedger,
  })  : _primitiveRegistry = primitiveRegistry,
        _compiler = compiler ?? const KernelGraphCompiler(),
        _adminDigestProjector =
            adminDigestProjector ?? const KernelGraphAdminDigestProjector(),
        _runLedger = runLedger;

  final KernelGraphPrimitiveRegistry _primitiveRegistry;
  final KernelGraphCompiler _compiler;
  final KernelGraphAdminDigestProjector _adminDigestProjector;
  final KernelGraphRunLedger? _runLedger;

  Future<KernelGraphRunResult> executeSpec(
    KernelGraphSpec spec, {
    String? runId,
    KernelGraphRollbackDescriptor? rollbackDescriptor,
    Map<String, dynamic> initialState = const <String, dynamic>{},
    Map<String, dynamic> runMetadata = const <String, dynamic>{},
  }) async {
    final compilation = _compiler.compile(
      spec: spec,
      registry: _primitiveRegistry,
    );
    if (!compilation.isValid || compilation.compiledPlan == null) {
      throw StateError(
        'KernelGraph compilation failed for `${spec.id}`: '
        '${compilation.diagnostics.map((entry) => entry.code).join(', ')}',
      );
    }

    final plan = compilation.compiledPlan!;
    final effectiveRunId =
        runId ?? '${spec.id}:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final context = KernelGraphExecutionContext(
      runId: effectiveRunId,
      specId: spec.id,
      initialState: initialState,
    );
    final startedAt = DateTime.now().toUtc();
    final nodeReceipts = <KernelGraphNodeReceipt>[];
    var runStatus = KernelGraphRunStatus.running;
    Object? failure;
    StackTrace? failureStackTrace;

    for (final step in plan.steps) {
      try {
        final handler = _primitiveRegistry.lookup(step.primitiveId);
        if (handler == null) {
          throw StateError(
            'KernelGraph primitive `${step.primitiveId}` was not registered at execution time.',
          );
        }
        final nodeStartedAt = DateTime.now().toUtc();
        final result = await handler.execute(context, step);
        final nodeCompletedAt = DateTime.now().toUtc();
        nodeReceipts.add(
          KernelGraphNodeReceipt(
            nodeId: step.nodeId,
            primitiveId: step.primitiveId,
            status: KernelGraphNodeStatus.completed,
            startedAt: nodeStartedAt,
            completedAt: nodeCompletedAt,
            summary: result.summary,
            outputRefs: result.outputRefs,
            metadata: result.metadata,
          ),
        );
      } catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
        final failedAt = DateTime.now().toUtc();
        nodeReceipts.add(
          KernelGraphNodeReceipt(
            nodeId: step.nodeId,
            primitiveId: step.primitiveId,
            status: KernelGraphNodeStatus.failed,
            startedAt: failedAt,
            completedAt: failedAt,
            summary: error.toString(),
            metadata: const <String, dynamic>{'error': true},
          ),
        );
        runStatus = KernelGraphRunStatus.failed;
        break;
      }
    }

    if (failure == null) {
      runStatus = KernelGraphRunStatus.completed;
    }

    final completedAt = DateTime.now().toUtc();
    final receipt = KernelGraphExecutionReceipt(
      runId: effectiveRunId,
      specId: plan.specId,
      title: plan.title,
      kind: plan.kind,
      status: runStatus,
      startedAt: startedAt,
      completedAt: completedAt,
      nodeReceipts: nodeReceipts,
      rollbackDescriptor: rollbackDescriptor,
      metadata: <String, dynamic>{
        'environment': plan.executionPolicy.environment.name,
        'simulationFirst': plan.executionPolicy.simulationFirst,
      },
    );
    final result = KernelGraphRunResult(
      compilation: compilation,
      receipt: receipt,
      adminDigest: _adminDigestProjector.project(
        plan: plan,
        receipt: receipt,
      ),
    );
    final runLedger = _runLedger;
    if (runLedger != null) {
      try {
        await runLedger.recordRun(
          KernelGraphRunRecord(
            runId: result.receipt.runId,
            specId: plan.specId,
            graphTitle: plan.title,
            kind: plan.kind,
            status: result.receipt.status,
            startedAt: result.receipt.startedAt,
            completedAt: result.receipt.completedAt,
            ownerUserId: runMetadata['ownerUserId']?.toString(),
            sourceId: runMetadata['sourceId']?.toString(),
            reviewItemId: runMetadata['reviewItemId']?.toString(),
            jobId: runMetadata['jobId']?.toString(),
            sourceKind: runMetadata['sourceKind']?.toString(),
            spec: spec,
            compiledPlan: plan,
            adminDigest: result.adminDigest,
            receipt: result.receipt,
            metadata: Map<String, dynamic>.from(runMetadata),
          ),
        );
      } catch (error, stackTrace) {
        developer.log(
          'Failed to persist KernelGraph run `${result.receipt.runId}`: $error',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (failure != null && failureStackTrace != null) {
      Error.throwWithStackTrace(failure, failureStackTrace);
    }
    return result;
  }
}
