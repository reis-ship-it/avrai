import 'dart:developer' as developer;

import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_core/services/event_planning_evidence_factory.dart';
import 'package:avrai_core/services/truth_scope_registry.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_compression_runtime_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:get_it/get_it.dart';

class EventOutcomeNotesPayload extends RawDataPayload {
  final String _rawContent;

  const EventOutcomeNotesPayload({
    required super.capturedAt,
    required super.sourceId,
    required String rawContent,
  }) : _rawContent = rawContent;

  @override
  String get rawContent => _rawContent;
}

class EventLearningSignalService {
  static const String _logName = 'EventLearningSignalService';
  static const TruthScopeRegistry _truthScopeRegistry = TruthScopeRegistry();

  final ContinuousLearningSystem? _continuousLearningSystem;
  final WhatRuntimeIngestionService? _whatIngestion;
  final AirGapContract _airGap;
  final RuntimeAirGapCompressionService _compressionService;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;

  final Map<String, EventCreationLearningSignal> _signalByEventId =
      <String, EventCreationLearningSignal>{};
  final List<EventCreationLearningSignal> _signalHistory =
      <EventCreationLearningSignal>[];

  EventLearningSignalService({
    ContinuousLearningSystem? continuousLearningSystem,
    WhatRuntimeIngestionService? whatIngestion,
    required AirGapContract airGap,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    RuntimeAirGapCompressionService compressionService =
        const RuntimeAirGapCompressionService(),
  })  : _continuousLearningSystem = continuousLearningSystem,
        _whatIngestion = whatIngestion,
        _airGap = airGap,
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _compressionService = compressionService;

  EventCreationLearningSignal? getSignalForEvent(String eventId) =>
      _signalByEventId[eventId];

  List<EventCreationLearningSignal> recentSignals({
    Duration lookbackWindow = const Duration(hours: 24),
    int limit = 100,
    TruthScopeDescriptor? truthScope,
  }) {
    final cutoff = DateTime.now().toUtc().subtract(lookbackWindow);
    final filtered = _signalHistory.where((signal) {
      if (signal.createdAt.toUtc().isBefore(cutoff)) {
        return false;
      }
      if (truthScope != null &&
          signal.truthScope.scopeKey != truthScope.scopeKey) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.take(limit).toList(growable: false);
  }

  Future<EventCreationLearningSignal> recordEventCreated({
    required ExpertiseEvent event,
    required EventPlanningSnapshot snapshot,
  }) async {
    EventPlanningBoundaryGuard.ensureSanitizedSnapshot(
      snapshot,
      context: 'event_creation_learning',
    );
    developer.log(
      'Recording air-gapped event creation learning '
      '[eventId=${event.id}, crossingId=${snapshot.docket.airGapProvenance.crossingId}]',
      name: _logName,
    );

    final payload = _buildBoundedPayload(
      event: event,
      snapshot: snapshot,
      kind: EventLearningSignalKind.eventCreated,
    );
    final planningTruthScope = _planningTruthScopeFor(snapshot);
    final semanticTuples = _buildPlanningSemanticTuples(
      event,
      snapshot,
      EventLearningSignalKind.eventCreated,
    );

    final signalId = _buildSignalId(
      event.id,
      EventLearningSignalKind.eventCreated,
    );
    final evidenceEnvelope = EventPlanningEvidenceFactory.learningSignal(
      signalId: signalId,
      eventId: event.id,
      kind: EventLearningSignalKind.eventCreated,
      snapshot: snapshot,
      tupleRefs: snapshot.docket.airGapProvenance.tupleRefs,
      truthScope: planningTruthScope,
    );
    final compressionBundle = _compressionService.compressSemanticTuples(
      contractId: signalId,
      tuples: semanticTuples,
      environmentId: _compressionService.buildEnvironmentId(
        surface: 'event_learning_created',
        cityCode: event.cityCode,
        localityCode:
            event.localityCode ?? snapshot.docket.candidateLocalityCode,
        scopeKey: planningTruthScope.scopeKey,
      ),
      primaryLayer: AirGapKnowledgeLayer.personal,
      privacyLadderTag: evidenceEnvelope.privacyLadderTag,
      provenanceRefs: snapshot.docket.airGapProvenance.tupleRefs,
      evidenceEnvelope: evidenceEnvelope,
      evidenceLayer:
          _compressionService.knowledgeLayerForScope(planningTruthScope),
      metadata: <String, dynamic>{
        'eventId': event.id,
        'signalKind': EventLearningSignalKind.eventCreated.name,
        'cityCode': event.cityCode,
        'localityCode':
            event.localityCode ?? snapshot.docket.candidateLocalityCode,
      },
    );
    payload['air_gap_compression'] = compressionBundle.toStructuredSignals();
    final signal = EventCreationLearningSignal(
      signalId: signalId,
      eventId: event.id,
      hostUserId: event.host.id,
      kind: EventLearningSignalKind.eventCreated,
      planningSnapshot: snapshot,
      tupleRefs: snapshot.docket.airGapProvenance.tupleRefs,
      boundedPayload: payload,
      createdAt: DateTime.now(),
      truthScope: planningTruthScope,
      evidenceEnvelope: evidenceEnvelope,
      compressedArtifactEnvelope: compressionBundle.primaryEnvelope,
      compressedKnowledgePacket: compressionBundle.knowledgePacket,
      compressionBudgetProfile: compressionBundle.budgetProfile,
    );

    await _recordPersonalLearning(
      userId: event.host.id,
      payload: payload,
      eventType: 'event_planning_created',
    );
    await _recordBoundedEntitySummaries(
      event: event,
      payload: payload,
      tuples: semanticTuples,
    );

    _storeSignal(event.id, signal);
    developer.log(
      'Recorded air-gapped event creation learning '
      '[eventId=${event.id}, tuples=${signal.tupleRefs.length}]',
      name: _logName,
    );
    return signal;
  }

  Future<EventCreationLearningSignal> recordEventOutcome({
    required ExpertiseEvent event,
    required HostEventDebrief debrief,
    String? outcomeNotesRaw,
  }) async {
    final snapshot = event.planningSnapshot;
    if (snapshot == null) {
      throw StateError(
        'Event outcome learning requires an air-gapped planning snapshot.',
      );
    }
    EventPlanningBoundaryGuard.ensureSanitizedSnapshot(
      snapshot,
      context: 'event_outcome_learning',
    );
    final planningTruthScope = _planningTruthScopeFor(snapshot);
    if (debrief.truthScope.scopeKey != planningTruthScope.scopeKey) {
      throw StateError(
        'Host event debrief truth scope must match the planning snapshot.',
      );
    }

    developer.log(
      'Recording air-gapped event outcome learning '
      '[eventId=${event.id}, crossingId=${snapshot.docket.airGapProvenance.crossingId}]',
      name: _logName,
    );

    final notesTupleRefs = await _airGapOutcomeNotesIfPresent(
      eventId: event.id,
      outcomeNotesRaw: outcomeNotesRaw,
    );

    final payload = _buildBoundedPayload(
      event: event,
      snapshot: snapshot,
      kind: EventLearningSignalKind.eventCompleted,
      debrief: debrief,
      notesTupleRefs: notesTupleRefs,
    );

    final signalId = _buildSignalId(
      event.id,
      EventLearningSignalKind.eventCompleted,
    );
    final tupleRefs = <String>[
      ...snapshot.docket.airGapProvenance.tupleRefs,
      ...notesTupleRefs,
    ];
    final evidenceEnvelope = EventPlanningEvidenceFactory.learningSignal(
      signalId: signalId,
      eventId: event.id,
      kind: EventLearningSignalKind.eventCompleted,
      snapshot: snapshot,
      tupleRefs: tupleRefs,
      truthScope: planningTruthScope,
    );
    final semanticTuples = _buildPlanningSemanticTuples(
      event,
      snapshot,
      EventLearningSignalKind.eventCompleted,
      debrief: debrief,
    );
    final compressionBundle = _compressionService.compressSemanticTuples(
      contractId: signalId,
      tuples: semanticTuples,
      environmentId: _compressionService.buildEnvironmentId(
        surface: 'event_learning_completed',
        cityCode: event.cityCode,
        localityCode:
            event.localityCode ?? snapshot.docket.candidateLocalityCode,
        scopeKey: planningTruthScope.scopeKey,
      ),
      primaryLayer: AirGapKnowledgeLayer.personal,
      privacyLadderTag: evidenceEnvelope.privacyLadderTag,
      provenanceRefs: tupleRefs,
      evidenceEnvelope: evidenceEnvelope,
      evidenceLayer:
          _compressionService.knowledgeLayerForScope(planningTruthScope),
      metadata: <String, dynamic>{
        'eventId': event.id,
        'signalKind': EventLearningSignalKind.eventCompleted.name,
        'cityCode': event.cityCode,
        'localityCode':
            event.localityCode ?? snapshot.docket.candidateLocalityCode,
      },
    );
    payload['air_gap_compression'] = compressionBundle.toStructuredSignals();
    final signal = EventCreationLearningSignal(
      signalId: signalId,
      eventId: event.id,
      hostUserId: event.host.id,
      kind: EventLearningSignalKind.eventCompleted,
      planningSnapshot: snapshot,
      tupleRefs: tupleRefs,
      boundedPayload: payload,
      createdAt: DateTime.now(),
      truthScope: planningTruthScope,
      evidenceEnvelope: evidenceEnvelope,
      compressedArtifactEnvelope: compressionBundle.primaryEnvelope,
      compressedKnowledgePacket: compressionBundle.knowledgePacket,
      compressionBudgetProfile: compressionBundle.budgetProfile,
    );

    await _recordPersonalLearning(
      userId: event.host.id,
      payload: payload,
      eventType: 'event_planning_outcome_recorded',
    );
    await _recordBoundedEntitySummaries(
      event: event,
      payload: payload,
      tuples: _buildPlanningSemanticTuples(
        event,
        snapshot,
        signal.kind,
        debrief: debrief,
      ),
    );
    await _stageEventOutcomeUpwardBestEffort(
      event: event,
      signal: signal,
    );

    _storeSignal(event.id, signal);
    developer.log(
      'Recorded air-gapped event outcome learning '
      '[eventId=${event.id}, tuples=${signal.tupleRefs.length}, '
      'outcomeNoteTuples=${notesTupleRefs.length}]',
      name: _logName,
    );
    return signal;
  }

  Future<void> _recordPersonalLearning({
    required String userId,
    required Map<String, dynamic> payload,
    required String eventType,
  }) async {
    final continuousLearningSystem = _continuousLearningSystem;
    if (continuousLearningSystem == null) {
      return;
    }

    await continuousLearningSystem.processUserInteraction(
      userId: userId,
      payload: <String, dynamic>{
        'event_type': eventType,
        'parameters': payload,
        'context': <String, dynamic>{
          'location': <String, dynamic>{
            'candidateLocalityCode': payload['candidate_locality_code'],
          },
        },
        'source': 'event_planning',
      },
    );
  }

  Future<void> _recordBoundedEntitySummaries({
    required ExpertiseEvent event,
    required Map<String, dynamic> payload,
    required List<SemanticTuple> tuples,
  }) async {
    final whatIngestion = _whatIngestion;
    if (whatIngestion == null || tuples.isEmpty) {
      return;
    }

    final observedAt = DateTime.now();

    await whatIngestion.ingestPluginSemanticObservation(
      source: 'event_learning_signal_service',
      entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
        'event_learning',
        <String, Object?>{
          'eventId': event.id,
          'kind': payload['signal_kind'],
        },
      ),
      observedAtUtc: observedAt,
      semanticTuples: tuples,
      structuredSignals: payload,
      locationContext: <String, dynamic>{
        'cityCode': event.cityCode,
        'localityCode':
            event.localityCode ?? payload['candidate_locality_code'],
      },
      activityContext: 'event_planning_learning',
      confidence: 0.72,
      lineageRef: 'event_learning:${event.id}:${payload['signal_kind']}',
    );

    final localityCode =
        event.localityCode ?? payload['candidate_locality_code'] as String?;
    if (localityCode != null && localityCode.isNotEmpty) {
      await whatIngestion.ingestPluginSemanticObservation(
        source: 'event_learning_signal_service',
        entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
          'event_locality_learning',
          <String, Object?>{
            'localityCode': localityCode,
            'category': event.category,
          },
        ),
        observedAtUtc: observedAt,
        semanticTuples: tuples,
        structuredSignals: <String, dynamic>{
          'category': event.category,
          'hostGoal': payload['host_goal'],
          'signal_kind': payload['signal_kind'],
        },
        locationContext: <String, dynamic>{
          'localityCode': localityCode,
        },
        activityContext: 'event_locality_learning',
        confidence: 0.66,
        lineageRef: 'event_locality:${event.id}:$localityCode',
      );
    }

    for (final spot in event.spots) {
      await _recordSpotSummary(
        observedAt: observedAt,
        spot: spot,
        payload: payload,
        tuples: tuples,
      );
    }
  }

  Future<void> _recordSpotSummary({
    required DateTime observedAt,
    required Spot spot,
    required Map<String, dynamic> payload,
    required List<SemanticTuple> tuples,
  }) async {
    final whatIngestion = _whatIngestion;
    if (whatIngestion == null) {
      return;
    }

    await whatIngestion.ingestPluginSemanticObservation(
      source: 'event_learning_signal_service',
      entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
        'event_spot_learning',
        <String, Object?>{
          'spotId': spot.id,
          'signal_kind': payload['signal_kind'],
        },
      ),
      observedAtUtc: observedAt,
      semanticTuples: tuples,
      structuredSignals: <String, dynamic>{
        'spotId': spot.id,
        'category': spot.category,
        'signal_kind': payload['signal_kind'],
        'host_goal': payload['host_goal'],
      },
      locationContext: <String, dynamic>{
        'cityCode': spot.cityCode,
        'localityCode': spot.localityCode,
      },
      activityContext: 'event_spot_learning',
      confidence: 0.62,
      lineageRef: 'event_spot:${spot.id}:${payload['signal_kind']}',
    );

    final businessId = spot.metadata['businessId'] ?? spot.metadata['venueId'];
    if (businessId is! String || businessId.isEmpty) {
      return;
    }

    await whatIngestion.ingestPluginSemanticObservation(
      source: 'event_learning_signal_service',
      entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
        'event_business_learning',
        <String, Object?>{
          'businessId': businessId,
          'signal_kind': payload['signal_kind'],
        },
      ),
      observedAtUtc: observedAt,
      semanticTuples: tuples,
      structuredSignals: <String, dynamic>{
        'businessId': businessId,
        'signal_kind': payload['signal_kind'],
        'host_goal': payload['host_goal'],
      },
      locationContext: <String, dynamic>{
        'cityCode': spot.cityCode,
        'localityCode': spot.localityCode,
      },
      activityContext: 'event_business_learning',
      confidence: 0.6,
      lineageRef: 'event_business:$businessId:${payload['signal_kind']}',
    );
  }

  Future<List<String>> _airGapOutcomeNotesIfPresent({
    required String eventId,
    required String? outcomeNotesRaw,
  }) async {
    if (outcomeNotesRaw == null || outcomeNotesRaw.trim().isEmpty) {
      return const <String>[];
    }

    final tuples = await _airGap.scrubAndExtract(
      EventOutcomeNotesPayload(
        capturedAt: DateTime.now(),
        sourceId: 'event_outcome_notes',
        rawContent:
            'EVENT_OUTCOME_NOTES:\neventId=$eventId\nnotes=$outcomeNotesRaw',
      ),
    );
    developer.log(
      'Outcome notes crossed the air gap '
      '[eventId=$eventId, tuples=${tuples.length}]',
      name: _logName,
    );
    return tuples.map((tuple) => tuple.id).toList(growable: false);
  }

  Map<String, dynamic> _buildBoundedPayload({
    required ExpertiseEvent event,
    required EventPlanningSnapshot snapshot,
    required EventLearningSignalKind kind,
    HostEventDebrief? debrief,
    List<String> notesTupleRefs = const <String>[],
  }) {
    final planningTruthScope = _planningTruthScopeFor(snapshot);
    return <String, dynamic>{
      'signal_kind': kind.name,
      'event_id': event.id,
      'planning_scope_key': planningTruthScope.scopeKey,
      'planning_truth_scope': planningTruthScope.toJson(),
      'event_category': event.category,
      'event_type': event.eventType.name,
      'host_goal': snapshot.docket.hostGoal.name,
      'size_intent': snapshot.docket.sizeIntent.name,
      'price_intent': snapshot.docket.priceIntent.name,
      'candidate_locality_code':
          snapshot.docket.candidateLocalityCode ?? event.localityCode,
      'candidate_locality_label': snapshot.docket.candidateLocalityLabel,
      'intent_tags': snapshot.docket.intentTags,
      'vibe_tags': snapshot.docket.vibeTags,
      'audience_tags': snapshot.docket.audienceTags,
      'accepted_suggestion': snapshot.acceptedSuggestion != null,
      'predicted_fill_band':
          snapshot.acceptedSuggestion?.predictedAttendanceFillBand.name,
      'suggested_max_attendees':
          snapshot.acceptedSuggestion?.suggestedMaxAttendees,
      'suggested_price': snapshot.acceptedSuggestion?.suggestedPrice,
      'selected_spot_ids': event.spots.map((spot) => spot.id).toList(),
      'selected_business_ids': event.spots
          .map(
              (spot) => spot.metadata['businessId'] ?? spot.metadata['venueId'])
          .whereType<String>()
          .toSet()
          .toList(),
      'actual_attendance': debrief?.actualAttendance,
      'attendance_rate': debrief?.attendanceRate,
      'average_rating': debrief?.averageRating,
      'would_attend_again_rate': debrief?.wouldAttendAgainRate,
      'insight_count': debrief?.insightLines.length ?? 0,
      'outcome_note_tuple_count': notesTupleRefs.length,
    };
  }

  List<SemanticTuple> _buildPlanningSemanticTuples(
    ExpertiseEvent event,
    EventPlanningSnapshot snapshot,
    EventLearningSignalKind kind, {
    HostEventDebrief? debrief,
  }) {
    final tuples = <SemanticTuple>[
      _tuple(
        id: '${event.id}-${kind.name}-goal',
        category: 'event_planning',
        subject: 'event:${event.id}',
        predicate: 'host_goal',
        object: snapshot.docket.hostGoal.name,
      ),
      _tuple(
        id: '${event.id}-${kind.name}-size',
        category: 'event_planning',
        subject: 'event:${event.id}',
        predicate: 'size_intent',
        object: snapshot.docket.sizeIntent.name,
      ),
      _tuple(
        id: '${event.id}-${kind.name}-price',
        category: 'event_planning',
        subject: 'event:${event.id}',
        predicate: 'price_intent',
        object: snapshot.docket.priceIntent.name,
      ),
    ];

    for (final tag in snapshot.docket.intentTags.take(3)) {
      tuples.add(
        _tuple(
          id: '${event.id}-${kind.name}-intent-$tag',
          category: 'event_planning',
          subject: 'event:${event.id}',
          predicate: 'intent_tag',
          object: tag,
        ),
      );
    }

    for (final tag in snapshot.docket.vibeTags.take(3)) {
      tuples.add(
        _tuple(
          id: '${event.id}-${kind.name}-vibe-$tag',
          category: 'event_planning',
          subject: 'event:${event.id}',
          predicate: 'vibe_tag',
          object: tag,
        ),
      );
    }

    if (debrief != null) {
      tuples.add(
        _tuple(
          id: '${event.id}-${kind.name}-attendance',
          category: 'event_outcome',
          subject: 'event:${event.id}',
          predicate: 'attendance_fill_band_actual',
          object: _actualFillBand(debrief.attendanceRate).name,
        ),
      );
      tuples.add(
        _tuple(
          id: '${event.id}-${kind.name}-rating',
          category: 'event_outcome',
          subject: 'event:${event.id}',
          predicate: 'average_rating_band',
          object: _ratingBand(debrief.averageRating),
        ),
      );
    }

    return tuples;
  }

  EventAttendanceFillBand _actualFillBand(double attendanceRate) {
    if (attendanceRate >= 0.75) {
      return EventAttendanceFillBand.high;
    }
    if (attendanceRate >= 0.4) {
      return EventAttendanceFillBand.medium;
    }
    return EventAttendanceFillBand.low;
  }

  String _ratingBand(double averageRating) {
    if (averageRating >= 4.4) {
      return 'strong';
    }
    if (averageRating >= 3.5) {
      return 'mixed_positive';
    }
    return 'needs_improvement';
  }

  SemanticTuple _tuple({
    required String id,
    required String category,
    required String subject,
    required String predicate,
    required String object,
  }) {
    return SemanticTuple(
      id: id,
      category: category,
      subject: subject,
      predicate: predicate,
      object: object,
      confidence: 0.8,
      extractedAt: DateTime.now(),
    );
  }

  String _buildSignalId(String eventId, EventLearningSignalKind kind) {
    return 'event_learning_${eventId}_${kind.name}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _stageEventOutcomeUpwardBestEffort({
    required ExpertiseEvent event,
    required EventCreationLearningSignal signal,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'event_outcome_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'event_outcome_intake',
          'eventId': event.id,
          'signalKind': signal.kind.name,
          ...signal.boundedPayload,
        },
      );
      await service.stageEventOutcomeIntake(
        event: event,
        signal: signal,
        airGapArtifact: airGapArtifact,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Event outcome upward learning staging skipped: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _storeSignal(String eventId, EventCreationLearningSignal signal) {
    _signalByEventId[eventId] = signal;
    _signalHistory.add(signal);
    if (_signalHistory.length > 250) {
      _signalHistory.removeAt(0);
    }
  }

  TruthScopeDescriptor _planningTruthScopeFor(EventPlanningSnapshot snapshot) {
    return _truthScopeRegistry.normalizePlanningScope(
      scope: snapshot.truthScope,
      familyId: snapshot.truthScope.familyId,
      metadata: <String, dynamic>{
        'governance_stratum': snapshot.truthScope.governanceStratum.name,
        'planning_sphere_id': snapshot.truthScope.sphereId,
        'planning_family_id': snapshot.truthScope.familyId,
        'agent_class': snapshot.truthScope.agentClass.name,
      },
    );
  }
}
