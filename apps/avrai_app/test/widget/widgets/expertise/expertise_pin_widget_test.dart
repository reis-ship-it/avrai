import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_pin_widget.dart';
import 'package:avrai_core/models/expertise/expertise_pin.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ExpertisePinWidget
/// Tests expertise pin display
void main() {
  group('ExpertisePinWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expertise pin widget tests focus on business logic (pin display, level details, user interactions), not property assignment

    testWidgets(
        'should display pin information correctly, display level details when showDetails is true, or call onTap callback when tapped',
        (WidgetTester tester) async {
      // Test business logic: expertise pin display and interactions
      final testPin1 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ExpertisePinWidget(pin: testPin1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Coffee'), findsOneWidget);

      final testPin2 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ExpertisePinWidget(
          pin: testPin2,
          showDetails: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('City Level'), findsOneWidget);

      bool wasTapped = false;
      final testPin3 = ExpertisePin(
        id: 'pin-123',
        userId: 'user-123',
        category: 'Coffee',
        level: ExpertiseLevel.city,
        earnedAt: TestHelpers.createTestDateTime(),
        earnedReason: 'Test',
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertisePinWidget(
          pin: testPin3,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      await tester.tap(find.byType(ExpertisePinWidget));
      await tester.pump();
      expect(wasTapped, isTrue);
    });
  });
}
