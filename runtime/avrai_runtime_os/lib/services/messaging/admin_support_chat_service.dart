import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_learning_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_planner.dart';
import 'package:avrai_runtime_os/services/messaging/bham_transport_policy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class AdminSupportChatService {
  static const String _storeName = 'bham_admin_support_chat';

  AdminSupportChatService({
    BhamRoutePlanner? routePlanner,
    BhamRouteLearningService? routeLearningService,
    BhamTransportPolicy? transportPolicy,
  })  : _routePlanner = routePlanner ??
            BhamRoutePlanner(
              routeLearningService: routeLearningService,
            ),
        _routeLearningService =
            routeLearningService ?? BhamRouteLearningService(),
        _transportPolicy = transportPolicy ?? const BhamTransportPolicy();

  final BhamRoutePlanner _routePlanner;
  final BhamRouteLearningService _routeLearningService;
  final BhamTransportPolicy _transportPolicy;

  String threadIdForUser(String userId) => 'admin_support:$userId';

  Future<List<BhamThreadMessage>> getConversationHistory(String userId) async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>(threadIdForUser(userId)) ?? <dynamic>[];
    return raw
        .map(
          (entry) => BhamThreadMessage.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
  }

  Future<ChatThreadSummary> getThreadSummary(String userId) async {
    final history = await getConversationHistory(userId);
    final last = history.isEmpty ? null : history.last;
    return ChatThreadSummary(
      threadId: threadIdForUser(userId),
      kind: ChatThreadKind.admin,
      title: 'Admin support',
      subtitle: 'Pseudonymous day-1 support thread',
      lastActivityAtUtc: last?.createdAtUtc ?? DateTime.now().toUtc(),
      lastMessagePreview: last?.body,
      unreadCount: 0,
      visibilityState: ThreadVisibilityState.active,
      routeReceipt: last?.routeReceipt,
    );
  }

  Future<BhamThreadMessage> sendMessage({
    required String userId,
    required String body,
  }) async {
    final messageId = const Uuid().v4();
    final expiresAtUtc = DateTime.now()
        .toUtc()
        .add(_transportPolicy.ttlForThreadKind(ChatThreadKind.admin));
    final routePlan = await _routePlanner.planRoutes(
      messageId: messageId,
      threadKind: ChatThreadKind.admin,
      expiresAtUtc: expiresAtUtc,
      availability: const <TransportMode, bool>{
        TransportMode.ble: true,
        TransportMode.localWifi: true,
        TransportMode.nearbyRelay: true,
        TransportMode.wormhole: true,
      },
      exploratory: true,
    );
    var routeReceipt = _routePlanner.buildQueuedReceipt(
      routePlan: routePlan,
      channel: 'admin_support',
      expiresAtUtc: expiresAtUtc,
    );
    final attempted = routePlan.candidateRoutes.take(2).toList();
    routeReceipt = _routePlanner.markReleased(
        receipt: routeReceipt, attemptedRoutes: attempted);
    final winningRoute =
        attempted.isEmpty ? routePlan.candidateRoutes.first : attempted.first;
    routeReceipt = _routePlanner.markCustodyAccepted(
      receipt: routeReceipt,
      winningRoute: winningRoute,
      winningRouteReason: 'beta support custody accepted',
      custodyAcceptedBy: winningRoute.mode.name,
    );
    routeReceipt = _routePlanner.markDelivered(
      receipt: routeReceipt,
      winningRoute: winningRoute,
      winningRouteReason: 'initial beta support routing',
    );
    await _routeLearningService.recordSignal(
      RouteLearningSignal(
        messageId: messageId,
        mode: winningRoute.mode,
        success: true,
        observedAtUtc: DateTime.now().toUtc(),
        latencyMs: winningRoute.estimatedLatencyMs,
      ),
    );
    final message = BhamThreadMessage(
      messageId: messageId,
      threadId: threadIdForUser(userId),
      threadKind: ChatThreadKind.admin,
      senderId: userId,
      body: body,
      createdAtUtc: DateTime.now().toUtc(),
      routeReceipt: routeReceipt,
    );
    await _appendMessage(message);
    return message;
  }

  Future<void> seedAdminReply({
    required String userId,
    required String body,
  }) async {
    final message = BhamThreadMessage(
      messageId: const Uuid().v4(),
      threadId: threadIdForUser(userId),
      threadKind: ChatThreadKind.admin,
      senderId: 'admin',
      body: body,
      createdAtUtc: DateTime.now().toUtc(),
      metadata: const <String, dynamic>{'pseudonymous': true},
    );
    await _appendMessage(message);
  }

  Future<void> _appendMessage(BhamThreadMessage message) async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>(message.threadId) ?? <dynamic>[];
    raw.add(message.toJson());
    await box.write(message.threadId, raw);
  }
}
