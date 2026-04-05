import 'dart:async';

import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';

import 'ai2ai_network_activity_event.dart';

/// AI2AI Network Activity Monitor: logs security-relevant events only (no message content).
///
/// Events: routing attempts, connection lifecycle, encryption failures, node discovery,
/// delivery success/failure, anomaly triggers. Persists via LedgerAuditV0 when enabled;
/// always keeps an in-memory buffer for admin real-time stream.
class NetworkActivityMonitor {
  /// Max events to keep in memory for admin dashboard stream.
  static const int maxBufferedEvents = 500;

  /// Anomaly detection: window size (number of recent events to consider).
  static const int _anomalyWindowSize = 50;

  /// Anomaly detection: if failures in window >= this, log anomaly.
  static const int _anomalyFailureThreshold = 10;

  final List<AI2AINetworkActivityEvent> _buffer = [];
  final StreamController<AI2AINetworkActivityEvent> _streamController =
      StreamController<AI2AINetworkActivityEvent>.broadcast();

  /// Last time we emitted an anomaly (to avoid spamming).
  DateTime? _lastAnomalyEmittedAt;
  static const Duration _anomalyCooldown = Duration(minutes: 5);

  /// Stream of recent AI2AI network activity events (for admin Security/Network view).
  Stream<AI2AINetworkActivityEvent> get eventStream => _streamController.stream;

  /// Log an event and optionally persist to LedgerAuditV0 (when enabled).
  void logEvent(AI2AINetworkActivityEvent event) {
    _addToBuffer(event);
    _streamController.add(event);
    _persistIfEnabled(event);
    _checkAnomaly(event);
  }

  /// Simple anomaly detection: spike in failures or delivery_failure in recent window.
  void _checkAnomaly(AI2AINetworkActivityEvent event) {
    if (_buffer.length < _anomalyWindowSize) return;
    final now = DateTime.now().toUtc();
    if (_lastAnomalyEmittedAt != null &&
        now.difference(_lastAnomalyEmittedAt!) < _anomalyCooldown) {
      return;
    }
    final window = _buffer.sublist(_buffer.length - _anomalyWindowSize);
    final failureCount = window
        .where((e) =>
            e.eventType == AI2AINetworkActivityEventType.deliveryFailure ||
            e.eventType == AI2AINetworkActivityEventType.encryptionFailure)
        .length;
    if (failureCount >= _anomalyFailureThreshold) {
      _lastAnomalyEmittedAt = now;
      logEvent(AI2AINetworkActivityEvent(
        eventType: AI2AINetworkActivityEventType.anomaly,
        occurredAt: now,
        reason: 'failure_spike',
        payload: <String, Object?>{
          'failure_count_in_window': failureCount,
          'window_size': _anomalyWindowSize,
        },
      ));
    }
  }

  void _addToBuffer(AI2AINetworkActivityEvent event) {
    _buffer.add(event);
    while (_buffer.length > maxBufferedEvents) {
      _buffer.removeAt(0);
    }
  }

  void _persistIfEnabled(AI2AINetworkActivityEvent event) {
    if (!LedgerAuditV0.isEnabled) return;
    Future.microtask(() => LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: event.eventType,
          occurredAt: event.occurredAt,
          payload: event.toLedgerPayload(),
          entityType: 'ai2ai_network',
          entityId: event.connectionId,
          source: 'network_activity_monitor',
        ));
  }

  /// Get recent events (newest first) for admin dashboard.
  List<AI2AINetworkActivityEvent> getRecentEvents({int limit = 100}) {
    final n = limit.clamp(0, _buffer.length);
    if (n == 0) return [];
    return _buffer.sublist(_buffer.length - n).reversed.toList();
  }

  /// Convenience: log routing attempt.
  void logRoutingAttempt({
    String? connectionId,
    String? remoteNodeId,
    num? hopCount,
    String? reason,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.routingAttempt,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      remoteNodeId: remoteNodeId,
      metric: hopCount,
      reason: reason,
    ));
  }

  /// Convenience: log connection established.
  void logConnectionEstablished({
    required String connectionId,
    String? remoteNodeId,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.connectionEstablished,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      remoteNodeId: remoteNodeId,
    ));
  }

  /// Convenience: log connection closed.
  void logConnectionClosed({
    required String connectionId,
    String? reason,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.connectionClosed,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      reason: reason,
    ));
  }

  /// Convenience: log encryption failure (no message content).
  void logEncryptionFailure({
    String? connectionId,
    String? reason,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.encryptionFailure,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      reason: reason,
    ));
  }

  /// Convenience: log node discovery.
  void logNodeDiscovery({
    String? remoteNodeId,
    String? reason,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.nodeDiscovery,
      occurredAt: DateTime.now().toUtc(),
      remoteNodeId: remoteNodeId,
      reason: reason,
    ));
  }

  /// Convenience: log delivery success.
  void logDeliverySuccess({
    String? connectionId,
    String? remoteNodeId,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.deliverySuccess,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      remoteNodeId: remoteNodeId,
    ));
  }

  /// Convenience: log delivery failure.
  void logDeliveryFailure({
    String? connectionId,
    String? reason,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.deliveryFailure,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      reason: reason,
    ));
  }

  /// Convenience: log anomaly (e.g. spike in failures, unusual routing).
  void logAnomaly({
    required String reason,
    String? connectionId,
    Map<String, Object?>? payload,
  }) {
    logEvent(AI2AINetworkActivityEvent(
      eventType: AI2AINetworkActivityEventType.anomaly,
      occurredAt: DateTime.now().toUtc(),
      connectionId: connectionId,
      reason: reason,
      payload: payload,
    ));
  }

  void dispose() {
    _streamController.close();
  }
}
