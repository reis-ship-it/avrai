import 'dart:convert';
import 'dart:math' as math;

import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

enum EventPlanningTelemetryKind {
  airGapCrossed,
  lowConfidenceSuggestionShown,
  suggestionAccepted,
  eventCreated,
  debriefCompleted,
}

class EventPlanningTelemetryRecord {
  const EventPlanningTelemetryRecord({
    required this.recordId,
    required this.timestamp,
    required this.kind,
    required this.sourceKind,
    required this.crossingId,
    required this.confidence,
    required this.truthScopeKey,
    this.localityCode,
    this.cityCode,
    this.eventId,
  });

  final String recordId;
  final DateTime timestamp;
  final EventPlanningTelemetryKind kind;
  final EventPlanningSourceKind sourceKind;
  final String crossingId;
  final EventPlanningConfidence confidence;
  final String truthScopeKey;
  final String? localityCode;
  final String? cityCode;
  final String? eventId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'record_id': recordId,
        'ts': timestamp.toUtc().toIso8601String(),
        'kind': kind.name,
        'source_kind': sourceKind.name,
        'crossing_id': crossingId,
        'confidence': confidence.name,
        'truth_scope_key': truthScopeKey,
        if (localityCode != null) 'locality_code': localityCode,
        if (cityCode != null) 'city_code': cityCode,
        if (eventId != null) 'event_id': eventId,
      };

  factory EventPlanningTelemetryRecord.fromJson(Map<String, dynamic> json) {
    return EventPlanningTelemetryRecord(
      recordId: json['record_id'] as String? ??
          'event_plan_record_${json['ts'] ?? '0'}',
      timestamp: DateTime.tryParse(json['ts'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      kind: EventPlanningTelemetryKind.values.firstWhere(
        (EventPlanningTelemetryKind value) => value.name == json['kind'],
        orElse: () => EventPlanningTelemetryKind.airGapCrossed,
      ),
      sourceKind: EventPlanningSourceKind.values.firstWhere(
        (EventPlanningSourceKind value) => value.name == json['source_kind'],
        orElse: () => EventPlanningSourceKind.human,
      ),
      crossingId: json['crossing_id'] as String? ?? 'unknown_crossing',
      confidence: EventPlanningConfidence.values.firstWhere(
        (EventPlanningConfidence value) => value.name == json['confidence'],
        orElse: () => EventPlanningConfidence.low,
      ),
      truthScopeKey: json['truth_scope_key'] as String? ?? 'planning:default',
      localityCode: json['locality_code'] as String?,
      cityCode: json['city_code'] as String?,
      eventId: json['event_id'] as String?,
    );
  }
}

class EventPlanningTelemetrySummary {
  const EventPlanningTelemetrySummary({
    required this.airGapCrossings,
    required this.lowConfidenceSuggestions,
    required this.suggestionAcceptances,
    required this.eventsCreated,
    required this.debriefCompletions,
    required this.lowConfidenceRate,
    required this.suggestionAcceptanceRate,
    required this.debriefCompletionRate,
  });

  final int airGapCrossings;
  final int lowConfidenceSuggestions;
  final int suggestionAcceptances;
  final int eventsCreated;
  final int debriefCompletions;
  final double lowConfidenceRate;
  final double suggestionAcceptanceRate;
  final double debriefCompletionRate;
}

class EventPlanningTelemetryService {
  EventPlanningTelemetryService({
    required SharedPreferencesCompat prefs,
    Duration retentionWindow = const Duration(days: 14),
    int maxEvents = 400,
  })  : _prefs = prefs,
        _retentionWindow = retentionWindow,
        _maxEvents = maxEvents;

  static const String _eventsKey = 'event_planning_telemetry_v1';

  final SharedPreferencesCompat _prefs;
  final Duration _retentionWindow;
  final int _maxEvents;

  Future<void> recordAirGapCrossed({
    required EventPlanningAirGapResult airGapResult,
    String? cityCode,
    String? eventId,
  }) {
    return _record(
      kind: EventPlanningTelemetryKind.airGapCrossed,
      docket: airGapResult.docket,
      confidence: airGapResult.confidence,
      truthScopeKey: airGapResult.truthScope.scopeKey,
      cityCode: cityCode,
      eventId: eventId,
    );
  }

  Future<void> recordLowConfidenceSuggestion({
    required EventPlanningAirGapResult airGapResult,
    required EventCreationSuggestion suggestion,
    String? cityCode,
    String? eventId,
  }) {
    return _record(
      kind: EventPlanningTelemetryKind.lowConfidenceSuggestionShown,
      docket: airGapResult.docket,
      confidence: suggestion.confidence,
      truthScopeKey: suggestion.truthScope.scopeKey,
      cityCode: cityCode,
      eventId: eventId,
    );
  }

  Future<void> recordSuggestionAccepted({
    required EventPlanningAirGapResult airGapResult,
    required EventCreationSuggestion suggestion,
    String? cityCode,
    String? eventId,
  }) {
    return _record(
      kind: EventPlanningTelemetryKind.suggestionAccepted,
      docket: airGapResult.docket,
      confidence: suggestion.confidence,
      truthScopeKey: suggestion.truthScope.scopeKey,
      cityCode: cityCode,
      eventId: eventId,
    );
  }

  Future<void> recordEventCreated({
    required ExpertiseEvent event,
  }) {
    final snapshot = event.planningSnapshot;
    if (snapshot == null) {
      return Future<void>.value();
    }
    EventPlanningBoundaryGuard.ensureSanitizedSnapshot(
      snapshot,
      context: 'event_planning_telemetry_created',
    );
    return _record(
      kind: EventPlanningTelemetryKind.eventCreated,
      docket: snapshot.docket,
      confidence: snapshot.acceptedSuggestion?.confidence ??
          snapshot.docket.airGapProvenance.confidence,
      truthScopeKey: snapshot.truthScope.scopeKey,
      cityCode: event.cityCode,
      eventId: event.id,
    );
  }

  Future<void> recordDebriefCompleted({
    required ExpertiseEvent event,
    required HostEventDebrief debrief,
  }) {
    final snapshot = event.planningSnapshot;
    if (snapshot == null) {
      return Future<void>.value();
    }
    EventPlanningBoundaryGuard.ensureSanitizedSnapshot(
      snapshot,
      context: 'event_planning_telemetry_debrief',
    );
    return _record(
      kind: EventPlanningTelemetryKind.debriefCompleted,
      docket: snapshot.docket,
      confidence: snapshot.acceptedSuggestion?.confidence ??
          snapshot.docket.airGapProvenance.confidence,
      truthScopeKey: debrief.truthScope.scopeKey,
      cityCode: event.cityCode,
      eventId: event.id,
    );
  }

  List<EventPlanningTelemetryRecord> listAll({int? limit}) {
    final List<EventPlanningTelemetryRecord> events = _readAll()
      ..sort(
        (EventPlanningTelemetryRecord left,
                EventPlanningTelemetryRecord right) =>
            right.timestamp.compareTo(left.timestamp),
      );
    if (limit == null || events.length <= limit) {
      return events;
    }
    return events.sublist(0, limit);
  }

  EventPlanningTelemetryRecord? latest() {
    final List<EventPlanningTelemetryRecord> all = listAll(limit: 1);
    return all.isEmpty ? null : all.first;
  }

  EventPlanningTelemetrySummary summarize() {
    final List<EventPlanningTelemetryRecord> events = _readAll();
    final int airGapCrossings = events
        .where((EventPlanningTelemetryRecord event) =>
            event.kind == EventPlanningTelemetryKind.airGapCrossed)
        .length;
    final int lowConfidenceSuggestions = events
        .where((EventPlanningTelemetryRecord event) =>
            event.kind ==
            EventPlanningTelemetryKind.lowConfidenceSuggestionShown)
        .length;
    final int suggestionAcceptances = events
        .where((EventPlanningTelemetryRecord event) =>
            event.kind == EventPlanningTelemetryKind.suggestionAccepted)
        .length;
    final int eventsCreated = events
        .where((EventPlanningTelemetryRecord event) =>
            event.kind == EventPlanningTelemetryKind.eventCreated)
        .length;
    final int debriefCompletions = events
        .where((EventPlanningTelemetryRecord event) =>
            event.kind == EventPlanningTelemetryKind.debriefCompleted)
        .length;

    return EventPlanningTelemetrySummary(
      airGapCrossings: airGapCrossings,
      lowConfidenceSuggestions: lowConfidenceSuggestions,
      suggestionAcceptances: suggestionAcceptances,
      eventsCreated: eventsCreated,
      debriefCompletions: debriefCompletions,
      lowConfidenceRate: airGapCrossings == 0
          ? 0
          : lowConfidenceSuggestions / airGapCrossings,
      suggestionAcceptanceRate: airGapCrossings == 0
          ? 0
          : suggestionAcceptances / airGapCrossings,
      debriefCompletionRate:
          eventsCreated == 0 ? 0 : debriefCompletions / eventsCreated,
    );
  }

  Future<int> compact() async {
    final int before =
        (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    final List<EventPlanningTelemetryRecord> events = _readAll();
    await _persistCompacted(events);
    final int after =
        (_prefs.getStringList(_eventsKey) ?? const <String>[]).length;
    return math.max(0, before - after);
  }

  Future<void> _record({
    required EventPlanningTelemetryKind kind,
    required EventDocketLite docket,
    required EventPlanningConfidence confidence,
    required String truthScopeKey,
    String? cityCode,
    String? eventId,
  }) async {
    EventPlanningBoundaryGuard.ensureSanitizedDocket(
      docket,
      context: 'event_planning_telemetry',
    );
    final DateTime timestamp = DateTime.now().toUtc();
    final EventPlanningTelemetryRecord record = EventPlanningTelemetryRecord(
      recordId:
          'evt_telemetry_${kind.name}_${timestamp.microsecondsSinceEpoch}',
      timestamp: timestamp,
      kind: kind,
      sourceKind: docket.airGapProvenance.sourceKind,
      crossingId: docket.airGapProvenance.crossingId,
      confidence: confidence,
      truthScopeKey: truthScopeKey,
      localityCode: docket.candidateLocalityCode,
      cityCode: cityCode,
      eventId: eventId,
    );

    final List<EventPlanningTelemetryRecord> next = <EventPlanningTelemetryRecord>[
      ..._readAll(),
      record,
    ];
    await _persistCompacted(next);
  }

  List<EventPlanningTelemetryRecord> _readAll() {
    final List<String> raw =
        _prefs.getStringList(_eventsKey) ?? const <String>[];
    final List<EventPlanningTelemetryRecord> out =
        <EventPlanningTelemetryRecord>[];
    for (final String item in raw) {
      try {
        out.add(
          EventPlanningTelemetryRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {
        // Ignore malformed telemetry records.
      }
    }
    return out;
  }

  Future<void> _persistCompacted(
    List<EventPlanningTelemetryRecord> events,
  ) async {
    final DateTime threshold = DateTime.now().toUtc().subtract(_retentionWindow);
    final List<EventPlanningTelemetryRecord> retained = events
        .where(
          (EventPlanningTelemetryRecord event) =>
              !event.timestamp.isBefore(threshold),
        )
        .toList()
      ..sort(
        (EventPlanningTelemetryRecord left,
                EventPlanningTelemetryRecord right) =>
            left.timestamp.compareTo(right.timestamp),
      );
    final List<EventPlanningTelemetryRecord> capped =
        retained.length <= _maxEvents
            ? retained
            : retained.sublist(retained.length - _maxEvents);
    await _prefs.setStringList(
      _eventsKey,
      capped
          .map(
            (EventPlanningTelemetryRecord event) => jsonEncode(event.toJson()),
          )
          .toList(),
    );
  }
}
