import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_badge_widget.dart';
import 'package:avrai_core/models/expertise/expertise_pin.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ExpertiseBadgeWidget
/// Tests expertise badge display
void main() {
  group('ExpertiseBadgeWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expertise badge widget tests focus on business logic (badge display, category matching, compact mode), not property assignment

    testWidgets(
        'should display badge when expert pins are provided, not display when no relevant pins, or display compact badge when compact is true',
        (WidgetTester tester) async {
      // Test business logic: expertise badge display
      final testPin1 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseBadgeWidget(
          expertPins: [testPin1],
          category: 'Coffee',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Verified by Experts'), findsOneWidget);

      final testPin2 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseBadgeWidget(
          expertPins: [testPin2],
          category: 'Restaurant', // Different category
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Verified by Experts'), findsNothing);

      final testPin3 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseBadgeWidget(
          expertPins: [testPin3],
          category: 'Coffee',
          compact: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Expert'), findsOneWidget);
    });
  });
}
