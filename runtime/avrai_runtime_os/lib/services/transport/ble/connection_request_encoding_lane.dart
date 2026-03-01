// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class ConnectionRequestEncodingLane {
  const ConnectionRequestEncodingLane._();

  static Future<void> maybeEncode({
    required AI2AIProtocol? protocol,
    required String localVibeArchetype,
    required String remoteVibeArchetype,
    required double initialCompatibility,
    required String connectionId,
    required String senderNodeId,
    required String recipientNodeId,
    required AppLogger logger,
    required String logName,
  }) async {
    if (protocol == null) return;

    try {
      final connectionMessage = await protocol.encodeMessage(
        type: MessageType.connectionRequest,
        payload: <String, dynamic>{
          'local_vibe_archetype': localVibeArchetype,
          'remote_vibe_archetype': remoteVibeArchetype,
          'initial_compatibility': initialCompatibility,
          'connection_id': connectionId,
        },
        senderNodeId: senderNodeId,
        recipientNodeId: recipientNodeId,
      );

      logger.debug(
        'Encoded connection message via protocol: type=${connectionMessage.type.name}, sender=${connectionMessage.senderId}',
        tag: logName,
      );
    } catch (e) {
      logger.warn(
        'Error encoding protocol message: $e, continuing without protocol',
        tag: logName,
      );
    }
  }
}
