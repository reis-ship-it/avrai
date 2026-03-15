import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:uuid/uuid.dart';

class BhamRoutePlanner {
  BhamRoutePlanner({
    BhamRouteLearningService? routeLearningService,
  }) : _routeLearningService =
            routeLearningService ?? BhamRouteLearningService();

  final BhamRouteLearningService _routeLearningService;

  Future<TransportRoutePlan> planRoutes({
    required String messageId,
    required ChatThreadKind threadKind,
    required DateTime expiresAtUtc,
    required Map<TransportMode, bool> availability,
    String? locality,
    bool exploratory = true,
  }) async {
    final now = DateTime.now().toUtc();
    final expiryRemainingMs =
        expiresAtUtc.difference(now).inMilliseconds.clamp(1, 1 << 31);
    final candidates = <TransportRouteCandidate>[];

    for (final entry in availability.entries) {
      if (!entry.value) {
        continue;
      }
      final learningBoost =
          await _routeLearningService.learningBoostForMode(entry.key);
      final estimatedLatencyMs = _latencyForMode(entry.key);
      final expiryFit =
          (expiryRemainingMs / (estimatedLatencyMs + 1)).clamp(0.0, 8.0) / 8.0;
      final localityFit = _localityFitForMode(entry.key, locality);
      final availabilityScore = 1.0;
      final confidence = ((0.45 * _baseConfidence(entry.key)) +
              (0.25 * learningBoost) +
              (0.15 * expiryFit) +
              (0.15 * localityFit))
          .clamp(0.0, 1.0);
      candidates.add(
        TransportRouteCandidate(
          routeId: '${messageId}_${entry.key.name}',
          mode: entry.key,
          confidence: confidence,
          estimatedLatencyMs: estimatedLatencyMs,
          expiryFit: expiryFit,
          localityFit: localityFit,
          availabilityScore: availabilityScore,
          rationale:
              'planned for ${threadKind.name} with ${entry.key.name} availability',
          metadata: <String, dynamic>{
            if (locality != null) 'locality': locality,
            'learning_boost': learningBoost,
          },
        ),
      );
    }

    candidates.sort((a, b) {
      final confidenceOrder = b.confidence.compareTo(a.confidence);
      if (confidenceOrder != 0) {
        return confidenceOrder;
      }
      return a.estimatedLatencyMs.compareTo(b.estimatedLatencyMs);
    });

    return TransportRoutePlan(
      planId: const Uuid().v4(),
      createdAtUtc: now,
      candidateRoutes: candidates,
      exploratory: exploratory,
      metadata: <String, dynamic>{
        'message_id': messageId,
        'thread_kind': threadKind.name,
      },
    );
  }

  TransportRouteReceipt buildQueuedReceipt({
    required TransportRoutePlan routePlan,
    required String channel,
    required DateTime expiresAtUtc,
    int? hopCount,
    String? fallbackReason,
  }) {
    return TransportRouteReceiptCompatibilityTranslator
        .buildQueuedFromRoutePlan(
      routePlan: routePlan,
      channel: channel,
      expiresAtUtc: expiresAtUtc,
      hopCount: hopCount,
      fallbackReason: fallbackReason,
    );
  }

  TransportRouteReceipt markReleased({
    required TransportRouteReceipt receipt,
    required List<TransportRouteCandidate> attemptedRoutes,
  }) {
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'released',
      recordedAtUtc: now,
      attemptedRoutes: attemptedRoutes,
      releasedAtUtc: now,
    );
  }

  TransportRouteReceipt markCustodyAccepted({
    required TransportRouteReceipt receipt,
    TransportRouteCandidate? winningRoute,
    String? winningRouteReason,
    String? custodyAcceptedBy,
  }) {
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'custody_accepted',
      recordedAtUtc: now,
      winningRoute: winningRoute,
      winningRouteReason: winningRouteReason,
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      custodyAcceptedBy: custodyAcceptedBy,
    );
  }

  TransportRouteReceipt markDelivered({
    required TransportRouteReceipt receipt,
    required TransportRouteCandidate winningRoute,
    String? winningRouteReason,
  }) {
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'delivered',
      recordedAtUtc: now,
      attemptedRoutes: receipt.attemptedRoutes.isEmpty
          ? receipt.plannedRoutes
          : receipt.attemptedRoutes,
      winningRoute: winningRoute,
      winningRouteReason: winningRouteReason,
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      custodyAcceptedBy: receipt.custodyAcceptedBy ??
          winningRoute.metadata['peer_id']?.toString(),
      deliveredAtUtc: now,
    );
  }

  TransportRouteReceipt markRead({
    required TransportRouteReceipt receipt,
    String? readBy,
  }) {
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'read',
      recordedAtUtc: now,
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      deliveredAtUtc: receipt.deliveredAtUtc ?? now,
      readAtUtc: now,
      readBy: readBy,
    );
  }

  TransportRouteReceipt markLearningApplied({
    required TransportRouteReceipt receipt,
    String? learningAppliedBy,
  }) {
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'learning_applied',
      recordedAtUtc: now,
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      deliveredAtUtc: receipt.deliveredAtUtc ?? now,
      learningAppliedAtUtc: now,
      learningAppliedBy: learningAppliedBy,
    );
  }

  int _latencyForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.ble:
        return 450;
      case TransportMode.localWifi:
        return 250;
      case TransportMode.nearbyRelay:
        return 1200;
      case TransportMode.wormhole:
        return 900;
      case TransportMode.cloudAssist:
        return 1100;
    }
  }

  double _baseConfidence(TransportMode mode) {
    switch (mode) {
      case TransportMode.ble:
        return 0.72;
      case TransportMode.localWifi:
        return 0.78;
      case TransportMode.nearbyRelay:
        return 0.69;
      case TransportMode.wormhole:
        return 0.74;
      case TransportMode.cloudAssist:
        return 0.58;
    }
  }

  double _localityFitForMode(TransportMode mode, String? locality) {
    if (locality == null || locality.isEmpty) {
      return mode == TransportMode.wormhole ? 0.7 : 0.85;
    }
    switch (mode) {
      case TransportMode.ble:
      case TransportMode.localWifi:
        return 0.95;
      case TransportMode.nearbyRelay:
        return 0.88;
      case TransportMode.wormhole:
        return 0.82;
      case TransportMode.cloudAssist:
        return 0.6;
    }
  }
}
