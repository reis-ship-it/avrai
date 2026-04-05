import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/pages/bootloader_page.dart';
import 'package:avrai/presentation/widgets/portal/avrai_portal_layout.dart';
import 'package:avrai/presentation/widgets/shell/app_shell_host.dart';
import 'package:avrai/theme/app_theme.dart';

void main() {
  Widget buildAppShell({
    required AppShellVariant variant,
    required Widget child,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: AppShellHost(
        variant: variant,
        child: child,
      ),
    );
  }

  group('AppShellHost', () {
    testWidgets(
      'uses the standard shell for the beta variant',
      (tester) async {
        await tester.pumpWidget(
          buildAppShell(
            variant: AppShellVariant.standard,
            child: const Text('standard child'),
          ),
        );

        expect(find.text('standard child'), findsOneWidget);
        expect(find.byType(BootloaderPage), findsNothing);
        expect(find.byType(AvraiPortalLayout), findsNothing);
      },
    );

    testWidgets(
      'uses the immersive shell for the immersive variant',
      (tester) async {
        await tester.pumpWidget(
          buildAppShell(
            variant: AppShellVariant.immersive,
            child: const Text('immersive child'),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(BootloaderPage), findsOneWidget);
        expect(find.byType(AvraiPortalLayout), findsOneWidget);
      },
    );
  });
}
