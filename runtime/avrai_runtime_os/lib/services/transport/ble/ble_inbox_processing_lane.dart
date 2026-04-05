import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';

class BleInboxProcessingLane {
  const BleInboxProcessingLane._();

  static Timer start({
    Duration interval = const Duration(seconds: 2),
    required MeshInboundDecodeLane inboundDecodeLane,
    required Map<String, int> seenBleMessageHashes,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingLocalityAgentUpdate,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingOrganicSpotDiscovery,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingLearningInsight,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingUserChat,
    required Future<void> Function() persistSeenBleHashesIfNeeded,
    required Future<void> Function() persistSeenLearningInsightIdsIfNeeded,
    required AppLogger logger,
    required String logName,
  }) {
    return Timer.periodic(interval, (_) async {
      try {
        final messages = await BleInbox.pollMessages(maxMessages: 50);
        if (messages.isEmpty) return;

        for (final msg in messages) {
          final hash = sha256.convert(msg.data).toString();
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final existingExpiry = seenBleMessageHashes[hash];
          if (existingExpiry != null && existingExpiry > nowMs) {
            continue;
          }
          seenBleMessageHashes[hash] =
              nowMs + const Duration(minutes: 10).inMilliseconds;

          final decodedPacket = await inboundDecodeLane.decode(
            packetData: msg.data,
            senderId: msg.senderId,
          );
          final decoded = decodedPacket?.toLegacyProtocolMessage();
          if (decoded == null) continue;

          if (decoded.type == MessageType.learningInsight) {
            final payload = decoded.payload;
            final type = payload['type'] as String?;
            if (type == 'locality_agent_update') {
              await handleIncomingLocalityAgentUpdate(decoded);
            } else if (type == 'organic_spot_discovery') {
              await handleIncomingOrganicSpotDiscovery(decoded);
            } else {
              await handleIncomingLearningInsight(decoded);
            }
          } else if (decoded.type == MessageType.userChat) {
            await handleIncomingUserChat(decoded);
          }
        }

        await persistSeenBleHashesIfNeeded();
        await persistSeenLearningInsightIdsIfNeeded();
      } catch (e) {
        logger.warn('BLE inbox processing error: $e', tag: logName);
      }
    });
  }
}
