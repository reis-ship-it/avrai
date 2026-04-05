// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/ai2ai/locality/incoming_learning_insight_parser.dart';
import 'package:avrai_runtime_os/ai2ai/locality/incoming_learning_insight_side_effects.dart';
import 'package:avrai_runtime_os/ai2ai/locality/learning_insight_flow_gate.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/avra_network.dart';

class IncomingLearningInsightProcessingLane {
  const IncomingLearningInsightProcessingLane._();

  static Future<void> handle({
    required ProtocolMessage message,
    required SharedPreferencesCompat prefs,
    required String prefsKeyAi2AiLearningEnabled,
    required String? currentUserId,
    required PersonalityLearning? personalityLearning,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required Map<String, int> seenLearningInsightIds,
    required Map<String, DateTime> lastAi2AiLearningAtByPeerId,
    required Future<bool> Function({
      required String userId,
      required PersonalityLearning personalityLearning,
      required String peerId,
      required AI2AILearningInsight insight,
      required DateTime now,
      required String source,
      required String? insightId,
      required double learningQuality,
      required Map<String, double> deltas,
    }) applyInsightForPeer,
    required Future<void> Function({
      required Map<String, dynamic> payload,
      required String originId,
      required int hop,
      required String receivedFromDeviceId,
    }) maybeForwardLearningInsightGossip,
    required AppLogger logger,
    required String logName,
  }) async {
    final bool learningEnabled =
        prefs.getBool(prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;

    if (currentUserId == null || personalityLearning == null) return;

    try {
      final Map<String, dynamic> payload = message.payload;
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final parseResult = IncomingLearningInsightParser.parse(
        payload: payload,
        senderId: message.senderId,
        adaptiveMeshService: adaptiveMeshService,
        nowMs: nowMs,
      );
      if (parseResult == null) return;

      final String insightId = parseResult.insightId;
      final int expiresAtMs = parseResult.expiresAtMs;
      final double learningQuality = parseResult.learningQuality;
      final String originId = parseResult.originId;
      final int hop = parseResult.hop;
      final Map<String, double> deltas = parseResult.deltas;

      if (!LearningInsightFlowGate.markSeenIfFresh(
        seenLearningInsightIds: seenLearningInsightIds,
        insightId: insightId,
        nowMs: nowMs,
        expiresAtMs: expiresAtMs,
      )) {
        return;
      }

      final DateTime now = DateTime.now();
      final String sender = message.senderId;
      if (LearningInsightFlowGate.isPeerLearningThrottled(
        lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
        peerId: sender,
        now: now,
      )) {
        return;
      }

      final AI2AILearningInsight insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: deltas,
        learningQuality: learningQuality,
        timestamp: now,
      );

      final applied = await applyInsightForPeer(
        userId: currentUserId,
        personalityLearning: personalityLearning,
        peerId: sender,
        insight: insight,
        now: now,
        source: 'inbox',
        insightId: insightId,
        learningQuality: learningQuality,
        deltas: deltas,
      );

      IncomingLearningInsightSideEffects.emitSuccess(
        insightId: insightId,
        sender: sender,
        originId: originId,
        hop: hop,
        applied: applied,
        learningQuality: learningQuality,
        deltaDimensionsCount: deltas.length,
        forwardGossip: () {
          unawaited(maybeForwardLearningInsightGossip(
            payload: payload,
            originId: originId,
            hop: hop,
            receivedFromDeviceId: sender,
          ));
        },
      );
    } catch (e) {
      IncomingLearningInsightSideEffects.emitFailure(
        error: e,
        senderDeviceId: message.senderId,
        logger: logger,
        logTag: logName,
      );
    }
  }
}
