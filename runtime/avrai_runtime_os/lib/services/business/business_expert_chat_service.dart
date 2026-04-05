import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:async';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_core/models/business/business_expert_message.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business-Expert Chat Service
///
/// Handles messaging between businesses and experts.
/// Signal Protocol ready - uses MessageEncryptionService abstraction.
class BusinessExpertChatService {
  static const String _logName = 'BusinessExpertChatService';
  final SupabaseService _supabaseService;
  final MessageEncryptionService _encryptionService;
  final PartnershipService? _partnershipService;
  final _uuid = const Uuid();

  BusinessExpertChatService({
    SupabaseService? supabaseService,
    MessageEncryptionService? encryptionService,
    PartnershipService? partnershipService,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _partnershipService = partnershipService;

  /// Send a message from business to expert or vice versa
  Future<BusinessExpertMessage> sendMessage({
    required String businessId,
    required String expertId,
    required String content,
    required MessageSenderType senderType,
    MessageType messageType = MessageType.text,
    bool encrypt = true,
  }) async {
    try {
      if (!_supabaseService.isAvailable) {
        throw Exception('Supabase not available');
      }

      final client = _supabaseService.client;

      // Get or create conversation
      final conversation = await _getOrCreateConversation(businessId, expertId);

      // Encrypt message if requested
      Uint8List? encryptedContent;
      String encryptionType = 'aes256gcm';
      if (encrypt) {
        final recipientId =
            senderType == MessageSenderType.business ? expertId : businessId;
        final encrypted =
            await _encryptionService.encrypt(content, recipientId);
        encryptedContent = encrypted.encryptedContent;
        encryptionType = encrypted.encryptionType.name;
      }

      // Create message
      final message = BusinessExpertMessage(
        id: _uuid.v4(),
        conversationId: conversation['id'] as String,
        senderType: senderType,
        senderId:
            senderType == MessageSenderType.business ? businessId : expertId,
        recipientType: senderType == MessageSenderType.business
            ? MessageRecipientType.expert
            : MessageRecipientType.business,
        recipientId:
            senderType == MessageSenderType.business ? expertId : businessId,
        content: content,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      final response = await client.from('business_expert_messages').insert(
            message.toJson(),
          );

      if (response.error != null) {
        throw Exception('Failed to save message: ${response.error!.message}');
      }

      // Update conversation last_message_at
      await client
          .from('business_expert_conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()}).eq(
              'id', conversation['id']);

      developer.log(
        'Message sent: ${message.id} (${senderType.name} -> ${message.recipientType.name})',
        name: _logName,
      );

      return message;
    } catch (e) {
      developer.log('Error sending message: $e', name: _logName);
      rethrow;
    }
  }

  /// Get conversation between business and expert
  Future<Map<String, dynamic>?> getConversation(
    String businessId,
    String expertId,
  ) async {
    try {
      if (!_supabaseService.isAvailable) {
        return null;
      }

      final client = _supabaseService.client;

      try {
        final response = await client
            .from('business_expert_conversations')
            .select()
            .eq('business_id', businessId)
            .eq('expert_id', expertId)
            .maybeSingle();

        return response;
      } catch (e) {
        developer.log('Error getting conversation: $e', name: _logName);
        return null;
      }
    } catch (e) {
      developer.log('Error getting conversation: $e', name: _logName);
      return null;
    }
  }

  /// Get or create conversation
  Future<Map<String, dynamic>> _getOrCreateConversation(
    String businessId,
    String expertId,
  ) async {
    final existing = await getConversation(businessId, expertId);
    if (existing != null) {
      return existing;
    }

    // Calculate vibe compatibility if partnership service is available
    double? vibeScore;
    if (_partnershipService != null) {
      try {
        vibeScore = await _partnershipService.calculateVibeCompatibility(
          userId: expertId,
          businessId: businessId,
        );
      } catch (e) {
        developer.log('Error calculating vibe compatibility: $e',
            name: _logName);
      }
    }

    // Create new conversation
    final client = _supabaseService.client;
    final conversationData = {
      'business_id': businessId,
      'expert_id': expertId,
      'vibe_compatibility_score': vibeScore,
      'connection_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await client
          .from('business_expert_conversations')
          .insert(conversationData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get message history for a conversation
  Future<List<BusinessExpertMessage>> getMessageHistory(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (!_supabaseService.isAvailable) {
        return [];
      }

      final client = _supabaseService.client;

      final response = await client
          .from('business_expert_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = (response as List)
          .map((json) =>
              BusinessExpertMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      // Decrypt messages if needed
      final decryptedMessages = <BusinessExpertMessage>[];
      for (final message in messages) {
        if (message.encryptedContent != null) {
          try {
            final senderId = message.senderId;
            final encrypted = EncryptedMessage(
              encryptedContent: message.encryptedContent!,
              encryptionType: EncryptionType.values.firstWhere(
                  (e) => e.name == message.encryptionType,
                  orElse: () => EncryptionType.aes256gcm),
            );
            final decrypted = await _encryptionService.decrypt(
              encrypted,
              senderId,
            );
            decryptedMessages.add(message.copyWith(content: decrypted));
          } catch (e) {
            developer.log('Error decrypting message: $e', name: _logName);
            // Add message with encrypted content indicator
            decryptedMessages.add(message);
          }
        } else {
          decryptedMessages.add(message);
        }
      }

      return decryptedMessages.reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      developer.log('Error getting message history: $e', name: _logName);
      return [];
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      if (!_supabaseService.isAvailable) {
        return;
      }

      final client = _supabaseService.client;

      try {
        await client.from('business_expert_messages').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', messageId);
      } catch (e) {
        developer.log('Error marking message as read: $e', name: _logName);
      }
    } catch (e) {
      developer.log('Error marking message as read: $e', name: _logName);
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(
      String businessIdOrExpertId, bool isBusiness) async {
    try {
      if (!_supabaseService.isAvailable) {
        return 0;
      }

      final client = _supabaseService.client;

      try {
        var query = client
            .from('business_expert_messages')
            .select('id')
            .eq('is_read', false);

        if (isBusiness) {
          query = query
              .eq('recipient_type', 'business')
              .eq('recipient_id', businessIdOrExpertId);
        } else {
          query = query
              .eq('recipient_type', 'expert')
              .eq('recipient_id', businessIdOrExpertId);
        }

        final response = await query;
        return (response as List).length;
      } catch (e) {
        developer.log('Error getting unread count: $e', name: _logName);
        return 0;
      }
    } catch (e) {
      developer.log('Error getting unread count: $e', name: _logName);
      return 0;
    }
  }

  /// Subscribe to real-time messages for a conversation
  Stream<BusinessExpertMessage> subscribeToMessages(String conversationId) {
    if (!_supabaseService.isAvailable) {
      return const Stream.empty();
    }

    try {
      final client = _supabaseService.client;
      final channel =
          client.channel('business_expert_messages:$conversationId');

      final controller = StreamController<BusinessExpertMessage>.broadcast();

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'business_expert_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) async {
              try {
                final newRecord = payload.newRecord;
                final message = BusinessExpertMessage.fromJson(
                  Map<String, dynamic>.from(newRecord),
                );

                // Decrypt if needed
                if (message.encryptedContent != null) {
                  try {
                    final encrypted = EncryptedMessage(
                      encryptedContent: message.encryptedContent!,
                      encryptionType: EncryptionType.values.firstWhere(
                          (e) => e.name == message.encryptionType,
                          orElse: () => EncryptionType.aes256gcm),
                    );
                    final decrypted = await _encryptionService.decrypt(
                      encrypted,
                      message.senderId,
                    );
                    controller.add(message.copyWith(content: decrypted));
                  } catch (e) {
                    developer.log('Error decrypting real-time message: $e',
                        name: _logName);
                    controller.add(message);
                  }
                } else {
                  controller.add(message);
                }
              } catch (e) {
                developer.log('Error processing real-time message: $e',
                    name: _logName);
              }
            },
          )
          .subscribe();

      return controller.stream;
    } catch (e) {
      developer.log('Error subscribing to messages: $e', name: _logName);
      return const Stream.empty();
    }
  }
}
