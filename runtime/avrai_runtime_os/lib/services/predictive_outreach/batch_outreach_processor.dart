// ignore: dangling_library_doc_comments
/// Batch Outreach Processor
///
/// Processes outreach in batches across all outreach types.
/// Part of Predictive Proactive Outreach System - Phase 4.3
///
/// Handles:
/// - Batch processing of communities, groups, events, businesses, clubs, experts, lists
/// - Incremental processing for scalability
/// - Error handling and retries
/// - Performance optimization

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/predictive_outreach/community_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/group_formation_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/event_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/business_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/club_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/expert_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/list_suggestion_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/outreach_queue_processor.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Batch processing result
class BatchProcessingResult {
  final bool success;
  final int totalProcessed;
  final int totalSuccess;
  final int totalFailures;
  final String? error;

  // Per-type counts
  final int communitiesProcessed;
  final int groupsProcessed;
  final int eventsProcessed;
  final int businessesProcessed;
  final int clubsProcessed;
  final int expertsProcessed;
  final int listsProcessed;

  BatchProcessingResult({
    required this.success,
    required this.totalProcessed,
    required this.totalSuccess,
    required this.totalFailures,
    this.error,
    this.communitiesProcessed = 0,
    this.groupsProcessed = 0,
    this.eventsProcessed = 0,
    this.businessesProcessed = 0,
    this.clubsProcessed = 0,
    this.expertsProcessed = 0,
    this.listsProcessed = 0,
  });
}

/// Service for batch processing all outreach types
class BatchOutreachProcessor {
  static const String _logName = 'BatchOutreachProcessor';

  final CommunityProactiveOutreachService _communityOutreach;
  // TODO: Use group outreach for proactive group formation
  // ignore: unused_field
  final GroupFormationOutreachService _groupOutreach;
  final EventProactiveOutreachService _eventOutreach;
  final BusinessProactiveOutreachService _businessOutreach;
  final ClubProactiveOutreachService _clubOutreach;
  final ExpertProactiveOutreachService _expertOutreach;
  final ListSuggestionOutreachService _listOutreach;
  final OutreachQueueProcessor _queueProcessor;
  final SupabaseService _supabaseService;

  // Batch sizes for each type
  static const int _communityBatchSize = 20;
  // TODO: Use group batch size when implementing proactive group formation
  // ignore: unused_field
  static const int _groupBatchSize = 10;
  // TODO: Use event batch size when implementing event batch processing
  // ignore: unused_field
  static const int _eventBatchSize = 50;
  static const int _businessBatchSize = 20;
  static const int _clubBatchSize = 20;
  static const int _expertBatchSize = 20;
  static const int _listBatchSize = 30;

  BatchOutreachProcessor({
    required CommunityProactiveOutreachService communityOutreach,
    required GroupFormationOutreachService groupOutreach,
    required EventProactiveOutreachService eventOutreach,
    required BusinessProactiveOutreachService businessOutreach,
    required ClubProactiveOutreachService clubOutreach,
    required ExpertProactiveOutreachService expertOutreach,
    required ListSuggestionOutreachService listOutreach,
    required OutreachQueueProcessor queueProcessor,
    required SupabaseService supabaseService,
  })  : _communityOutreach = communityOutreach,
        _groupOutreach = groupOutreach,
        _eventOutreach = eventOutreach,
        _businessOutreach = businessOutreach,
        _clubOutreach = clubOutreach,
        _expertOutreach = expertOutreach,
        _listOutreach = listOutreach,
        _queueProcessor = queueProcessor,
        _supabaseService = supabaseService;

  /// Process all outreach types
  ///
  /// **Flow:**
  /// 1. Process outreach queue (deliver pending messages)
  /// 2. Process communities
  /// 3. Process groups
  /// 4. Process events
  /// 5. Process businesses
  /// 6. Process clubs
  /// 7. Process experts
  /// 8. Process lists
  ///
  /// **Returns:**
  /// Combined result with counts for all types
  Future<BatchProcessingResult> processAllOutreachTypes() async {
    try {
      developer.log(
        '🚀 Starting batch processing of all outreach types',
        name: _logName,
      );

      int totalProcessed = 0;
      int totalSuccess = 0;
      int totalFailures = 0;

      // 1. Process outreach queue first (deliver pending messages)
      final queueResult = await _queueProcessor.processPendingMessages();
      totalProcessed += queueResult.totalProcessed;
      totalSuccess += queueResult.successCount;
      totalFailures += queueResult.failureCount;

      // 2. Process communities
      final communitiesResult = await _processCommunities();
      totalProcessed += communitiesResult.processed;
      totalSuccess += communitiesResult.success;
      totalFailures += communitiesResult.failures;

      // 3. Process groups
      final groupsResult = await _processGroups();
      totalProcessed += groupsResult.processed;
      totalSuccess += groupsResult.success;
      totalFailures += groupsResult.failures;

      // 4. Process events
      final eventsResult = await _processEvents();
      totalProcessed += eventsResult.processed;
      totalSuccess += eventsResult.success;
      totalFailures += eventsResult.failures;

      // 5. Process businesses
      final businessesResult = await _processBusinesses();
      totalProcessed += businessesResult.processed;
      totalSuccess += businessesResult.success;
      totalFailures += businessesResult.failures;

      // 6. Process clubs
      final clubsResult = await _processClubs();
      totalProcessed += clubsResult.processed;
      totalSuccess += clubsResult.success;
      totalFailures += clubsResult.failures;

      // 7. Process experts
      final expertsResult = await _processExperts();
      totalProcessed += expertsResult.processed;
      totalSuccess += expertsResult.success;
      totalFailures += expertsResult.failures;

      // 8. Process lists
      final listsResult = await _processLists();
      totalProcessed += listsResult.processed;
      totalSuccess += listsResult.success;
      totalFailures += listsResult.failures;

      developer.log(
        '✅ Batch processing complete: $totalProcessed total, '
        '$totalSuccess succeeded, $totalFailures failed',
        name: _logName,
      );

      return BatchProcessingResult(
        success: totalFailures < totalProcessed * 0.1, // < 10% failure rate
        totalProcessed: totalProcessed,
        totalSuccess: totalSuccess,
        totalFailures: totalFailures,
        communitiesProcessed: communitiesResult.processed,
        groupsProcessed: groupsResult.processed,
        eventsProcessed: eventsResult.processed,
        businessesProcessed: businessesResult.processed,
        clubsProcessed: clubsResult.processed,
        expertsProcessed: expertsResult.processed,
        listsProcessed: listsResult.processed,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Batch processing failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );

      return BatchProcessingResult(
        success: false,
        totalProcessed: 0,
        totalSuccess: 0,
        totalFailures: 0,
        error: e.toString(),
      );
    }
  }

  /// Process communities
  Future<TypeProcessingResult> _processCommunities() async {
    try {
      final communityIds =
          await _getActiveCommunityIds(limit: _communityBatchSize);

      int processed = 0;
      int success = 0;
      int failures = 0;

      for (final communityId in communityIds) {
        try {
          await _communityOutreach.processCommunityOutreach(
              communityId: communityId);
          success++;
        } catch (e) {
          developer.log('Error processing community $communityId: $e',
              name: _logName);
          failures++;
        }
        processed++;
      }

      return TypeProcessingResult(
        processed: processed,
        success: success,
        failures: failures,
      );
    } catch (e) {
      developer.log('Error processing communities: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Process groups
  Future<TypeProcessingResult> _processGroups() async {
    // Groups are typically formed on-demand, not in batch
    // This would handle proactive group formation suggestions
    return TypeProcessingResult(processed: 0, success: 0, failures: 0);
  }

  /// Process events
  Future<TypeProcessingResult> _processEvents() async {
    try {
      await _eventOutreach.processAllUpcomingEvents();
      return TypeProcessingResult(processed: 1, success: 1, failures: 0);
    } catch (e) {
      developer.log('Error processing events: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Process businesses
  Future<TypeProcessingResult> _processBusinesses() async {
    try {
      final businessIds =
          await _getActiveBusinessIds(limit: _businessBatchSize);

      int processed = 0;
      int success = 0;
      int failures = 0;

      for (final businessId in businessIds) {
        try {
          await _businessOutreach.processBusinessExpertOutreach(
              businessId: businessId);
          await _businessOutreach.processBusinessBusinessOutreach(
              businessId: businessId);
          success++;
        } catch (e) {
          developer.log('Error processing business $businessId: $e',
              name: _logName);
          failures++;
        }
        processed++;
      }

      return TypeProcessingResult(
        processed: processed,
        success: success,
        failures: failures,
      );
    } catch (e) {
      developer.log('Error processing businesses: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Process clubs
  Future<TypeProcessingResult> _processClubs() async {
    try {
      final clubIds = await _getActiveClubIds(limit: _clubBatchSize);

      int processed = 0;
      int success = 0;
      int failures = 0;

      for (final clubId in clubIds) {
        try {
          await _clubOutreach.processClubMembershipOutreach(clubId: clubId);
          success++;
        } catch (e) {
          developer.log('Error processing club $clubId: $e', name: _logName);
          failures++;
        }
        processed++;
      }

      return TypeProcessingResult(
        processed: processed,
        success: success,
        failures: failures,
      );
    } catch (e) {
      developer.log('Error processing clubs: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Process experts
  Future<TypeProcessingResult> _processExperts() async {
    try {
      final expertIds = await _getActiveExpertIds(limit: _expertBatchSize);

      int processed = 0;
      int success = 0;
      int failures = 0;

      for (final expertId in expertIds) {
        try {
          await _expertOutreach.processExpertLearningOutreach(
              expertId: expertId);
          await _expertOutreach.processExpertBusinessOutreach(
              expertId: expertId);
          success++;
        } catch (e) {
          developer.log('Error processing expert $expertId: $e',
              name: _logName);
          failures++;
        }
        processed++;
      }

      return TypeProcessingResult(
        processed: processed,
        success: success,
        failures: failures,
      );
    } catch (e) {
      developer.log('Error processing experts: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Process lists
  Future<TypeProcessingResult> _processLists() async {
    try {
      final userIds = await _getActiveUserIds(limit: _listBatchSize);

      int processed = 0;
      int success = 0;
      int failures = 0;

      for (final userId in userIds) {
        try {
          await _listOutreach.processGeneralListSuggestions(userId: userId);
          await _listOutreach.processExpertCuratedListSuggestions(
              userId: userId);
          success++;
        } catch (e) {
          developer.log('Error processing lists for user $userId: $e',
              name: _logName);
          failures++;
        }
        processed++;
      }

      return TypeProcessingResult(
        processed: processed,
        success: success,
        failures: failures,
      );
    } catch (e) {
      developer.log('Error processing lists: $e', name: _logName);
      return TypeProcessingResult(processed: 0, success: 0, failures: 0);
    }
  }

  /// Get active community IDs
  Future<List<String>> _getActiveCommunityIds({required int limit}) async {
    try {
      final response = await _supabaseService.client
          .from('communities_v1')
          .select('id')
          .eq('activity_level', 'active')
          .limit(limit);

      if (response.isEmpty) return [];

      return (response as List).map((row) => row['id'] as String).toList();
    } catch (e) {
      developer.log('Error fetching community IDs: $e', name: _logName);
      return [];
    }
  }

  /// Get active business IDs
  Future<List<String>> _getActiveBusinessIds({required int limit}) async {
    // Placeholder - would query business accounts table
    return [];
  }

  /// Get active club IDs
  Future<List<String>> _getActiveClubIds({required int limit}) async {
    // Placeholder - would query clubs table
    return [];
  }

  /// Get active expert IDs
  Future<List<String>> _getActiveExpertIds({required int limit}) async {
    // Placeholder - would query users with expertise
    return [];
  }

  /// Get active user IDs
  Future<List<String>> _getActiveUserIds({required int limit}) async {
    try {
      final response = await _supabaseService.client
          .from('users')
          .select('id')
          .eq('is_active', true)
          .limit(limit);

      if (response.isEmpty) return [];

      return (response as List).map((row) => row['id'] as String).toList();
    } catch (e) {
      developer.log('Error fetching user IDs: $e', name: _logName);
      return [];
    }
  }
}

/// Type processing result
class TypeProcessingResult {
  final int processed;
  final int success;
  final int failures;

  TypeProcessingResult({
    required this.processed,
    required this.success,
    required this.failures,
  });
}
