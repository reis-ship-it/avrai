import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/network/mesh_packet_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';

class ConnectionRequestEncodingLane {
  const ConnectionRequestEncodingLane._();

  static Future<void> maybeEncode({
    required GovernedMeshPacketCodec? packetCodec,
    required String localVibeArchetype,
    required String remoteVibeArchetype,
    required double initialCompatibility,
    required String connectionId,
    required String senderNodeId,
    required String recipientNodeId,
    required AppLogger logger,
    required String logName,
  }) async {
    final codec = packetCodec;
    if (codec == null) return;

    try {
      final packetBytes = await codec.encode(
        type: MeshPacketType.connectionRequest,
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
        'Encoded connection request via governed mesh codec: bytes=${packetBytes.length}, sender=$senderNodeId, recipient=$recipientNodeId',
        tag: logName,
      );
    } catch (e) {
      logger.warn(
        'Error encoding governed mesh connection request: $e',
        tag: logName,
      );
    }
  }
}
