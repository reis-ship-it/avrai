import 'dart:convert';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class RealityGroupingAuditService {
  static const String _keyPrefix = 'admin_reality_grouping_audit_v1_';
  static const int _maxEventsPerLayer = 400;

  Future<void> recordEvent({
    required String layer,
    required String action,
    required String grouping,
    required String actor,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final key = '$_keyPrefix$layer';

    final existing = prefs.getStringList(key) ?? const <String>[];
    final event = RealityGroupingAuditEvent(
      layer: layer,
      action: action,
      grouping: grouping,
      actor: actor,
      timestamp: DateTime.now().toUtc(),
      metadata: metadata ?? const <String, dynamic>{},
    );

    final updated = <String>[jsonEncode(event.toJson()), ...existing]
        .take(_maxEventsPerLayer)
        .toList();

    await prefs.setStringList(key, updated);
  }

  Future<List<RealityGroupingAuditEvent>> getRecentEvents({
    required String layer,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final key = '$_keyPrefix$layer';
    final raw = prefs.getStringList(key) ?? const <String>[];

    final events = <RealityGroupingAuditEvent>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        events.add(RealityGroupingAuditEvent.fromJson(decoded));
      } catch (_) {
        // Ignore malformed entries.
      }
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(limit).toList();
  }
}

class RealityGroupingAuditEvent {
  const RealityGroupingAuditEvent({
    required this.layer,
    required this.action,
    required this.grouping,
    required this.actor,
    required this.timestamp,
    required this.metadata,
  });

  final String layer;
  final String action;
  final String grouping;
  final String actor;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'layer': layer,
      'action': action,
      'grouping': grouping,
      'actor': actor,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory RealityGroupingAuditEvent.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    return RealityGroupingAuditEvent(
      layer: json['layer'] as String? ?? 'unknown',
      action: json['action'] as String? ?? 'unknown',
      grouping: json['grouping'] as String? ?? 'unknown',
      actor: json['actor'] as String? ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      metadata: metadataRaw is Map<String, dynamic>
          ? metadataRaw
          : const <String, dynamic>{},
    );
  }
}
