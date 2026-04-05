// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_conversation_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLegacyConversationTransportAdapter extends Mock
    implements LegacyConversationTransportAdapter {}

void main() {
  group('ConversationOrchestrationLane', () {
    late _MockLegacyConversationTransportAdapter transportAdapter;
    late ConversationOrchestrationLane lane;

    setUp(() {
      transportAdapter = _MockLegacyConversationTransportAdapter();
      registerFallbackValue(<String, dynamic>{});
      when(
        () => transportAdapter.sendDirectMessagePayload(
          recipientAgentId: any(named: 'recipientAgentId'),
          payload: any(named: 'payload'),
          messageCategory: any(named: 'messageCategory'),
        ),
      ).thenAnswer(
        (_) async => LegacyConversationTransportDispatch(
          messageId: 'msg',
          timestamp: DateTime.utc(2026, 3, 12, 12),
          messageCategory: 'user_chat',
        ),
      );
      lane = ConversationOrchestrationLane(
        transportAdapter: transportAdapter,
      );
    });

    test('sends direct user chat payload through the private protocol seam',
        () async {
      final result = await lane.sendDirectMessagePayload(
        recipientAgentId: 'peer',
        payload: <String, dynamic>{
          'content': 'hello',
        },
      );

      expect(result.messageId, 'msg');
      expect(result.messageCategory, 'user_chat');

      verify(
        () => transportAdapter.sendDirectMessagePayload(
          recipientAgentId: 'peer',
          payload: any(
            named: 'payload',
            that: predicate<Map<String, dynamic>>(
              (payload) => payload['content'] == 'hello',
            ),
          ),
          messageCategory: 'user_chat',
        ),
      ).called(1);
    });
  });
}
