import 'dart:convert';
import 'dart:typed_data';

import 'package:avrai_network/network/binary_packet_codec.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_network/network/mesh_packet_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GovernedMeshPacketCodec', () {
    test('encodes encrypted binary packets without plaintext fallback',
        () async {
      final codec = GovernedMeshPacketCodec(
        encryptionService: _SignalLikeEncryptionService(),
      );

      final packet = await codec.encode(
        type: MeshPacketType.learningInsight,
        payload: const <String, dynamic>{'kind': 'learning_insight'},
        senderNodeId: 'node-a',
        recipientNodeId: 'node-b',
      );
      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.message.type, MeshPacketType.learningInsight);
      expect(
        utf8.decode(decoded.encryptedPayload),
        startsWith('signal:node-b:'),
      );
      expect(
        utf8.decode(decoded.encryptedPayload),
        isNot(equals('{"kind":"learning_insight"}')),
      );
    });

    test('fails closed when encryption throws', () async {
      final codec = GovernedMeshPacketCodec(
        encryptionService: _FailingEncryptionService(),
      );

      expect(
        () => codec.encode(
          type: MeshPacketType.learningInsight,
          payload: const <String, dynamic>{'kind': 'learning_insight'},
          senderNodeId: 'node-a',
          recipientNodeId: 'node-b',
        ),
        throwsA(isA<GovernedMeshPacketEncodingException>()),
      );
    });

    test('rejects payloads that expose direct identity fields', () async {
      final codec = GovernedMeshPacketCodec(
        encryptionService: _SignalLikeEncryptionService(),
      );

      expect(
        () => codec.encode(
          type: MeshPacketType.learningInsight,
          payload: const <String, dynamic>{
            'nested': <String, dynamic>{'userId': 'user-123'},
          },
          senderNodeId: 'node-a',
          recipientNodeId: 'node-b',
        ),
        throwsA(isA<GovernedMeshPacketEncodingException>()),
      );
    });
  });
}

class _SignalLikeEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent:
          Uint8List.fromList(utf8.encode('signal:$recipientId:$plaintext')),
      encryptionType: encryptionType,
    );
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return utf8.decode(encrypted.encryptedContent);
  }
}

class _FailingEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    throw StateError('signal session unavailable');
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    throw UnimplementedError();
  }
}
