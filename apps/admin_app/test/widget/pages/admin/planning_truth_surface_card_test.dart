import 'package:avrai_admin_app/ui/widgets/planning_truth_surface_card.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_runtime_os/services/admin/planning_truth_surface_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanningTruthSurfaceAdminService extends Mock
    implements PlanningTruthSurfaceAdminService {}

void main() {
  group('PlanningTruthSurfaceCard', () {
    late GetIt getIt;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    tearDown(() {
      getIt = GetIt.instance;
      if (getIt.isRegistered<PlanningTruthSurfaceAdminService>()) {
        getIt.unregister<PlanningTruthSurfaceAdminService>();
      }
    });

    testWidgets('renders unavailable state when service is absent', (
      tester,
    ) async {
      getIt = GetIt.instance;
      if (getIt.isRegistered<PlanningTruthSurfaceAdminService>()) {
        getIt.unregister<PlanningTruthSurfaceAdminService>();
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlanningTruthSurfaceCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planning Truth Surface'), findsOneWidget);
      expect(
        find.text('Planning truth surface diagnostics are not registered.'),
        findsOneWidget,
      );
    });

    testWidgets('renders planning truth snapshot details when registered', (
      tester,
    ) async {
      getIt = GetIt.instance;
      final service = MockPlanningTruthSurfaceAdminService();
      if (getIt.isRegistered<PlanningTruthSurfaceAdminService>()) {
        getIt.unregister<PlanningTruthSurfaceAdminService>();
      }
      getIt.registerSingleton<PlanningTruthSurfaceAdminService>(service);

      when(
        () => service.watchPlanningSnapshot(
          lookbackWindow: any(named: 'lookbackWindow'),
          refreshInterval: any(named: 'refreshInterval'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot()));
      when(
        () => service.getPlanningSnapshot(),
      ).thenAnswer((_) async => _buildSnapshot());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlanningTruthSurfaceCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planning Truth Surface'), findsOneWidget);
      expect(find.textContaining('Signals: 2'), findsOneWidget);
      expect(find.textContaining('eventCompleted • event-1'), findsOneWidget);
    });
  });
}

PlanningTruthSurfaceAdminSnapshot _buildSnapshot() {
  const truthScope = TruthScopeDescriptor.defaultPlanning(
    governanceStratum: GovernanceStratum.locality,
    sphereId: 'event_planning_locality',
    familyId: 'creator_event_prep_human',
  );
  const evidenceEnvelope = TruthEvidenceEnvelope(
    scope: truthScope,
    traceId: 'signal-2',
    evidenceClass: 'planning_learning_signal',
    privacyLadderTag: 'bounded_planning_learning',
    sourceRefs: <String>['evtplan_1', 'tuple-1'],
  );
  return PlanningTruthSurfaceAdminSnapshot(
    generatedAt: DateTime.utc(2026, 3, 14, 12),
    windowStart: DateTime.utc(2026, 3, 13, 12),
    windowEnd: DateTime.utc(2026, 3, 14, 12),
    signalCount: 2,
    createdSignalCount: 1,
    completedSignalCount: 1,
    personalScopedCount: 0,
    localityScopedCount: 2,
    averageTupleRefCount: 1.0,
    averageAttendanceRate: 0.8,
    averageAverageRating: 4.7,
    averageWouldAttendAgainRate: 0.9,
    stratumCounts: const <String, int>{'locality': 2},
    evidenceClassCounts: const <String, int>{'planning_learning_signal': 2},
    privacyCounts: const <String, int>{'bounded_planning_learning': 2},
    hostGoalCounts: const <String, int>{'community': 2},
    recentSignals: <PlanningTruthSurfaceAdminRow>[
      PlanningTruthSurfaceAdminRow(
        signalId: 'signal-2',
        eventId: 'event-1',
        kind: EventLearningSignalKind.eventCompleted,
        truthScope: truthScope,
        evidenceEnvelope: evidenceEnvelope,
        createdAt: DateTime(2026, 3, 14, 12),
        hostUserId: 'host-1',
        tupleRefCount: 1,
        sourceKind: 'human',
        confidence: 'high',
        hostGoal: 'community',
        candidateLocalityCode: 'bham_avondale',
        acceptedSuggestion: true,
        predictedFillBand: 'high',
        attendanceRate: 0.8,
        averageRating: 4.7,
        wouldAttendAgainRate: 0.9,
      ),
    ],
  );
}
