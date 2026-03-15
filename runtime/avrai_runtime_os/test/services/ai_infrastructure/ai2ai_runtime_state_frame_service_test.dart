import 'package:avrai_runtime_os/monitoring/ai2ai_network_activity_event.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a deterministic AI2AI runtime frame from recent events', () {
    final capturedAt = DateTime.utc(2026, 3, 12, 23, 0);
    final frame = const Ai2AiRuntimeStateFrameService().buildFrame(
      events: <AI2AINetworkActivityEvent>[
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.connectionEstablished,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 50),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.custodyAccepted,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 51),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.deliverySuccess,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 52),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.readConfirmed,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 53),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.learningApplied,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 54),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.peerReceived,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 54, 10),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.peerValidated,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 54, 20),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.peerConsumed,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 54, 30),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.peerApplied,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 54, 40),
          connectionId: 'conn-1',
          remoteNodeId: 'peer-a',
        ),
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.deliveryFailure,
          occurredAt: DateTime.utc(2026, 3, 12, 22, 55),
          connectionId: 'conn-2',
          remoteNodeId: 'peer-b',
        ),
      ],
      capturedAtUtc: capturedAt,
    );

    expect(frame.capturedAtUtc, capturedAt);
    expect(frame.recentEventCount, 10);
    expect(frame.activeConnectionCount, 1);
    expect(frame.distinctConnectionCount, 2);
    expect(frame.distinctRemoteNodeCount, 2);
    expect(frame.custodyAcceptedCount, 1);
    expect(frame.deliverySuccessCount, 1);
    expect(frame.deliveryFailureCount, 1);
    expect(frame.readConfirmedCount, 1);
    expect(frame.learningAppliedCount, 1);
    expect(frame.peerReceivedCount, 1);
    expect(frame.peerValidatedCount, 1);
    expect(frame.peerConsumedCount, 1);
    expect(frame.peerAppliedCount, 1);
    expect(frame.peers.first.peerRef, 'peer-a');
    expect(frame.peers.first.activeConnectionCount, 1);
    expect(frame.peers.first.deliverySuccessCount, 1);
    expect(frame.peers.first.peerReceivedCount, 1);
    expect(frame.peers.first.peerValidatedCount, 1);
    expect(frame.peers.first.peerConsumedCount, 1);
    expect(frame.peers.first.peerAppliedCount, 1);

    final decoded = Ai2AiRuntimeStateFrame.fromJson(frame.toJson());
    expect(decoded.peerReceivedCount, 1);
    expect(decoded.peerAppliedCount, 1);
  });
}
