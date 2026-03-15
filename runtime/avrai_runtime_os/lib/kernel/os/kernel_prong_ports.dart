import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';

abstract class ModelTruthPort {
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
}

abstract class RuntimeExecutionPort {
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  });
}

abstract class TrustGovernancePort {
  Future<KernelGovernanceReport> inspectTrustGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
}

class FunctionalKernelProngPorts
    implements ModelTruthPort, RuntimeExecutionPort, TrustGovernancePort {
  FunctionalKernelProngPorts({
    required this.kernelOs,
    required this.whoKernel,
    required this.whatKernel,
    required this.whenKernel,
    required this.whereKernel,
    required this.howKernel,
    required this.whyKernel,
  });

  final FunctionalKernelOs kernelOs;
  final WhoKernelContract whoKernel;
  final WhatKernelContract whatKernel;
  final WhenKernelContract whenKernel;
  final WhereKernelContract whereKernel;
  final HowKernelContract howKernel;
  final WhyKernelContract whyKernel;

  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    return kernelOs.buildRealityKernelFusionInput(
      envelope: envelope,
      whyRequest: whyRequest,
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) {
    return kernelOs.resolveKernelContext(envelope);
  }

  @override
  Future<KernelGovernanceReport> inspectTrustGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    final bundle = await kernelOs.resolveKernelContext(envelope);
    final why = kernelOs.explainWhy(
      KernelWhyRequest(
        bundle: bundle.withoutWhy(),
        goal: whyRequest.goal,
        predictedOutcome: whyRequest.predictedOutcome,
        predictedConfidence: whyRequest.predictedConfidence,
        actualOutcome: whyRequest.actualOutcome,
        actualOutcomeScore: whyRequest.actualOutcomeScore,
        coreSignals: whyRequest.coreSignals,
        pheromoneSignals: whyRequest.pheromoneSignals,
        policySignals: whyRequest.policySignals,
        memoryContext: whyRequest.memoryContext,
        severity: whyRequest.severity,
      ),
    );
    final enrichedBundle = KernelContextBundle(
      who: bundle.who,
      what: bundle.what,
      when: bundle.when,
      where: bundle.where,
      how: bundle.how,
      vibe: bundle.vibe,
      vibeStack: bundle.vibeStack,
      why: why,
    );
    final whatProjection = await whatKernel.projectForGovernance(
      WhatProjectionRequest(
        agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
        entityRef: bundle.what?.targetEntityId ??
            envelope.entityId ??
            envelope.eventId,
      ),
    );
    final whereState = await whereKernel.resolveWhere(
      WhereKernelInput(
        agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
        latitude: (envelope.context['latitude'] as num?)?.toDouble(),
        longitude: (envelope.context['longitude'] as num?)?.toDouble(),
        occurredAtUtc: envelope.occurredAtUtc,
        topAlias: envelope.context['location_label'] as String?,
      ),
    );
    final whereProjection = await whereKernel.projectForGovernance(
      WhereProjectionRequest(
        audience: WhereProjectionAudience.admin,
        state: whereState,
      ),
    );
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: enrichedBundle,
      projections: <KernelGovernanceProjection>[
        await whoKernel.projectForGovernance(
          KernelProjectionRequest(
            subjectId: enrichedBundle.who?.primaryActor,
            envelope: envelope,
            bundle: enrichedBundle.withoutWhy(),
            who: enrichedBundle.who,
          ),
        ),
        whatProjection,
        await whenKernel.projectForGovernance(
          KernelProjectionRequest(
            subjectId: envelope.eventId,
            envelope: envelope,
            bundle: enrichedBundle.withoutWhy(),
            when: enrichedBundle.when,
          ),
        ),
        whereProjection,
        await howKernel.projectForGovernance(
          KernelProjectionRequest(
            subjectId: envelope.eventId,
            envelope: envelope,
            bundle: enrichedBundle.withoutWhy(),
            how: enrichedBundle.how,
          ),
        ),
        await whyKernel.projectForGovernance(
          KernelProjectionRequest(
            subjectId: why.goal,
            envelope: envelope,
            bundle: enrichedBundle.withoutWhy(),
            why: why,
          ),
        ),
        if (enrichedBundle.vibe != null)
          KernelGovernanceProjection(
            domain: KernelDomain.vibe,
            summary:
                'Governance vibe view for ${enrichedBundle.vibe!.subjectId}',
            confidence: enrichedBundle.vibe!.confidence,
            highlights: <String>[
              enrichedBundle.vibe!.expressionContext.toneProfile,
              if (enrichedBundle.vibe!.provenanceTags.isNotEmpty)
                enrichedBundle.vibe!.provenanceTags.first,
            ],
            payload: enrichedBundle.vibe!.toJson(),
          ),
      ],
      generatedAtUtc: why.createdAtUtc,
    );
  }
}
