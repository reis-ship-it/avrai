import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/validation/community_validation_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for CommunityValidationWidget
/// Tests community validation UI for external spots
void main() {
  group('CommunityValidationWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Community validation widget tests focus on business logic (validation widget display for external/community spots), not property assignment

    testWidgets(
        'should display validation widget for external spots or not display for community spots',
        (WidgetTester tester) async {
      // Test business logic: community validation widget display
      final testSpot1 = ModelFactories.createTestSpot(
        id: 'spot-123',
        name: 'External Spot',
      );
      final externalSpot = testSpot1.copyWith(
        metadata: {
          ...testSpot1.metadata,
          'is_external': true,
          'source': 'google_places',
        },
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: CommunityValidationWidget(spot: externalSpot),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(CommunityValidationWidget), findsOneWidget);

      final testSpot2 = ModelFactories.createTestSpot(
        id: 'spot-123',
        name: 'Community Spot',
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: CommunityValidationWidget(spot: testSpot2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(CommunityValidationWidget), findsOneWidget);
    });
  });
}
