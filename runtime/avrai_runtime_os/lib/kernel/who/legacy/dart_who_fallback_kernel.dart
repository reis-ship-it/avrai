import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';

class DartWhoFallbackKernel extends WhoKernelFallbackSurface {
  const DartWhoFallbackKernel();

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async {
    final companions = ((envelope.context['companion_actor_ids'] as List?) ??
            const <dynamic>[])
        .map((entry) => entry.toString())
        .toList();
    return WhoKernelSnapshot(
      primaryActor: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
      affectedActor: envelope.context['affected_actor'] as String? ??
          envelope.agentId ??
          envelope.userId ??
          'unknown_actor',
      companionActors: companions,
      actorRoles: ((envelope.context['actor_roles'] as List?) ??
              const <dynamic>['requester'])
          .map((entry) => entry.toString())
          .toList(),
      trustScope: envelope.policyContext['trust_scope'] as String? ?? 'private',
      cohortRefs:
          ((envelope.context['cohort_refs'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      identityConfidence:
          (envelope.agentId != null || envelope.userId != null) ? 0.91 : 0.25,
    );
  }
}
