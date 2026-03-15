import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';

class Ai2AiMeshGovernanceBindingService {
  const Ai2AiMeshGovernanceBindingService({
    required FunctionalKernelOs kernelOs,
  }) : _kernelOs = kernelOs;

  final FunctionalKernelOs _kernelOs;

  Future<KernelBundleRecord> buildMeshGovernanceRecord({
    required KernelEventEnvelope envelope,
    String goal = 'govern_mesh_delivery',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) {
    return _buildGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
  }

  Future<KernelBundleRecord> buildAi2AiGovernanceRecord({
    required KernelEventEnvelope envelope,
    String goal = 'govern_ai2ai_delivery',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) {
    return _buildGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
  }

  Future<MeshRoutePlanningRequest> buildMeshPlanningRequest({
    required String planningId,
    required String destinationId,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    bool storeCarryForwardAllowed = true,
    Map<String, dynamic> runtimeContext = const <String, dynamic>{},
    Map<String, dynamic> policyContext = const <String, dynamic>{},
    MonteCarloRunContext? runContext,
    String goal = 'govern_mesh_delivery',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final record = await buildMeshGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return MeshRoutePlanningRequest(
      planningId: planningId,
      destinationId: destinationId,
      envelope: envelope,
      governanceBundle: record.bundle,
      routeReceipt: routeReceipt,
      storeCarryForwardAllowed: storeCarryForwardAllowed,
      runtimeContext: <String, dynamic>{
        ...runtimeContext,
        ..._governanceTrace(record),
      },
      policyContext: <String, dynamic>{
        ...policyContext,
        'governance_goal': record.bundle.why?.goal,
        'governance_summary': record.bundle.why?.summary,
      },
      runContext: runContext,
    );
  }

  Future<MeshObservation> buildMeshObservation({
    required String observationId,
    required String subjectId,
    required MeshLifecycleState lifecycleState,
    required DateTime observedAtUtc,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    Map<String, dynamic> outcomeContext = const <String, dynamic>{},
    String goal = 'observe_mesh_outcome',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final record = await buildMeshGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome ?? lifecycleState.name,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return MeshObservation(
      observationId: observationId,
      subjectId: subjectId,
      lifecycleState: lifecycleState,
      observedAtUtc: observedAtUtc,
      envelope: envelope,
      governanceBundle: record.bundle,
      routeReceipt: routeReceipt,
      outcomeContext: <String, dynamic>{
        ...outcomeContext,
        ..._governanceTrace(record),
      },
    );
  }

  Future<Ai2AiExchangeCandidate> buildAi2AiExchangeCandidate({
    required String messageId,
    required String conversationId,
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    bool requiresApplyReceipt = false,
    Ai2AiExchangeDecision decision = Ai2AiExchangeDecision.exchangeNow,
    Ai2AiRendezvousPolicy? rendezvousPolicy,
    Map<String, dynamic> context = const <String, dynamic>{},
    String goal = 'govern_ai2ai_delivery',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final record = await buildAi2AiGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return Ai2AiExchangeCandidate(
      exchangeId: messageId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: artifactClass,
      envelope: envelope,
      governanceBundle: record.bundle,
      routeReceipt: routeReceipt,
      decision: decision,
      rendezvousPolicy: rendezvousPolicy,
      requiresApplyReceipt: requiresApplyReceipt,
      context: <String, dynamic>{
        ...context,
        ..._governanceTrace(record),
      },
    );
  }

  @Deprecated('Use buildAi2AiExchangeCandidate()')
  Future<Ai2AiMessageCandidate> buildAi2AiMessageCandidate({
    required String messageId,
    required String conversationId,
    required String peerId,
    required Ai2AiPayloadClass payloadClass,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    bool requiresLearningReceipt = false,
    Map<String, dynamic> context = const <String, dynamic>{},
    String goal = 'govern_ai2ai_delivery',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final candidate = await buildAi2AiExchangeCandidate(
      messageId: messageId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: payloadClass.toExchangeArtifactClass(),
      envelope: envelope,
      routeReceipt: routeReceipt,
      requiresApplyReceipt: requiresLearningReceipt,
      context: context,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return candidate.toLegacyCandidate();
  }

  Future<Ai2AiExchangeObservation> buildAi2AiExchangeObservation({
    required String observationId,
    required String messageId,
    required String conversationId,
    required Ai2AiExchangeLifecycleState lifecycleState,
    required DateTime observedAtUtc,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    Map<String, dynamic> outcomeContext = const <String, dynamic>{},
    String goal = 'observe_ai2ai_outcome',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final record = await buildAi2AiGovernanceRecord(
      envelope: envelope,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome ?? lifecycleState.name,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return Ai2AiExchangeObservation(
      observationId: observationId,
      exchangeId: messageId,
      conversationId: conversationId,
      lifecycleState: lifecycleState,
      observedAtUtc: observedAtUtc,
      envelope: envelope,
      governanceBundle: record.bundle,
      routeReceipt: routeReceipt,
      outcomeContext: <String, dynamic>{
        ...outcomeContext,
        ..._governanceTrace(record),
      },
    );
  }

  @Deprecated('Use buildAi2AiExchangeObservation()')
  Future<Ai2AiObservation> buildAi2AiObservation({
    required String observationId,
    required String messageId,
    required String conversationId,
    required Ai2AiLifecycleState lifecycleState,
    required DateTime observedAtUtc,
    required KernelEventEnvelope envelope,
    TransportRouteReceipt? routeReceipt,
    Map<String, dynamic> outcomeContext = const <String, dynamic>{},
    String goal = 'observe_ai2ai_outcome',
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) async {
    final observation = await buildAi2AiExchangeObservation(
      observationId: observationId,
      messageId: messageId,
      conversationId: conversationId,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      observedAtUtc: observedAtUtc,
      envelope: envelope,
      routeReceipt: routeReceipt,
      outcomeContext: outcomeContext,
      goal: goal,
      predictedOutcome: predictedOutcome,
      predictedConfidence: predictedConfidence,
      actualOutcome: actualOutcome,
      actualOutcomeScore: actualOutcomeScore,
      coreSignals: coreSignals,
      pheromoneSignals: pheromoneSignals,
      policySignals: policySignals,
      memoryContext: memoryContext,
      severity: severity,
    );
    return observation.toLegacyObservation();
  }

  Future<KernelBundleRecord> _buildGovernanceRecord({
    required KernelEventEnvelope envelope,
    required String goal,
    String? predictedOutcome,
    double? predictedConfidence,
    String? actualOutcome,
    double? actualOutcomeScore,
    List<WhySignal> coreSignals = const <WhySignal>[],
    List<WhySignal> pheromoneSignals = const <WhySignal>[],
    List<WhySignal> policySignals = const <WhySignal>[],
    Map<String, dynamic> memoryContext = const <String, dynamic>{},
    String? severity,
  }) {
    return _kernelOs.resolveAndExplain(
      envelope: envelope,
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: goal,
        predictedOutcome: predictedOutcome,
        predictedConfidence: predictedConfidence,
        actualOutcome: actualOutcome,
        actualOutcomeScore: actualOutcomeScore,
        coreSignals: coreSignals,
        pheromoneSignals: pheromoneSignals,
        policySignals: policySignals,
        memoryContext: memoryContext,
        severity: severity,
      ),
    );
  }

  Map<String, dynamic> _governanceTrace(KernelBundleRecord record) {
    return <String, dynamic>{
      'governance_record_id': record.recordId,
      'governance_event_id': record.eventId,
      'governance_created_at_utc':
          record.createdAtUtc.toUtc().toIso8601String(),
      'governance_goal': record.bundle.why?.goal,
      'governance_confidence': record.bundle.why?.confidence,
    };
  }
}
