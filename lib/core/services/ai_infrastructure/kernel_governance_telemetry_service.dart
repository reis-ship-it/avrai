// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:convert';
import 'dart:math' as math;

import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class KernelGovernanceTelemetryEvent {
  const KernelGovernanceTelemetryEvent({
    required this.timestamp,
    required this.decisionId,
    required this.action,
    required this.mode,
    required this.wouldAllow,
    required this.servingAllowed,
    required this.shadowBypassApplied,
    required this.reasonCodes,
    required this.policyVersion,
    this.correlationId,
    this.modelType,
    this.fromVersion,
    this.toVersion,
  });

  final DateTime timestamp;
  final String decisionId;
  final String action;
  final String mode;
  final bool wouldAllow;
  final bool servingAllowed;
  final bool shadowBypassApplied;
  final List<String> reasonCodes;
  final String policyVersion;
  final String? correlationId;
  final String? modelType;
  final String? fromVersion;
  final String? toVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ts': timestamp.toUtc().toIso8601String(),
        'decision_id': decisionId,
        'action': action,
        'mode': mode,
        'would_allow': wouldAllow,
        'serving_allowed': servingAllowed,
        'shadow_bypass_applied': shadowBypassApplied,
        'reason_codes': reasonCodes,
        'policy_version': policyVersion,
        if (correlationId != null) 'correlation_id': correlationId,
        if (modelType != null) 'model_type': modelType,
        if (fromVersion != null) 'from_version': fromVersion,
        if (toVersion != null) 'to_version': toVersion,
      };

  factory KernelGovernanceTelemetryEvent.fromJson(Map<String, dynamic> json) {
    return KernelGovernanceTelemetryEvent(
      timestamp: DateTime.tryParse(json['ts'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      decisionId: json['decision_id'] as String? ?? 'unknown',
      action: json['action'] as String? ?? 'unknown',
      mode: json['mode'] as String? ?? 'shadow',
      wouldAllow: json['would_allow'] as bool? ?? true,
      servingAllowed: json['serving_allowed'] as bool? ?? true,
      shadowBypassApplied: json['shadow_bypass_applied'] as bool? ?? false,
      reasonCodes: (json['reason_codes'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      policyVersion: json['policy_version'] as String? ?? 'unknown',
      correlationId: json['correlation_id'] as String?,
      modelType: json['model_type'] as String?,
      fromVersion: json['from_version'] as String?,
      toVersion: json['to_version'] as String?,
    );
  }
}

class KernelGovernanceTelemetrySummary {
  const KernelGovernanceTelemetrySummary({
    required this.totalDecisions,
    required this.deniedCount,
    required this.shadowBypassCount,
    required this.byAction,
    required this.topReasonCodes,
  });

  final int totalDecisions;
  final int deniedCount;
  final int shadowBypassCount;
  final Map<String, int> byAction;
  final Map<String, int> topReasonCodes;
}

class KernelGovernanceTelemetryService {
  KernelGovernanceTelemetryService({
    required SharedPreferencesCompat prefs,
    Duration retentionWindow = const Duration(days: 30),
    int maxEvents = 2000,
  })  : _prefs = prefs,
        _retentionWindow = retentionWindow,
        _maxEvents = maxEvents;

  static const String _eventsKey = 'kernel_governance_decisions_v1';

  final SharedPreferencesCompat _prefs;
  final Duration _retentionWindow;
  final int _maxEvents;

  Future<void> recordDecision(KernelGovernanceTelemetryEvent event) async {
    final existing = _readAll();
    final next = <KernelGovernanceTelemetryEvent>[...existing, event];
    await _persistCompacted(next);
  }

  List<KernelGovernanceTelemetryEvent> listRecent({
    Duration window = const Duration(hours: 24),
    int? limit,
  }) {
    final threshold = DateTime.now().toUtc().subtract(window);
    final events = listAll()
        .where((event) => !event.timestamp.isBefore(threshold))
        .toList();
    if (limit == null || events.length <= limit) {
      return events;
    }
    return events.sublist(0, limit);
  }

  List<KernelGovernanceTelemetryEvent> listAll({int? limit}) {
    final events = _readAll()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit == null || events.length <= limit) {
      return events;
    }
    return events.sublist(0, limit);
  }

  Future<int> compact() async {
    final before =
        (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    final events = _readAll();
    await _persistCompacted(events);
    final after = (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    return math.max(0, before - after);
  }

  String exportEventsJson(List<KernelGovernanceTelemetryEvent> events) {
    final payload = events.map((event) => event.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  KernelGovernanceTelemetrySummary summarize({
    Duration window = const Duration(hours: 24),
  }) {
    final events = listRecent(window: window, limit: _maxEvents);
    final byAction = <String, int>{};
    final reasonCounts = <String, int>{};
    int denied = 0;
    int shadowBypass = 0;
    for (final event in events) {
      byAction[event.action] = (byAction[event.action] ?? 0) + 1;
      if (!event.servingAllowed) {
        denied += 1;
      }
      if (event.shadowBypassApplied) {
        shadowBypass += 1;
      }
      for (final reason in event.reasonCodes) {
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }
    }

    final topReasonCodes = Map<String, int>.fromEntries(
      reasonCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..retainWhere((entry) => entry.value > 0),
    );

    return KernelGovernanceTelemetrySummary(
      totalDecisions: events.length,
      deniedCount: denied,
      shadowBypassCount: shadowBypass,
      byAction: byAction,
      topReasonCodes: topReasonCodes,
    );
  }

  List<KernelGovernanceTelemetryEvent> _readAll() {
    final raw = _prefs.getStringList(_eventsKey) ?? const <String>[];
    final out = <KernelGovernanceTelemetryEvent>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        out.add(KernelGovernanceTelemetryEvent.fromJson(decoded));
      } catch (_) {
        // Ignore malformed telemetry records.
      }
    }
    return out;
  }

  Future<void> _persistCompacted(
    List<KernelGovernanceTelemetryEvent> events,
  ) async {
    final threshold = DateTime.now().toUtc().subtract(_retentionWindow);
    final retained = events
        .where((event) => !event.timestamp.isBefore(threshold))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final capped = retained.length <= _maxEvents
        ? retained
        : retained.sublist(retained.length - _maxEvents);
    final encoded = capped.map((event) => jsonEncode(event.toJson())).toList();
    await _prefs.setStringList(_eventsKey, encoded);
  }
}
