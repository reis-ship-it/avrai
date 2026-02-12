// ignore: dangling_library_doc_comments
/// Outreach History Service
/// 
/// Tracks outreach history to prevent duplicates and manage frequency.
/// Part of Predictive Proactive Outreach System - Phase 5.2
/// 
/// Features:
/// - Prevents duplicate outreach
/// - Tracks outreach frequency
/// - Manages cooldown periods
/// - Records success/failure rates

import 'dart:developer' as developer;
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Outreach history entry
class OutreachHistoryEntry {
  final String id;
  final String targetUserId;
  final String sourceId;
  final String sourceType;
  final String outreachType;
  final DateTime sentAt;
  final String? responseAction;
  final DateTime? respondedAt;
  final double compatibilityScore;
  
  OutreachHistoryEntry({
    required this.id,
    required this.targetUserId,
    required this.sourceId,
    required this.sourceType,
    required this.outreachType,
    required this.sentAt,
    this.responseAction,
    this.respondedAt,
    required this.compatibilityScore,
  });
}

/// Service for managing outreach history
class OutreachHistoryService {
  static const String _logName = 'OutreachHistoryService';
  
  final SupabaseService _supabaseService;
  
  // Cooldown periods (in days)
  static const int _communityCooldownDays = 30;
  static const int _groupCooldownDays = 14;
  static const int _eventCooldownDays = 7;
  static const int _businessCooldownDays = 30;
  static const int _clubCooldownDays = 30;
  static const int _expertCooldownDays = 30;
  static const int _listCooldownDays = 14;
  
  OutreachHistoryService({
    required SupabaseService supabaseService,
  })  : _supabaseService = supabaseService;
  
  /// Check if outreach is allowed (not in cooldown period)
  /// 
  /// Returns true if outreach can be sent, false if in cooldown.
  Future<bool> canSendOutreach({
    required String targetUserId,
    required String sourceId,
    required String sourceType,
    required String outreachType,
  }) async {
    try {
      final cooldownDays = _getCooldownDays(outreachType);
      final cooldownDate = DateTime.now().subtract(Duration(days: cooldownDays));
      
      final response = await _supabaseService.client
          .from('outreach_history')
          .select()
          .eq('target_user_id', targetUserId)
          .eq('source_id', sourceId)
          .eq('source_type', sourceType)
          .eq('outreach_type', outreachType)
          .gte('sent_at', cooldownDate.toIso8601String())
          .maybeSingle();
      
      // If no recent outreach found, can send
      if (response == null) {
        return true;
      }
      
      developer.log(
        '⚠️ Outreach in cooldown: $sourceType $sourceId -> user $targetUserId '
        '(last sent: ${response['sent_at']})',
        name: _logName,
      );
      
      return false;
    } catch (e) {
      developer.log('Error checking outreach cooldown: $e', name: _logName);
      // On error, allow outreach (fail open)
      return true;
    }
  }
  
  /// Record outreach in history
  /// 
  /// Called after outreach is successfully sent.
  Future<bool> recordOutreach({
    required String targetUserId,
    required String sourceId,
    required String sourceType,
    required String outreachType,
    required double compatibilityScore,
  }) async {
    try {
      await _supabaseService.client
          .from('outreach_history')
          .insert({
            'target_user_id': targetUserId,
            'source_id': sourceId,
            'source_type': sourceType,
            'outreach_type': outreachType,
            'compatibility_score': compatibilityScore,
            'sent_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
      
      developer.log(
        '✅ Outreach recorded in history: $sourceType $sourceId -> user $targetUserId',
        name: _logName,
      );
      
      return true;
    } catch (e) {
      developer.log('Error recording outreach: $e', name: _logName);
      return false;
    }
  }
  
  /// Update outreach response
  /// 
  /// Called when user responds to outreach.
  Future<bool> updateOutreachResponse({
    required String targetUserId,
    required String sourceId,
    required String sourceType,
    required String outreachType,
    required String responseAction, // 'accepted', 'rejected', 'ignored'
  }) async {
    try {
      await _supabaseService.client
          .from('outreach_history')
          .update({
            'response_action': responseAction,
            'responded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('target_user_id', targetUserId)
          .eq('source_id', sourceId)
          .eq('source_type', sourceType)
          .eq('outreach_type', outreachType)
          .isFilter('responded_at', null) // Only update if not already responded
          .limit(1);
      
      developer.log(
        '✅ Outreach response updated: $sourceType $sourceId -> $responseAction',
        name: _logName,
      );
      
      return true;
    } catch (e) {
      developer.log('Error updating outreach response: $e', name: _logName);
      return false;
    }
  }
  
  /// Get outreach history for a user
  /// 
  /// Returns all outreach sent to a user.
  Future<List<OutreachHistoryEntry>> getUserOutreachHistory({
    required String userId,
    int? limit,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('outreach_history')
          .select()
          .eq('target_user_id', userId)
          .order('sent_at', ascending: false)
          .limit(limit ?? 100);
      
      if (response.isEmpty) {
        return [];
      }
      
      final entries = <OutreachHistoryEntry>[];
      for (final row in response) {
        try {
          entries.add(OutreachHistoryEntry(
            id: row['id'] as String,
            targetUserId: row['target_user_id'] as String,
            sourceId: row['source_id'] as String,
            sourceType: row['source_type'] as String,
            outreachType: row['outreach_type'] as String,
            sentAt: DateTime.parse(row['sent_at'] as String),
            responseAction: row['response_action'] as String?,
            respondedAt: row['responded_at'] != null
                ? DateTime.parse(row['responded_at'] as String)
                : null,
            compatibilityScore: (row['compatibility_score'] as num?)?.toDouble() ?? 0.0,
          ));
        } catch (e) {
          developer.log('Error parsing history entry: $e', name: _logName);
          continue;
        }
      }
      
      return entries;
    } catch (e) {
      developer.log('Error getting outreach history: $e', name: _logName);
      return [];
    }
  }
  
  /// Get cooldown days for outreach type
  int _getCooldownDays(String outreachType) {
    switch (outreachType) {
      case 'community_invitation':
        return _communityCooldownDays;
      case 'group_formation':
        return _groupCooldownDays;
      case 'event_call':
        return _eventCooldownDays;
      case 'business_event_invitation':
      case 'business_expert_partnership':
      case 'business_business_partnership':
        return _businessCooldownDays;
      case 'club_membership_invitation':
      case 'club_event_invitation':
        return _clubCooldownDays;
      case 'expert_learning_opportunity':
      case 'expert_business_partnership':
        return _expertCooldownDays;
      case 'list_suggestion':
      case 'expert_curated_list':
        return _listCooldownDays;
      default:
        return 30; // Default cooldown
    }
  }
}
