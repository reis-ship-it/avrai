// Scan Friend QR Page Tests

import 'package:avrai/injection_container.dart' as di;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/presentation/pages/social/scan_friend_qr_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_discovery_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../../widget/mocks/mock_blocs.dart';

class _MockSocialMediaDiscoveryService extends Mock
    implements SocialMediaDiscoveryService {}

class _MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('ScanFriendQRPage', () {
    late _MockSocialMediaDiscoveryService mockDiscoveryService;
    late _MockAgentIdService mockAgentIdService;

    setUp(() async {
      await di.sl.reset();
      mockDiscoveryService = _MockSocialMediaDiscoveryService();
      mockAgentIdService = _MockAgentIdService();
      di.sl.registerSingleton<SocialMediaDiscoveryService>(mockDiscoveryService);
      di.sl.registerSingleton<AgentIdService>(mockAgentIdService);
    });

    tearDown(() async {
      await di.sl.reset();
    });

    testWidgets('should display scanner view initially', (tester) async {
      final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const ScanFriendQRPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Scan Friend QR Code'), findsOneWidget);
      expect(find.text('Position the QR code within the frame'), findsOneWidget);
    });
  });
}
