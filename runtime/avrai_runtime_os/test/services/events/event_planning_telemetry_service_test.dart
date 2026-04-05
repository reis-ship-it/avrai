import 'dart:io';

import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventPlanningTelemetryService', () {
    const MethodChannel pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    late Directory storageRoot;
    late GetStorage storage;
    late SharedPreferencesCompat prefs;
    late EventPlanningTelemetryService service;
    late EventPlanningAirGapResult airGapResult;
    late EventCreationSuggestion lowConfidenceSuggestion;
    late EventCreationSuggestion acceptedSuggestion;
    late EventPlanningSnapshot snapshot;
    late ExpertiseEvent event;
    late HostEventDebrief debrief;

    setUp(() async {
      storageRoot = await Directory.systemTemp.createTemp(
        'event_planning_telemetry_test_',
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
      storage = GetStorage('event_planning_telemetry', storageRoot.path);
      await storage.initStorage;
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      service = EventPlanningTelemetryService(prefs: prefs);

      airGapResult = EventPlanningAirGapResult(
        docket: EventDocketLite(
          intentTags: const <String>['spring', 'music'],
          vibeTags: const <String>['outdoor'],
          audienceTags: const <String>['families'],
          candidateLocalityLabel: 'Avondale',
          candidateLocalityCode: 'bham_avondale',
          preferredStartDate: DateTime.utc(2026, 3, 21, 18),
          preferredEndDate: DateTime.utc(2026, 3, 21, 21),
          sizeIntent: EventSizeIntent.large,
          priceIntent: EventPriceIntent.lowCost,
          hostGoal: EventHostGoal.celebration,
          airGapProvenance: EventAirGapProvenance(
            crossingId: 'evtplan_123_personalAgent_host0001',
            crossedAt: DateTime.utc(2026, 3, 14, 12),
            sourceKind: EventPlanningSourceKind.personalAgent,
            tupleRefs: const <String>['tuple-1'],
            confidence: EventPlanningConfidence.high,
          ),
        ),
        confidence: EventPlanningConfidence.high,
        sourceKind: EventPlanningSourceKind.personalAgent,
      );

      lowConfidenceSuggestion = EventCreationSuggestion(
        suggestedStartTime: DateTime.utc(2026, 3, 21, 18),
        suggestedEndTime: DateTime.utc(2026, 3, 21, 21),
        suggestedLocalityLabel: 'Avondale',
        suggestedMaxAttendees: 48,
        suggestedPrice: 15,
        predictedAttendanceFillBand: EventAttendanceFillBand.low,
        confidence: EventPlanningConfidence.low,
        explanation: 'Low confidence suggestion.',
      );

      acceptedSuggestion = EventCreationSuggestion(
        suggestedStartTime: DateTime.utc(2026, 3, 21, 18),
        suggestedEndTime: DateTime.utc(2026, 3, 21, 21),
        suggestedLocalityLabel: 'Avondale',
        suggestedMaxAttendees: 48,
        suggestedPrice: 15,
        predictedAttendanceFillBand: EventAttendanceFillBand.medium,
        confidence: EventPlanningConfidence.medium,
        explanation: 'Medium confidence suggestion.',
      );

      snapshot = EventPlanningSnapshot(
        docket: airGapResult.docket,
        acceptedSuggestion: acceptedSuggestion,
        createdAt: DateTime.utc(2026, 3, 14, 12, 30),
      );

      final UnifiedUser host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        createdAt: DateTime.utc(2026, 3, 14),
        updatedAt: DateTime.utc(2026, 3, 14),
        isOnline: false,
      );
      event = ExpertiseEvent(
        id: 'event-1',
        title: 'Spring Music Celebration',
        description: 'Air-gapped event truth test.',
        category: 'Music',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime.utc(2026, 3, 21, 18),
        endTime: DateTime.utc(2026, 3, 21, 21),
        cityCode: 'birmingham_al',
        localityCode: 'bham_avondale',
        planningSnapshot: snapshot,
        createdAt: DateTime.utc(2026, 3, 14, 12),
        updatedAt: DateTime.utc(2026, 3, 14, 12),
        status: EventStatus.upcoming,
      );
      debrief = HostEventDebrief(
        eventId: event.id,
        predictedAttendanceFillBand: EventAttendanceFillBand.medium,
        actualAttendance: 44,
        attendanceRate: 0.88,
        averageRating: 4.7,
        wouldAttendAgainRate: 0.91,
        insightLines: const <String>['Families stayed through the full set.'],
        createdAt: DateTime.utc(2026, 3, 22, 8),
      );
    });

    tearDown(() async {
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

    test('records bounded telemetry events and summarizes rates', () async {
      await service.recordAirGapCrossed(
        airGapResult: airGapResult,
      );
      await service.recordLowConfidenceSuggestion(
        airGapResult: airGapResult,
        suggestion: lowConfidenceSuggestion,
      );
      await service.recordSuggestionAccepted(
        airGapResult: airGapResult,
        suggestion: acceptedSuggestion,
      );
      await service.recordEventCreated(event: event);
      await service.recordDebriefCompleted(event: event, debrief: debrief);

      final List<EventPlanningTelemetryRecord> records = service.listAll();
      expect(records, hasLength(5));
      expect(
        records.map((EventPlanningTelemetryRecord record) => record.kind),
        containsAll(<EventPlanningTelemetryKind>[
          EventPlanningTelemetryKind.airGapCrossed,
          EventPlanningTelemetryKind.lowConfidenceSuggestionShown,
          EventPlanningTelemetryKind.suggestionAccepted,
          EventPlanningTelemetryKind.eventCreated,
          EventPlanningTelemetryKind.debriefCompleted,
        ]),
      );
      expect(
        records.every(
          (EventPlanningTelemetryRecord record) =>
              !record.toJson().toString().contains('Air-gapped event truth'),
        ),
        isTrue,
      );

      final EventPlanningTelemetrySummary summary = service.summarize();
      expect(summary.airGapCrossings, 1);
      expect(summary.lowConfidenceSuggestions, 1);
      expect(summary.suggestionAcceptances, 1);
      expect(summary.eventsCreated, 1);
      expect(summary.debriefCompletions, 1);
      expect(summary.lowConfidenceRate, 1);
      expect(summary.suggestionAcceptanceRate, 1);
      expect(summary.debriefCompletionRate, 1);
    });
  });
}
