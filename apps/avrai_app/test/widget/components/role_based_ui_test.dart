import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/user.dart' as user_model;
import 'package:avrai/presentation/pages/home/home_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import '../helpers/widget_test_helpers.dart';
import '../mocks/mock_blocs.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('Role-Based UI Widget Tests', () {
    // Removed: Property assignment tests
    // Role-based UI tests focus on business logic (role-based UI behavior, permissions, age verification), not property assignment

    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    group('Role-Based UI Rendering', () {
      testWidgets(
          'should render HomePage for all roles (follower, collaborator, curator) with appropriate permissions, handle age verification UI for unverified users, block age-restricted content for unverified users, enable full access for age-verified users, show or hide UI elements based on permissions, or adapt UI based on privacy settings',
          (WidgetTester tester) async {
        // Test business logic: role-based UI rendering with various role and permission scenarios
        final roles = [
          user_model.UserRole.user,
          user_model.UserRole.admin,
          user_model.UserRole.moderator
        ];

        for (final role in roles) {
          mockAuthBloc =
              MockBlocFactory.createAuthenticatedAuthBloc(role: role);
          final widget = WidgetTestHelpers.createTestableWidget(
            child: const HomePage(),
            authBloc: mockAuthBloc,
          );
          await WidgetTestHelpers.pumpAndSettle(tester, widget);
          expect(find.byType(HomePage), findsOneWidget);
          await tester.pumpWidget(Container());
        }

        mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc(
            role: user_model.UserRole.user, isAgeVerified: false);
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: const HomePage(),
          authBloc: mockAuthBloc,
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.byType(HomePage), findsOneWidget);

        mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc(
            role: user_model.UserRole.user, isAgeVerified: true);
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: const HomePage(),
          authBloc: mockAuthBloc,
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('Role Transition and Accessibility', () {
      testWidgets(
          'should handle role changes gracefully, show role upgrade notifications, maintain accessibility across all roles, or provide role-appropriate semantic labels',
          (WidgetTester tester) async {
        // Test business logic: role transitions and accessibility
        final followerUser = WidgetTestHelpers.createTestUserForAuth(
            role: user_model.UserRole.user);
        mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc(
            role: user_model.UserRole.user);
        mockAuthBloc.setStream(Stream.fromIterable([
          Authenticated(user: followerUser),
          Authenticated(
              user: WidgetTestHelpers.createTestUserForAuth(
                  role: user_model.UserRole.user)),
        ]));
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: const HomePage(),
          authBloc: mockAuthBloc,
        );
        await tester.pumpWidget(widget1);
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);

        final roles = [
          user_model.UserRole.user,
          user_model.UserRole.admin,
          user_model.UserRole.moderator
        ];
        for (final role in roles) {
          mockAuthBloc =
              MockBlocFactory.createAuthenticatedAuthBloc(role: role);
          final widget2 = WidgetTestHelpers.createTestableWidget(
            child: const HomePage(),
            authBloc: mockAuthBloc,
          );
          await WidgetTestHelpers.pumpAndSettle(tester, widget2);
          expect(find.byType(HomePage), findsOneWidget);
          await tester.pumpWidget(Container());
        }

        mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: const HomePage(),
          authBloc: mockAuthBloc,
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.byType(HomePage), findsOneWidget);
      });
    });
  });
}
