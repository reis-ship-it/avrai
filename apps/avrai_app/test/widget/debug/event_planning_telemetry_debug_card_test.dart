import 'package:avrai/presentation/widgets/debug/event_planning_telemetry_debug_card.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders bounded event-planning telemetry summary and records',
      (WidgetTester tester) async {
    const summary = EventPlanningTelemetrySummary(
      airGapCrossings: 1,
      lowConfidenceSuggestions: 1,
      suggestionAcceptances: 1,
      eventsCreated: 1,
      debriefCompletions: 1,
      lowConfidenceRate: 1,
      suggestionAcceptanceRate: 1,
      debriefCompletionRate: 1,
    );

    final records = <EventPlanningTelemetryRecord>[
      EventPlanningTelemetryRecord(
        recordId: 'record-1',
        timestamp: DateTime.utc(2026, 3, 14, 12),
        kind: EventPlanningTelemetryKind.airGapCrossed,
        sourceKind: EventPlanningSourceKind.personalAgent,
        crossingId: 'evtplan_456_personalAgent_host0001',
        confidence: EventPlanningConfidence.high,
        truthScopeKey: 'planning:event_truth_beta',
        localityCode: 'bham_avondale',
        cityCode: 'birmingham_al',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventPlanningTelemetryDebugCard(
            summaryOverride: summary,
            recordsOverride: records,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Event Planning Telemetry'), findsOneWidget);
    expect(find.textContaining('Crossings'), findsOneWidget);
    expect(find.textContaining('Low-confidence'), findsOneWidget);
    expect(find.textContaining('Accepted'), findsOneWidget);
    expect(find.textContaining('Air gap crossed'), findsOneWidget);
    expect(find.textContaining('personalAgent'), findsOneWidget);
  });
}
