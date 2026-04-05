import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('OnboardingPage Widget Tests', () {
    const deviceCapabilitiesChannel = MethodChannel('avra/device_capabilities');
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceCapabilitiesChannel,
              (MethodCall methodCall) async {
        if (methodCall.method != 'getCapabilities') {
          return null;
        }
        return <String, Object?>{
          'platform': 'ios',
          'deviceModel': 'iPhone 15',
          'osVersion': 18,
          'totalRamMb': 8192,
          'freeDiskMb': 32768,
          'totalDiskMb': 131072,
          'cpuCores': 6,
          'isLowPowerMode': false,
        };
      });
      mockAuthBloc = MockAuthBloc();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceCapabilitiesChannel, null);
      mockAuthBloc.close();
    });

    // Removed: Property assignment tests
    // Onboarding page tests focus on business logic (initial step display, navigation, button states), not property assignment

    testWidgets('shows questionnaire step first and hides skip shortcut',
        (WidgetTester tester) async {
      mockAuthBloc.setState(AuthInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const OnboardingPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Birmingham beta questionnaire'), findsOneWidget);
      expect(
        find.text(
          'Answer the 11 direct BHAM prompts exactly once. This is the full questionnaire for the first slice.',
        ),
        findsOneWidget,
      );
      expect(find.text('What do you want more of right now?'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('advances from questionnaire into the consent step',
        (WidgetTester tester) async {
      mockAuthBloc.setState(AuthInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const OnboardingPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(10));
      for (var i = 0; i < 10; i++) {
        await tester.enterText(textFields.at(i), 'Answer ${i + 1}');
      }
      await tester.ensureVisible(find.text('In the middle'));
      await tester.tap(find.text('In the middle'));
      await tester.pump();

      expect(find.widgetWithText(AppButtonPrimary, 'Continue'), findsOneWidget);

      await tester
          .ensureVisible(find.widgetWithText(AppButtonPrimary, 'Continue'));
      await tester.tap(find.widgetWithText(AppButtonPrimary, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Birmingham beta consent'), findsOneWidget);
      expect(find.text('What AVRAI is doing in beta'), findsOneWidget);
      expect(find.text('I accept the Terms of Service.'), findsOneWidget);
    });
  });
}
