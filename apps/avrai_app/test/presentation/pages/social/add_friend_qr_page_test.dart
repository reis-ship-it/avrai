// Add Friend QR Page Tests

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/presentation/pages/social/add_friend_qr_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import '../../../widget/mocks/mock_blocs.dart';

class _MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('AddFriendQRPage', () {
    late _MockAgentIdService mockAgentIdService;

    setUp(() async {
      await di.sl.reset();
      mockAgentIdService = _MockAgentIdService();
      when(() => mockAgentIdService.getUserAgentId(any()))
          .thenAnswer((_) async => 'agent_test_123');
      di.sl.registerSingleton<AgentIdService>(mockAgentIdService);
    });

    tearDown(() async {
      await di.sl.reset();
    });

    testWidgets('should display QR code after loading agent id',
        (tester) async {
      final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const AddFriendQRPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.text('Let your friend scan this QR code'), findsOneWidget);
      expect(find.text('Copy Agent ID'), findsOneWidget);
    });
  });
}
