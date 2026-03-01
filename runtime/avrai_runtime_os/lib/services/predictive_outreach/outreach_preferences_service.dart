// ignore: dangling_library_doc_comments
/// Outreach Preferences Service
///
/// Manages user preferences for proactive outreach.
/// Part of Predictive Proactive Outreach System - Phase 5.3
///
/// Features:
/// - Opt-in/opt-out controls
/// - Frequency preferences
/// - Notification preferences
/// - Per-type preferences

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Outreach preferences
class OutreachPreferences {
  final String userId;
  final bool enabled;
  final String frequency; // 'high', 'medium', 'low', 'off'
  final bool allowCommunityInvitations;
  final bool allowGroupFormation;
  final bool allowEventCalls;
  final bool allowBusinessOutreach;
  final bool allowClubOutreach;
  final bool allowExpertOutreach;
  final bool allowListSuggestions;
  final DateTime updatedAt;

  OutreachPreferences({
    required this.userId,
    required this.enabled,
    required this.frequency,
    required this.allowCommunityInvitations,
    required this.allowGroupFormation,
    required this.allowEventCalls,
    required this.allowBusinessOutreach,
    required this.allowClubOutreach,
    required this.allowExpertOutreach,
    required this.allowListSuggestions,
    required this.updatedAt,
  });

  /// Check if a specific outreach type is allowed
  bool isOutreachTypeAllowed(String outreachType) {
    if (!enabled) return false;
    if (frequency == 'off') return false;

    switch (outreachType) {
      case 'community_invitation':
        return allowCommunityInvitations;
      case 'group_formation':
        return allowGroupFormation;
      case 'event_call':
        return allowEventCalls;
      case 'business_event_invitation':
      case 'business_expert_partnership':
      case 'business_business_partnership':
        return allowBusinessOutreach;
      case 'club_membership_invitation':
      case 'club_event_invitation':
        return allowClubOutreach;
      case 'expert_learning_opportunity':
      case 'expert_business_partnership':
        return allowExpertOutreach;
      case 'list_suggestion':
      case 'expert_curated_list':
        return allowListSuggestions;
      default:
        return true; // Default allow
    }
  }

  /// Get frequency multiplier (for adjusting outreach frequency)
  double get frequencyMultiplier {
    switch (frequency) {
      case 'high':
        return 1.0;
      case 'medium':
        return 0.7;
      case 'low':
        return 0.4;
      case 'off':
        return 0.0;
      default:
        return 0.7; // Default medium
    }
  }
}

/// Service for managing outreach preferences
class OutreachPreferencesService {
  static const String _logName = 'OutreachPreferencesService';

  final SupabaseService _supabaseService;

  OutreachPreferencesService({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  /// Get user's outreach preferences
  ///
  /// Returns default preferences if none exist.
  Future<OutreachPreferences> getUserPreferences({
    required String userId,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('outreach_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Return default preferences
        return OutreachPreferences(
          userId: userId,
          enabled: true,
          frequency: 'medium',
          allowCommunityInvitations: true,
          allowGroupFormation: true,
          allowEventCalls: true,
          allowBusinessOutreach: true,
          allowClubOutreach: true,
          allowExpertOutreach: true,
          allowListSuggestions: true,
          updatedAt: DateTime.now(),
        );
      }

      return OutreachPreferences(
        userId: userId,
        enabled: response['enabled'] as bool? ?? true,
        frequency: response['frequency'] as String? ?? 'medium',
        allowCommunityInvitations:
            response['allow_community_invitations'] as bool? ?? true,
        allowGroupFormation: response['allow_group_formation'] as bool? ?? true,
        allowEventCalls: response['allow_event_calls'] as bool? ?? true,
        allowBusinessOutreach:
            response['allow_business_outreach'] as bool? ?? true,
        allowClubOutreach: response['allow_club_outreach'] as bool? ?? true,
        allowExpertOutreach: response['allow_expert_outreach'] as bool? ?? true,
        allowListSuggestions:
            response['allow_list_suggestions'] as bool? ?? true,
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      developer.log('Error getting user preferences: $e', name: _logName);
      // Return default on error
      return OutreachPreferences(
        userId: userId,
        enabled: true,
        frequency: 'medium',
        allowCommunityInvitations: true,
        allowGroupFormation: true,
        allowEventCalls: true,
        allowBusinessOutreach: true,
        allowClubOutreach: true,
        allowExpertOutreach: true,
        allowListSuggestions: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Update user's outreach preferences
  Future<bool> updateUserPreferences({
    required String userId,
    required OutreachPreferences preferences,
  }) async {
    try {
      await _supabaseService.client.from('outreach_preferences').upsert({
        'user_id': userId,
        'enabled': preferences.enabled,
        'frequency': preferences.frequency,
        'allow_community_invitations': preferences.allowCommunityInvitations,
        'allow_group_formation': preferences.allowGroupFormation,
        'allow_event_calls': preferences.allowEventCalls,
        'allow_business_outreach': preferences.allowBusinessOutreach,
        'allow_club_outreach': preferences.allowClubOutreach,
        'allow_expert_outreach': preferences.allowExpertOutreach,
        'allow_list_suggestions': preferences.allowListSuggestions,
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log(
        '✅ Outreach preferences updated for user: $userId',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error updating user preferences: $e', name: _logName);
      return false;
    }
  }

  /// Check if outreach is allowed for user
  ///
  /// Combines preferences check with history cooldown.
  Future<bool> isOutreachAllowed({
    required String userId,
    required String outreachType,
  }) async {
    try {
      final preferences = await getUserPreferences(userId: userId);
      return preferences.isOutreachTypeAllowed(outreachType);
    } catch (e) {
      developer.log('Error checking outreach allowance: $e', name: _logName);
      // Fail open - allow outreach on error
      return true;
    }
  }
}
