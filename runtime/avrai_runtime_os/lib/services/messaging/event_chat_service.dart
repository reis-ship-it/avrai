import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_learning_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_planner.dart';
import 'package:avrai_runtime_os/services/messaging/bham_transport_policy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class EventChatService {
  static const String _messageStore = 'bham_event_chat';
  static const String _membershipStore = 'bham_event_chat_memberships';

  EventChatService({
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

  String eventThreadId(String eventId) => 'event:$eventId';
  String announcementThreadId(String scope, String scopeId) =>
      'announcement:$scope:$scopeId';

  Future<void> joinEventThread({
    required String userId,
    required String eventId,
    required String title,
    DateTime? eventEndsAtUtc,
  }) async {
    final box = GetStorage(_membershipStore);
    final key = 'members:$userId';
    final raw = box.read<List<dynamic>>(key) ?? <dynamic>[];
    final entry = <String, dynamic>{
      'thread_id': eventThreadId(eventId),
      'title': title,
      if (eventEndsAtUtc != null)
        'event_ends_at_utc': eventEndsAtUtc.toUtc().toIso8601String(),
    };
    if (!raw
        .any((value) => (value as Map)['thread_id'] == entry['thread_id'])) {
      raw.add(entry);
      await box.write(key, raw);
    }
  }

  Future<List<ChatThreadSummary>> listThreadsForUser(String userId) async {
    final memberships = await _membershipsForUser(userId);
    final summaries = <ChatThreadSummary>[];
    for (final membership in memberships) {
      final threadId = membership['thread_id'] as String;
      final history = await getThreadHistory(threadId);
      final last = history.isEmpty ? null : history.last;
      final kind = threadId.startsWith('announcement:')
          ? ChatThreadKind.announcement
          : ChatThreadKind.event;
      summaries.add(
        ChatThreadSummary(
          threadId: threadId,
          kind: kind,
          title: membership['title'] as String? ?? 'Thread',
          subtitle: kind == ChatThreadKind.announcement
              ? 'Leader announcements'
              : 'Event chat',
          lastActivityAtUtc: last?.createdAtUtc ?? DateTime.now().toUtc(),
          lastMessagePreview: last?.body,
          visibilityState: ThreadVisibilityState.active,
          routeReceipt: last?.routeReceipt,
          canPost: kind == ChatThreadKind.event,
        ),
      );
    }
    summaries
        .sort((a, b) => b.lastActivityAtUtc.compareTo(a.lastActivityAtUtc));
    return summaries;
  }

  Future<List<BhamThreadMessage>> getThreadHistory(String threadId) async {
    final box = GetStorage(_messageStore);
    final raw = box.read<List<dynamic>>(threadId) ?? <dynamic>[];
    return raw
        .map(
          (entry) => BhamThreadMessage.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
  }

  Future<BhamThreadMessage> sendEventMessage({
    required String userId,
    required String eventId,
    required String body,
    DateTime? eventEndsAtUtc,
  }) async {
    final threadId = eventThreadId(eventId);
    final messageId = const Uuid().v4();
    final expiresAtUtc = DateTime.now().toUtc().add(
        _transportPolicy.ttlForThreadKind(ChatThreadKind.event,
            eventEndsAtUtc: eventEndsAtUtc));
    final routePlan = await _routePlanner.planRoutes(
      messageId: messageId,
      threadKind: ChatThreadKind.event,
      expiresAtUtc: expiresAtUtc,
      availability: const <TransportMode, bool>{
        TransportMode.ble: true,
        TransportMode.localWifi: true,
        TransportMode.nearbyRelay: true,
        TransportMode.wormhole: true,
      },
    );
    var routeReceipt = _routePlanner.buildQueuedReceipt(
      routePlan: routePlan,
      channel: 'event_chat',
      expiresAtUtc: expiresAtUtc,
    );
    final attempted = routePlan.candidateRoutes.take(3).toList();
    routeReceipt = _routePlanner.markReleased(
        receipt: routeReceipt, attemptedRoutes: attempted);
    final winningRoute =
        attempted.length > 1 ? attempted[1] : routePlan.candidateRoutes.first;
    routeReceipt = _routePlanner.markCustodyAccepted(
      receipt: routeReceipt,
      winningRoute: winningRoute,
      winningRouteReason: 'event-scoped custody accepted',
      custodyAcceptedBy: winningRoute.mode.name,
    );
    routeReceipt = _routePlanner.markDelivered(
      receipt: routeReceipt,
      winningRoute: winningRoute,
      winningRouteReason: 'event-scoped multi-route selection',
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
      threadId: threadId,
      threadKind: ChatThreadKind.event,
      senderId: userId,
      body: body,
      createdAtUtc: DateTime.now().toUtc(),
      routeReceipt: routeReceipt,
      metadata: <String, dynamic>{
        if (eventEndsAtUtc != null)
          'event_ends_at_utc': eventEndsAtUtc.toUtc().toIso8601String(),
      },
    );
    await _appendMessage(threadId, message);
    return message;
  }

  Future<AnnouncementMessage> publishAnnouncement({
    required String scope,
    required String scopeId,
    required String title,
    required String body,
    required String senderRole,
    required List<String> userIds,
  }) async {
    final threadId = announcementThreadId(scope, scopeId);
    for (final userId in userIds) {
      final box = GetStorage(_membershipStore);
      final key = 'members:$userId';
      final raw = box.read<List<dynamic>>(key) ?? <dynamic>[];
      final entry = <String, dynamic>{
        'thread_id': threadId,
        'title': title,
      };
      if (!raw.any((value) => (value as Map)['thread_id'] == threadId)) {
        raw.add(entry);
        await box.write(key, raw);
      }
    }
    final message = BhamThreadMessage(
      messageId: const Uuid().v4(),
      threadId: threadId,
      threadKind: ChatThreadKind.announcement,
      senderId: senderRole,
      body: body,
      createdAtUtc: DateTime.now().toUtc(),
      readOnly: true,
      pinned: true,
      metadata: <String, dynamic>{'title': title, 'sender_role': senderRole},
    );
    await _appendMessage(threadId, message);
    return AnnouncementMessage(
      threadId: threadId,
      messageId: message.messageId,
      title: title,
      body: body,
      createdAtUtc: message.createdAtUtc,
      senderRole: senderRole,
    );
  }

  Future<void> leaveThread({
    required String userId,
    required String threadId,
  }) async {
    final box = GetStorage(_membershipStore);
    final key = 'members:$userId';
    final raw = box.read<List<dynamic>>(key) ?? <dynamic>[];
    raw.removeWhere((entry) => (entry as Map)['thread_id'] == threadId);
    await box.write(key, raw);
  }

  Future<List<Map<String, dynamic>>> _membershipsForUser(String userId) async {
    final box = GetStorage(_membershipStore);
    final raw = box.read<List<dynamic>>('members:$userId') ?? <dynamic>[];
    return raw.map((entry) => Map<String, dynamic>.from(entry as Map)).toList();
  }

  Future<void> _appendMessage(
      String threadId, BhamThreadMessage message) async {
    final box = GetStorage(_messageStore);
    final raw = box.read<List<dynamic>>(threadId) ?? <dynamic>[];
    raw.add(message.toJson());
    await box.write(threadId, raw);
  }
}
