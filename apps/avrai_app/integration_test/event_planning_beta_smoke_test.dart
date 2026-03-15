import 'dart:io';

import 'package:avrai/presentation/pages/events/event_success_dashboard.dart';
import 'package:avrai/presentation/pages/events/quick_event_builder_page.dart';
import 'package:avrai/presentation/widgets/events/safety_checklist_widget.dart';
import 'package:avrai/services/debug/proof_run_automation_service.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/events/event_success_level.dart';
import 'package:avrai_core/models/events/event_success_metrics.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_runtime_os/services/events/beta_event_planning_suggestion_service.dart';
import 'package:avrai_runtime_os/services/events/event_host_debrief_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_intake_adapter.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/events/event_template_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat, StorageService;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

class _IntegrationAirGap implements AirGapContract {
  final List<RawDataPayload> payloads = <RawDataPayload>[];

  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    payloads.add(payload);
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-${payloads.length}',
        category: 'event_planning',
        subject: 'event_plan',
        predicate: 'sanitized',
        object: 'truth',
        confidence: 0.94,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

class _AllowAllGeographicScopeService extends GeographicScopeService {
  @override
  bool validateEventLocation({
    required String userId,
    required UnifiedUser user,
    required String category,
    required String eventLocality,
  }) {
    return true;
  }
}

class _CapturingEventCreationController extends EventCreationController {
  ExpertiseEvent? lastCreatedEvent;

  _CapturingEventCreationController()
      : super(
          eventService: ExpertiseEventService(),
          geographicScopeService: _AllowAllGeographicScopeService(),
          geoHierarchyService: GeoHierarchyService(),
        );

  @override
  Future<EventCreationResult> createEvent({
    required EventFormData formData,
    required UnifiedUser host,
  }) async {
    final ExpertiseEvent event = ExpertiseEvent(
      id: 'event-smoke-1',
      title: formData.title,
      description: formData.description,
      category: formData.category,
      eventType: formData.eventType,
      host: host,
      startTime: formData.startTime,
      endTime: formData.endTime,
      spots: formData.spots ?? const <Spot>[],
      location: formData.location,
      latitude: formData.latitude,
      longitude: formData.longitude,
      cityCode: formData.spots?.firstOrNull?.cityCode,
      localityCode: formData.planningSnapshot?.docket.candidateLocalityCode ??
          formData.spots?.firstOrNull?.localityCode,
      maxAttendees: formData.maxAttendees,
      price: formData.price,
      isPaid: formData.price != null && formData.price! > 0,
      isPublic: formData.isPublic,
      planningSnapshot: formData.planningSnapshot,
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      status: EventStatus.upcoming,
    );
    lastCreatedEvent = event;
    return EventCreationResult.success(event: event);
  }
}

class _StubEventService extends ExpertiseEventService {
  _StubEventService(this.event);

  final ExpertiseEvent event;

  @override
  Future<ExpertiseEvent?> getEventById(String eventId) async {
    return event.id == eventId ? event : null;
  }
}

class _StubEventSuccessAnalysisService extends EventSuccessAnalysisService {
  _StubEventSuccessAnalysisService({
    required super.eventService,
    required this.metrics,
  }) : super(
          feedbackService: PostEventFeedbackService(eventService: eventService),
        );

  final EventSuccessMetrics metrics;

  @override
  Future<EventSuccessMetrics?> getEventMetrics(String eventId) async => null;

  @override
  Future<EventSuccessMetrics> analyzeEventSuccess(String eventId) async =>
      metrics;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;

  testWidgets(
    'runs event-planning beta smoke and exports an iOS receipt bundle',
    (tester) async {
      const String platformMode = 'ios';
      final Map<String, Object?> report = <String, Object?>{
        'success': false,
        'platform_mode': platformMode,
      };

      try {
        await getIt.reset();
        await StorageService.instance.init();

        final SharedPreferencesCompat prefs =
            await SharedPreferencesCompat.getInstance();
        final ProofRunServiceV0 proofRunService = ProofRunServiceV0(
          ledger: LedgerRecorderServiceV0(
            supabaseService: SupabaseService(),
            agentIdService: AgentIdService(
              supabaseService: SupabaseService(),
            ),
            storage: StorageService.instance,
          ),
          supabase: SupabaseService(),
          prefs: prefs,
        );
        final ProofRunAutomationService automation = ProofRunAutomationService(
          proofRunService: proofRunService,
          prefs: prefs,
          storageService: StorageService.instance,
          supabaseService: SupabaseService(),
        );

        final _IntegrationAirGap planningAirGap = _IntegrationAirGap();
        final _CapturingEventCreationController eventController =
            _CapturingEventCreationController();
        getIt.registerSingleton<EventCreationController>(eventController);
        getIt.registerSingleton<EventPlanningIntakeAdapter>(
          EventPlanningIntakeAdapter(planningAirGap),
        );
        getIt.registerSingleton<BetaEventPlanningSuggestionService>(
          const BetaEventPlanningSuggestionService(),
        );

        final String runId = await automation.startEventPlanningBetaSmoke(
          platformMode: platformMode,
          userId: 'integration_event_planner',
        );

        final UnifiedUser host = UnifiedUser(
          id: 'host-1',
          email: 'host@example.com',
          displayName: 'Host',
          createdAt: DateTime.utc(2026, 3, 14),
          updatedAt: DateTime.utc(2026, 3, 14),
          isOnline: false,
          location: 'Avondale, Birmingham, AL, USA',
          expertiseMap: const <String, String>{'Music': 'local'},
        );
        final template = EventTemplateService().getTemplate('concert_meetup');
        expect(template, isNotNull);

        await tester.pumpWidget(
          MaterialApp(
            home: QuickEventBuilderPage(
              currentUser: host,
              preselectedTemplate: template,
              initialPlanningInput: RawEventPlanningInput(
                sourceKind: EventPlanningSourceKind.personalAgent,
                purposeText: 'spring music festival for the city',
                preferredStartDate: DateTime.utc(2026, 3, 21, 18),
                hostGoal: EventHostGoal.celebration,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Event Truth'), findsOneWidget);
        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.eventTruthEntered,
        );

        await tester.tap(find.text('Cross Air Gap & Review'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Air-Gapped Event Truth'), findsOneWidget);
        expect(planningAirGap.payloads, isNotEmpty);
        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.airGapCrossed,
        );
        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.suggestionShown,
        );

        await tester.tap(find.text('Publish Event'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Event Published'), findsOneWidget);
        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.publishCompleted,
        );

        expect(find.text('Open Safety Checklist'), findsOneWidget);
        final _StubEventService safetyEventService =
            _StubEventService(eventController.lastCreatedEvent!);
        if (getIt.isRegistered<ExpertiseEventService>()) {
          getIt.unregister<ExpertiseEventService>();
        }
        getIt.registerSingleton<ExpertiseEventService>(safetyEventService);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SafetyChecklistWidget(
                  event: eventController.lastCreatedEvent!),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.safetyChecklistOpened,
        );

        final ExpertiseEvent createdEvent = eventController.lastCreatedEvent!;
        final ExpertiseEvent completedEvent = ExpertiseEvent(
          id: createdEvent.id,
          title: createdEvent.title,
          description: createdEvent.description,
          category: createdEvent.category,
          eventType: createdEvent.eventType,
          host: createdEvent.host,
          startTime: createdEvent.startTime,
          endTime: createdEvent.endTime,
          spots: createdEvent.spots,
          location: createdEvent.location,
          latitude: createdEvent.latitude,
          longitude: createdEvent.longitude,
          cityCode: createdEvent.cityCode,
          localityCode: createdEvent.localityCode,
          maxAttendees: createdEvent.maxAttendees,
          attendeeIds: const <String>['a', 'b', 'c', 'd', 'e'],
          price: createdEvent.price,
          isPaid: createdEvent.isPaid,
          isPublic: createdEvent.isPublic,
          planningSnapshot: createdEvent.planningSnapshot,
          createdAt: createdEvent.createdAt,
          updatedAt: DateTime.utc(2026, 3, 22, 8),
          status: EventStatus.completed,
        );

        final EventSuccessMetrics metrics = EventSuccessMetrics(
          eventId: completedEvent.id,
          ticketsSold: 5,
          actualAttendance: 4,
          attendanceRate: 0.8,
          grossRevenue: 60,
          netRevenue: 48,
          revenueVsProjected: 0.8,
          profitMargin: 0.4,
          averageRating: 4.6,
          nps: 72,
          fiveStarCount: 4,
          fourStarCount: 1,
          threeStarCount: 0,
          twoStarCount: 0,
          oneStarCount: 0,
          feedbackResponseRate: 0.8,
          attendeesWhoWouldReturn: 4,
          attendeesWhoWouldRecommend: 4,
          partnerSatisfaction: const <String, double>{},
          partnersWouldCollaborateAgain: true,
          successLevel: EventSuccessLevel.high,
          successFactors: const <String>['Guests stayed longer than expected.'],
          improvementAreas: const <String>['Add clearer signage next time.'],
          calculatedAt: DateTime.utc(2026, 3, 22, 8),
        );

        final _StubEventService eventService =
            _StubEventService(completedEvent);
        final EventLearningSignalService learningSignalService =
            EventLearningSignalService(airGap: _IntegrationAirGap());
        final EventSuccessAnalysisService analysisService =
            _StubEventSuccessAnalysisService(
          eventService: eventService,
          metrics: metrics,
        );
        final EventHostDebriefService debriefService = EventHostDebriefService(
          eventService: eventService,
          successAnalysisService: analysisService,
          learningSignalService: learningSignalService,
        );

        if (getIt.isRegistered<EventSuccessAnalysisService>()) {
          getIt.unregister<EventSuccessAnalysisService>();
        }
        if (getIt.isRegistered<EventHostDebriefService>()) {
          getIt.unregister<EventHostDebriefService>();
        }
        getIt.registerSingleton<EventSuccessAnalysisService>(analysisService);
        getIt.registerSingleton<EventHostDebriefService>(debriefService);

        await tester.pumpWidget(
          MaterialApp(
            home: EventSuccessDashboard(event: completedEvent),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final HostEventDebrief recordedDebrief =
            await debriefService.createDebrief(
          eventId: completedEvent.id,
          outcomeNotesRaw:
              'Families wanted more shaded seating near the music area.',
        );
        expect(recordedDebrief.eventId, completedEvent.id);
        await automation.recordEventPlanningBetaSmokeMilestone(
          runId: runId,
          milestone: EventPlanningBetaSmokeMilestone.debriefCompleted,
        );

        final String exportDirectoryPath =
            await automation.finishAndExportEventPlanningBetaSmoke(
          runId: runId,
          platformMode: platformMode,
        );
        expect(Directory(exportDirectoryPath).existsSync(), isTrue);
        final String ledgerJsonl = File(
          '$exportDirectoryPath/ledger_rows.jsonl',
        ).readAsStringSync();
        final String ledgerCsv = File(
          '$exportDirectoryPath/ledger_rows.csv',
        ).readAsStringSync();

        report.addAll(<String, Object?>{
          'success': true,
          'run_id': runId,
          'export_directory_path': exportDirectoryPath,
          'receipt_mode': 'ios_integration_smoke',
          'receipt_files': <String, Object?>{
            'ledger_rows.jsonl': ledgerJsonl,
            'ledger_rows.csv': ledgerCsv,
          },
        });
      } catch (error, stackTrace) {
        report['failure_summary'] = error.toString();
        report['failure_stack'] = stackTrace.toString();
        rethrow;
      } finally {
        binding.reportData = report;
        await getIt.reset();
      }
    },
  );
}
