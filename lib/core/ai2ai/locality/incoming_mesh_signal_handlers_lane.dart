import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/locality/incoming_locality_agent_update_processor.dart';
import 'package:avrai/core/ai2ai/locality/incoming_organic_spot_discovery_processor.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class IncomingMeshSignalHandlersLane {
  const IncomingMeshSignalHandlersLane._();

  static Future<void> handleLocalityAgentUpdate({
    required ProtocolMessage message,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required Future<void> Function({
      required Map<String, dynamic> payload,
      required String originId,
      required int hop,
      required String receivedFromDeviceId,
    })
    maybeForwardLocalityAgentUpdateGossip,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final Map<String, dynamic> payload = message.payload;
      final ingestionResult = await IncomingLocalityAgentUpdateProcessor.process(
        payload: payload,
        senderId: message.senderId,
        adaptiveMeshService: adaptiveMeshService,
        logger: logger,
        logName: logName,
      );
      if (ingestionResult == null) return;

      await maybeForwardLocalityAgentUpdateGossip(
        payload: payload,
        originId: ingestionResult.originId,
        hop: ingestionResult.hop,
        receivedFromDeviceId: message.senderId,
      );
    } catch (e, st) {
      logger.error(
        'Failed to handle incoming locality agent update: $e',
        error: e,
        stackTrace: st,
        tag: logName,
      );
    }
  }

  static Future<void> handleOrganicSpotDiscovery({
    required ProtocolMessage message,
    required String? currentUserId,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      await IncomingOrganicSpotDiscoveryProcessor.process(
        payload: message.payload,
        currentUserId: currentUserId,
        logger: logger,
        logName: logName,
      );
    } catch (e, st) {
      logger.error(
        'Failed to handle incoming organic spot discovery: $e',
        error: e,
        stackTrace: st,
        tag: logName,
      );
    }
  }
}
