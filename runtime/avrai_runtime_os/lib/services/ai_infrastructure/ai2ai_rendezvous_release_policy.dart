import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';

class Ai2AiRendezvousRuntimeState {
  const Ai2AiRendezvousRuntimeState({
    required this.isWifiAvailable,
    required this.isIdle,
    required this.observedAtUtc,
  });

  final bool isWifiAvailable;
  final bool isIdle;
  final DateTime observedAtUtc;
}

class Ai2AiRendezvousReleaseDecision {
  const Ai2AiRendezvousReleaseDecision({
    required this.releasable,
    required this.missingConditions,
    required this.reason,
  });

  final bool releasable;
  final Set<Ai2AiRendezvousCondition> missingConditions;
  final String reason;
}

class Ai2AiRendezvousReleasePolicy {
  const Ai2AiRendezvousReleasePolicy({
    this.nowUtc,
  });

  final DateTime Function()? nowUtc;

  Ai2AiRendezvousReleaseDecision evaluate({
    required Ai2AiRendezvousTicket ticket,
    required Ai2AiRendezvousRuntimeState runtimeState,
  }) {
    final effectiveNow = nowUtc?.call() ?? runtimeState.observedAtUtc.toUtc();
    if (ticket.policy.expiresAtUtc.isBefore(effectiveNow)) {
      return const Ai2AiRendezvousReleaseDecision(
        releasable: false,
        missingConditions: <Ai2AiRendezvousCondition>{},
        reason: 'expired',
      );
    }

    final missingConditions = <Ai2AiRendezvousCondition>{};
    for (final condition in ticket.policy.requiredConditions) {
      switch (condition) {
        case Ai2AiRendezvousCondition.idle:
          if (!runtimeState.isIdle) {
            missingConditions.add(condition);
          }
        case Ai2AiRendezvousCondition.wifi:
          if (!runtimeState.isWifiAvailable) {
            missingConditions.add(condition);
          }
        case Ai2AiRendezvousCondition.unmetered:
        case Ai2AiRendezvousCondition.charging:
        case Ai2AiRendezvousCondition.trustedNetwork:
          missingConditions.add(condition);
      }
    }

    if (missingConditions.isNotEmpty) {
      return Ai2AiRendezvousReleaseDecision(
        releasable: false,
        missingConditions: missingConditions,
        reason: 'conditions_pending',
      );
    }

    return const Ai2AiRendezvousReleaseDecision(
      releasable: true,
      missingConditions: <Ai2AiRendezvousCondition>{},
      reason: 'ready',
    );
  }
}
