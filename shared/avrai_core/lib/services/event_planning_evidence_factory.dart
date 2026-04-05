import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class EventPlanningEvidenceFactory {
  const EventPlanningEvidenceFactory._();

  static TruthEvidenceEnvelope airGapResult({
    required EventDocketLite docket,
    required EventPlanningConfidence confidence,
    required EventPlanningSourceKind sourceKind,
    required TruthScopeDescriptor truthScope,
  }) {
    return TruthEvidenceEnvelope(
      scope: truthScope,
      traceId: docket.airGapProvenance.crossingId,
      evidenceClass: 'planning_air_gap_result',
      privacyLadderTag: 'air_gap_redacted',
      sourceRefs: <String>[
        docket.airGapProvenance.crossingId,
        ...docket.airGapProvenance.tupleRefs,
      ],
      metadata: <String, dynamic>{
        'sourceKind': sourceKind.name,
        'confidence': confidence.name,
        'tupleRefCount': docket.airGapProvenance.tupleRefs.length,
        'candidateLocalityCode': docket.candidateLocalityCode,
        'hostGoal': docket.hostGoal.name,
      },
    );
  }

  static TruthEvidenceEnvelope suggestion({
    required EventDocketLite docket,
    required EventCreationSuggestion suggestion,
    required TruthScopeDescriptor truthScope,
  }) {
    return TruthEvidenceEnvelope(
      scope: truthScope,
      traceId: '${docket.airGapProvenance.crossingId}:suggestion',
      evidenceClass: 'planning_suggestion',
      privacyLadderTag: 'bounded_planning_suggestion',
      sourceRefs: <String>[
        docket.airGapProvenance.crossingId,
        ...docket.airGapProvenance.tupleRefs,
      ],
      metadata: <String, dynamic>{
        'confidence': suggestion.confidence.name,
        'predictedFillBand': suggestion.predictedAttendanceFillBand.name,
        'suggestedMaxAttendees': suggestion.suggestedMaxAttendees,
        'suggestedPrice': suggestion.suggestedPrice,
        'suggestedLocalityLabel': suggestion.suggestedLocalityLabel,
      },
    );
  }

  static TruthEvidenceEnvelope snapshot({
    required EventPlanningAirGapResult airGapResult,
    required EventCreationSuggestion? acceptedSuggestion,
    required TruthScopeDescriptor truthScope,
  }) {
    return TruthEvidenceEnvelope(
      scope: truthScope,
      traceId: '${airGapResult.docket.airGapProvenance.crossingId}:snapshot',
      evidenceClass: 'planning_snapshot',
      privacyLadderTag: 'bounded_planning_snapshot',
      sourceRefs: <String>[
        airGapResult.docket.airGapProvenance.crossingId,
        ...airGapResult.tupleRefs,
      ],
      approvals: acceptedSuggestion == null
          ? const <String>[]
          : const <String>['host_acceptance'],
      metadata: <String, dynamic>{
        'acceptedSuggestion': acceptedSuggestion != null,
        'sourceKind': airGapResult.sourceKind.name,
        'confidence': airGapResult.confidence.name,
        'tupleRefCount': airGapResult.tupleRefs.length,
      },
    );
  }

  static TruthEvidenceEnvelope learningSignal({
    required String signalId,
    required String eventId,
    required EventLearningSignalKind kind,
    required EventPlanningSnapshot snapshot,
    required Iterable<String> tupleRefs,
    required TruthScopeDescriptor truthScope,
  }) {
    final refs = tupleRefs.where((entry) => entry.trim().isNotEmpty).toList();
    return TruthEvidenceEnvelope(
      scope: truthScope,
      traceId: signalId,
      evidenceClass: 'planning_learning_signal',
      privacyLadderTag: 'bounded_planning_learning',
      sourceRefs: <String>[
        snapshot.docket.airGapProvenance.crossingId,
        ...refs,
      ],
      approvals: kind == EventLearningSignalKind.eventCompleted
          ? const <String>['host_debrief_submitted']
          : const <String>[],
      metadata: <String, dynamic>{
        'eventId': eventId,
        'signalKind': kind.name,
        'tupleRefCount': refs.length,
        'acceptedSuggestion': snapshot.acceptedSuggestion != null,
      },
    );
  }

  static TruthEvidenceEnvelope debrief({
    required EventPlanningSnapshot snapshot,
    required HostEventDebrief debrief,
  }) {
    return TruthEvidenceEnvelope(
      scope: debrief.truthScope,
      traceId: '${debrief.eventId}:debrief',
      evidenceClass: 'planning_host_debrief',
      privacyLadderTag: 'bounded_planning_debrief',
      sourceRefs: <String>[
        snapshot.docket.airGapProvenance.crossingId,
        'event:${debrief.eventId}',
      ],
      approvals: const <String>['host_debrief_submitted'],
      metadata: <String, dynamic>{
        'attendanceRate': debrief.attendanceRate,
        'averageRating': debrief.averageRating,
        'wouldAttendAgainRate': debrief.wouldAttendAgainRate,
        'actualAttendance': debrief.actualAttendance,
      },
    );
  }
}
