// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_network/avra_network.dart';

class PrekeySessionPrimeLane {
  const PrekeySessionPrimeLane._();

  static Future<void> run({
    required bool allowBleSideEffects,
    required SignalKeyManager? signalKeyManager,
    required GovernedMeshPacketCodec? packetCodec,
    required DiscoveredDevice device,
    required BleGattSession session,
    required Map<String, String> peerNodeIdByDeviceId,
    required bool federatedLearningParticipationEnabled,
    required Future<void> Function({
      required SignalPreKeyBundle bundle,
      required String recipientId,
      required DiscoveredDevice device,
    }) forwardPreKeyBundleThroughMesh,
    required String localBleNodeId,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!allowBleSideEffects) return;
    if (signalKeyManager == null || packetCodec == null) return;

    try {
      final bytes = await session.readStreamPayload(streamId: 1);
      if (bytes == null || bytes.isEmpty) return;

      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final peerNodeId = decoded['node_id'] as String?;
      final bundleJson = decoded['prekey_bundle'] as Map<String, dynamic>?;
      if (bundleJson == null) return;

      final bundle = SignalPreKeyBundle.fromJson(bundleJson);
      final recipientId = (peerNodeId != null && peerNodeId.isNotEmpty)
          ? peerNodeId
          : device.deviceId;
      if (peerNodeId != null && peerNodeId.isNotEmpty) {
        peerNodeIdByDeviceId[device.deviceId] = peerNodeId;
      }

      final needsRefresh =
          signalKeyManager.getRecipientsNeedingRefresh().contains(recipientId);
      if (needsRefresh) {
        logger.debug(
          'Prekey bundle for $recipientId needs refresh - attempting background refresh',
          tag: logName,
        );
        unawaited(
          signalKeyManager.fetchPreKeyBundle(recipientId).then((_) {
            logger.debug(
              'Successfully refreshed prekey bundle for recipient: $recipientId',
              tag: logName,
            );
          }).catchError((e) {
            logger.debug(
              'Background refresh failed for $recipientId, using BLE bundle: $e',
              tag: logName,
            );
          }),
        );
      }

      await signalKeyManager.cacheRemotePreKeyBundle(
        recipientId: recipientId,
        preKeyBundle: bundle,
      );
      logger.debug(
        'Cached and validated prekey bundle for recipient: $recipientId (PQXDH enabled)',
        tag: logName,
      );

      if (federatedLearningParticipationEnabled) {
        await forwardPreKeyBundleThroughMesh(
          bundle: bundle,
          recipientId: recipientId,
          device: device,
        );
      }

      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_signal_prekey_cached_from_peer',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'device_id': device.deviceId,
            'peer_node_id': peerNodeId ?? '',
            'recipient_id': recipientId,
            'stream_id': 1,
            'bytes_len': bytes.length,
          },
        ));
      }

      final packetBytes = await packetCodec.encode(
        type: MeshPacketType.heartbeat,
        payload: <String, dynamic>{
          't': DateTime.now().toUtc().toIso8601String(),
          'kind': 'silent_signal_bootstrap',
        },
        senderNodeId: localBleNodeId,
        recipientNodeId: recipientId,
      );

      final results = await session.sendPacketsBatch(
        senderId: localBleNodeId,
        packetBytesList: <Uint8List>[packetBytes],
      );
      final ok = results.isNotEmpty && results.first;
      if (ok) {
        logger.debug(
          'Sent silent Signal bootstrap packet (session) to ${device.deviceId}',
          tag: logName,
        );
      }
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_silent_bootstrap_sent',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'ok': ok,
            'device_id': device.deviceId,
            'recipient_id': recipientId,
            'message_type': MeshPacketType.heartbeat.name,
            'kind': 'silent_signal_bootstrap',
          },
        ));
      }
    } catch (e) {
      logger.warn('Failed to prime offline Signal in session: $e',
          tag: logName);
      if (!LedgerAuditV0.isEnabled) return;

      unawaited(LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.deviceCapability,
        eventType: 'ai2ai_offline_signal_prime_failed',
        occurredAt: DateTime.now(),
        payload: <String, Object?>{
          'device_id': device.deviceId,
          'error': e.toString(),
        },
      ));
    }
  }
}
