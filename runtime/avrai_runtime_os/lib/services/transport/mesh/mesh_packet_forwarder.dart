// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';
import 'dart:typed_data';

import 'package:avrai_network/avra_network.dart';

class MeshPacketForwarder {
  const MeshPacketForwarder._();

  static Future<void> forwardToCandidates({
    required List<String> candidatePeerIds,
    required DeviceDiscoveryService discovery,
    required AI2AIProtocol protocol,
    required String senderNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required MessageType messageType,
    required Map<String, dynamic> payload,
    String? geographicScope,
    bool fireAndForgetSend = false,
    void Function(String peerId, String recipientId)? onForwarded,
    void Function(String peerId, String recipientId, Object error)?
        onForwardFailed,
  }) async {
    for (final peerId in candidatePeerIds) {
      final device = discovery.getDevice(peerId);
      if (device == null || device.type != DeviceType.bluetooth) continue;

      final recipientId =
          peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;

      try {
        final packetBytes = await protocol.encodePacketBytes(
          type: messageType,
          payload: payload,
          senderNodeId: senderNodeId,
          recipientNodeId: recipientId,
          geographicScope: geographicScope,
        );

        if (fireAndForgetSend) {
          unawaited(sendBlePacketsBatch(
            device: device,
            senderId: senderNodeId,
            packetBytesList: <Uint8List>[packetBytes],
          ));
        } else {
          await sendBlePacketsBatch(
            device: device,
            senderId: senderNodeId,
            packetBytesList: <Uint8List>[packetBytes],
          );
        }
        onForwarded?.call(peerId, recipientId);
      } catch (e) {
        onForwardFailed?.call(peerId, recipientId, e);
      }
    }
  }
}
