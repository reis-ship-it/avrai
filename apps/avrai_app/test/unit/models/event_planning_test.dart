import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventPlanning models', () {
    const planningScope = TruthScopeDescriptor.defaultPlanning(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'event_planning_locality',
      familyId: 'creator_event_prep_human',
    );
    const evidenceEnvelope = TruthEvidenceEnvelope(
      scope: planningScope,
      traceId: 'evtplan_trace',
      evidenceClass: 'planning_snapshot',
      privacyLadderTag: 'bounded_planning_snapshot',
      sourceRefs: <String>['evtplan_trace', 'tuple-1'],
    );
    final provenance = EventAirGapProvenance(
      crossingId: 'crossing-evt-plan-test',
      crossedAt: DateTime.utc(2026, 3, 14, 12),
      sourceKind: EventPlanningSourceKind.human,
      tupleRefs: const <String>['tuple-1', 'tuple-2'],
      confidence: EventPlanningConfidence.medium,
    );

    test('EventDocketLite JSON round-trip keeps only sanitized fields', () {
      final docket = EventDocketLite(
        intentTags: const <String>['spring', 'music'],
        vibeTags: const <String>['outdoor', 'celebration'],
        audienceTags: const <String>['families', 'neighbors'],
        candidateLocalityLabel: 'Avondale',
        candidateLocalityCode: 'bham_avondale',
        preferredStartDate: DateTime.utc(2026, 3, 21, 17),
        preferredEndDate: DateTime.utc(2026, 3, 21, 21),
        sizeIntent: EventSizeIntent.large,
        priceIntent: EventPriceIntent.lowCost,
        hostGoal: EventHostGoal.celebration,
        airGapProvenance: provenance,
      );

      final json = docket.toJson();
      final restored = EventDocketLite.fromJson(json);

      expect(restored, equals(docket));
      expect(json.keys, isNot(contains('purposeText')));
      expect(json.keys, isNot(contains('vibeText')));
      expect(json.keys, isNot(contains('targetAudienceText')));
    });

    test('EventPlanningSnapshot JSON round-trip keeps accepted suggestion', () {
      final snapshot = EventPlanningSnapshot(
        docket: EventDocketLite(
          intentTags: const <String>['community'],
          vibeTags: const <String>['lively'],
          audienceTags: const <String>['neighbors'],
          candidateLocalityLabel: 'Downtown',
          candidateLocalityCode: 'bham_downtown',
          preferredStartDate: DateTime.utc(2026, 3, 21, 18),
          preferredEndDate: DateTime.utc(2026, 3, 21, 22),
          sizeIntent: EventSizeIntent.standard,
          priceIntent: EventPriceIntent.free,
          hostGoal: EventHostGoal.community,
          airGapProvenance: provenance,
        ),
        acceptedSuggestion: EventCreationSuggestion(
          suggestedStartTime: DateTime.utc(2026, 3, 21, 18),
          suggestedEndTime: DateTime.utc(2026, 3, 21, 20),
          suggestedLocalityLabel: 'Downtown',
          suggestedMaxAttendees: 32,
          suggestedPrice: null,
          predictedAttendanceFillBand: EventAttendanceFillBand.high,
          confidence: EventPlanningConfidence.medium,
          explanation: 'Medium confidence test suggestion.',
          truthScope: planningScope,
          evidenceEnvelope: evidenceEnvelope,
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12, 30),
        truthScope: planningScope,
        evidenceEnvelope: evidenceEnvelope,
      );

      final restored = EventPlanningSnapshot.fromJson(snapshot.toJson());

      expect(restored, equals(snapshot));
      expect(restored.truthScope.scopeKey, planningScope.scopeKey);
      expect(restored.evidenceEnvelope?.traceId, evidenceEnvelope.traceId);
      expect(
        restored.acceptedSuggestion?.evidenceEnvelope?.traceId,
        evidenceEnvelope.traceId,
      );
    });

    test('HostEventDebrief JSON round-trip keeps bounded insights', () {
      final debrief = HostEventDebrief(
        eventId: 'event-123',
        predictedAttendanceFillBand: EventAttendanceFillBand.medium,
        actualAttendance: 54,
        attendanceRate: 0.72,
        averageRating: 4.4,
        wouldAttendAgainRate: 0.81,
        insightLines: const <String>[
          'Predicted medium fill; actual attendance landed high.',
          'Families stayed longer than expected.',
        ],
        createdAt: DateTime.utc(2026, 3, 23, 9),
        truthScope: planningScope,
        evidenceEnvelope: evidenceEnvelope,
      );

      final restored = HostEventDebrief.fromJson(debrief.toJson());

      expect(restored, equals(debrief));
      expect(restored.truthScope.scopeKey, planningScope.scopeKey);
      expect(restored.evidenceEnvelope?.traceId, evidenceEnvelope.traceId);
    });

    test('EventPlanningBoundaryGuard accepts sanitized snapshot', () {
      final snapshot = EventPlanningSnapshot(
        docket: EventDocketLite(
          intentTags: const <String>['spring', 'music'],
          vibeTags: const <String>['joyful'],
          audienceTags: const <String>['families'],
          candidateLocalityLabel: 'Five Points South',
          candidateLocalityCode: 'bham_five_points_south',
          preferredStartDate: DateTime.utc(2026, 3, 21, 17),
          preferredEndDate: DateTime.utc(2026, 3, 21, 20),
          sizeIntent: EventSizeIntent.standard,
          priceIntent: EventPriceIntent.free,
          hostGoal: EventHostGoal.community,
          airGapProvenance: provenance,
        ),
        acceptedSuggestion: EventCreationSuggestion(
          suggestedStartTime: DateTime.utc(2026, 3, 21, 17),
          suggestedEndTime: DateTime.utc(2026, 3, 21, 19),
          suggestedLocalityLabel: 'Five Points South',
          suggestedMaxAttendees: 24,
          suggestedPrice: null,
          predictedAttendanceFillBand: EventAttendanceFillBand.medium,
          confidence: EventPlanningConfidence.medium,
          explanation: 'Medium confidence suggestion.',
          truthScope: planningScope,
          evidenceEnvelope: evidenceEnvelope,
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12, 30),
        truthScope: planningScope,
        evidenceEnvelope: evidenceEnvelope,
      );

      expect(
        () => EventPlanningBoundaryGuard.ensureSanitizedSnapshot(snapshot),
        returnsNormally,
      );
    });

    test('EventPlanningBoundaryGuard rejects raw phrase tags', () {
      final snapshot = EventPlanningSnapshot(
        docket: EventDocketLite(
          intentTags: const <String>['spring music celebration'],
          vibeTags: const <String>['joyful'],
          audienceTags: const <String>['families'],
          candidateLocalityLabel: 'Avondale',
          candidateLocalityCode: 'bham_avondale',
          preferredStartDate: DateTime.utc(2026, 3, 21, 17),
          preferredEndDate: DateTime.utc(2026, 3, 21, 20),
          sizeIntent: EventSizeIntent.standard,
          priceIntent: EventPriceIntent.free,
          hostGoal: EventHostGoal.community,
          airGapProvenance: provenance,
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12, 30),
      );

      expect(
        () => EventPlanningBoundaryGuard.ensureSanitizedSnapshot(snapshot),
        throwsFormatException,
      );
    });
  });
}
