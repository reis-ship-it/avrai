// ignore: dangling_library_doc_comments
/// Outreach Queue Processor
///
/// Processes messages from the outreach_queue table.
/// Part of Predictive Proactive Outreach System - Phase 4.2
///
/// Handles:
/// - Reading pending/scheduled messages from database
/// - Respecting optimal_timing for scheduled outreach
/// - Updating message status (pending → delivered → seen)
/// - Batch processing for efficiency

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';

/// Outreach queue message status
enum OutreachQueueStatus {
  pending,
  scheduled,
  processing,
  delivered,
  seen,
  failed,
  cancelled,
}

/// Outreach queue message
class OutreachQueueMessage {
  final String id;
  final String type;
  final String targetUserId;
  final String? sourceId;
  final String? sourceType;
  final double compatibilityScore;
  final double? stringPredictionScore;
  final double? quantumTrajectoryScore;
  final String? fromAgentId;
  final String? toAgentId;
  final String? reasoning;
  final DateTime? optimalTiming;
  final OutreachQueueStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final Map<String, dynamic>? metadata;

  OutreachQueueMessage({
    required this.id,
    required this.type,
    required this.targetUserId,
    this.sourceId,
    this.sourceType,
    required this.compatibilityScore,
    this.stringPredictionScore,
    this.quantumTrajectoryScore,
    this.fromAgentId,
    this.toAgentId,
    this.reasoning,
    this.optimalTiming,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.seenAt,
    this.metadata,
  });

  /// Check if message is ready to be processed
  bool get isReadyToProcess {
    if (status != OutreachQueueStatus.pending &&
        status != OutreachQueueStatus.scheduled) {
      return false;
    }

    // If scheduled, check if optimal timing has passed
    if (optimalTiming != null) {
      return DateTime.now().isAfter(optimalTiming!);
    }

    return true;
  }
}

/// Service for processing outreach queue messages
class OutreachQueueProcessor {
  static const String _logName = 'OutreachQueueProcessor';

  final SupabaseService _supabaseService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;

  // Batch size for processing
  static const int _batchSize = 50;

  OutreachQueueProcessor({
    required SupabaseService supabaseService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
  })  : _supabaseService = supabaseService,
        _ai2aiCommunication = ai2aiCommunication;

  /// Process pending messages from queue
  ///
  /// **Flow:**
  /// 1. Fetch pending/scheduled messages ready to process
  /// 2. Process in batches
  /// 3. Update status to delivered or failed
  ///
  /// **Returns:**
  /// Processing result with counts
  Future<QueueProcessingResult> processPendingMessages({
    int? limit,
  }) async {
    try {
      developer.log(
        'Processing pending outreach messages',
        name: _logName,
      );

      // Fetch messages ready to process
      final messages = await _fetchReadyMessages(limit: limit ?? _batchSize);

      if (messages.isEmpty) {
        developer.log(
          'No messages ready to process',
          name: _logName,
        );
        return QueueProcessingResult(
          totalProcessed: 0,
          successCount: 0,
          failureCount: 0,
        );
      }

      developer.log(
        'Found ${messages.length} messages ready to process',
        name: _logName,
      );

      // Process messages
      int successCount = 0;
      int failureCount = 0;

      for (final message in messages) {
        try {
          // Update status to processing
          await _updateMessageStatus(
              message.id, OutreachQueueStatus.processing);

          // Send message via AI2AI
          final result = await _sendOutreachMessage(message);

          if (result.success) {
            // Update status to delivered
            await _updateMessageStatus(
              message.id,
              OutreachQueueStatus.delivered,
              deliveredAt: DateTime.now(),
            );
            successCount++;
          } else {
            // Update status to failed
            await _updateMessageStatus(
              message.id,
              OutreachQueueStatus.failed,
            );
            failureCount++;
          }
        } catch (e) {
          developer.log(
            'Error processing message ${message.id}: $e',
            name: _logName,
          );
          await _updateMessageStatus(message.id, OutreachQueueStatus.failed);
          failureCount++;
        }
      }

      developer.log(
        '✅ Processed ${messages.length} messages: $successCount succeeded, $failureCount failed',
        name: _logName,
      );

      return QueueProcessingResult(
        totalProcessed: messages.length,
        successCount: successCount,
        failureCount: failureCount,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process pending messages: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return QueueProcessingResult(
        totalProcessed: 0,
        successCount: 0,
        failureCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Fetch messages ready to process
  Future<List<OutreachQueueMessage>> _fetchReadyMessages({
    required int limit,
  }) async {
    try {
      final now = DateTime.now();

      // Query database for ready messages
      // Use .or() to filter by multiple status values
      final response = await _supabaseService.client
          .from('outreach_queue')
          .select()
          .or('status.eq.pending,status.eq.scheduled')
          .or('optimal_timing.is.null,optimal_timing.lte.$now')
          .order('created_at', ascending: true)
          .limit(limit);

      if (response.isEmpty) return [];

      final messages = <OutreachQueueMessage>[];

      for (final row in response) {
        try {
          messages.add(parseQueueMessage(row));
        } catch (e) {
          developer.log(
            'Error parsing message: $e',
            name: _logName,
          );
          continue;
        }
      }

      return messages;
    } catch (e) {
      developer.log(
        'Error fetching ready messages: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Send outreach message via AI2AI
  Future<OutreachMessageResult> _sendOutreachMessage(
    OutreachQueueMessage message,
  ) async {
    if (message.fromAgentId == null || message.toAgentId == null) {
      return OutreachMessageResult(
        success: false,
        timestamp: DateTime.now(),
        encryptionType: EncryptionType.aes256gcm,
        error: 'Missing agent IDs',
      );
    }

    // Map queue type to OutreachMessageType
    final messageType = _mapQueueTypeToMessageType(message.type);

    // Extract payload from metadata or construct from message
    final payload = message.metadata ??
        {
          'compatibility_score': message.compatibilityScore,
          'reasoning': message.reasoning,
          'source_id': message.sourceId,
          'source_type': message.sourceType,
        };

    return await _ai2aiCommunication.sendOutreachMessage(
      fromAgentId: message.fromAgentId!,
      toAgentId: message.toAgentId!,
      messageType: messageType,
      payload: payload,
    );
  }

  /// Update message status in database
  Future<void> _updateMessageStatus(
    String messageId,
    OutreachQueueStatus status, {
    DateTime? deliveredAt,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (deliveredAt != null) {
        updates['delivered_at'] = deliveredAt.toIso8601String();
      }

      await _supabaseService.client
          .from('outreach_queue')
          .update(updates)
          .eq('id', messageId);
    } catch (e) {
      developer.log(
        'Error updating message status: $e',
        name: _logName,
      );
    }
  }

  /// Parse queue message from database row
  OutreachQueueMessage parseQueueMessage(Map<String, dynamic> row) {
    return OutreachQueueMessage(
      id: row['id'] as String,
      type: row['type'] as String,
      targetUserId: row['target_user_id'] as String,
      sourceId: row['source_id'] as String?,
      sourceType: row['source_type'] as String?,
      compatibilityScore:
          (row['compatibility_score'] as num?)?.toDouble() ?? 0.0,
      stringPredictionScore:
          (row['string_prediction_score'] as num?)?.toDouble(),
      quantumTrajectoryScore:
          (row['quantum_trajectory_score'] as num?)?.toDouble(),
      fromAgentId: row['from_agent_id'] as String?,
      toAgentId: row['to_agent_id'] as String?,
      reasoning: row['reasoning'] as String?,
      optimalTiming: row['optimal_timing'] != null
          ? DateTime.parse(row['optimal_timing'] as String)
          : null,
      status: OutreachQueueStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => OutreachQueueStatus.pending,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      deliveredAt: row['delivered_at'] != null
          ? DateTime.parse(row['delivered_at'] as String)
          : null,
      seenAt: row['seen_at'] != null
          ? DateTime.parse(row['seen_at'] as String)
          : null,
      metadata: row['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Map queue type to OutreachMessageType
  OutreachMessageType _mapQueueTypeToMessageType(String queueType) {
    switch (queueType) {
      case 'community_invitation':
        return OutreachMessageType.communityInvitation;
      case 'group_formation':
        return OutreachMessageType.groupFormation;
      case 'event_call':
        return OutreachMessageType.eventCall;
      case 'spot_recommendation':
        return OutreachMessageType.spotRecommendation;
      case 'friend_suggestion':
        return OutreachMessageType.friendSuggestion;
      case 'business_event_invitation':
        return OutreachMessageType.businessEventInvitation;
      case 'business_expert_partnership':
        return OutreachMessageType.businessExpertPartnership;
      case 'business_business_partnership':
        return OutreachMessageType.businessBusinessPartnership;
      case 'club_membership_invitation':
        return OutreachMessageType.clubMembershipInvitation;
      case 'club_event_invitation':
        return OutreachMessageType.clubEventInvitation;
      case 'expert_learning_opportunity':
        return OutreachMessageType.expertLearningOpportunity;
      case 'expert_business_partnership':
        return OutreachMessageType.expertBusinessPartnership;
      case 'list_suggestion':
        return OutreachMessageType.listSuggestion;
      case 'expert_curated_list':
        return OutreachMessageType.expertCuratedList;
      default:
        return OutreachMessageType.communityInvitation;
    }
  }
}

/// Queue processing result
class QueueProcessingResult {
  final int totalProcessed;
  final int successCount;
  final int failureCount;
  final String? error;

  QueueProcessingResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    this.error,
  });
}
