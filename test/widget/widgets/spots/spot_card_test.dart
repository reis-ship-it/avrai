import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/spots/spot_card.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for SpotCard
/// Tests spot card display and interactions
void main() {
  group('SpotCard Widget Tests', () {
    // Removed: Property assignment tests
    // Spot card tests focus on business logic (spot card display, user interactions), not property assignment

    testWidgets(
        'should display spot information correctly, display spot rating when available, call onTap callback when tapped, or display custom trailing widget',
        (WidgetTester tester) async {
      // Test business logic: spot card display and interactions
      final testSpot1 = ModelFactories.createTestSpot(
        id: 'spot-123',
        name: 'Test Coffee Shop',
        category: 'Cafe',
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SpotCard(spot: testSpot1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Test Coffee Shop'), findsOneWidget);
      expect(find.text('Cafe'), findsOneWidget);

      final testSpot2 = ModelFactories.createTestSpot(
        id: 'spot-123',
        name: 'Rated Spot',
        category: 'Restaurant',
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: SpotCard(spot: testSpot2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byIcon(Icons.star), findsOneWidget);

      bool wasTapped = false;
      final testSpot3 = ModelFactories.createTestSpot(id: 'spot-123');
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: SpotCard(
          spot: testSpot3,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      await tester.tap(find.byType(SpotCard));
      await tester.pump();
      expect(wasTapped, isTrue);

      final testSpot4 = ModelFactories.createTestSpot(id: 'spot-123');
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: SpotCard(
          spot: testSpot4,
          trailing: const Icon(Icons.favorite),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
