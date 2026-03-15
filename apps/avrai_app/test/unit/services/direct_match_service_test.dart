import 'package:avrai_runtime_os/services/messaging/direct_match_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DirectMatchService', () {
    late DirectMatchService service;

    setUpAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        },
      );
      await GetStorage.init('bham_direct_match');
    });

    setUp(() async {
      service = DirectMatchService();
      await GetStorage('bham_direct_match').erase();
    });

    test('does not create invitation below threshold', () async {
      final invitation = await service.createInvitation(
        userAId: 'user-a',
        userBId: 'user-b',
        compatibilityScore: 0.99,
      );

      expect(invitation, isNull);
    });

    test('opens matched thread only after both users accept', () async {
      final invitation = await service.createInvitation(
        userAId: 'user-a',
        userBId: 'user-b',
        compatibilityScore: 0.999,
      );

      expect(invitation, isNotNull);

      final first = await service.respond(
        invitationId: invitation!.invitationId,
        userId: 'user-a',
        accepted: true,
      );
      final second = await service.respond(
        invitationId: invitation.invitationId,
        userId: 'user-b',
        accepted: true,
      );

      expect(first.chatOpened, isFalse);
      expect(second.chatOpened, isTrue);
      expect(second.chatThreadId, isNotNull);
    });
  });
}
