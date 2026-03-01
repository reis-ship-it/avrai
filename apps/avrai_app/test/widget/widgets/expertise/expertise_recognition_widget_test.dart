import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_recognition_widget.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_recognition_service.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertiseRecognitionWidget
/// Tests expertise recognition display
void main() {
  group('ExpertiseRecognitionWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expertise recognition widget tests focus on business logic (recognition display, loading state, user interactions), not property assignment

    testWidgets(
        'should display loading state initially, display recognition header, display recognize button when callback provided, or display featured expert widget',
        (WidgetTester tester) async {
      // Test business logic: expertise recognition widget display and interactions
      final expert1 = WidgetTestHelpers.createTestUser();
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(expert: expert1),
      );
      await tester.pumpWidget(widget1);
      await tester.pump(); // Don't settle, check loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final expert2 = WidgetTestHelpers.createTestUser();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(expert: expert2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Community Recognition'), findsOneWidget);

      final expert3 = WidgetTestHelpers.createTestUser();
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(
          expert: expert3,
          onRecognize: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Recognize Expert'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      final expert4 = WidgetTestHelpers.createTestUser();
      final featuredExpert = FeaturedExpert(
        expert: expert4,
        recognitionCount: 10,
        recentRecognitionCount: 3,
        recognitionScore: 0.9,
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: FeaturedExpertWidget(featuredExpert: featuredExpert),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byType(FeaturedExpertWidget), findsOneWidget);
      expect(find.text('Featured Expert'), findsOneWidget);
      expect(find.text('10 recognitions'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
