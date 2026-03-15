import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/services/admin/planning_truth_surface_admin_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAirGap implements AirGapContract {
  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-1',
        category: 'event_planning',
        subject: 'event',
        predicate: 'sanitized',
        object: 'truth',
        confidence: 0.9,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

void main() {
  test('aggregates recent planning learning signals into an admin snapshot',
      () async {
    final learningSignalService = EventLearningSignalService(
      airGap: _FakeAirGap(),
    );
    const planningScope = TruthScopeDescriptor.defaultPlanning(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'event_planning_locality',
      familyId: 'creator_event_prep_human',
    );
    final snapshot = EventPlanningSnapshot(
      docket: EventDocketLite(
        intentTags: const <String>['music'],
        vibeTags: const <String>['warm'],
        audienceTags: const <String>['neighbors'],
        candidateLocalityLabel: 'Avondale',
        candidateLocalityCode: 'bham_avondale',
        preferredStartDate: DateTime.utc(2026, 3, 20, 18),
        preferredEndDate: DateTime.utc(2026, 3, 20, 21),
        sizeIntent: EventSizeIntent.standard,
        priceIntent: EventPriceIntent.free,
        hostGoal: EventHostGoal.community,
        airGapProvenance: EventAirGapProvenance(
          crossingId: 'evtplan_1',
          crossedAt: DateTime.utc(2026, 3, 14, 12),
          sourceKind: EventPlanningSourceKind.human,
          tupleRefs: const <String>['tuple-1'],
          confidence: EventPlanningConfidence.high,
        ),
      ),
      acceptedSuggestion: EventCreationSuggestion(
        suggestedStartTime: DateTime.utc(2026, 3, 20, 18),
        suggestedEndTime: DateTime.utc(2026, 3, 20, 20),
        suggestedLocalityLabel: 'Avondale',
        suggestedMaxAttendees: 30,
        predictedAttendanceFillBand: EventAttendanceFillBand.high,
        confidence: EventPlanningConfidence.high,
        explanation: 'High confidence suggestion.',
        truthScope: planningScope,
      ),
      createdAt: DateTime.now(),
      truthScope: planningScope,
    );
    final event = ExpertiseEvent(
      id: 'event-1',
      title: 'Neighborhood Session',
      description: 'Sanitized planning record.',
      eventType: ExpertiseEventType.meetup,
      host: UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        createdAt: DateTime.utc(2026, 3, 14),
        updatedAt: DateTime.utc(2026, 3, 14),
        isOnline: false,
      ),
      spots: const <Spot>[],
      startTime: DateTime.utc(2026, 3, 20, 18),
      endTime: DateTime.utc(2026, 3, 20, 21),
      maxAttendees: 30,
      category: 'community',
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      planningSnapshot: snapshot,
    );

    await learningSignalService.recordEventCreated(
      event: event,
      snapshot: snapshot,
    );
    await learningSignalService.recordEventOutcome(
      event: event,
      debrief: HostEventDebrief(
        eventId: event.id,
        predictedAttendanceFillBand: EventAttendanceFillBand.high,
        actualAttendance: 24,
        attendanceRate: 0.8,
        averageRating: 4.7,
        wouldAttendAgainRate: 0.9,
        insightLines: const <String>['Strong turnout.'],
        createdAt: DateTime.now(),
        truthScope: planningScope,
      ),
    );

    final service = PlanningTruthSurfaceAdminService(
      learningSignalService: learningSignalService,
      nowProvider: () => DateTime.now().toUtc(),
    );
    final adminSnapshot = await service.getPlanningSnapshot();

    expect(adminSnapshot.signalCount, 2);
    expect(adminSnapshot.createdSignalCount, 1);
    expect(adminSnapshot.completedSignalCount, 1);
    expect(adminSnapshot.localityScopedCount, 2);
    expect(adminSnapshot.evidenceClassCounts['planning_learning_signal'], 2);
    expect(adminSnapshot.averageAttendanceRate, greaterThan(0.0));
    expect(
      adminSnapshot.recentSignals.first.truthScope.scopeKey,
      planningScope.scopeKey,
    );
  });
}
