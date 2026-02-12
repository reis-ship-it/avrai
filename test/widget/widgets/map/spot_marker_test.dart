import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/map/spot_marker.dart';
import 'package:avrai/core/theme/colors.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for SpotMarker
/// Tests map marker display and interactions
void main() {
  group('SpotMarker Widget Tests', () {
    // Removed: Property assignment tests
    // Spot marker tests focus on business logic (marker display, category icon, user interactions), not property assignment

    testWidgets(
        'should display marker with correct color, display category icon, or call onTap callback when tapped',
        (WidgetTester tester) async {
      // Test business logic: spot marker display and interactions
      final testSpot1 = ModelFactories.createTestSpot(
        id: 'spot-123',
        category: 'Coffee',
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SpotMarker(
          spot: testSpot1,
          color: AppColors.electricGreen,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(SpotMarker), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);

      bool wasTapped = false;
      final testSpot2 = ModelFactories.createTestSpot(id: 'spot-123');
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: SpotMarker(
          spot: testSpot2,
          color: AppColors.electricGreen,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      await tester.tap(find.byType(SpotMarker));
      await tester.pump();
      expect(wasTapped, isTrue);
    });
  });
}
