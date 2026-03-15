import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  setUp(() {
    MockGetStorage.reset();
  });

  Future<RecommendationTelemetryService> buildService({
    Duration retentionWindow = const Duration(days: 14),
    int maxEvents = 400,
    String boxName = 'recommendation_telemetry_test',
  }) async {
    final storage = MockGetStorage.getInstance(boxName: boxName);
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    return RecommendationTelemetryService(
      prefs: prefs,
      retentionWindow: retentionWindow,
      maxEvents: maxEvents,
    );
  }

  RecommendationTelemetryRecord buildRecord({
    required String eventId,
    required DateTime timestamp,
  }) {
    return RecommendationTelemetryRecord(
      recordId: 'rec_$eventId',
      timestamp: timestamp,
      userId: 'user-1',
      eventId: eventId,
      eventTitle: 'Event $eventId',
      category: 'food',
      reason: 'Matches your interest in food',
      relevanceScore: 0.82,
      traceRef: 'user:user-1|event:$eventId',
      location: 'Austin, TX',
      kernelEventId: 'kernel:$eventId',
      modelTruthReady: true,
      localityContainedInWhere: true,
      governanceSummary: 'locality in where',
      governanceDomains: const <String>['who', 'where', 'why'],
      explanation: const WhySnapshot(
        goal: 'explain_event_recommendation',
        queryKind: WhyQueryKind.recommendation,
        drivers: <WhySignal>[
          WhySignal(
            label: 'category fit food',
            weight: 0.82,
            kernel: WhyEvidenceSourceKernel.what,
          ),
        ],
        inhibitors: <WhySignal>[],
        counterfactuals: <WhyCounterfactual>[],
        confidence: 0.82,
        rootCauseType: WhyRootCauseType.contextDriven,
        summary: 'recommend_event produced Event due to category signals.',
      ),
    );
  }

  test('latest returns newest recommendation record', () async {
    final service = await buildService();
    final now = DateTime.now().toUtc();
    await service.recordRecommendations(<RecommendationTelemetryRecord>[
      buildRecord(
          eventId: 'event-1',
          timestamp: now.subtract(const Duration(minutes: 5))),
      buildRecord(eventId: 'event-2', timestamp: now),
    ]);

    final latest = service.latest();

    expect(latest, isNotNull);
    expect(latest!.eventId, 'event-2');
    expect(latest.explanation.queryKind, WhyQueryKind.recommendation);
    expect(latest.kernelEventId, 'kernel:event-2');
    expect(latest.modelTruthReady, isTrue);
    expect(latest.localityContainedInWhere, isTrue);
    expect(latest.governanceDomains, containsAll(<String>['where', 'why']));
  });

  test('compact enforces retention and max events', () async {
    final service = await buildService(
      retentionWindow: const Duration(days: 1),
      maxEvents: 2,
    );
    final now = DateTime.now().toUtc();
    await service.recordRecommendations(<RecommendationTelemetryRecord>[
      buildRecord(
        eventId: 'expired',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      buildRecord(
        eventId: 'event-1',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      buildRecord(
        eventId: 'event-2',
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      buildRecord(
        eventId: 'event-3',
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    ]);

    await service.compact();
    final all = service.listAll();

    expect(all.map((entry) => entry.eventId).toList(),
        <String>['event-3', 'event-2']);
  });
}
