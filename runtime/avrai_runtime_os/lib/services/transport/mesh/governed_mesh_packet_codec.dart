// TODO(Phase 0.5.0): Remove this suppression after packet models migrate out of AI2AIProtocol.
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:avrai_network/network/binary_packet_codec.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_network/network/mesh_packet_models.dart';

class GovernedMeshPacketEncodingException implements Exception {
  const GovernedMeshPacketEncodingException(this.message);

  final String message;

  @override
  String toString() => 'GovernedMeshPacketEncodingException: $message';
}

class GovernedMeshPacketCodec {
  const GovernedMeshPacketCodec({
    required MessageEncryptionService encryptionService,
    DateTime Function()? nowUtc,
  })  : _encryptionService = encryptionService,
        _nowUtc = nowUtc;

  final MessageEncryptionService _encryptionService;
  final DateTime Function()? _nowUtc;

  bool get failClosedOnEncryptionFailure => true;

  Future<Uint8List> encode({
    required MeshPacketType type,
    required Map<String, dynamic> payload,
    required String senderNodeId,
    required String recipientNodeId,
    String? geographicScope,
    bool requiresAck = false,
  }) async {
    _validateNoUnifiedUserInPayload(payload);
    final occurredAtUtc = (_nowUtc ?? () => DateTime.now().toUtc())();
    final plaintext = jsonEncode(payload);
    try {
      final encrypted = await _encryptionService.encrypt(
        plaintext,
        recipientNodeId,
      );
      final message = MeshPacketEnvelope(
        version: 'mesh-governed-v1',
        type: type,
        senderId: senderNodeId,
        recipientId: recipientNodeId,
        timestamp: occurredAtUtc,
        payload: payload,
      );
      return BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encrypted.encryptedContent,
        geographicScope: geographicScope,
        requiresAck: requiresAck,
        isDeniable: type == MeshPacketType.learningInsight,
      );
    } catch (error) {
      throw GovernedMeshPacketEncodingException(
        'Mesh packet encryption failed for $recipientNodeId: $error',
      );
    }
  }

  void _validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    const forbiddenFields = <String>[
      'id',
      'email',
      'displayName',
      'photoUrl',
      'userId',
    ];
    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw GovernedMeshPacketEncodingException(
          'UnifiedUser field "$field" is not allowed in governed mesh payloads.',
        );
      }
    }
    for (final value in payload.values) {
      if (value is Map<String, dynamic>) {
        _validateNoUnifiedUserInPayload(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _validateNoUnifiedUserInPayload(item);
          }
        }
      }
    }
  }
}
