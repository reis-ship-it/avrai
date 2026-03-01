// ignore: dangling_library_doc_comments
/// Silent Notification Service
///
/// Handles silent delivery of outreach messages (no push notifications).
/// Part of Predictive Proactive Outreach System - Phase 5.1
///
/// Features:
/// - Stores messages in local database for offline access
/// - Delivers when user opens app (not via push)
/// - Tracks delivery and seen status
/// - Supports offline-first architecture

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/outreach_queue_processor.dart';

/// Silent notification delivery result
class SilentNotificationResult {
  final bool success;
  final int deliveredCount;
  final int seenCount;
  final String? error;

  SilentNotificationResult({
    required this.success,
    required this.deliveredCount,
    required this.seenCount,
    this.error,
  });
}

/// Service for silent notification delivery
class SilentNotificationService {
  static const String _logName = 'SilentNotificationService';

  final SupabaseService _supabaseService;
  final OutreachQueueProcessor _queueProcessor;

  SilentNotificationService({
    required SupabaseService supabaseService,
    required OutreachQueueProcessor queueProcessor,
  })  : _supabaseService = supabaseService,
        _queueProcessor = queueProcessor;

  /// Get pending notifications for a user
  ///
  /// Returns messages that have been delivered but not yet seen.
  Future<List<OutreachQueueMessage>> getPendingNotifications({
    required String userId,
    int? limit,
  }) async {
    try {
      developer.log(
        'Getting pending notifications for user: $userId',
        name: _logName,
      );

      final response = await _supabaseService.client
          .from('outreach_queue')
          .select()
          .eq('target_user_id', userId)
          .eq('status', 'delivered')
          .isFilter('seen_at', null)
          .order('delivered_at', ascending: false)
          .limit(limit ?? 50);

      if (response.isEmpty) {
        return [];
      }

      final messages = <OutreachQueueMessage>[];
      for (final row in response) {
        try {
          messages.add(_queueProcessor.parseQueueMessage(row));
        } catch (e) {
          developer.log('Error parsing notification: $e', name: _logName);
          continue;
        }
      }

      return messages;
    } catch (e) {
      developer.log('Error getting pending notifications: $e', name: _logName);
      return [];
    }
  }

  /// Mark notification as seen
  ///
  /// Called when user views the notification in-app.
  Future<bool> markNotificationAsSeen({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _supabaseService.client
          .from('outreach_queue')
          .update({
            'status': 'seen',
            'seen_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('target_user_id', userId);

      developer.log(
        '✅ Notification marked as seen: $messageId',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log(
        'Error marking notification as seen: $e',
        name: _logName,
      );
      return false;
    }
  }

  /// Handle user response to notification
  ///
  /// Called when user accepts, rejects, or ignores the outreach.
  Future<bool> handleNotificationResponse({
    required String messageId,
    required String userId,
    required String action, // 'accepted', 'rejected', 'ignored'
  }) async {
    try {
      await _supabaseService.client
          .from('outreach_queue')
          .update({
            'status': action,
            'response_action': action,
            'responded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('target_user_id', userId);

      developer.log(
        '✅ Notification response recorded: $messageId -> $action',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log(
        'Error handling notification response: $e',
        name: _logName,
      );
      return false;
    }
  }

  /// Get notification statistics for a user
  ///
  /// Returns counts of pending, seen, and responded notifications.
  Future<NotificationStats> getNotificationStats({
    required String userId,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('outreach_queue')
          .select('status')
          .eq('target_user_id', userId);

      if (response.isEmpty) {
        return NotificationStats(
          pending: 0,
          seen: 0,
          accepted: 0,
          rejected: 0,
          ignored: 0,
        );
      }

      int pending = 0;
      int seen = 0;
      int accepted = 0;
      int rejected = 0;
      int ignored = 0;

      for (final row in response) {
        final status = row['status'] as String;
        switch (status) {
          case 'delivered':
            pending++;
            break;
          case 'seen':
            seen++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'ignored':
            ignored++;
            break;
        }
      }

      return NotificationStats(
        pending: pending,
        seen: seen,
        accepted: accepted,
        rejected: rejected,
        ignored: ignored,
      );
    } catch (e) {
      developer.log('Error getting notification stats: $e', name: _logName);
      return NotificationStats(
        pending: 0,
        seen: 0,
        accepted: 0,
        rejected: 0,
        ignored: 0,
      );
    }
  }
}

/// Notification statistics
class NotificationStats {
  final int pending;
  final int seen;
  final int accepted;
  final int rejected;
  final int ignored;

  NotificationStats({
    required this.pending,
    required this.seen,
    required this.accepted,
    required this.rejected,
    required this.ignored,
  });

  int get total => pending + seen + accepted + rejected + ignored;
}
