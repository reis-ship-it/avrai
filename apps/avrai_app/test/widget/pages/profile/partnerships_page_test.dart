import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/profile/partnerships_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai_core/models/user/user.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('PartnershipsPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    // Removed: Property assignment tests
    // Partnerships page tests focus on business logic (page display, empty state), not property assignment

    testWidgets(
        'should display partnerships page or display empty state when no partnerships',
        (WidgetTester tester) async {
      // Test business logic: Partnerships page display
      final now = DateTime.now();
      mockAuthBloc.setState(
        Authenticated(
          user: User(
            id: 'test-user-id',
            email: 'test@example.com',
            name: 'Test User',
            role: UserRole.user,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PartnershipsPage(),
        authBloc: mockAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(PartnershipsPage), findsOneWidget);
      expect(find.text('Your Partnerships'), findsOneWidget);
    });
  });
}
