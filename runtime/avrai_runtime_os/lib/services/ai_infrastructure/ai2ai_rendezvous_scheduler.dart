import 'dart:async';

import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Ai2AiRendezvousScheduler {
  Ai2AiRendezvousScheduler({
    required Ai2AiRendezvousStore store,
    required Ai2AiExchangeSubmissionLane submissionLane,
    required Ai2AiRendezvousReleasePolicy releasePolicy,
    Future<bool> Function(String peerId)? hasTrustedRoute,
    Connectivity? connectivity,
    DateTime Function()? nowUtc,
  })  : _store = store,
        _submissionLane = submissionLane,
        _releasePolicy = releasePolicy,
        _hasTrustedRoute = hasTrustedRoute,
        _connectivity = connectivity,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final Ai2AiRendezvousStore _store;
  final Ai2AiExchangeSubmissionLane _submissionLane;
  final Ai2AiRendezvousReleasePolicy _releasePolicy;
  final Future<bool> Function(String peerId)? _hasTrustedRoute;
  final Connectivity? _connectivity;
  final DateTime Function() _nowUtc;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wifiAvailable = false;
  bool _idle = false;
  int _releasedTicketCount = 0;
  int _blockedByConditionCount = 0;
  int _trustedRouteUnavailableBlockCount = 0;
  String? _lastReleaseReason;
  String? _lastBlockedReason;

  int get activeRendezvousCount => _store.activeCount();
  int get releasedTicketCount => _releasedTicketCount;
  int get blockedByConditionCount => _blockedByConditionCount;
  int get trustedRouteUnavailableBlockCount =>
      _trustedRouteUnavailableBlockCount;
  String? get lastReleaseReason => _lastReleaseReason;
  String? get lastBlockedReason => _lastBlockedReason;

  Future<void> start() async {
    final connectivity = _connectivity;
    if (connectivity == null || _connectivitySubscription != null) {
      return;
    }
    final initial = await connectivity.checkConnectivity();
    _wifiAvailable = initial.contains(ConnectivityResult.wifi);
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((results) {
      unawaited(
        updateRuntimeState(
          isWifiAvailable: results.contains(ConnectivityResult.wifi),
        ),
      );
    });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> setIdleState(bool isIdle) async {
    await updateRuntimeState(isIdle: isIdle);
  }

  Future<void> updateRuntimeState({
    bool? isWifiAvailable,
    bool? isIdle,
  }) async {
    if (isWifiAvailable != null) {
      _wifiAvailable = isWifiAvailable;
    }
    if (isIdle != null) {
      _idle = isIdle;
    }
    await releaseEligibleTickets();
  }

  Future<int> releaseEligibleTickets() async {
    final runtimeState = Ai2AiRendezvousRuntimeState(
      isWifiAvailable: _wifiAvailable,
      isIdle: _idle,
      observedAtUtc: _nowUtc(),
    );
    var releasedCount = 0;
    var blockedCount = 0;
    for (final entry in _store.allEntries()) {
      final decision = _releasePolicy.evaluate(
        ticket: entry.ticket,
        runtimeState: runtimeState,
      );
      if (!decision.releasable) {
        blockedCount += 1;
        _lastBlockedReason = decision.reason;
        if (decision.reason == 'expired') {
          await _store.removeTicket(entry.ticket.ticketId);
        }
        continue;
      }
      final hasTrustedRoute = _hasTrustedRoute;
      if (hasTrustedRoute != null &&
          !(await hasTrustedRoute(entry.candidate.peerId))) {
        blockedCount += 1;
        _trustedRouteUnavailableBlockCount += 1;
        _lastBlockedReason = 'trusted_route_unavailable';
        continue;
      }

      final releaseCandidate = Ai2AiExchangeCandidate(
        exchangeId: entry.candidate.exchangeId,
        conversationId: entry.candidate.conversationId,
        peerId: entry.candidate.peerId,
        artifactClass: entry.candidate.artifactClass,
        envelope: entry.candidate.envelope,
        governanceBundle: entry.candidate.governanceBundle,
        routeReceipt: entry.candidate.routeReceipt,
        decision: Ai2AiExchangeDecision.exchangeNow,
        requiresApplyReceipt: entry.candidate.requiresApplyReceipt,
        context: <String, dynamic>{
          ...entry.candidate.context,
          'rendezvous_release': true,
          'rendezvous_ticket_id': entry.ticket.ticketId,
          'rendezvous_reprobe_required':
              entry.ticket.policy.requiresReprobeBeforeRelease,
        },
      );
      final result = await _submissionLane.submitCandidate(releaseCandidate);
      if (result.deferred) {
        blockedCount += 1;
        _lastBlockedReason = result.error ?? 'exchange_deferred';
        continue;
      }
      await _store.removeTicket(entry.ticket.ticketId);
      releasedCount += 1;
      _lastReleaseReason = _releaseReasonFor(entry.ticket.policy);
    }
    _releasedTicketCount += releasedCount;
    _blockedByConditionCount += blockedCount;
    return releasedCount;
  }

  String _releaseReasonFor(Ai2AiRendezvousPolicy policy) {
    final conditions = policy.requiredConditions;
    if (conditions.contains(Ai2AiRendezvousCondition.wifi) &&
        conditions.contains(Ai2AiRendezvousCondition.idle)) {
      return 'wifi_or_idle';
    }
    if (conditions.contains(Ai2AiRendezvousCondition.wifi)) {
      return 'wifi';
    }
    if (conditions.contains(Ai2AiRendezvousCondition.idle)) {
      return 'idle';
    }
    return 'immediate';
  }
}
