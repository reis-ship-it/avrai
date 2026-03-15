import 'dart:io';

import 'package:avrai/presentation/pages/events/quick_event_builder_page.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_runtime_os/services/events/beta_event_planning_suggestion_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_intake_adapter.dart';
import 'package:avrai_runtime_os/services/events/event_template_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _RecordingExpertiseEventService extends ExpertiseEventService {
  ExpertiseEvent? lastCreatedEvent;

  @override
  Future<ExpertiseEvent> createEvent({
    required UnifiedUser host,
    required String title,
    required String description,
    required String category,
    required ExpertiseEventType eventType,
    required DateTime startTime,
    required DateTime endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    String? cityCode,
    String? localityCode,
    int maxAttendees = 20,
    double? price,
    bool isPublic = true,
    EventPlanningSnapshot? planningSnapshot,
  }) async {
    final event = ExpertiseEvent(
      id: 'event-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      eventType: eventType,
      host: host,
      startTime: startTime,
      endTime: endTime,
      spots: spots ?? const <Spot>[],
      location: location,
      latitude: latitude,
      longitude: longitude,
      cityCode: cityCode,
      localityCode: localityCode,
      maxAttendees: maxAttendees,
      price: price,
      isPaid: price != null && price > 0,
      isPublic: isPublic,
      planningSnapshot: planningSnapshot,
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      status: EventStatus.upcoming,
    );
    lastCreatedEvent = event;
    return event;
  }
}

class _CapturingEventCreationController extends EventCreationController {
  EventFormData? lastFormData;
  UnifiedUser? lastHost;
  ExpertiseEvent? lastCreatedEvent;

  _CapturingEventCreationController()
      : super(
          eventService: _RecordingExpertiseEventService(),
          geographicScopeService: _AllowAllGeographicScopeService(),
          geoHierarchyService: GeoHierarchyService(),
        );

  @override
  Future<EventCreationResult> createEvent({
    required EventFormData formData,
    required UnifiedUser host,
  }) async {
    lastFormData = formData;
    lastHost = host;
    final event = ExpertiseEvent(
      id: 'event-test-1',
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

class _FakeAirGap implements AirGapContract {
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
        confidence: 0.9,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

void main() {
  final getIt = GetIt.instance;
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  late _CapturingEventCreationController controller;
  late Directory storageRoot;

  UnifiedUser buildHost() {
    return UnifiedUser(
      id: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      isOnline: false,
      location: 'Avondale, Birmingham, AL, USA',
      expertiseMap: const <String, String>{'Coffee': 'local'},
    );
  }

  Future<void> pumpBuilder(
    WidgetTester tester, {
    required UnifiedUser user,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuickEventBuilderPage(currentUser: user),
      ),
    );
  }

  Future<void> advanceToEventTruth(WidgetTester tester) async {
    await tester.tap(find.text('Coffee Tasting Tour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('This Weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await getIt.reset();
    storageRoot = await Directory.systemTemp.createTemp(
      'quick_event_builder_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return storageRoot.path;
        }
        return null;
      },
    );

    controller = _CapturingEventCreationController();
    getIt.registerSingleton<EventCreationController>(controller);
  });

  tearDown(() async {
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore temporary directory cleanup failures in tests.
    }
  });

  testWidgets('editing event truth forces re-crossing the air gap',
      (WidgetTester tester) async {
    final airGap = _FakeAirGap();
    getIt.registerSingleton<EventPlanningIntakeAdapter>(
      EventPlanningIntakeAdapter(airGap),
    );
    getIt.registerSingleton<BetaEventPlanningSuggestionService>(
      const BetaEventPlanningSuggestionService(),
    );

    await pumpBuilder(tester, user: buildHost());
    await advanceToEventTruth(tester);

    final firstPlanningField = find.byType(TextField).first;

    await tester.enterText(firstPlanningField, 'spring music celebration');
    await tester.pump();

    await tester.tap(find.text('Cross Air Gap & Review'));
    await tester.pumpAndSettle();

    expect(find.text('Air-Gapped Event Truth'), findsOneWidget);
    expect(airGap.payloads, hasLength(1));
    expect(
      airGap.payloads.single.rawContent,
      contains('spring music celebration'),
    );

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.enterText(
      firstPlanningField,
      'updated spring music celebration',
    );
    await tester.pump();

    await tester.tap(find.text('Cross Air Gap & Review'));
    await tester.pumpAndSettle();

    expect(airGap.payloads, hasLength(2));
    expect(
      airGap.payloads.last.rawContent,
      contains('updated spring music celebration'),
    );
  });

  testWidgets(
      'publish flow stores only sanitized planning snapshot before handoff',
      (WidgetTester tester) async {
    final airGap = _FakeAirGap();
    getIt.registerSingleton<EventPlanningIntakeAdapter>(
      EventPlanningIntakeAdapter(airGap),
    );
    getIt.registerSingleton<BetaEventPlanningSuggestionService>(
      const BetaEventPlanningSuggestionService(),
    );

    await pumpBuilder(tester, user: buildHost());
    await advanceToEventTruth(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'spring music celebration for neighbors',
    );
    await tester.pump();

    await tester.tap(find.text('Cross Air Gap & Review'));
    await tester.pumpAndSettle();

    expect(find.text('Air-Gapped Event Truth'), findsOneWidget);

    await tester.tap(find.text('Publish Event'));
    await tester.pumpAndSettle();

    final createdEvent = controller.lastCreatedEvent;
    expect(createdEvent, isNotNull);
    expect(createdEvent!.planningSnapshot, isNotNull);
    expect(
      createdEvent.planningSnapshot!.docket.airGapProvenance.crossingId,
      isNotEmpty,
    );

    final persistedPlanningJson = createdEvent.planningSnapshot!.toJson();
    expect(persistedPlanningJson.toString(), isNot(contains('purposeText')));
    expect(persistedPlanningJson.toString(), isNot(contains('vibeText')));
    expect(
      persistedPlanningJson.toString(),
      isNot(contains('targetAudienceText')),
    );
    expect(
      persistedPlanningJson.toString(),
      isNot(contains('spring music celebration for neighbors')),
    );
  });

  testWidgets(
      'personal-agent drafts still cross the same air gap and flip to human after edit',
      (WidgetTester tester) async {
    final airGap = _FakeAirGap();
    getIt.registerSingleton<EventPlanningIntakeAdapter>(
      EventPlanningIntakeAdapter(airGap),
    );
    getIt.registerSingleton<BetaEventPlanningSuggestionService>(
      const BetaEventPlanningSuggestionService(),
    );

    final template = EventTemplateService().getTemplate('concert_meetup');
    expect(template, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: QuickEventBuilderPage(
          currentUser: buildHost(),
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Event Truth'), findsOneWidget);
    expect(find.textContaining('personal agent chat'), findsOneWidget);

    await tester.tap(find.text('Cross Air Gap & Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(airGap.payloads, hasLength(1));
    expect(airGap.payloads.single.sourceId, 'event_planning_personalAgent');
    expect(find.textContaining('Source: Personal Agent'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(
      find.byType(TextField).first,
      'revised spring music festival for the city',
    );
    await tester.pump();

    expect(
      find.textContaining('must cross the air gap again'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cross Air Gap & Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(airGap.payloads, hasLength(2));
    expect(airGap.payloads.last.sourceId, 'event_planning_human');
    expect(find.textContaining('Source: Human'), findsOneWidget);
  });
}
