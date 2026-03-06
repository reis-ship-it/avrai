import 'dart:convert';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

/// Message Queue Service
///
/// Manages persistent message queue for AI2AI network routing.
/// Stores encrypted messages in Supabase for reliable delivery.
///
/// **Phase 4:** Secure Encrypted Private AI2AI Network Implementation
class MessageQueueService {
  static const String _logName = 'MessageQueueService';
  static const String _wormholeQueueTable = 'wormhole_message_queue';
  static const String _markExpiredRpc = 'mark_expired_wormhole_messages';
  static const String _cleanupExpiredRpc = 'cleanup_expired_wormhole_messages';

  final SupabaseService _supabaseService;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'MessageQueue',
    minimumLevel: LogLevel.debug,
  );

  // Queue configuration
  static const int _maxQueueSize = 1000; // Maximum messages per agent
  static const int _maxDeliveryAttempts = 3;

  MessageQueueService({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  /// Store message in queue
  ///
  /// Stores encrypted message for later delivery to target agent.
  Future<void> enqueueMessage({
    required String messageId,
    required String senderAgentId,
    required String targetAgentId,
    required String encryptedPayload,
    required String messageType,
    required DateTime expiresAt,
    List<String>? routingHops,
  }) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        throw MessageQueueException('Supabase client not available');
      }

      // Check queue size for target agent
      final currentQueueSize = await _getQueueSize(targetAgentId);
      if (currentQueueSize >= _maxQueueSize) {
        // Remove oldest pending message (FIFO eviction)
        await _evictOldestMessage(targetAgentId);
      }

      // Insert message into queue
      await client.from(_wormholeQueueTable).insert({
        'message_id': messageId,
        'sender_agent_id': senderAgentId,
        'target_agent_id': targetAgentId,
        'encrypted_payload': encryptedPayload,
        'message_type': messageType,
        'expires_at': expiresAt.toIso8601String(),
        'routing_hops': routingHops != null ? jsonEncode(routingHops) : null,
        'status': 'pending',
        'delivery_attempts': 0,
      });

      _logger.debug(
        'Message enqueued: $messageId for agent $targetAgentId',
        tag: _logName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error enqueueing message: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw MessageQueueException('Failed to enqueue message: $e');
    }
  }

  /// Get pending messages for agent
  ///
  /// Retrieves all pending messages for the specified agent.
  Future<List<QueuedMessage>> getPendingMessages(String agentId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return [];
      }

      // Get pending messages for agent
      final response = await client
          .from(_wormholeQueueTable)
          .select()
          .eq('target_agent_id', agentId)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(100); // Limit to prevent memory issues

      final messages = (response as List)
          .map((row) => QueuedMessage.fromJson(row as Map<String, dynamic>))
          .toList();

      _logger.debug(
        'Retrieved ${messages.length} pending messages for agent $agentId',
        tag: _logName,
      );

      return messages;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting pending messages: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Mark message as delivered
  ///
  /// Updates message status to 'delivered' after successful delivery.
  Future<void> markMessageDelivered(String messageId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return; // Non-fatal if Supabase unavailable
      }

      await client.from(_wormholeQueueTable).update({
        'status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('message_id', messageId);

      _logger.debug('Message marked as delivered: $messageId', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error marking message as delivered: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw MessageQueueException('Failed to mark message as delivered: $e');
    }
  }

  /// Mark message as failed
  ///
  /// Updates message status to 'failed' after delivery failure.
  /// Increments delivery attempts counter.
  Future<void> markMessageFailed(String messageId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return; // Non-fatal if Supabase unavailable
      }

      // Get current delivery attempts
      final response = await client
          .from(_wormholeQueueTable)
          .select('delivery_attempts')
          .eq('message_id', messageId)
          .single();

      final currentAttempts = response['delivery_attempts'] as int? ?? 0;
      final newAttempts = currentAttempts + 1;

      // Update status based on attempts
      final status = newAttempts >= _maxDeliveryAttempts ? 'failed' : 'pending';

      await client.from(_wormholeQueueTable).update({
        'status': status,
        'delivery_attempts': newAttempts,
        'last_delivery_attempt': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('message_id', messageId);

      _logger.debug(
        'Message marked as failed: $messageId (attempts: $newAttempts)',
        tag: _logName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error marking message as failed: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw MessageQueueException('Failed to mark message as failed: $e');
    }
  }

  /// Remove message from queue
  ///
  /// Deletes message from queue after successful processing.
  Future<void> removeMessage(String messageId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return; // Non-fatal if Supabase unavailable
      }

      await client
          .from(_wormholeQueueTable)
          .delete()
          .eq('message_id', messageId);

      _logger.debug('Message removed from queue: $messageId', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error removing message: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw MessageQueueException('Failed to remove message: $e');
    }
  }

  /// Clean up expired messages
  ///
  /// Marks expired messages and removes old expired messages.
  Future<void> cleanupExpiredMessages() async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return; // Non-fatal if Supabase unavailable
      }

      // Mark expired messages
      await client.rpc(_markExpiredRpc);

      // Cleanup old expired messages (older than 7 days)
      await client.rpc(_cleanupExpiredRpc);

      _logger.debug('Expired messages cleaned up', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error cleaning up expired messages: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal - cleanup can fail without breaking functionality
    }
  }

  /// Get queue size for agent
  Future<int> _getQueueSize(String agentId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return 0;
      }

      final response = await client
          .from(_wormholeQueueTable)
          .select('id')
          .eq('target_agent_id', agentId)
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      _logger.warn('Error getting queue size: $e', tag: _logName);
      return 0;
    }
  }

  /// Evict oldest message (FIFO)
  Future<void> _evictOldestMessage(String agentId) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return;
      }

      // Get oldest pending message
      final response = await client
          .from(_wormholeQueueTable)
          .select('message_id')
          .eq('target_agent_id', agentId)
          .eq('status', 'pending')
          .order('timestamp', ascending: true)
          .limit(1)
          .single();

      final oldestMessageId = response['message_id'] as String;

      // Remove oldest message
      await removeMessage(oldestMessageId);

      _logger.debug(
        'Evicted oldest message from queue: $oldestMessageId',
        tag: _logName,
      );
    } catch (e) {
      _logger.warn('Error evicting oldest message: $e', tag: _logName);
      // Non-fatal - queue can continue even if eviction fails
    }
  }
}

/// Queued message model
class QueuedMessage {
  final String id;
  final String messageId;
  final String senderAgentId;
  final String targetAgentId;
  final String encryptedPayload;
  final String messageType;
  final DateTime timestamp;
  final DateTime expiresAt;
  final List<String>? routingHops;
  final String status;
  final int deliveryAttempts;
  final DateTime? lastDeliveryAttempt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QueuedMessage({
    required this.id,
    required this.messageId,
    required this.senderAgentId,
    required this.targetAgentId,
    required this.encryptedPayload,
    required this.messageType,
    required this.timestamp,
    required this.expiresAt,
    this.routingHops,
    required this.status,
    required this.deliveryAttempts,
    this.lastDeliveryAttempt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      senderAgentId: json['sender_agent_id'] as String,
      targetAgentId: json['target_agent_id'] as String,
      encryptedPayload: json['encrypted_payload'] as String,
      messageType: json['message_type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      routingHops: json['routing_hops'] != null
          ? (jsonDecode(json['routing_hops'] as String) as List)
              .map((e) => e as String)
              .toList()
          : null,
      status: json['status'] as String,
      deliveryAttempts: json['delivery_attempts'] as int? ?? 0,
      lastDeliveryAttempt: json['last_delivery_attempt'] != null
          ? DateTime.parse(json['last_delivery_attempt'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Message queue exception
class MessageQueueException implements Exception {
  final String message;
  MessageQueueException(this.message);

  @override
  String toString() => 'MessageQueueException: $message';
}
