import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/design/design_playground_page.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('design playground light golden', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_wrap(const DesignPlaygroundPage()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DesignPlaygroundPage),
      matchesGoldenFile('goldens/design_playground_light.png'),
    );
  });

  testWidgets('design playground dark golden', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const DesignPlaygroundPage(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DesignPlaygroundPage),
      matchesGoldenFile('goldens/design_playground_dark.png'),
    );
  });

  testWidgets('design playground iOS-style golden', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        const DesignPlaygroundPage(),
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DesignPlaygroundPage),
      matchesGoldenFile('goldens/design_playground_ios.png'),
    );
  });

  testWidgets('design playground android-style golden', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        const DesignPlaygroundPage(),
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.android),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DesignPlaygroundPage),
      matchesGoldenFile('goldens/design_playground_android.png'),
    );
  });
}
