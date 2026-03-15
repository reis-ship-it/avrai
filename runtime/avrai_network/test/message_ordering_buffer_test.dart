import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart';
import 'package:avrai_network/network/message_ordering_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProtocolMessage message(int seq, DateTime time) {
    return ProtocolMessage(
      version: '1.0',
      type: MessageType.learningInsight,
      senderId: 'peer',
      timestamp: time,
      payload: {'seq': seq},
    );
  }

  test('releases ordered messages in sequence', () {
    final buffer = MessageOrderingBuffer();

    expect(
      buffer.addMessage(
        peerAgentId: 'peer',
        sequenceNumber: 0,
        message: message(0, DateTime.utc(2026, 3, 6, 10)),
      ),
      hasLength(1),
    );
    expect(
      buffer.addMessage(
        peerAgentId: 'peer',
        sequenceNumber: 1,
        message: message(1, DateTime.utc(2026, 3, 6, 10, 1)),
      ),
      hasLength(1),
    );
  });

  test('releases buffered message when sequence gap exceeds policy', () {
    final buffer = MessageOrderingBuffer(
      orderingPolicy: const TemporalOrderingPolicy(maxSequenceGap: 2),
    );

    final ready = buffer.addMessage(
      peerAgentId: 'peer',
      sequenceNumber: 5,
      message: message(5, DateTime.utc(2026, 3, 6, 10)),
    );

    expect(ready, hasLength(1));
    expect(ready.first.payload['seq'], 5);
  });
}
