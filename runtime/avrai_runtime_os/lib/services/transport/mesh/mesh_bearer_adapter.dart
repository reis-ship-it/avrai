import 'dart:async';
import 'dart:typed_data';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';

class MeshBearerDispatchRequest {
  const MeshBearerDispatchRequest({
    required this.candidatePeerIds,
    required this.senderNodeId,
    required this.peerNodeIdByDeviceId,
    required this.messageType,
    required this.payload,
    this.geographicScope,
    this.fireAndForgetSend = false,
  });

  final List<String> candidatePeerIds;
  final String senderNodeId;
  final Map<String, String> peerNodeIdByDeviceId;
  final MeshPacketType messageType;
  final Map<String, dynamic> payload;
  final String? geographicScope;
  final bool fireAndForgetSend;
}

class MeshBearerDispatchResult {
  const MeshBearerDispatchResult({
    this.forwardedRecipients = const <String, String>{},
    this.failedPeers = const <String, Object>{},
  });

  final Map<String, String> forwardedRecipients;
  final Map<String, Object> failedPeers;
}

abstract class MeshBearerAdapter {
  const MeshBearerAdapter();

  Future<MeshBearerDispatchResult> dispatch(MeshBearerDispatchRequest request);
}

class BleMeshBearerAdapter extends MeshBearerAdapter {
  const BleMeshBearerAdapter({
    required DeviceDiscoveryService discovery,
    required GovernedMeshPacketCodec packetCodec,
  })  : _discovery = discovery,
        _packetCodec = packetCodec;

  final DeviceDiscoveryService _discovery;
  final GovernedMeshPacketCodec _packetCodec;

  @override
  Future<MeshBearerDispatchResult> dispatch(
    MeshBearerDispatchRequest request,
  ) async {
    final forwardedRecipients = <String, String>{};
    final failedPeers = <String, Object>{};
    for (final peerId in request.candidatePeerIds) {
      final device = _discovery.getDevice(peerId);
      if (device == null || device.type != DeviceType.bluetooth) {
        continue;
      }
      final recipientId =
          request.peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
      try {
        final packetBytes = await _packetCodec.encode(
          type: request.messageType,
          payload: request.payload,
          senderNodeId: request.senderNodeId,
          recipientNodeId: recipientId,
          geographicScope: request.geographicScope,
        );
        if (request.fireAndForgetSend) {
          unawaited(sendBlePacketsBatch(
            device: device,
            senderId: request.senderNodeId,
            packetBytesList: <Uint8List>[packetBytes],
          ));
        } else {
          await sendBlePacketsBatch(
            device: device,
            senderId: request.senderNodeId,
            packetBytesList: <Uint8List>[packetBytes],
          );
        }
        forwardedRecipients[peerId] = recipientId;
      } catch (error) {
        failedPeers[peerId] = error;
      }
    }
    return MeshBearerDispatchResult(
      forwardedRecipients: forwardedRecipients,
      failedPeers: failedPeers,
    );
  }
}
