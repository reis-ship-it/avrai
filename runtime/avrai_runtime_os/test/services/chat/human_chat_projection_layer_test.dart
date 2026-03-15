import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/chat/human_chat_projection_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HumanChatProjectionLayer', () {
    const layer = HumanChatProjectionLayer();

    test('projects sending when no transport receipt is present', () {
      final readModel = layer.project(
        messageId: 'message-1',
        occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
        metadata: const <String, dynamic>{},
      );

      expect(readModel.status, HumanChatProjectionStatus.sending);
      expect(readModel.routeReceipt, isNull);
    });

    test('projects delivered, read, and AI learning updated in precedence order',
        () {
      final receipt = TransportRouteReceipt(
        receiptId: 'receipt-1',
        channel: 'mesh_ble_forward',
        status: 'forwarded',
        recordedAtUtc: DateTime.utc(2026, 3, 12, 18),
        deliveredAtUtc: DateTime.utc(2026, 3, 12, 18, 0, 1),
        readAtUtc: DateTime.utc(2026, 3, 12, 18, 0, 2),
        learningAppliedAtUtc: DateTime.utc(2026, 3, 12, 18, 0, 3),
      );

      final readModel = layer.project(
        messageId: 'message-2',
        occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
        metadata: <String, dynamic>{
          HumanChatProjectionLayer.routeReceiptMetadataKey: receipt.toJson(),
        },
      );

      expect(readModel.status, HumanChatProjectionStatus.aiLearningUpdated);
      expect(readModel.readAtUtc, DateTime.utc(2026, 3, 12, 18, 0, 2));
      expect(
        readModel.aiLearningUpdatedAtUtc,
        DateTime.utc(2026, 3, 12, 18, 0, 3),
      );
    });
  });
}
