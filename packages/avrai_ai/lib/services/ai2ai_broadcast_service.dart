import 'dart:async';
import 'dart:convert';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_core/services/logger.dart';

/// AI2AI Broadcast Service for SPOTS
/// 
/// Manages broadcast channel-based communication for AI-to-AI agent interactions.
/// Uses Supabase Realtime channels for personality discovery, vibe learning, and
/// network coordination.
/// 
/// **Note:** This service handles broadcast channels. For direct encrypted messaging
/// between agents, use `AnonymousCommunicationProtocol` instead.
/// 
/// Integrates with `VibeConnectionOrchestrator` for offline AI2AI communication.
/// 
/// OUR_GUTS.md: "Privacy-preserving AI2AI communication with real-time updates"
class AI2AIBroadcastService {
  final RealtimeBackend _realtimeBackend;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'AI2AI', minimumLevel: LogLevel.debug);

  bool _isInitialized = false;
  bool _isConnected = false;
  StreamSubscription<RealtimeConnectionStatus>? _connectionSub;

  // Broadcast channels for AI2AI communication
  static const String _ai2aiChannel = 'ai2ai-network';
  static const String _personalityDiscoveryChannel = 'personality-discovery';
  static const String _vibeLearningChannel = 'vibe-learning';
  static const String _anonymousCommunicationChannel =
      'anonymous-communication';

  // Active channel ids tracked locally
  final Set<String> _activeChannels = {};

  AI2AIBroadcastService(this._realtimeBackend);

  /// Initialize realtime backend + join channels.
  ///
  /// This is the API expected by `VibeConnectionOrchestrator`.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      await _realtimeBackend.connect();

      // Cancel existing subscription if re-initializing
      await _connectionSub?.cancel();
      _connectionSub = _realtimeBackend.connectionStatus.listen((status) {
        _isConnected = status.isConnected;
      });

      // Join the channels used by this service.
      await _realtimeBackend.joinChannel(_ai2aiChannel);
      await _realtimeBackend.joinChannel(_personalityDiscoveryChannel);
      await _realtimeBackend.joinChannel(_vibeLearningChannel);
      await _realtimeBackend.joinChannel(_anonymousCommunicationChannel);

      _activeChannels
        ..add(_ai2aiChannel)
        ..add(_personalityDiscoveryChannel)
        ..add(_vibeLearningChannel)
        ..add(_anonymousCommunicationChannel);

      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      // Clean up subscription on failure
      await _connectionSub?.cancel();
      _connectionSub = null;
      _logger.error(
        'Error initializing realtime backend: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Stream of realtime messages for personality discovery.
  ///
  /// This is the API expected by `RealtimeCoordinator`.
  Stream<RealtimeMessage> listenToPersonalityDiscovery() {
    return _realtimeBackend.subscribeToMessages(_personalityDiscoveryChannel);
  }

  /// Stream of realtime messages for the main AI2AI network channel.
  Stream<RealtimeMessage> listenToAI2AINetwork() {
    return _realtimeBackend.subscribeToMessages(_ai2aiChannel);
  }

  /// Stream of realtime messages for vibe learning.
  Stream<RealtimeMessage> listenToVibeLearning() {
    return _realtimeBackend.subscribeToMessages(_vibeLearningChannel);
  }

  /// Stream of realtime messages for anonymous communication.
  Stream<RealtimeMessage> listenToAnonymousCommunication() {
    return _realtimeBackend.subscribeToMessages(_anonymousCommunicationChannel);
  }

  /// Stream of presence updates for the AI2AI network channel.
  Stream<List<UserPresence>> watchAINetworkPresence() {
    return _realtimeBackend.subscribeToPresence(_ai2aiChannel);
  }

  /// Subscribe to AI2AI network updates
  /// Returns StreamSubscription for managing subscription lifecycle
  StreamSubscription<RealtimeMessage>? subscribeToNetwork({
    required String agentId,
    required void Function(Map<String, dynamic> data) onUpdate,
    Function(Object error)? onError,
  }) {
    try {
      _logger.debug('Subscribing to AI2AI network channel for agent: $agentId');

      return _realtimeBackend.subscribeToMessages(_ai2aiChannel).listen(
        (message) {
          try {
            final metaAgentId = message.metadata['agent_id'] as String?;
            // Ignore messages without agent_id or messages not for this agent
            if (metaAgentId == null || metaAgentId != agentId) return;

            // Validate message content
            if (message.content.isEmpty) {
              _logger.warning('Received message with empty content, ignoring');
              return;
            }

            final data = jsonDecode(message.content) as Map<String, dynamic>;
            // Use sender_agent_id from message metadata, fallback to subscriber agent_id
            final senderAgentId = metaAgentId;
            onUpdate(<String, dynamic>{
              'sender_agent_id': senderAgentId,
              'subscriber_agent_id': agentId, // For clarity
              'timestamp': message.timestamp.toIso8601String(),
              ...data,
            });
          } catch (e) {
            _logger.warning('Error parsing network update: $e');
            onError?.call(e);
          }
        },
        onError: (error) {
          _logger.error('Error in network subscription: $error');
          onError?.call(error);
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error subscribing to network: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Subscribe to personality discovery updates
  StreamSubscription<RealtimeMessage>? subscribeToPersonalityDiscovery({
    required String agentId,
    required void Function(Map<String, dynamic> data) onUpdate,
    Function(Object error)? onError,
  }) {
    try {
      _logger.debug(
          'Subscribing to personality discovery channel for agent: $agentId');

      return _realtimeBackend
          .subscribeToMessages(_personalityDiscoveryChannel)
          .listen(
        (message) {
          try {
            final metaAgentId = message.metadata['agent_id'] as String?;
            // Ignore messages without agent_id or messages not for this agent
            if (metaAgentId == null || metaAgentId != agentId) return;

            // Validate message content
            if (message.content.isEmpty) {
              _logger.warning('Received message with empty content, ignoring');
              return;
            }

            final data = jsonDecode(message.content) as Map<String, dynamic>;
            // Use sender_agent_id from message metadata, fallback to subscriber agent_id
            final senderAgentId = metaAgentId;
            onUpdate(<String, dynamic>{
              'sender_agent_id': senderAgentId,
              'subscriber_agent_id': agentId, // For clarity
              'timestamp': message.timestamp.toIso8601String(),
              ...data,
            });
          } catch (e) {
            _logger.warning('Error parsing discovery update: $e');
            onError?.call(e);
          }
        },
        onError: (error) {
          _logger.error('Error in discovery subscription: $error');
          onError?.call(error);
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error subscribing to personality discovery: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Subscribe to vibe learning updates
  StreamSubscription<RealtimeMessage>? subscribeToVibeLearning({
    required String agentId,
    required void Function(Map<String, dynamic> data) onUpdate,
    Function(Object error)? onError,
  }) {
    try {
      _logger
          .debug('Subscribing to vibe learning channel for agent: $agentId');

      return _realtimeBackend.subscribeToMessages(_vibeLearningChannel).listen(
        (message) {
          try {
            final metaAgentId = message.metadata['agent_id'] as String?;
            // Ignore messages without agent_id or messages not for this agent
            if (metaAgentId == null || metaAgentId != agentId) return;

            // Validate message content
            if (message.content.isEmpty) {
              _logger.warning('Received message with empty content, ignoring');
              return;
            }

            final data = jsonDecode(message.content) as Map<String, dynamic>;
            // Use sender_agent_id from message metadata, fallback to subscriber agent_id
            final senderAgentId = metaAgentId;
            onUpdate(<String, dynamic>{
              'sender_agent_id': senderAgentId,
              'subscriber_agent_id': agentId, // For clarity
              'timestamp': message.timestamp.toIso8601String(),
              ...data,
            });
          } catch (e) {
            _logger.warning('Error parsing vibe learning update: $e');
            onError?.call(e);
          }
        },
        onError: (error) {
          _logger.error('Error in vibe learning subscription: $error');
          onError?.call(error);
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error subscribing to vibe learning: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Broadcast AI2AI network update
  Future<bool> broadcastNetworkUpdate({
    required String agentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.debug('Broadcasting network update for agent: $agentId');

      final payload = jsonEncode({
        'agent_id': agentId,
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      });

      await _realtimeBackend.sendMessage(
        _ai2aiChannel,
        RealtimeMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: agentId,
          content: payload,
          type: 'update',
          timestamp: DateTime.now(),
          metadata: {'agent_id': agentId},
        ),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error broadcasting network update: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Broadcast personality discovery update
  Future<bool> broadcastPersonalityDiscovery({
    required String agentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.debug('Broadcasting personality discovery for agent: $agentId');

      final payload = jsonEncode({
        'agent_id': agentId,
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      });

      await _realtimeBackend.sendMessage(
        _personalityDiscoveryChannel,
        RealtimeMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: agentId,
          content: payload,
          type: 'discovery',
          timestamp: DateTime.now(),
          metadata: {'agent_id': agentId},
        ),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error broadcasting personality discovery: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Broadcast vibe learning update
  Future<bool> broadcastVibeLearning({
    required String agentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.debug('Broadcasting vibe learning for agent: $agentId');

      final payload = jsonEncode({
        'agent_id': agentId,
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      });

      await _realtimeBackend.sendMessage(
        _vibeLearningChannel,
        RealtimeMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: agentId,
          content: payload,
          type: 'learning',
          timestamp: DateTime.now(),
          metadata: {'agent_id': agentId},
        ),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error broadcasting vibe learning: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Convenience: send a best-effort anonymous message payload.
  ///
  /// This is primarily used by tests and debugging tools.
  Future<bool> sendAnonymousMessage(
    String message, [
    Map<String, dynamic> metadata = const {},
  ]) async {
    try {
      final payload = jsonEncode({
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        ...metadata,
      });

      await _realtimeBackend.sendMessage(
        _anonymousCommunicationChannel,
        RealtimeMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: 'anonymous',
          content: payload,
          type: 'anonymous',
          timestamp: DateTime.now(),
          metadata: metadata,
        ),
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error sending anonymous message: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// @deprecated This method broadcasts to public channel and is not truly private.
  /// Use AnonymousCommunicationProtocol.sendEncryptedMessage() for private messaging.
  ///
  /// **WARNING:** This method broadcasts to the public ai2ai-network channel.
  /// All subscribers will receive this message. For true private messaging,
  /// use AnonymousCommunicationProtocol instead.
  ///
  /// This is primarily used by tests and debugging tools.
  @Deprecated('Use AnonymousCommunicationProtocol for private messaging')
  Future<bool> sendPrivateMessage(
    String recipientAgentId,
    Map<String, dynamic> payload,
  ) async {
    _logger.warning(
      'sendPrivateMessage broadcasts to public channel - not truly private. '
      'Consider using AnonymousCommunicationProtocol for private messaging.',
    );
    try {
      final content = jsonEncode({
        'to': recipientAgentId,
        'timestamp': DateTime.now().toIso8601String(),
        ...payload,
      });

      await _realtimeBackend.sendMessage(
        _ai2aiChannel,
        RealtimeMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: 'system',
          content: content,
          type: 'private',
          timestamp: DateTime.now(),
          metadata: {'to': recipientAgentId},
        ),
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error sending private message: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Measure realtime round-trip-ish latency (best-effort).
  ///
  /// **LIMITATION:** This method may not work correctly if the backend doesn't
  /// echo messages back to the sender. The method listens for its own message,
  /// which requires backend support for message echoing.
  ///
  /// This is primarily for diagnostics/tests. In production, the backend may not
  /// echo messages, so this may return null.
  ///
  /// Returns latency in **milliseconds**, or null on timeout/failure.
  Future<int?> measureRealtimeLatency({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final traceId = DateTime.now().microsecondsSinceEpoch.toString();
    final sendTime = DateTime.now();
    final completer = Completer<int?>();

    StreamSubscription<RealtimeMessage>? sub;
    try {
      sub = listenToAI2AINetwork().listen((message) {
        final msgTraceId = message.metadata['trace_id'] as String?;
        if (msgTraceId != traceId) return;
        if (completer.isCompleted) return;
        completer.complete(message.timestamp.difference(sendTime).inMilliseconds);
      });

      await _realtimeBackend.sendMessage(
        _ai2aiChannel,
        RealtimeMessage(
          id: traceId,
          senderId: 'latency_probe',
          content: 'latency_ping',
          type: 'latency_ping',
          timestamp: sendTime,
          metadata: {
            'trace_id': traceId,
            'send_ts': sendTime.toIso8601String(),
          },
        ),
      );

      return await completer.future.timeout(timeout);
    } catch (e, stackTrace) {
      _logger.warning(
        'Latency measurement failed: $e',
      );
      _logger.debug('$stackTrace');
      return null;
    } finally {
      await sub?.cancel();
    }
  }

  /// Unsubscribe from a specific channel
  Future<void> unsubscribe(String channelId) async {
    try {
      _logger.debug('Unsubscribing from channel: $channelId');
      await _realtimeBackend.leaveChannel(channelId);
      _activeChannels.remove(channelId);
    } catch (e, stackTrace) {
      _logger.error(
        'Error unsubscribing from channel: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Unsubscribe from all active channels
  Future<void> unsubscribeAll() async {
    try {
      _logger.debug('Unsubscribing from all channels (${_activeChannels.length})');
      for (final channelId in _activeChannels.toList()) {
        await unsubscribe(channelId);
      }
      _activeChannels.clear();
    } catch (e, stackTrace) {
      _logger.error(
        'Error unsubscribing from all channels: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get list of active channel subscriptions
  List<String> getActiveChannels() => _activeChannels.toList();

  /// Compatibility getter used by some UI/tests.
  List<String> get activeChannels => getActiveChannels();

  /// Check if service is connected to realtime backend
  bool get isConnected => _isConnected;

  /// Reconnect to realtime backend
  Future<bool> reconnect() async {
    try {
      _logger.debug('Reconnecting to realtime backend');
      await _realtimeBackend.disconnect();
      await _realtimeBackend.connect();
      return isConnected;
    } catch (e, stackTrace) {
      _logger.error(
        'Error reconnecting: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Disconnect from realtime backend
  Future<void> disconnect() async {
    try {
      _logger.debug('Disconnecting from realtime backend');
      await unsubscribeAll();
      await _realtimeBackend.disconnect();
      await _connectionSub?.cancel();
      _connectionSub = null;
      _isConnected = false;
      _isInitialized = false;
    } catch (e, stackTrace) {
      _logger.error(
        'Error disconnecting: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
