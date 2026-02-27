import 'dart:async';
import 'dart:typed_data';

import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_network/avra_network.dart';

class LearningInsightPeerSendLane {
  const LearningInsightPeerSendLane._();

  static Future<void> send({
    required AI2AIProtocol protocol,
    required DiscoveredDevice device,
    required String peerId,
    required String localBleNodeId,
    required String recipientId,
    required String insightId,
    required double learningQuality,
    required AI2AILearningInsight insight,
    required Future<void> Function(Map<String, dynamic> payload)
        enqueueFederatedDeltaForCloudFromInsightPayload,
    required AppLogger logger,
    required String logName,
  }) async {
    const ttlMs = 60 * 60 * 1000;

    final payload = <String, dynamic>{
      'schema_version': 1,
      'insight_id': insightId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'ttl_ms': ttlMs,
      'learning_quality': learningQuality,
      'insight_type': insight.type.name,
      'origin_id': localBleNodeId,
      'hop': 0,
      'dimension_insights': insight.dimensionInsights.map(
        (k, v) => MapEntry(k, v.clamp(-0.35, 0.35)),
      ),
    };

    try {
      await enqueueFederatedDeltaForCloudFromInsightPayload(payload);

      final packetBytes = await protocol.encodePacketBytes(
        type: MessageType.learningInsight,
        payload: payload,
        senderNodeId: localBleNodeId,
        recipientNodeId: recipientId,
      );

      final results = await sendBlePacketsBatch(
        device: device,
        senderId: localBleNodeId,
        packetBytesList: <Uint8List>[packetBytes],
      );
      final ok = results.isNotEmpty && results.first;
      if (ok) {
        logger.debug('Sent learning insight to $peerId', tag: logName);
      }
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_learning_insight_sent',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'ok': ok,
            'peer_id': peerId,
            'recipient_id': recipientId,
            'insight_id': insightId,
            'schema_version': 1,
            'learning_quality': learningQuality,
            'delta_dimensions_count': insight.dimensionInsights.length,
          },
        ));
      }
    } catch (e) {
      logger.debug('Failed to send learning insight to $peerId: $e', tag: logName);
      if (!LedgerAuditV0.isEnabled) return;

      unawaited(LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.deviceCapability,
        eventType: 'ai2ai_learning_insight_send_failed',
        occurredAt: DateTime.now(),
        payload: <String, Object?>{
          'peer_id': peerId,
          'recipient_id': recipientId,
          'insight_id': insightId,
          'error': e.toString(),
        },
      ));
    }
  }
}
