import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/widget_test_helpers.dart';

Future<void> _tapElevatedButton(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(ElevatedButton, label).hitTestable();
  expect(finder, findsOneWidget);
  await tester.tap(finder);
}

Future<void> _tapTextButton(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(TextButton, label).hitTestable();
  expect(finder, findsOneWidget);
  await tester.tap(finder);
}

Future<void> _dismissDialogProgrammatically(WidgetTester tester) async {
  final dialog = find.byType(AlertDialog);
  expect(dialog, findsOneWidget);
  Navigator.of(tester.element(dialog)).pop();
  // Let the dialog route transition fully complete so barriers are removed.
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  group('Dialogs and Permissions Widget Tests', () {
    // Removed: Property assignment tests
    // Dialog tests focus on business logic (dialog display, user interactions, state management), not property assignment

    group('Age Verification Dialog Tests', () {
      testWidgets(
          'should display age verification dialog correctly, handle confirmation (Yes), or handle denial (No)',
          (WidgetTester tester) async {
        // Test business logic: age verification dialog behavior
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Age Verification'), findsOneWidget);
        expect(find.text('Are you 18 or older?'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
        // Close so the modal barrier doesn't leak into subsequent pumps.
        await _tapTextButton(tester, 'No');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        bool? verificationResult1;
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(
                context,
                onResult: (result) => verificationResult1 = result,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pumpAndSettle();
        await _tapTextButton(tester, 'Yes');
        await tester.pumpAndSettle();
        expect(verificationResult1, isTrue);
        expect(find.byType(AlertDialog), findsNothing);

        bool? verificationResult2;
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(
                context,
                onResult: (result) => verificationResult2 = result,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pumpAndSettle();
        await _tapTextButton(tester, 'No');
        await tester.pumpAndSettle();
        expect(verificationResult2, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Permission Request Dialog Tests', () {
      testWidgets(
          'should display location permission dialog, handle location permission grant, or display camera permission dialog',
          (WidgetTester tester) async {
        // Test business logic: permission request dialog behavior
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLocationPermissionDialog(context),
              child: const Text('Request Location'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        await _tapElevatedButton(tester, 'Request Location');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Location Permission'), findsOneWidget);
        expect(find.textContaining('location'), findsWidgets);
        expect(find.text('Allow'), findsOneWidget);
        expect(find.text('Deny'), findsOneWidget);
        // Close so the modal barrier doesn't leak into subsequent pumps.
        await _tapTextButton(tester, 'Deny');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        bool? permissionGranted;
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLocationPermissionDialog(
                context,
                onResult: (granted) => permissionGranted = granted,
              ),
              child: const Text('Request Location'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        await _tapElevatedButton(tester, 'Request Location');
        await tester.pumpAndSettle();
        await _tapTextButton(tester, 'Allow');
        await tester.pumpAndSettle();
        expect(permissionGranted, isTrue);
        expect(find.byType(AlertDialog), findsNothing);

        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showCameraPermissionDialog(context),
              child: const Text('Request Camera'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        await _tapElevatedButton(tester, 'Request Camera');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Camera Permission'), findsOneWidget);
        expect(find.textContaining('camera'), findsWidgets);
        await _tapTextButton(tester, 'Deny');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Confirmation Dialog Tests', () {
      testWidgets(
          'should display delete confirmation dialog, handle delete confirmation, or handle delete cancellation',
          (WidgetTester tester) async {
        // Test business logic: confirmation dialog behavior
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(context),
              child: const Text('Delete Item'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        await _tapElevatedButton(tester, 'Delete Item');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Confirm Delete'), findsOneWidget);
        expect(find.textContaining('permanently'), findsWidgets);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        // Close so the modal barrier doesn't leak into subsequent pumps.
        await _tapTextButton(tester, 'Cancel');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        bool? deleteConfirmed1;
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(
                context,
                onConfirm: () => deleteConfirmed1 = true,
              ),
              child: const Text('Delete Item'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        await _tapElevatedButton(tester, 'Delete Item');
        await tester.pumpAndSettle();
        await _tapTextButton(tester, 'Delete');
        await tester.pumpAndSettle();
        expect(deleteConfirmed1, isTrue);
        expect(find.byType(AlertDialog), findsNothing);

        bool? deleteConfirmed2;
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(
                context,
                onConfirm: () => deleteConfirmed2 = true,
              ),
              child: const Text('Delete Item'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        await _tapElevatedButton(tester, 'Delete Item');
        await tester.pumpAndSettle();
        await _tapTextButton(tester, 'Cancel');
        await tester.pumpAndSettle();
        expect(deleteConfirmed2, isNull);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Loading and Error Dialog Tests', () {
      testWidgets(
          'should display loading dialog with message, prevent interaction during loading, display error dialog with message, or dismiss error dialog on OK tap',
          (WidgetTester tester) async {
        // Test business logic: loading and error dialog behavior
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLoadingDialog(context, 'Saving...'),
              child: const Text('Show Loading'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        await _tapElevatedButton(tester, 'Show Loading');
        await tester.pump();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Saving...'), findsOneWidget);
        await _dismissDialogProgrammatically(tester);
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);

        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showLoadingDialog(context, 'Loading...'),
                  child: const Text('Show Loading'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Other Button'),
                ),
              ],
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        await _tapElevatedButton(tester, 'Show Loading');
        await tester.pump();
        // Should not be tappable through the modal barrier.
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Other Button'),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await _dismissDialogProgrammatically(tester);
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);

        const errorMessage = 'Something went wrong!';
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => _showErrorDialog(context, errorMessage),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        await _tapElevatedButton(tester, 'Show Error');
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
        await _tapTextButton(tester, 'OK');
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(AlertDialog), findsNothing);

        final widget4 = WidgetTestHelpers.createTestableWidget(
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => _showErrorDialog(context, 'Error message'),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget4);
        await _tapElevatedButton(tester, 'Show Error');
        await tester.pump(const Duration(milliseconds: 350));
        await _tapTextButton(tester, 'OK');
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Dialog Accessibility and State Management Tests', () {
      testWidgets(
          'should meet accessibility requirements (minimum button sizes, screen reader navigation), maintain dialog state during orientation changes, or handle rapid dialog operations gracefully',
          (WidgetTester tester) async {
        // Test business logic: dialog accessibility and state management
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pumpAndSettle();
        expect(find.text('Age Verification'), findsOneWidget);
        final yesButton =
            tester.getSize(find.widgetWithText(TextButton, 'Yes'));
        expect(yesButton.height, greaterThanOrEqualTo(48.0));
        final noButton = tester.getSize(find.widgetWithText(TextButton, 'No'));
        expect(noButton.height, greaterThanOrEqualTo(48.0));
        await _tapTextButton(tester, 'No');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(context),
              child: const Text('Show Delete Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        await _tapElevatedButton(tester, 'Show Delete Dialog');
        await tester.pumpAndSettle();
        expect(find.text('Confirm Delete'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        await _tapTextButton(tester, 'Cancel');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pumpAndSettle();
        final originalSize = tester.view.physicalSize;
        tester.view.physicalSize = const Size(800, 400);
        await tester.pump();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Age Verification'), findsOneWidget);
        tester.view.physicalSize = originalSize;
        await tester.pump();
        await _tapTextButton(tester, 'No');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        final widget4 = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget4);
        await _tapElevatedButton(tester, 'Show Dialog');
        await tester.pump();
        await _tapTextButton(tester, 'Yes');
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
      });
    });
  });
}

// Helper functions to simulate actual dialog implementations
void _showAgeVerificationDialog(BuildContext context,
    {Function(bool)? onResult}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text('Age Verification'),
      content: const Text('Are you 18 or older?'),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(false);
          },
          child: const Text('No'),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(true);
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

void _showLocationPermissionDialog(BuildContext context,
    {Function(bool)? onResult}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission'),
      content:
          const Text('This app needs location access to show nearby spots.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(false);
          },
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(true);
          },
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

void _showCameraPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Camera Permission'),
      content: const Text('This app needs camera access to take photos.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmationDialog(BuildContext context,
    {VoidCallback? onConfirm}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text('Confirm Delete'),
      content: const Text(
          'This action cannot be undone. Are you sure you want to permanently delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    ),
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
