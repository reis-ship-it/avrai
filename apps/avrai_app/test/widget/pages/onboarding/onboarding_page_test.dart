import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('OnboardingPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    tearDown(() {
      mockAuthBloc.close();
    });

    // Removed: Property assignment tests
    // Onboarding page tests focus on business logic (initial step display, navigation, button states), not property assignment

    testWidgets('shows welcome step first and hides skip shortcut',
        (WidgetTester tester) async {
      mockAuthBloc.setState(AuthInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const OnboardingPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets(
        'advances from welcome into the first actionable onboarding step',
        (WidgetTester tester) async {
      mockAuthBloc.setState(AuthInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const OnboardingPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const Key('onboarding_primary_cta')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Age Verification'), findsWidgets);
    });
  });
}
