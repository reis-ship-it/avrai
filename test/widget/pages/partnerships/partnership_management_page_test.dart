import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart' hide UserRole;
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_management_page.dart';

import '../../../helpers/getit_test_harness.dart';
import '../../mocks/mock_blocs.dart';

/// Partnership Management Page Widget Tests
///
/// Agent 2: Partnership UI, Business UI (Week 8)
///
/// Tests the partnership management page functionality.
void main() {
  group('PartnershipManagementPage Widget Tests', () {
    setUpAll(() {
      // Needed for mocktail `any()` on `UnifiedUser` arguments.
      registerFallbackValue(
        UnifiedUser(
          id: 'fallback-user',
          email: 'fallback@example.com',
          createdAt: DateTime(2020, 1, 1),
          updatedAt: DateTime(2020, 1, 1),
        ),
      );
    });

    late GetItTestHarness getIt;
    late MockAuthBloc mockAuthBloc;
    late _MockPartnershipService mockPartnershipService;
    late _MockExpertiseEventService mockEventService;

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      mockAuthBloc = MockAuthBloc();
      mockPartnershipService = _MockPartnershipService();
      mockEventService = _MockExpertiseEventService();

      final now = DateTime.now();
      mockAuthBloc.setState(
        Authenticated(
          user: User(
            id: 'user-1',
            email: 'user@example.com',
            name: 'Test User',
            role: UserRole.user,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );

      // Register minimal GetIt dependencies used by the page.
      getIt.registerSingletonReplace<PartnershipService>(mockPartnershipService);
      getIt.registerSingletonReplace<ExpertiseEventService>(mockEventService);

      // Default: no events, no partnerships (empty state).
      when(() => mockEventService.getEventsByHost(any()))
          .thenAnswer((_) async => <ExpertiseEvent>[]);
      when(() => mockPartnershipService.getPartnershipsForEvent(any()))
          .thenAnswer((_) async => <EventPartnership>[]);
    });

    tearDown(() {
      mockAuthBloc.close();
      getIt.unregisterIfRegistered<PartnershipService>();
      getIt.unregisterIfRegistered<ExpertiseEventService>();
    });

    // Removed: Property assignment tests
    // Partnership management page tests focus on business logic (page display, tab navigation, new partnership button, empty state), not property assignment

    testWidgets(
        'should display partnership management page, display tab navigation, display new partnership button, or show empty state when no partnerships',
        (WidgetTester tester) async {
      // Test business logic: Partnership management page display and functionality
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const PartnershipManagementPage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('My Partnerships'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('New Partnership'), findsOneWidget);
      await tester.pumpAndSettle();
      // Empty state copy is stable; the header includes dynamic status text.
      expect(find.text('Create a partnership to get started'), findsOneWidget);
    });
  });
}

class _MockPartnershipService extends Mock implements PartnershipService {}

class _MockExpertiseEventService extends Mock implements ExpertiseEventService {}
