import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_planner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    await GetStorage.init('bham_route_learning');
  });

  setUp(() async {
    await GetStorage('bham_route_learning').erase();
  });

  group('BhamRoutePlanner', () {
    test('plans wormhole as a first-class route before release', () async {
      final planner = BhamRoutePlanner();

      final plan = await planner.planRoutes(
        messageId: 'message-1',
        threadKind: ChatThreadKind.event,
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
        availability: const <TransportMode, bool>{
          TransportMode.ble: true,
          TransportMode.localWifi: true,
          TransportMode.nearbyRelay: true,
          TransportMode.wormhole: true,
        },
      );

      expect(plan.candidateRoutes, isNotEmpty);
      expect(
        plan.candidateRoutes
            .any((route) => route.mode == TransportMode.wormhole),
        isTrue,
      );
    });

    test('tracks custody, delivery, read, and learning milestones', () async {
      final planner = BhamRoutePlanner();

      final plan = await planner.planRoutes(
        messageId: 'message-2',
        threadKind: ChatThreadKind.matchedDirect,
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
        availability: const <TransportMode, bool>{
          TransportMode.ble: true,
          TransportMode.wormhole: true,
        },
      );
      final queued = planner.buildQueuedReceipt(
        routePlan: plan,
        channel: 'friend_chat',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final released = planner.markReleased(
        receipt: queued,
        attemptedRoutes: plan.candidateRoutes,
      );
      final custodyAccepted = planner.markCustodyAccepted(
        receipt: released,
        winningRoute: plan.candidateRoutes.first,
      );
      final delivered = planner.markDelivered(
        receipt: custodyAccepted,
        winningRoute: plan.candidateRoutes.first,
      );
      final read = planner.markRead(
        receipt: delivered,
        readBy: 'user-b',
      );
      final learningApplied = planner.markLearningApplied(
        receipt: read,
        learningAppliedBy: 'agent-b',
      );

      expect(custodyAccepted.status, 'custody_accepted');
      expect(custodyAccepted.custodyAcceptedAtUtc, isNotNull);
      expect(custodyAccepted.lifecycleStage,
          TransportReceiptLifecycleStage.custodyAccepted);
      expect(delivered.status, 'delivered');
      expect(delivered.deliveredAtUtc, isNotNull);
      expect(read.status, 'read');
      expect(read.readAtUtc, isNotNull);
      expect(read.readBy, 'user-b');
      expect(learningApplied.status, 'learning_applied');
      expect(learningApplied.learningAppliedAtUtc, isNotNull);
      expect(learningApplied.learningAppliedBy, 'agent-b');
      expect(
        learningApplied.lifecycleStage,
        TransportReceiptLifecycleStage.learningApplied,
      );

      final roundTripped = TransportRouteReceipt.fromJson(
        learningApplied.toJson(),
      );
      expect(roundTripped.custodyAcceptedAtUtc, isNotNull);
      expect(roundTripped.readAtUtc, isNotNull);
      expect(roundTripped.learningAppliedAtUtc, isNotNull);
      expect(roundTripped.learningAppliedBy, 'agent-b');
    });

    test('marks delivered route with winning path and attempts', () async {
      final planner = BhamRoutePlanner();

      final plan = await planner.planRoutes(
        messageId: 'message-3',
        threadKind: ChatThreadKind.matchedDirect,
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
        availability: const <TransportMode, bool>{
          TransportMode.ble: true,
          TransportMode.wormhole: true,
        },
      );
      final queued = planner.buildQueuedReceipt(
        routePlan: plan,
        channel: 'friend_chat',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final released = planner.markReleased(
        receipt: queued,
        attemptedRoutes: plan.candidateRoutes,
      );
      final delivered = planner.markDelivered(
        receipt: released,
        winningRoute: plan.candidateRoutes.first,
      );

      expect(delivered.status, 'delivered');
      expect(delivered.winningRoute, isNotNull);
      expect(delivered.attemptedRoutes, isNotEmpty);
      expect(delivered.custodyAcceptedAtUtc, isNotNull);
    });
  });
}
