import 'dart:convert';
import 'dart:math' as math;

import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class RecommendationTelemetryRecord {
  const RecommendationTelemetryRecord({
    required this.recordId,
    required this.timestamp,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.category,
    required this.reason,
    required this.relevanceScore,
    required this.explanation,
    this.traceRef,
    this.location,
    this.kernelEventId,
    this.modelTruthReady,
    this.localityContainedInWhere,
    this.governanceSummary,
    this.governanceDomains = const <String>[],
  });

  final String recordId;
  final DateTime timestamp;
  final String userId;
  final String eventId;
  final String eventTitle;
  final String category;
  final String reason;
  final double relevanceScore;
  final String? traceRef;
  final String? location;
  final WhySnapshot explanation;
  final String? kernelEventId;
  final bool? modelTruthReady;
  final bool? localityContainedInWhere;
  final String? governanceSummary;
  final List<String> governanceDomains;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'record_id': recordId,
        'ts': timestamp.toUtc().toIso8601String(),
        'user_id': userId,
        'event_id': eventId,
        'event_title': eventTitle,
        'category': category,
        'reason': reason,
        'relevance_score': relevanceScore,
        if (traceRef != null) 'trace_ref': traceRef,
        if (location != null) 'location': location,
        if (kernelEventId != null) 'kernel_event_id': kernelEventId,
        if (modelTruthReady != null) 'model_truth_ready': modelTruthReady,
        if (localityContainedInWhere != null)
          'locality_contained_in_where': localityContainedInWhere,
        if (governanceSummary != null) 'governance_summary': governanceSummary,
        'governance_domains': governanceDomains,
        'explanation': explanation.toJson(),
      };

  factory RecommendationTelemetryRecord.fromJson(Map<String, dynamic> json) {
    return RecommendationTelemetryRecord(
      recordId: json['record_id'] as String? ??
          'rec_${json['event_id'] ?? 'unknown'}_${json['ts'] ?? '0'}',
      timestamp: DateTime.tryParse(json['ts'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: json['user_id'] as String? ?? 'unknown',
      eventId: json['event_id'] as String? ?? 'unknown',
      eventTitle: json['event_title'] as String? ?? 'unknown',
      category: json['category'] as String? ?? 'unknown',
      reason: json['reason'] as String? ?? 'unknown',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      traceRef: json['trace_ref'] as String?,
      location: json['location'] as String?,
      kernelEventId: json['kernel_event_id'] as String?,
      modelTruthReady: json['model_truth_ready'] as bool?,
      localityContainedInWhere: json['locality_contained_in_where'] as bool?,
      governanceSummary: json['governance_summary'] as String?,
      governanceDomains:
          ((json['governance_domains'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      explanation: json['explanation'] is Map
          ? WhySnapshot.fromJson(
              Map<String, dynamic>.from(json['explanation'] as Map),
            )
          : const WhySnapshot(
              goal: 'explain_event_recommendation',
              drivers: <WhySignal>[],
              inhibitors: <WhySignal>[],
              confidence: 0,
              rootCauseType: WhyRootCauseType.unknown,
              summary: 'Missing explanation payload.',
              counterfactuals: <WhyCounterfactual>[],
            ),
    );
  }
}

class RecommendationTelemetryService {
  RecommendationTelemetryService({
    required SharedPreferencesCompat prefs,
    Duration retentionWindow = const Duration(days: 14),
    int maxEvents = 400,
  })  : _prefs = prefs,
        _retentionWindow = retentionWindow,
        _maxEvents = maxEvents;

  static const String _eventsKey = 'event_recommendation_telemetry_v1';

  final SharedPreferencesCompat _prefs;
  final Duration _retentionWindow;
  final int _maxEvents;

  Future<void> recordRecommendations(
    List<RecommendationTelemetryRecord> events,
  ) async {
    if (events.isEmpty) {
      return;
    }
    final existing = _readAll();
    final next = <RecommendationTelemetryRecord>[...existing, ...events];
    await _persistCompacted(next);
  }

  List<RecommendationTelemetryRecord> listAll({int? limit}) {
    final events = _readAll()
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    if (limit == null || events.length <= limit) {
      return events;
    }
    return events.sublist(0, limit);
  }

  RecommendationTelemetryRecord? latest() {
    final all = listAll(limit: 1);
    return all.isEmpty ? null : all.first;
  }

  Future<int> compact() async {
    final before =
        (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    final events = _readAll();
    await _persistCompacted(events);
    final after = (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    return math.max(0, before - after);
  }

  List<RecommendationTelemetryRecord> _readAll() {
    final raw = _prefs.getStringList(_eventsKey) ?? const <String>[];
    final out = <RecommendationTelemetryRecord>[];
    for (final item in raw) {
      try {
        out.add(
          RecommendationTelemetryRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {
        // Ignore malformed records.
      }
    }
    return out;
  }

  Future<void> _persistCompacted(
    List<RecommendationTelemetryRecord> events,
  ) async {
    final threshold = DateTime.now().toUtc().subtract(_retentionWindow);
    final retained = events
        .where((event) => !event.timestamp.isBefore(threshold))
        .toList()
      ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
    final capped = retained.length <= _maxEvents
        ? retained
        : retained.sublist(retained.length - _maxEvents);
    await _prefs.setStringList(
      _eventsKey,
      capped.map((event) => jsonEncode(event.toJson())).toList(),
    );
  }
}
