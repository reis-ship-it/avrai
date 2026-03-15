import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/binary_packet_codec.dart';
import 'package:avrai_network/network/packet_padding.dart';

class MeshInboundDecodedPacket {
  const MeshInboundDecodedPacket({
    required this.envelope,
    required this.encryptedPayload,
    required this.ttl,
    required this.isBinaryFormat,
    this.signature,
    this.nonce,
    this.sequenceNumber,
    this.requiresAck = false,
  });

  final MeshPacketEnvelope envelope;
  final Uint8List encryptedPayload;
  final int ttl;
  final bool isBinaryFormat;
  final Uint8List? signature;
  final Uint8List? nonce;
  final int? sequenceNumber;
  final bool requiresAck;

  ProtocolMessage toLegacyProtocolMessage() {
    return ProtocolMessage(
      version: envelope.version,
      type: _legacyMessageTypeFor(envelope.type),
      senderId: envelope.senderId,
      recipientId: envelope.recipientId,
      timestamp: envelope.timestamp,
      payload: envelope.payload,
    );
  }

  static MessageType _legacyMessageTypeFor(MeshPacketType type) {
    return switch (type) {
      MeshPacketType.connectionRequest => MessageType.connectionRequest,
      MeshPacketType.connectionResponse => MessageType.connectionResponse,
      MeshPacketType.learningExchange => MessageType.learningExchange,
      MeshPacketType.learningInsight => MessageType.learningInsight,
      MeshPacketType.heartbeat => MessageType.heartbeat,
      MeshPacketType.disconnect => MessageType.disconnect,
      MeshPacketType.vibeExchange => MessageType.vibeExchange,
      MeshPacketType.personalityExchange => MessageType.personalityExchange,
      MeshPacketType.fragmentStart => MessageType.fragmentStart,
      MeshPacketType.fragmentContinue => MessageType.fragmentContinue,
      MeshPacketType.fragmentEnd => MessageType.fragmentEnd,
      MeshPacketType.userChat => MessageType.userChat,
      MeshPacketType.deliveryAck => MessageType.deliveryAck,
      MeshPacketType.readReceipt => MessageType.readReceipt,
    };
  }
}

class MeshInboundDecodeLane {
  const MeshInboundDecodeLane({
    required MessageEncryptionService encryptionService,
  }) : _encryptionService = encryptionService;

  static const int _wrapperHeaderSize = 80;
  static const String _legacyIdentifier = 'SPOTS-AI2AI';

  final MessageEncryptionService _encryptionService;

  Future<MeshInboundDecodedPacket?> decode({
    required Uint8List packetData,
    required String senderId,
  }) async {
    final wrappedPacket = _parseLegacyWrapper(packetData);
    final isBinaryFormat = wrappedPacket?.version == '2.0';
    final rawPayload = wrappedPacket?.data ?? packetData;
    Uint8List binaryPayload = rawPayload;

    if (wrappedPacket != null &&
        wrappedPacket.checksum.isNotEmpty &&
        _calculateChecksum(rawPayload) != wrappedPacket.checksum) {
      return null;
    }

    if (isBinaryFormat) {
      try {
        binaryPayload = PacketPadding.unpad(rawPayload);
      } catch (_) {
        return null;
      }
    }

    if (isBinaryFormat) {
      final decoded = BinaryPacketCodec.decode(binaryPayload);
      final payload = await _decryptPayload(
        encryptedPayload: decoded.encryptedPayload,
        senderId: senderId,
      );
      return MeshInboundDecodedPacket(
        envelope: decoded.message.copyWith(payload: payload),
        encryptedPayload: decoded.encryptedPayload,
        ttl: decoded.ttl,
        isBinaryFormat: true,
        signature: decoded.signature,
        nonce: decoded.nonce,
        sequenceNumber: decoded.sequenceNumber,
        requiresAck: decoded.requiresAck,
      );
    }

    final payload = await _decryptPayload(
      encryptedPayload: rawPayload,
      senderId: senderId,
    );
    // ignore: deprecated_member_use
    final legacyMessage = ProtocolMessage.fromJson(payload);
    return MeshInboundDecodedPacket(
      envelope: MeshPacketEnvelope(
        version: legacyMessage.version,
        type: _meshPacketTypeFor(legacyMessage.type),
        senderId: legacyMessage.senderId,
        recipientId: legacyMessage.recipientId,
        timestamp: legacyMessage.timestamp,
        payload: legacyMessage.payload,
      ),
      encryptedPayload: rawPayload,
      ttl: BinaryPacketCodec.getTTLForGeographicScope(
        legacyMessage.payload['geographic_scope']?.toString(),
      ),
      isBinaryFormat: false,
    );
  }

  Future<Map<String, dynamic>> _decryptPayload({
    required Uint8List encryptedPayload,
    required String senderId,
  }) async {
    try {
      final json = await _encryptionService.decrypt(
        EncryptedMessage(
          encryptedContent: encryptedPayload,
          encryptionType: _encryptionService.encryptionType,
        ),
        senderId,
      );
      return Map<String, dynamic>.from(
        jsonDecode(json) as Map? ?? const <String, dynamic>{},
      );
    } catch (_) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(encryptedPayload)) as Map? ??
            const <String, dynamic>{},
      );
    }
  }

  _MeshLegacyPacket? _parseLegacyWrapper(Uint8List packetData) {
    if (packetData.length < _wrapperHeaderSize) {
      return null;
    }
    final identifier = utf8.decode(packetData.sublist(0, 12)).trim();
    if (identifier != _legacyIdentifier) {
      return null;
    }
    return _MeshLegacyPacket(
      identifier: identifier,
      version: utf8.decode(packetData.sublist(12, 16)).trim(),
      checksum: utf8.decode(packetData.sublist(16, 80)).trim(),
      data: Uint8List.fromList(packetData.sublist(_wrapperHeaderSize)),
    );
  }

  static String _calculateChecksum(Uint8List data) {
    return sha256.convert(data).toString();
  }

  static MeshPacketType _meshPacketTypeFor(MessageType type) {
    return switch (type) {
      MessageType.connectionRequest => MeshPacketType.connectionRequest,
      MessageType.connectionResponse => MeshPacketType.connectionResponse,
      MessageType.learningExchange => MeshPacketType.learningExchange,
      MessageType.learningInsight => MeshPacketType.learningInsight,
      MessageType.heartbeat => MeshPacketType.heartbeat,
      MessageType.disconnect => MeshPacketType.disconnect,
      MessageType.vibeExchange => MeshPacketType.vibeExchange,
      MessageType.personalityExchange => MeshPacketType.personalityExchange,
      MessageType.fragmentStart => MeshPacketType.fragmentStart,
      MessageType.fragmentContinue => MeshPacketType.fragmentContinue,
      MessageType.fragmentEnd => MeshPacketType.fragmentEnd,
      MessageType.userChat => MeshPacketType.userChat,
      MessageType.deliveryAck => MeshPacketType.deliveryAck,
      MessageType.readReceipt => MeshPacketType.readReceipt,
    };
  }
}

class _MeshLegacyPacket {
  const _MeshLegacyPacket({
    required this.identifier,
    required this.version,
    required this.checksum,
    required this.data,
  });

  final String identifier;
  final String version;
  final String checksum;
  final Uint8List data;
}
