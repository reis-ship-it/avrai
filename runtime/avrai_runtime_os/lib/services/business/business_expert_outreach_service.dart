import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai_core/models/business/business_expert_message.dart';

/// Business-Expert Outreach Service
///
/// Handles vibe-based matching and outreach between businesses and experts.
/// Manages discovery, compatibility scoring, and outreach initiation.
class BusinessExpertOutreachService {
  static const String _logName = 'BusinessExpertOutreachService';
  final PartnershipService? _partnershipService;
  final BusinessExpertChatServiceAI2AI? _chatService;

  BusinessExpertOutreachService({
    PartnershipService? partnershipService,
    BusinessExpertChatServiceAI2AI? chatService,
  })  : _partnershipService = partnershipService,
        _chatService = chatService;

  /// Discover experts based on vibe compatibility
  ///
  /// Returns a list of experts sorted by compatibility score.
  /// Filters by minimum compatibility threshold and other criteria.
  Future<List<ExpertMatch>> discoverExperts({
    required String businessId,
    double minCompatibilityScore = 0.5,
    int limit = 20,
    List<String>? excludeExpertIds,
    Map<String, dynamic>? filters, // e.g., location, expertise areas
  }) async {
    try {
      developer.log(
        'Discovering experts for business: $businessId (min score: $minCompatibilityScore)',
        name: _logName,
      );

      // TODO: Get list of experts from user service
      // For now, this is a placeholder that would query experts
      // In production, would:
      // 1. Query all experts (or filtered by criteria)
      // 2. Calculate vibe compatibility for each
      // 3. Sort by score
      // 4. Return top matches

      final expertMatches = <ExpertMatch>[];

      // Placeholder: In real implementation, would query experts
      // For now, return empty list - this will be implemented when
      // expert discovery system is available

      developer.log(
        'Found ${expertMatches.length} expert matches',
        name: _logName,
      );

      return expertMatches;
    } catch (e) {
      developer.log('Error discovering experts: $e', name: _logName);
      return [];
    }
  }

  /// Calculate vibe compatibility between business and expert
  ///
  /// Returns a score from 0.0 to 1.0 indicating compatibility.
  Future<double?> calculateCompatibility({
    required String businessId,
    required String expertId,
  }) async {
    try {
      if (_partnershipService == null) {
        developer.log(
          'PartnershipService not available, cannot calculate compatibility',
          name: _logName,
        );
        return null;
      }

      final score = await _partnershipService.calculateVibeCompatibility(
        userId: expertId,
        businessId: businessId,
      );

      developer.log(
        'Compatibility score for business $businessId and expert $expertId: $score',
        name: _logName,
      );

      return score;
    } catch (e) {
      developer.log('Error calculating compatibility: $e', name: _logName);
      return null;
    }
  }

  /// Send outreach message to an expert
  ///
  /// Initiates a conversation with an expert by sending an initial message.
  /// Creates conversation if it doesn't exist.
  Future<bool> sendOutreach({
    required String businessId,
    required String expertId,
    required String message,
    String? subject, // Optional subject/topic
  }) async {
    try {
      if (_chatService == null) {
        developer.log(
          'ChatService not available, cannot send outreach',
          name: _logName,
        );
        return false;
      }

      // Calculate compatibility score
      final compatibilityScore = await calculateCompatibility(
        businessId: businessId,
        expertId: expertId,
      );

      // Send initial message via chat service
      await _chatService.sendMessage(
        businessId: businessId,
        expertId: expertId,
        content: message,
        senderType: MessageSenderType.business,
        messageType: MessageType.text,
      );

      developer.log(
        'Outreach sent to expert $expertId from business $businessId (compatibility: $compatibilityScore)',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error sending outreach: $e', name: _logName);
      return false;
    }
  }

  /// Get outreach history for a business
  ///
  /// Returns list of experts the business has reached out to.
  Future<List<OutreachRecord>> getOutreachHistory(String businessId) async {
    try {
      if (_chatService == null) {
        return [];
      }

      // Get all conversations for this business
      final conversations =
          await _chatService.getBusinessConversations(businessId);

      // Filter to only conversations initiated by the business
      // (i.e., where business sent the first message)
      final outreachRecords = <OutreachRecord>[];

      for (final conversation in conversations) {
        final expertId = conversation['expert_id'] as String?;
        if (expertId == null) continue;

        // Get first message to determine if business initiated
        final conversationId = conversation['id'] as String;
        final messages =
            await _chatService.getMessageHistory(conversationId, limit: 1);

        if (messages.isNotEmpty) {
          final firstMessage = messages.first;
          if (firstMessage.senderType == MessageSenderType.business) {
            outreachRecords.add(OutreachRecord(
              expertId: expertId,
              expertName: conversation['expert_name'] as String?,
              businessId: businessId,
              message: firstMessage.content,
              sentAt: firstMessage.createdAt,
              compatibilityScore:
                  conversation['vibe_compatibility_score'] as double?,
              conversationId: conversationId,
            ));
          }
        }
      }

      // Sort by most recent
      outreachRecords.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return outreachRecords;
    } catch (e) {
      developer.log('Error getting outreach history: $e', name: _logName);
      return [];
    }
  }

  /// Get recommended experts for a business
  ///
  /// Returns experts with high compatibility scores that haven't been contacted yet.
  Future<List<ExpertMatch>> getRecommendedExperts({
    required String businessId,
    double minCompatibilityScore = 0.7,
    int limit = 10,
  }) async {
    try {
      // Get all experts
      final allExperts = await discoverExperts(
        businessId: businessId,
        minCompatibilityScore: minCompatibilityScore,
        limit: 100, // Get more to filter out contacted ones
      );

      // Get outreach history to exclude already contacted experts
      final outreachHistory = await getOutreachHistory(businessId);
      final contactedExpertIds =
          outreachHistory.map((record) => record.expertId).toSet();

      // Filter out contacted experts and sort by compatibility
      final recommended = allExperts
          .where((expert) => !contactedExpertIds.contains(expert.expertId))
          .toList()
        ..sort((a, b) => (b.compatibilityScore ?? 0.0)
            .compareTo(a.compatibilityScore ?? 0.0));

      return recommended.take(limit).toList();
    } catch (e) {
      developer.log('Error getting recommended experts: $e', name: _logName);
      return [];
    }
  }
}

/// Expert match result
class ExpertMatch {
  final String expertId;
  final String? expertName;
  final double? compatibilityScore;
  final Map<String, dynamic>? metadata; // Additional expert info

  ExpertMatch({
    required this.expertId,
    this.expertName,
    this.compatibilityScore,
    this.metadata,
  });
}

/// Outreach record
class OutreachRecord {
  final String expertId;
  final String? expertName;
  final String businessId;
  final String message;
  final DateTime sentAt;
  final double? compatibilityScore;
  final String conversationId;

  OutreachRecord({
    required this.expertId,
    this.expertName,
    required this.businessId,
    required this.message,
    required this.sentAt,
    this.compatibilityScore,
    required this.conversationId,
  });
}
