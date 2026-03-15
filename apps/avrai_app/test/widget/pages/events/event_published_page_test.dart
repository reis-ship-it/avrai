import 'package:avrai/presentation/pages/events/event_published_page.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('published page exposes safety checklist handoff',
      (WidgetTester tester) async {
    final host = UnifiedUser(
      id: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      isOnline: false,
    );
    final event = ExpertiseEvent(
      id: 'event-1',
      title: 'Spring Coffee Walk',
      description: 'A neighborhood coffee walk to welcome spring.',
      category: 'Coffee',
      eventType: ExpertiseEventType.tour,
      host: host,
      startTime: DateTime.utc(2026, 3, 21, 17),
      endTime: DateTime.utc(2026, 3, 21, 19),
      location: 'Avondale',
      maxAttendees: 24,
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      status: EventStatus.upcoming,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EventPublishedPage(event: event),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event Published!'), findsOneWidget);
    expect(find.text('Open Safety Checklist'), findsOneWidget);
    expect(
      find.text(
        'Safety acknowledgments and the host debrief both continue on the event details flow.',
      ),
      findsOneWidget,
    );
  });
}
