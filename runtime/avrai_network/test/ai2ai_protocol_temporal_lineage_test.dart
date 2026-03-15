import 'dart:typed_data';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ai2ai protocol records encoded lineage events', () async {
    final sink = _RecordingTemporalLineageSink();
    // ignore: deprecated_member_use_from_same_package
    final protocol = AI2AIProtocol(
      encryptionService: _PassthroughEncryptionService(),
      temporalLineageSink: sink,
    );

    await protocol.encodeMessage(
      type: MessageType.heartbeat,
      payload: const <String, dynamic>{'kind': 'heartbeat'},
      senderNodeId: 'sender',
      recipientNodeId: 'recipient',
    );

    expect(sink.events, isNotEmpty);
    expect(sink.events.first.stage, TemporalLineageStage.encoded);
    expect(sink.events.first.source, 'ai2ai_protocol');
  });
}

class _RecordingTemporalLineageSink implements TemporalLineageSink {
  final List<TemporalLineageEvent> events = <TemporalLineageEvent>[];

  @override
  Future<void> record(TemporalLineageEvent event) async {
    events.add(event);
  }
}

class _PassthroughEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return String.fromCharCodes(encrypted.encryptedContent);
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(plaintext.codeUnits),
      encryptionType: encryptionType,
    );
  }
}
