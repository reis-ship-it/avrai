import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/offline_indicator.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/models/user/user.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for OfflineIndicator
/// Tests offline indicator display based on auth state
void main() {
  group('OfflineIndicator Widget Tests', () {
    // Note: MockAuthBloc's stream is a single-value broadcast stream per
    // setState(). To avoid stale subscriptions, use a fresh bloc per scenario.

    // Removed: Property assignment tests
    // Offline indicator tests focus on business logic (offline indicator display based on auth state), not property assignment

    testWidgets(
        'should display offline indicator when user is offline, not display when user is online, or not display when user is not authenticated',
        (WidgetTester tester) async {
      // Test business logic: Offline indicator display based on auth state
      final testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
      final authBlocOffline = MockAuthBloc()
        ..setState(Authenticated(user: testUser, isOffline: true));
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const OfflineIndicator(),
        authBloc: authBlocOffline,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      final authBlocOnline = MockAuthBloc()
        ..setState(Authenticated(user: testUser, isOffline: false));
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const OfflineIndicator(),
        authBloc: authBlocOnline,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Offline'), findsNothing);

      final authBlocUnauthed = MockAuthBloc()..setState(Unauthenticated());
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const OfflineIndicator(),
        authBloc: authBlocUnauthed,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Offline'), findsNothing);
    });
  });
}
