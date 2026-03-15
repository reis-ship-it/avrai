import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';

class Ai2AiBackgroundExecutionResult {
  const Ai2AiBackgroundExecutionResult({
    required this.releasedCount,
    required this.blockedCount,
    required this.trustedRouteUnavailableBlockCount,
  });

  final int releasedCount;
  final int blockedCount;
  final int trustedRouteUnavailableBlockCount;
}

class Ai2AiBackgroundExecutionLane {
  Ai2AiBackgroundExecutionLane({
    required Ai2AiRendezvousScheduler scheduler,
  }) : _scheduler = scheduler;

  final Ai2AiRendezvousScheduler _scheduler;

  Future<void> start() async {
    await _scheduler.start();
  }

  Future<Ai2AiBackgroundExecutionResult> handleWake({
    required BackgroundWakeReason reason,
    required BackgroundCapabilitySnapshot capabilities,
  }) async {
    final releasedBefore = _scheduler.releasedTicketCount;
    final blockedBefore = _scheduler.blockedByConditionCount;
    final trustedRouteBefore = _scheduler.trustedRouteUnavailableBlockCount;
    await _scheduler.updateRuntimeState(
      isWifiAvailable: capabilities.isWifiAvailable,
      isIdle: capabilities.isIdle,
    );
    return Ai2AiBackgroundExecutionResult(
      releasedCount: _scheduler.releasedTicketCount - releasedBefore,
      blockedCount: _scheduler.blockedByConditionCount - blockedBefore,
      trustedRouteUnavailableBlockCount:
          _scheduler.trustedRouteUnavailableBlockCount - trustedRouteBefore,
    );
  }
}
