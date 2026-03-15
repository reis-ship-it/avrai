import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';

class Ai2AiExchangeSubmissionRequest {
  const Ai2AiExchangeSubmissionRequest({
    required this.exchangeId,
    required this.conversationId,
    required this.peerId,
    required this.artifactClass,
    required this.payload,
    this.envelope,
    this.governanceBundle,
    this.routeReceipt,
    this.decision = Ai2AiExchangeDecision.exchangeNow,
    this.rendezvousPolicy,
    this.requiresApplyReceipt = false,
    this.legacyMessageTypeName,
    this.context = const <String, dynamic>{},
  });

  final String exchangeId;
  final String conversationId;
  final String peerId;
  final Ai2AiExchangeArtifactClass artifactClass;
  final Map<String, dynamic> payload;
  final KernelEventEnvelope? envelope;
  final KernelContextBundle? governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final Ai2AiExchangeDecision decision;
  final Ai2AiRendezvousPolicy? rendezvousPolicy;
  final bool requiresApplyReceipt;
  final String? legacyMessageTypeName;
  final Map<String, dynamic> context;

  Ai2AiExchangeCandidate toCandidate({
    required DateTime nowUtc,
  }) {
    return Ai2AiExchangeCandidate(
      exchangeId: exchangeId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: artifactClass,
      envelope: envelope ??
          KernelEventEnvelope(
            eventId: exchangeId,
            occurredAtUtc: nowUtc,
            sourceSystem: 'ai2ai_exchange_submission_lane',
            eventType: 'ai2ai_exchange_submission',
            entityId: peerId,
            entityType: 'agent',
            context: <String, dynamic>{
              'artifact_class': artifactClass.name,
              ...context,
            },
          ),
      governanceBundle: governanceBundle ??
          const KernelContextBundle(
            who: null,
            what: null,
            when: null,
            where: null,
            how: null,
            vibe: null,
            vibeStack: null,
            why: null,
          ),
      routeReceipt: routeReceipt,
      decision: decision,
      rendezvousPolicy: rendezvousPolicy,
      requiresApplyReceipt: requiresApplyReceipt,
      context: <String, dynamic>{
        ...context,
        'submission_payload': payload,
        if (legacyMessageTypeName != null)
          'legacy_message_type': legacyMessageTypeName,
      },
    );
  }
}

class Ai2AiExchangeSubmissionResult {
  const Ai2AiExchangeSubmissionResult({
    required this.plan,
    this.commitReceipt,
    this.observationReceipt,
    this.deferred = false,
    this.dispatched = false,
    this.error,
  });

  final Ai2AiExchangePlan plan;
  final Ai2AiExchangeReceipt? commitReceipt;
  final Ai2AiExchangeReceipt? observationReceipt;
  final bool deferred;
  final bool dispatched;
  final String? error;
}

/// Kernel-owned submission seam for AI/system artifact exchange.
///
/// The legacy private-messaging protocol remains an internal adapter only
/// during migration. Callers of this lane do not depend on it directly.
class Ai2AiExchangeSubmissionLane {
  Ai2AiExchangeSubmissionLane({
    required Ai2AiKernelContract ai2aiKernel,
    LegacyAi2AiExchangeTransportAdapter? transportAdapter,
    DateTime Function()? nowUtc,
  })  : _ai2aiKernel = ai2aiKernel,
        _transportAdapter = transportAdapter,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final Ai2AiKernelContract _ai2aiKernel;
  final LegacyAi2AiExchangeTransportAdapter? _transportAdapter;
  final DateTime Function() _nowUtc;

  Future<Ai2AiExchangeSubmissionResult> submit(
    Ai2AiExchangeSubmissionRequest request,
  ) async {
    return submitCandidate(
      request.toCandidate(nowUtc: _nowUtc()),
    );
  }

  Future<Ai2AiExchangeSubmissionResult> submitCandidate(
    Ai2AiExchangeCandidate candidate,
  ) async {
    final plan = await _ai2aiKernel.planExchange(candidate);
    if (!plan.allowed) {
      return Ai2AiExchangeSubmissionResult(
        plan: plan,
        deferred: plan.lifecycleState == Ai2AiExchangeLifecycleState.deferred,
      );
    }

    if (plan.rendezvousTicket != null ||
        plan.decision != Ai2AiExchangeDecision.exchangeNow) {
      return Ai2AiExchangeSubmissionResult(
        plan: plan,
        deferred: true,
      );
    }

    final commitReceipt = await _ai2aiKernel.commitExchange(
      Ai2AiExchangeCommit(
        attemptId: 'exchange-commit-${candidate.exchangeId}',
        plan: plan,
        envelope: candidate.envelope,
        commitContext: <String, dynamic>{
          'submission_lane': true,
        },
      ),
    );

    final payload = Map<String, dynamic>.from(
      candidate.context['submission_payload'] as Map? ??
          const <String, dynamic>{},
    );
    payload.putIfAbsent('ai2ai_exchange_id', () => candidate.exchangeId);
    payload.putIfAbsent(
      'ai2ai_artifact_class',
      () => candidate.artifactClass.name,
    );
    payload.putIfAbsent(
      'ai2ai_requires_apply_receipt',
      () => candidate.requiresApplyReceipt,
    );
    final transportAdapter = _transportAdapter;
    if (transportAdapter == null) {
      return Ai2AiExchangeSubmissionResult(
        plan: plan,
        commitReceipt: commitReceipt,
        dispatched: false,
        error: 'legacy_transport_adapter_unavailable',
      );
    }

    try {
      await transportAdapter.dispatchExchange(
        peerId: candidate.peerId,
        artifactClass: candidate.artifactClass,
        payload: payload,
        legacyMessageTypeName:
            candidate.context['legacy_message_type']?.toString(),
      );
      return Ai2AiExchangeSubmissionResult(
        plan: plan,
        commitReceipt: commitReceipt,
        dispatched: true,
      );
    } catch (error) {
      final observationReceipt = await _ai2aiKernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: 'exchange-observation-${candidate.exchangeId}',
          exchangeId: candidate.exchangeId,
          conversationId: candidate.conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.failed,
          observedAtUtc: _nowUtc(),
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: plan.routeReceipt,
          outcomeContext: <String, dynamic>{
            'submission_lane': true,
            'dispatch_error': error.toString(),
          },
        ),
      );
      return Ai2AiExchangeSubmissionResult(
        plan: plan,
        commitReceipt: commitReceipt,
        observationReceipt: observationReceipt,
        dispatched: false,
        error: error.toString(),
      );
    }
  }
}
