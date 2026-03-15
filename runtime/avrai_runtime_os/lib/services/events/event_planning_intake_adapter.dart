import 'dart:developer' as developer;

import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/services/event_planning_evidence_factory.dart';
import 'package:avrai_core/services/truth_scope_registry.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';

class EventPlanningPayload extends RawDataPayload {
  final String _rawContent;

  const EventPlanningPayload({
    required super.capturedAt,
    required super.sourceId,
    required String rawContent,
  }) : _rawContent = rawContent;

  @override
  String get rawContent => _rawContent;
}

class EventPlanningIntakeAdapter {
  static const String _logName = 'EventPlanningIntakeAdapter';
  static const TruthScopeRegistry _truthScopeRegistry = TruthScopeRegistry();

  final AirGapContract _airGap;
  final WhatRuntimeIngestionService? _whatIngestion;
  final GeoHierarchyService? _geoHierarchyService;
  final EventPlanningTelemetryService? _telemetryService;

  EventPlanningIntakeAdapter(
    this._airGap, {
    WhatRuntimeIngestionService? whatIngestion,
    GeoHierarchyService? geoHierarchyService,
    EventPlanningTelemetryService? telemetryService,
  })  : _whatIngestion = whatIngestion,
        _geoHierarchyService = geoHierarchyService,
        _telemetryService = telemetryService;

  Future<EventPlanningAirGapResult> ingestPlanningInput({
    required String ownerUserId,
    required RawEventPlanningInput input,
    TruthScopeDescriptor? truthScope,
  }) async {
    final capturedAt = DateTime.now();
    final crossingId = _buildCrossingId(
      ownerUserId: ownerUserId,
      sourceKind: input.sourceKind,
      capturedAt: capturedAt,
    );
    final payload = EventPlanningPayload(
      capturedAt: capturedAt,
      sourceId: 'event_planning_${input.sourceKind.name}',
      rawContent: _serializeRawInput(input),
    );

    developer.log(
      'Crossing event planning input through air gap '
      '[crossingId=$crossingId, source=${input.sourceKind.name}]',
      name: _logName,
    );

    final tuples = await _airGap.scrubAndExtract(payload);
    final tupleRefs = tuples.map((tuple) => tuple.id).toList(growable: false);
    final confidence = _deriveConfidence(input);
    final localityLabel = _normalizeLocalityLabel(input.candidateLocalityLabel);
    final localityCode = await _resolveLocalityCode(localityLabel);
    final planningTruthScope = _resolvePlanningTruthScope(
      input: input,
      localityCode: localityCode,
      truthScope: truthScope,
    );

    final docket = EventDocketLite(
      intentTags: _extractTags(input.purposeText),
      vibeTags: _extractTags(input.vibeText),
      audienceTags: _extractTags(input.targetAudienceText),
      candidateLocalityLabel: localityLabel,
      candidateLocalityCode: localityCode,
      preferredStartDate: input.preferredStartDate,
      preferredEndDate: input.preferredEndDate,
      sizeIntent: input.sizeIntent,
      priceIntent: input.priceIntent,
      hostGoal: input.hostGoal,
      airGapProvenance: EventAirGapProvenance(
        crossingId: crossingId,
        crossedAt: payload.capturedAt,
        sourceKind: input.sourceKind,
        tupleRefs: tupleRefs,
        confidence: confidence,
      ),
    );
    EventPlanningBoundaryGuard.ensureSanitizedDocket(
      docket,
      context: 'event_planning_intake',
    );
    final evidenceEnvelope = EventPlanningEvidenceFactory.airGapResult(
      docket: docket,
      confidence: confidence,
      sourceKind: input.sourceKind,
      truthScope: planningTruthScope,
    );

    developer.log(
      'Air-gap crossing completed '
      '[crossingId=$crossingId, tuples=${tupleRefs.length}, '
      'confidence=${confidence.name}, locality=${localityCode ?? localityLabel ?? "none"}]',
      name: _logName,
    );

    final whatIngestion = _whatIngestion;
    if (whatIngestion != null && tuples.isNotEmpty) {
      await whatIngestion.ingestPluginSemanticObservation(
        source: 'event_planning_intake_adapter',
        entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
          'event_planning',
          <String, Object?>{
            'ownerUserId': ownerUserId,
            'sourceKind': input.sourceKind.name,
            'locality': localityLabel ?? 'unknown',
          },
        ),
        observedAtUtc: payload.capturedAt,
        semanticTuples: tuples,
        structuredSignals: _boundedSignalsFromDocket(
          docket,
          truthScope: planningTruthScope,
        ),
        locationContext: <String, dynamic>{
          'candidateLocalityLabel': docket.candidateLocalityLabel,
          'candidateLocalityCode': docket.candidateLocalityCode,
        },
        temporalContext: <String, dynamic>{
          'preferredStartDate': docket.preferredStartDate?.toIso8601String(),
          'preferredEndDate': docket.preferredEndDate?.toIso8601String(),
        },
        activityContext: 'event_planning',
        confidence: switch (confidence) {
          EventPlanningConfidence.high => 0.85,
          EventPlanningConfidence.medium => 0.65,
          EventPlanningConfidence.low => 0.45,
        },
        lineageRef: 'event_plan:$crossingId',
      );
    }

    final EventPlanningTelemetryService? telemetryService = _telemetryService;
    if (telemetryService != null) {
      await telemetryService.recordAirGapCrossed(
        airGapResult: EventPlanningAirGapResult(
          docket: docket,
          confidence: confidence,
          tupleRefs: tupleRefs,
          sourceKind: input.sourceKind,
          truthScope: planningTruthScope,
          evidenceEnvelope: evidenceEnvelope,
        ),
      );
    }

    return EventPlanningAirGapResult(
      docket: docket,
      confidence: confidence,
      tupleRefs: tupleRefs,
      sourceKind: input.sourceKind,
      truthScope: planningTruthScope,
      evidenceEnvelope: evidenceEnvelope,
    );
  }

  String? _normalizeLocalityLabel(String rawLabel) {
    final normalized = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? null : normalized;
  }

  String _buildCrossingId({
    required String ownerUserId,
    required EventPlanningSourceKind sourceKind,
    required DateTime capturedAt,
  }) {
    final ownerToken = ownerUserId
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .padRight(8, '0');
    final ownerSuffix = ownerToken.substring(0, 8);
    return 'evtplan_${capturedAt.microsecondsSinceEpoch}_${sourceKind.name}_$ownerSuffix';
  }

  Map<String, dynamic> _boundedSignalsFromDocket(
    EventDocketLite docket, {
    required TruthScopeDescriptor truthScope,
  }) {
    return <String, dynamic>{
      'airGapCrossingId': docket.airGapProvenance.crossingId,
      'intentTags': docket.intentTags,
      'vibeTags': docket.vibeTags,
      'audienceTags': docket.audienceTags,
      'candidateLocalityCode': docket.candidateLocalityCode,
      'sizeIntent': docket.sizeIntent.name,
      'priceIntent': docket.priceIntent.name,
      'hostGoal': docket.hostGoal.name,
      'airGapTupleCount': docket.airGapProvenance.tupleRefs.length,
      'planningScopeKey': truthScope.scopeKey,
      'planningTruthScope': truthScope.toJson(),
    };
  }

  EventPlanningConfidence _deriveConfidence(RawEventPlanningInput input) {
    var signals = 0;
    if (input.purposeText.trim().isNotEmpty) {
      signals += 1;
    }
    if (input.vibeText.trim().isNotEmpty) {
      signals += 1;
    }
    if (input.targetAudienceText.trim().isNotEmpty) {
      signals += 1;
    }
    if (input.candidateLocalityLabel.trim().isNotEmpty) {
      signals += 1;
    }
    if (input.preferredStartDate != null || input.preferredEndDate != null) {
      signals += 1;
    }

    if (signals >= 4) {
      return EventPlanningConfidence.high;
    }
    if (signals >= 2) {
      return EventPlanningConfidence.medium;
    }
    return EventPlanningConfidence.low;
  }

  List<String> _extractTags(String raw) {
    const stopWords = <String>{
      'about',
      'after',
      'around',
      'because',
      'event',
      'from',
      'into',
      'that',
      'this',
      'with',
      'your',
      'ours',
      'have',
      'will',
      'want',
      'would',
      'there',
      'their',
      'them',
      'more',
      'than',
      'some',
      'just',
      'really',
      'very',
      'like',
    };

    final words = RegExp(r"[a-zA-Z0-9']+")
        .allMatches(raw.toLowerCase())
        .map((match) => match.group(0)!)
        .where((word) => word.length >= 3 && !stopWords.contains(word))
        .toList();

    final seen = <String>{};
    final tags = <String>[];
    for (final word in words) {
      if (seen.add(word)) {
        tags.add(word);
      }
      if (tags.length == 6) {
        break;
      }
    }
    return tags;
  }

  Future<String?> _resolveLocalityCode(String? localityLabel) async {
    if (_geoHierarchyService == null ||
        localityLabel == null ||
        localityLabel.isEmpty) {
      return null;
    }

    try {
      final geoHierarchyService = _geoHierarchyService;
      final cityCode = await geoHierarchyService.lookupCityCode(localityLabel);
      if (cityCode == null || cityCode.isEmpty) {
        return null;
      }
      return geoHierarchyService.lookupLocalityCode(
        cityCode: cityCode,
        localityName: localityLabel,
      );
    } catch (_) {
      return null;
    }
  }

  TruthScopeDescriptor _resolvePlanningTruthScope({
    required RawEventPlanningInput input,
    required String? localityCode,
    TruthScopeDescriptor? truthScope,
  }) {
    return _truthScopeRegistry.normalizePlanningScope(
      scope: truthScope,
      familyId: 'creator_event_prep_${input.sourceKind.name}',
      metadata: <String, dynamic>{
        'governance_stratum': localityCode == null ? 'personal' : 'locality',
        'planning_sphere_id':
            localityCode == null ? 'event_planning' : 'event_planning_locality',
        'planning_family_id': 'creator_event_prep_${input.sourceKind.name}',
        'agent_class': TruthAgentClass.organizer.name,
      },
    );
  }

  String _serializeRawInput(RawEventPlanningInput input) {
    return '''
EVENT_PLANNING_INPUT:
source_kind=${input.sourceKind.name}
purpose=${input.purposeText.trim()}
vibe=${input.vibeText.trim()}
target_audience=${input.targetAudienceText.trim()}
candidate_locality=${input.candidateLocalityLabel.trim()}
preferred_start=${input.preferredStartDate?.toIso8601String() ?? ''}
preferred_end=${input.preferredEndDate?.toIso8601String() ?? ''}
size_intent=${input.sizeIntent.name}
price_intent=${input.priceIntent.name}
host_goal=${input.hostGoal.name}
''';
  }
}
