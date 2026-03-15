import 'dart:io';

import 'package:avrai/presentation/pages/events/event_success_dashboard.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/events/event_success_level.dart';
import 'package:avrai_core/models/events/event_success_metrics.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/services/events/event_host_debrief_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _FakeAirGap implements AirGapContract {
  final List<RawDataPayload> payloads = <RawDataPayload>[];

  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    payloads.add(payload);
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-${payloads.length}',
        category: 'event_outcome',
        subject: 'event_note',
        predicate: 'sanitized',
        object: 'bounded_note',
        confidence: 0.88,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

class _StubEventService extends ExpertiseEventService {
  final ExpertiseEvent event;

  _StubEventService(this.event);

  @override
  Future<ExpertiseEvent?> getEventById(String eventId) async {
    return event.id == eventId ? event : null;
  }
}

class _StubEventSuccessAnalysisService extends EventSuccessAnalysisService {
  final EventSuccessMetrics metrics;

  _StubEventSuccessAnalysisService({
    required super.eventService,
    required this.metrics,
  }) : super(
          feedbackService: PostEventFeedbackService(eventService: eventService),
        );

  @override
  Future<EventSuccessMetrics?> getEventMetrics(String eventId) async => null;

  @override
  Future<EventSuccessMetrics> analyzeEventSuccess(String eventId) async =>
      metrics;
}

void main() {
  final getIt = GetIt.instance;
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  testWidgets('host debrief records outcome notes through the air gap',
      (WidgetTester tester) async {
    final host = UnifiedUser(
      id: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      isOnline: false,
      expertiseMap: const <String, String>{'Coffee': 'local'},
    );
    final snapshot = EventPlanningSnapshot(
      docket: EventDocketLite(
        intentTags: const <String>['spring', 'music'],
        vibeTags: const <String>['joyful', 'outdoor'],
        audienceTags: const <String>['families'],
        candidateLocalityLabel: 'Avondale',
        candidateLocalityCode: 'bham_avondale',
        preferredStartDate: DateTime.utc(2026, 3, 21, 17),
        preferredEndDate: DateTime.utc(2026, 3, 21, 21),
        sizeIntent: EventSizeIntent.large,
        priceIntent: EventPriceIntent.lowCost,
        hostGoal: EventHostGoal.celebration,
        airGapProvenance: EventAirGapProvenance(
          crossingId: 'evtplan_123456_human_host0001',
          crossedAt: DateTime.utc(2026, 3, 14, 12),
          sourceKind: EventPlanningSourceKind.human,
          tupleRefs: const <String>['tuple-1'],
          confidence: EventPlanningConfidence.high,
        ),
      ),
      acceptedSuggestion: EventCreationSuggestion(
        suggestedStartTime: DateTime.utc(2026, 3, 21, 18),
        suggestedEndTime: DateTime.utc(2026, 3, 21, 20),
        suggestedLocalityLabel: 'Avondale',
        suggestedMaxAttendees: 48,
        suggestedPrice: 15.0,
        predictedAttendanceFillBand: EventAttendanceFillBand.high,
        confidence: EventPlanningConfidence.high,
        explanation: 'High confidence suggestion.',
      ),
      createdAt: DateTime.utc(2026, 3, 14, 12, 30),
    );
    final event = ExpertiseEvent(
      id: 'event-1',
      title: 'Coffee Tasting Tour',
      description: 'An outdoor spring coffee and music event.',
      category: 'Coffee',
      eventType: ExpertiseEventType.tour,
      host: host,
      startTime: DateTime.utc(2026, 3, 21, 18),
      endTime: DateTime.utc(2026, 3, 21, 20),
      maxAttendees: 60,
      attendeeIds: const <String>['a', 'b', 'c', 'd', 'e'],
      planningSnapshot: snapshot,
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      status: EventStatus.completed,
    );
    final metrics = EventSuccessMetrics(
      eventId: event.id,
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

    final eventService = _StubEventService(event);
    final airGap = _FakeAirGap();
    final learningService = EventLearningSignalService(airGap: airGap);
    final analysisService = _StubEventSuccessAnalysisService(
      eventService: eventService,
      metrics: metrics,
    );
    final debriefService = EventHostDebriefService(
      eventService: eventService,
      successAnalysisService: analysisService,
      learningSignalService: learningService,
    );

    getIt.registerSingleton<EventSuccessAnalysisService>(analysisService);
    getIt.registerSingleton<EventHostDebriefService>(debriefService);

    await tester.pumpWidget(
      MaterialApp(
        home: EventSuccessDashboard(event: event),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Record Host Debrief'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Families wanted more shaded seating near the music area.',
    );
    await tester.ensureVisible(find.text('Record Debrief'));
    await tester.tap(find.text('Record Debrief'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Host Debrief'), findsOneWidget);
    expect(airGap.payloads, hasLength(1));
    expect(
      airGap.payloads.single.rawContent,
      contains('Families wanted more shaded seating near the music area.'),
    );
  });
}
