import 'package:avrai_runtime_os/monitoring/ai2ai_network_activity_event.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';

class Ai2AiRuntimePeerState {
  const Ai2AiRuntimePeerState({
    required this.peerRef,
    required this.eventCount,
    required this.activeConnectionCount,
    required this.deliverySuccessCount,
    required this.deliveryFailureCount,
    required this.readConfirmedCount,
    required this.learningAppliedCount,
    required this.learningBufferedCount,
    this.peerReceivedCount = 0,
    this.peerValidatedCount = 0,
    this.peerConsumedCount = 0,
    this.peerAppliedCount = 0,
    required this.connectionIds,
    required this.eventTypeCounts,
    this.lastEventAtUtc,
  });

  final String peerRef;
  final int eventCount;
  final int activeConnectionCount;
  final int deliverySuccessCount;
  final int deliveryFailureCount;
  final int readConfirmedCount;
  final int learningAppliedCount;
  final int learningBufferedCount;
  final int peerReceivedCount;
  final int peerValidatedCount;
  final int peerConsumedCount;
  final int peerAppliedCount;
  final List<String> connectionIds;
  final Map<String, int> eventTypeCounts;
  final DateTime? lastEventAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'peer_ref': peerRef,
        'event_count': eventCount,
        'active_connection_count': activeConnectionCount,
        'delivery_success_count': deliverySuccessCount,
        'delivery_failure_count': deliveryFailureCount,
        'read_confirmed_count': readConfirmedCount,
        'learning_applied_count': learningAppliedCount,
        'learning_buffered_count': learningBufferedCount,
        'peer_received_count': peerReceivedCount,
        'peer_validated_count': peerValidatedCount,
        'peer_consumed_count': peerConsumedCount,
        'peer_applied_count': peerAppliedCount,
        'connection_ids': connectionIds,
        'event_type_counts': eventTypeCounts,
        'last_event_at_utc': lastEventAtUtc?.toUtc().toIso8601String(),
      };

  factory Ai2AiRuntimePeerState.fromJson(Map<String, dynamic> json) {
    return Ai2AiRuntimePeerState(
      peerRef: json['peer_ref'] as String? ?? 'unattributed',
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
      activeConnectionCount:
          (json['active_connection_count'] as num?)?.toInt() ?? 0,
      deliverySuccessCount:
          (json['delivery_success_count'] as num?)?.toInt() ?? 0,
      deliveryFailureCount:
          (json['delivery_failure_count'] as num?)?.toInt() ?? 0,
      readConfirmedCount: (json['read_confirmed_count'] as num?)?.toInt() ?? 0,
      learningAppliedCount:
          (json['learning_applied_count'] as num?)?.toInt() ?? 0,
      learningBufferedCount:
          (json['learning_buffered_count'] as num?)?.toInt() ?? 0,
      peerReceivedCount: (json['peer_received_count'] as num?)?.toInt() ?? 0,
      peerValidatedCount:
          (json['peer_validated_count'] as num?)?.toInt() ?? 0,
      peerConsumedCount:
          (json['peer_consumed_count'] as num?)?.toInt() ?? 0,
      peerAppliedCount: (json['peer_applied_count'] as num?)?.toInt() ?? 0,
      connectionIds: (json['connection_ids'] as List? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      eventTypeCounts: (json['event_type_counts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      lastEventAtUtc:
          DateTime.tryParse(json['last_event_at_utc'] as String? ?? '')
              ?.toUtc(),
    );
  }
}

class Ai2AiRuntimeStateFrame {
  const Ai2AiRuntimeStateFrame({
    required this.capturedAtUtc,
    required this.recentEventCount,
    required this.activeConnectionCount,
    required this.distinctConnectionCount,
    required this.distinctRemoteNodeCount,
    required this.routingAttemptCount,
    required this.custodyAcceptedCount,
    required this.deliverySuccessCount,
    required this.deliveryFailureCount,
    required this.readConfirmedCount,
    required this.learningAppliedCount,
    required this.learningBufferedCount,
    this.peerReceivedCount = 0,
    this.peerValidatedCount = 0,
    this.peerConsumedCount = 0,
    this.peerAppliedCount = 0,
    required this.encryptionFailureCount,
    required this.anomalyCount,
    required this.eventTypeCounts,
    required this.peers,
  });

  final DateTime capturedAtUtc;
  final int recentEventCount;
  final int activeConnectionCount;
  final int distinctConnectionCount;
  final int distinctRemoteNodeCount;
  final int routingAttemptCount;
  final int custodyAcceptedCount;
  final int deliverySuccessCount;
  final int deliveryFailureCount;
  final int readConfirmedCount;
  final int learningAppliedCount;
  final int learningBufferedCount;
  final int peerReceivedCount;
  final int peerValidatedCount;
  final int peerConsumedCount;
  final int peerAppliedCount;
  final int encryptionFailureCount;
  final int anomalyCount;
  final Map<String, int> eventTypeCounts;
  final List<Ai2AiRuntimePeerState> peers;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'captured_at_utc': capturedAtUtc.toUtc().toIso8601String(),
        'recent_event_count': recentEventCount,
        'active_connection_count': activeConnectionCount,
        'distinct_connection_count': distinctConnectionCount,
        'distinct_remote_node_count': distinctRemoteNodeCount,
        'routing_attempt_count': routingAttemptCount,
        'custody_accepted_count': custodyAcceptedCount,
        'delivery_success_count': deliverySuccessCount,
        'delivery_failure_count': deliveryFailureCount,
        'read_confirmed_count': readConfirmedCount,
        'learning_applied_count': learningAppliedCount,
        'learning_buffered_count': learningBufferedCount,
        'peer_received_count': peerReceivedCount,
        'peer_validated_count': peerValidatedCount,
        'peer_consumed_count': peerConsumedCount,
        'peer_applied_count': peerAppliedCount,
        'encryption_failure_count': encryptionFailureCount,
        'anomaly_count': anomalyCount,
        'event_type_counts': eventTypeCounts,
        'peers': peers.map((entry) => entry.toJson()).toList(),
      };

  factory Ai2AiRuntimeStateFrame.fromJson(Map<String, dynamic> json) {
    return Ai2AiRuntimeStateFrame(
      capturedAtUtc: DateTime.tryParse(json['captured_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      recentEventCount: (json['recent_event_count'] as num?)?.toInt() ?? 0,
      activeConnectionCount:
          (json['active_connection_count'] as num?)?.toInt() ?? 0,
      distinctConnectionCount:
          (json['distinct_connection_count'] as num?)?.toInt() ?? 0,
      distinctRemoteNodeCount:
          (json['distinct_remote_node_count'] as num?)?.toInt() ?? 0,
      routingAttemptCount:
          (json['routing_attempt_count'] as num?)?.toInt() ?? 0,
      custodyAcceptedCount:
          (json['custody_accepted_count'] as num?)?.toInt() ?? 0,
      deliverySuccessCount:
          (json['delivery_success_count'] as num?)?.toInt() ?? 0,
      deliveryFailureCount:
          (json['delivery_failure_count'] as num?)?.toInt() ?? 0,
      readConfirmedCount: (json['read_confirmed_count'] as num?)?.toInt() ?? 0,
      learningAppliedCount:
          (json['learning_applied_count'] as num?)?.toInt() ?? 0,
      learningBufferedCount:
          (json['learning_buffered_count'] as num?)?.toInt() ?? 0,
      peerReceivedCount: (json['peer_received_count'] as num?)?.toInt() ?? 0,
      peerValidatedCount:
          (json['peer_validated_count'] as num?)?.toInt() ?? 0,
      peerConsumedCount:
          (json['peer_consumed_count'] as num?)?.toInt() ?? 0,
      peerAppliedCount: (json['peer_applied_count'] as num?)?.toInt() ?? 0,
      encryptionFailureCount:
          (json['encryption_failure_count'] as num?)?.toInt() ?? 0,
      anomalyCount: (json['anomaly_count'] as num?)?.toInt() ?? 0,
      eventTypeCounts: (json['event_type_counts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      peers: (json['peers'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (entry) => Ai2AiRuntimePeerState.fromJson(
                Map<String, dynamic>.from(entry)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toSimulationTopology() => <String, dynamic>{
        'ai2ai_runtime_state_frame': toJson(),
      };
}

class Ai2AiRuntimeStateFrameService {
  const Ai2AiRuntimeStateFrameService();

  Ai2AiRuntimeStateFrame buildFrame({
    required List<AI2AINetworkActivityEvent> events,
    DateTime? capturedAtUtc,
  }) {
    final sortedEvents = events.toList()
      ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    final now = capturedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final activeConnections = <String>{};
    final distinctConnections = <String>{};
    final distinctRemoteNodes = <String>{};
    final eventTypeCounts = <String, int>{};
    final peerAccumulators = <String, _Ai2AiRuntimePeerAccumulator>{};
    var routingAttemptCount = 0;
    var custodyAcceptedCount = 0;
    var deliverySuccessCount = 0;
    var deliveryFailureCount = 0;
    var readConfirmedCount = 0;
    var learningAppliedCount = 0;
    var learningBufferedCount = 0;
    var peerReceivedCount = 0;
    var peerValidatedCount = 0;
    var peerConsumedCount = 0;
    var peerAppliedCount = 0;
    var encryptionFailureCount = 0;
    var anomalyCount = 0;

    for (final event in sortedEvents) {
      eventTypeCounts[event.eventType] =
          (eventTypeCounts[event.eventType] ?? 0) + 1;
      final connectionId = event.connectionId;
      final remoteNodeId = event.remoteNodeId;
      if (connectionId != null && connectionId.isNotEmpty) {
        distinctConnections.add(connectionId);
      }
      if (remoteNodeId != null && remoteNodeId.isNotEmpty) {
        distinctRemoteNodes.add(remoteNodeId);
      }

      final peerRef = _peerRefFor(event);
      final accumulator = peerAccumulators.putIfAbsent(
        peerRef,
        () => _Ai2AiRuntimePeerAccumulator(peerRef: peerRef),
      );
      accumulator.record(event);

      switch (event.eventType) {
        case AI2AINetworkActivityEventType.routingAttempt:
          routingAttemptCount += 1;
          break;
        case AI2AINetworkActivityEventType.custodyAccepted:
          custodyAcceptedCount += 1;
          break;
        case AI2AINetworkActivityEventType.deliverySuccess:
          deliverySuccessCount += 1;
          break;
        case AI2AINetworkActivityEventType.deliveryFailure:
          deliveryFailureCount += 1;
          break;
        case AI2AINetworkActivityEventType.readConfirmed:
          readConfirmedCount += 1;
          break;
        case AI2AINetworkActivityEventType.learningApplied:
          learningAppliedCount += 1;
          break;
        case AI2AINetworkActivityEventType.learningBuffered:
          learningBufferedCount += 1;
          break;
        case AI2AINetworkActivityEventType.peerReceived:
          peerReceivedCount += 1;
          break;
        case AI2AINetworkActivityEventType.peerValidated:
          peerValidatedCount += 1;
          break;
        case AI2AINetworkActivityEventType.peerConsumed:
          peerConsumedCount += 1;
          break;
        case AI2AINetworkActivityEventType.peerApplied:
          peerAppliedCount += 1;
          break;
        case AI2AINetworkActivityEventType.encryptionFailure:
          encryptionFailureCount += 1;
          break;
        case AI2AINetworkActivityEventType.anomaly:
          anomalyCount += 1;
          break;
        case AI2AINetworkActivityEventType.connectionEstablished:
          if (connectionId != null && connectionId.isNotEmpty) {
            activeConnections.add(connectionId);
          }
          break;
        case AI2AINetworkActivityEventType.connectionClosed:
          if (connectionId != null && connectionId.isNotEmpty) {
            activeConnections.remove(connectionId);
          }
          break;
        case AI2AINetworkActivityEventType.nodeDiscovery:
          break;
      }
    }

    final peers = peerAccumulators.values
        .map((entry) => entry.toState(activeConnectionIds: activeConnections))
        .toList()
      ..sort((left, right) {
        final eventOrder = right.eventCount.compareTo(left.eventCount);
        if (eventOrder != 0) {
          return eventOrder;
        }
        return left.peerRef.compareTo(right.peerRef);
      });

    return Ai2AiRuntimeStateFrame(
      capturedAtUtc: now,
      recentEventCount: sortedEvents.length,
      activeConnectionCount: activeConnections.length,
      distinctConnectionCount: distinctConnections.length,
      distinctRemoteNodeCount: distinctRemoteNodes.length,
      routingAttemptCount: routingAttemptCount,
      custodyAcceptedCount: custodyAcceptedCount,
      deliverySuccessCount: deliverySuccessCount,
      deliveryFailureCount: deliveryFailureCount,
      readConfirmedCount: readConfirmedCount,
      learningAppliedCount: learningAppliedCount,
      learningBufferedCount: learningBufferedCount,
      peerReceivedCount: peerReceivedCount,
      peerValidatedCount: peerValidatedCount,
      peerConsumedCount: peerConsumedCount,
      peerAppliedCount: peerAppliedCount,
      encryptionFailureCount: encryptionFailureCount,
      anomalyCount: anomalyCount,
      eventTypeCounts: _sortedCounts(eventTypeCounts),
      peers: peers,
    );
  }

  Ai2AiRuntimeStateFrame buildFrameFromMonitor(
    NetworkActivityMonitor monitor, {
    int limit = NetworkActivityMonitor.maxBufferedEvents,
    DateTime? capturedAtUtc,
  }) {
    return buildFrame(
      events: monitor.getRecentEvents(limit: limit),
      capturedAtUtc: capturedAtUtc,
    );
  }

  Map<String, int> _sortedCounts(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  String _peerRefFor(AI2AINetworkActivityEvent event) {
    if (event.remoteNodeId != null && event.remoteNodeId!.isNotEmpty) {
      return event.remoteNodeId!;
    }
    if (event.connectionId != null && event.connectionId!.isNotEmpty) {
      return 'connection:${event.connectionId}';
    }
    return 'unattributed';
  }
}

class _Ai2AiRuntimePeerAccumulator {
  _Ai2AiRuntimePeerAccumulator({required this.peerRef});

  final String peerRef;
  final Set<String> connectionIds = <String>{};
  final Map<String, int> eventTypeCounts = <String, int>{};
  int eventCount = 0;
  int deliverySuccessCount = 0;
  int deliveryFailureCount = 0;
  int readConfirmedCount = 0;
  int learningAppliedCount = 0;
  int learningBufferedCount = 0;
  int peerReceivedCount = 0;
  int peerValidatedCount = 0;
  int peerConsumedCount = 0;
  int peerAppliedCount = 0;
  DateTime? lastEventAtUtc;

  void record(AI2AINetworkActivityEvent event) {
    eventCount += 1;
    final connectionId = event.connectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      connectionIds.add(connectionId);
    }
    eventTypeCounts[event.eventType] =
        (eventTypeCounts[event.eventType] ?? 0) + 1;
    if (lastEventAtUtc == null || event.occurredAt.isAfter(lastEventAtUtc!)) {
      lastEventAtUtc = event.occurredAt.toUtc();
    }
    switch (event.eventType) {
      case AI2AINetworkActivityEventType.deliverySuccess:
        deliverySuccessCount += 1;
        break;
      case AI2AINetworkActivityEventType.deliveryFailure:
        deliveryFailureCount += 1;
        break;
      case AI2AINetworkActivityEventType.readConfirmed:
        readConfirmedCount += 1;
        break;
      case AI2AINetworkActivityEventType.learningApplied:
        learningAppliedCount += 1;
        break;
      case AI2AINetworkActivityEventType.learningBuffered:
        learningBufferedCount += 1;
        break;
      case AI2AINetworkActivityEventType.peerReceived:
        peerReceivedCount += 1;
        break;
      case AI2AINetworkActivityEventType.peerValidated:
        peerValidatedCount += 1;
        break;
      case AI2AINetworkActivityEventType.peerConsumed:
        peerConsumedCount += 1;
        break;
      case AI2AINetworkActivityEventType.peerApplied:
        peerAppliedCount += 1;
        break;
      case AI2AINetworkActivityEventType.routingAttempt:
      case AI2AINetworkActivityEventType.connectionEstablished:
      case AI2AINetworkActivityEventType.connectionClosed:
      case AI2AINetworkActivityEventType.encryptionFailure:
      case AI2AINetworkActivityEventType.nodeDiscovery:
      case AI2AINetworkActivityEventType.custodyAccepted:
      case AI2AINetworkActivityEventType.anomaly:
        break;
    }
  }

  Ai2AiRuntimePeerState toState({
    required Set<String> activeConnectionIds,
  }) {
    return Ai2AiRuntimePeerState(
      peerRef: peerRef,
      eventCount: eventCount,
      activeConnectionCount:
          connectionIds.where(activeConnectionIds.contains).length,
      deliverySuccessCount: deliverySuccessCount,
      deliveryFailureCount: deliveryFailureCount,
      readConfirmedCount: readConfirmedCount,
      learningAppliedCount: learningAppliedCount,
      learningBufferedCount: learningBufferedCount,
      peerReceivedCount: peerReceivedCount,
      peerValidatedCount: peerValidatedCount,
      peerConsumedCount: peerConsumedCount,
      peerAppliedCount: peerAppliedCount,
      connectionIds: connectionIds.toList()..sort(),
      eventTypeCounts: Map<String, int>.fromEntries(
        eventTypeCounts.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
      lastEventAtUtc: lastEventAtUtc,
    );
  }
}
