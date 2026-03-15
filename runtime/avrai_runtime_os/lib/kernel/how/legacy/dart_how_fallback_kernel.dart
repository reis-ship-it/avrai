import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

class DartHowFallbackKernel extends HowKernelFallbackSurface {
  const DartHowFallbackKernel();

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async {
    return HowKernelSnapshot(
      executionPath: envelope.runtimeContext['execution_path'] as String? ??
          'native_orchestrated',
      workflowStage:
          envelope.runtimeContext['workflow_stage'] as String? ?? 'inference',
      transportMode:
          envelope.runtimeContext['transport_mode'] as String? ?? 'in_process',
      plannerMode:
          envelope.predictionContext['planner_mode'] as String? ?? 'heuristic',
      modelFamily:
          envelope.predictionContext['model_family'] as String? ?? 'baseline',
      interventionChain:
          ((envelope.runtimeContext['intervention_chain'] as List?) ??
                  const <dynamic>[
                    'rank',
                    'filter',
                    'return',
                  ])
              .map((entry) => entry.toString())
              .toList(),
      failureMechanism:
          envelope.runtimeContext['failure_mechanism'] as String? ?? 'none',
      mechanismConfidence:
          envelope.runtimeContext['failure_mechanism'] == null ? 0.84 : 0.63,
    );
  }
}
