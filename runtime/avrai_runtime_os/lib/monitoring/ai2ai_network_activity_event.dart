/// Security-relevant AI2AI network event (no message content).
///
/// Used by [NetworkActivityMonitor] for admin visibility and audit.
/// All fields are IDs/aggregate only; no PII or message payloads.
class AI2AINetworkActivityEvent {
  /// Event type (e.g. ai2ai_routing_attempt, ai2ai_connection_established).
  final String eventType;

  /// When the event occurred.
  final DateTime occurredAt;

  /// Optional connection ID (opaque, not user identity).
  final String? connectionId;

  /// Optional remote node/agent identifier (opaque, not PII).
  final String? remoteNodeId;

  /// Optional reason or code (e.g. failure reason code).
  final String? reason;

  /// Optional numeric metric (e.g. hop count, latency ms).
  final num? metric;

  /// Optional extra context (IDs/codes only; no message content).
  final Map<String, Object?>? payload;

  const AI2AINetworkActivityEvent({
    required this.eventType,
    required this.occurredAt,
    this.connectionId,
    this.remoteNodeId,
    this.reason,
    this.metric,
    this.payload,
  });

  /// Payload for LedgerAuditV0 (security domain).
  Map<String, Object?> toLedgerPayload() {
    final map = <String, Object?>{
      'event_type': eventType,
      'occurred_at': occurredAt.toIso8601String(),
      if (connectionId != null) 'connection_id': connectionId,
      if (remoteNodeId != null) 'remote_node_id': remoteNodeId,
      if (reason != null) 'reason': reason,
      if (metric != null) 'metric': metric,
      if (payload != null) ...payload!,
    };
    return map;
  }
}

/// Well-known AI2AI network activity event types (security-focused, no content).
class AI2AINetworkActivityEventType {
  AI2AINetworkActivityEventType._();

  static const String routingAttempt = 'ai2ai_routing_attempt';
  static const String connectionEstablished = 'ai2ai_connection_established';
  static const String connectionClosed = 'ai2ai_connection_closed';
  static const String encryptionFailure = 'ai2ai_encryption_failure';
  static const String nodeDiscovery = 'ai2ai_node_discovery';
  static const String deliverySuccess = 'ai2ai_delivery_success';
  static const String deliveryFailure = 'ai2ai_delivery_failure';
  static const String custodyAccepted = 'ai2ai_custody_accepted';
  static const String readConfirmed = 'ai2ai_read_confirmed';
  static const String learningApplied = 'ai2ai_learning_applied';
  static const String learningBuffered = 'ai2ai_learning_buffered';
  static const String peerReceived = 'ai2ai_peer_received';
  static const String peerValidated = 'ai2ai_peer_validated';
  static const String peerConsumed = 'ai2ai_peer_consumed';
  static const String peerApplied = 'ai2ai_peer_applied';
  static const String anomaly = 'ai2ai_anomaly';
}
