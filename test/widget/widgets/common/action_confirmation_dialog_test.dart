/// SPOTS ActionConfirmationDialog Widget Tests
/// Date: November 20, 2025
/// Purpose: Test ActionConfirmationDialog widget functionality and UI behavior
///
/// Test Coverage:
/// - Rendering: Dialog displays correctly with various action types
/// - User Interactions: Cancel/confirm button taps
/// - Action Preview: Shows correct preview for each action type
/// - Edge Cases: Different action intents, null handling
///
/// Dependencies:
/// - ActionIntent models from core/ai/action_models.dart
/// - AppTheme for consistent styling
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/presentation/widgets/common/action_confirmation_dialog.dart';
import '../../helpers/widget_test_helpers.dart';

class _DialogLauncher extends StatefulWidget {
  final WidgetBuilder dialogBuilder;
  final bool barrierDismissible;

  const _DialogLauncher({
    super.key,
    required this.dialogBuilder,
    this.barrierDismissible = false,
  });

  @override
  State<_DialogLauncher> createState() => _DialogLauncherState();
}

class _DialogLauncherState extends State<_DialogLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: widget.barrierDismissible,
        builder: widget.dialogBuilder,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}

/// Widget tests for ActionConfirmationDialog
/// Tests dialog rendering, user interactions, and action preview display
void main() {
  group('ActionConfirmationDialog Widget Tests', () {
    // Removed: Property assignment tests
    // Action confirmation dialog tests focus on business logic (dialog display, user interactions, action preview), not property assignment

    testWidgets(
        'should display dialog correctly for CreateSpotIntent/CreateListIntent/AddSpotToListIntent, call onConfirm when confirm button is tapped, call onCancel when cancel button is tapped, dismiss dialog when tapping outside, show correct preview for CreateSpotIntent with all fields, show correct preview for CreateListIntent with public setting, handle CreateSpotIntent with minimal fields, or display confidence level when provided',
        (WidgetTester tester) async {
      // Test business logic: action confirmation dialog display, interactions, and preview
      const intent1 = CreateSpotIntent(
        name: 'Blue Bottle Coffee',
        description: 'A great coffee shop',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'Coffee',
        userId: 'user123',
        confidence: 0.95,
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_1'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent1,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(ActionConfirmationDialog), findsOneWidget);
      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Create Spot'), findsOneWidget);
      expect(find.text('Blue Bottle Coffee'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent2 = CreateListIntent(
        title: 'My Coffee Shops',
        description: 'Favorite coffee spots',
        userId: 'user123',
        confidence: 0.90,
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_2'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent2,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(ActionConfirmationDialog), findsOneWidget);
      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Create List'), findsOneWidget);
      expect(find.text('My Coffee Shops'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent3 = AddSpotToListIntent(
        spotId: 'spot123',
        listId: 'list456',
        userId: 'user123',
        confidence: 0.85,
        metadata: {
          'spotName': 'Blue Bottle Coffee',
          'listName': 'My Coffee Shops',
        },
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_3'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent3,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(ActionConfirmationDialog), findsOneWidget);
      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Add Spot to List'), findsOneWidget);
      expect(find.text('Blue Bottle Coffee'), findsOneWidget);
      expect(find.text('My Coffee Shops'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      bool confirmCalled = false;
      const intent4 = CreateSpotIntent(
        name: 'Test Spot',
        description: 'Test',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Test',
        userId: 'user123',
        confidence: 0.9,
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_4'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent4,
            onConfirm: () {
              confirmCalled = true;
            },
            onCancel: () {
            },
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(confirmCalled, isTrue);
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      bool cancelCalled = false;
      const intent5 = CreateSpotIntent(
        name: 'Test Spot',
        description: 'Test',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Test',
        userId: 'user123',
        confidence: 0.9,
      );
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_5'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent5,
            onConfirm: () {
            },
            onCancel: () {
              cancelCalled = true;
            },
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelCalled, isTrue);
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent6 = CreateSpotIntent(
        name: 'Test Spot',
        description: 'Test',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Test',
        userId: 'user123',
        confidence: 0.9,
      );
      final widget6 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_6'),
          barrierDismissible: true,
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent6,
            onConfirm: () {
            },
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget6);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent7 = CreateSpotIntent(
        name: 'Blue Bottle Coffee',
        description: 'A great coffee shop',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'Coffee',
        address: '123 Main St',
        tags: ['coffee', 'cafe'],
        userId: 'user123',
        confidence: 0.95,
      );
      final widget7 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_7'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent7,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget7);
      expect(find.text('Blue Bottle Coffee'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('123 Main St'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent8 = CreateListIntent(
        title: 'My Coffee Shops',
        description: 'Favorite coffee spots',
        category: 'Food & Drink',
        isPublic: true,
        tags: ['coffee', 'favorites'],
        userId: 'user123',
        confidence: 0.90,
      );
      final widget8 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_8'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent8,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget8);
      expect(find.text('My Coffee Shops'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent9 = CreateSpotIntent(
        name: 'Test Spot',
        description: '',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Other',
        userId: 'user123',
        confidence: 0.5,
      );
      final widget9 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_9'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent9,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget9);
      expect(find.byType(ActionConfirmationDialog), findsOneWidget);
      expect(find.text('Test Spot'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);

      const intent10 = CreateSpotIntent(
        name: 'Test Spot',
        description: 'Test',
        latitude: 0.0,
        longitude: 0.0,
        category: 'Test',
        userId: 'user123',
        confidence: 0.75,
      );
      final widget10 = WidgetTestHelpers.createTestableWidget(
        child: _DialogLauncher(
          key: const ValueKey('action_confirmation_dialog_10'),
          dialogBuilder: (dialogContext) => ActionConfirmationDialog(
            intent: intent10,
            onConfirm: () {},
            onCancel: () {},
            showConfidence: true,
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget10);
      expect(find.textContaining('75%'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionConfirmationDialog), findsNothing);
    });
  });
}
