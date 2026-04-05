import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_business_chat_service_ai2ai.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_business_message.dart';

/// Business-Business Outreach Service
///
/// Handles vibe-based matching and outreach between businesses.
/// Manages discovery, compatibility scoring, and partnership proposals.
class BusinessBusinessOutreachService {
  static const String _logName = 'BusinessBusinessOutreachService';
  final BusinessAccountService? _businessService;
  final BusinessBusinessChatServiceAI2AI? _chatService;

  BusinessBusinessOutreachService({
    dynamic
        partnershipService, // Reserved for future use (PartnershipService type)
    BusinessAccountService? businessService,
    BusinessBusinessChatServiceAI2AI? chatService,
  })  : _businessService = businessService,
        _chatService = chatService;

  /// Discover businesses for potential partnerships
  ///
  /// Returns a list of businesses sorted by compatibility score.
  /// Filters by minimum compatibility threshold and other criteria.
  Future<List<BusinessMatch>> discoverBusinesses({
    required String businessId,
    double minCompatibilityScore = 0.5,
    int limit = 20,
    List<String>? excludeBusinessIds,
    Map<String, dynamic>? filters, // e.g., location, business type
  }) async {
    try {
      developer.log(
        'Discovering businesses for partnership: $businessId (min score: $minCompatibilityScore)',
        name: _logName,
      );

      if (_businessService == null) {
        developer.log('BusinessAccountService not available', name: _logName);
        return [];
      }

      // Get all businesses (excluding self)
      // Note: In production, would query database for all businesses
      // For now, using getBusinessAccountsByUser as a workaround
      // TODO: Add getAllBusinessAccounts() method to BusinessAccountService
      final allBusinesses =
          <BusinessAccount>[]; // Placeholder - would query all businesses
      final filteredBusinesses = allBusinesses
          .where((b) => b.id != businessId)
          .where((b) => !(excludeBusinessIds?.contains(b.id) ?? false))
          .toList();

      // Calculate compatibility for each business
      final matches = <BusinessMatch>[];
      for (final business in filteredBusinesses) {
        try {
          // For business-business compatibility, we'll use a simplified approach
          // In production, this would use business vibes/preferences
          final compatibility = await _calculateBusinessCompatibility(
            businessId,
            business.id,
          );

          if (compatibility >= minCompatibilityScore) {
            matches.add(BusinessMatch(
              businessId: business.id,
              businessName: business.name,
              compatibilityScore: compatibility,
              metadata: {
                'business_type': business.businessType,
                'location': business.location,
                'description': business.description,
              },
            ));
          }
        } catch (e) {
          developer.log(
            'Error calculating compatibility for business ${business.id}: $e',
            name: _logName,
          );
        }
      }

      // Sort by compatibility score (highest first)
      matches.sort((a, b) =>
          (b.compatibilityScore ?? 0.0).compareTo(a.compatibilityScore ?? 0.0));

      // Limit results
      final limitedMatches = matches.take(limit).toList();

      developer.log(
        'Found ${limitedMatches.length} business matches',
        name: _logName,
      );

      return limitedMatches;
    } catch (e) {
      developer.log('Error discovering businesses: $e', name: _logName);
      return [];
    }
  }

  /// Calculate compatibility between two businesses
  ///
  /// Returns a score from 0.0 to 1.0 indicating compatibility.
  /// For business-business, uses business preferences and types.
  Future<double> _calculateBusinessCompatibility(
    String business1Id,
    String business2Id,
  ) async {
    try {
      if (_businessService == null) {
        return 0.5; // Default moderate compatibility
      }

      final business1 = await _businessService.getBusinessAccount(business1Id);
      final business2 = await _businessService.getBusinessAccount(business2Id);

      if (business1 == null || business2 == null) {
        return 0.0;
      }

      // Simple compatibility based on business type and location
      // In production, would use more sophisticated matching
      double compatibility = 0.5; // Base compatibility

      // Type match bonus
      if (business1.businessType == business2.businessType) {
        compatibility += 0.2;
      }

      // Location match bonus
      if (business1.location != null &&
          business2.location != null &&
          business1.location == business2.location) {
        compatibility += 0.2;
      }

      // Description similarity (simple keyword matching)
      if (business1.description != null && business2.description != null) {
        final desc1 = business1.description!.toLowerCase();
        final desc2 = business2.description!.toLowerCase();
        final words1 = desc1.split(' ');
        final words2 = desc2.split(' ');
        final commonWords = words1.where((w) => words2.contains(w)).length;
        final similarity = commonWords / (words1.length + words2.length);
        compatibility += similarity * 0.1;
      }

      return compatibility.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error calculating business compatibility: $e',
          name: _logName);
      return 0.5;
    }
  }

  /// Send partnership outreach to another business
  ///
  /// Initiates a conversation with a business by sending an initial message.
  /// Creates conversation if it doesn't exist.
  Future<bool> sendPartnershipOutreach({
    required String senderBusinessId,
    required String recipientBusinessId,
    required String message,
    String? partnershipType, // e.g., 'event_partnership', 'collaboration'
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
      final compatibilityScore = await _calculateBusinessCompatibility(
        senderBusinessId,
        recipientBusinessId,
      );

      // Send initial message via chat service
      await _chatService.sendMessage(
        senderBusinessId: senderBusinessId,
        recipientBusinessId: recipientBusinessId,
        content: message,
        messageType: partnershipType != null
            ? BusinessBusinessMessageType.eventPartnershipProposal
            : BusinessBusinessMessageType.text,
      );

      developer.log(
        'Partnership outreach sent to business $recipientBusinessId from business $senderBusinessId (compatibility: $compatibilityScore)',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error sending partnership outreach: $e', name: _logName);
      return false;
    }
  }

  /// Get partnership outreach history for a business
  ///
  /// Returns list of businesses the business has reached out to.
  Future<List<PartnershipOutreachRecord>> getOutreachHistory(
      String businessId) async {
    try {
      if (_chatService == null) {
        return [];
      }

      // Get all conversations for this business
      final conversations =
          await _chatService.getBusinessConversations(businessId);

      // Filter to only conversations initiated by this business
      final outreachRecords = <PartnershipOutreachRecord>[];

      for (final conversation in conversations) {
        final partnerBusinessId = conversation['partner_id'] as String?;
        if (partnerBusinessId == null) continue;

        // Get first message to determine if this business initiated
        final conversationId = conversation['id'] as String;
        final messages =
            await _chatService.getMessageHistory(conversationId, limit: 1);

        if (messages.isNotEmpty) {
          final firstMessage = messages.first;
          if (firstMessage.senderBusinessId == businessId) {
            outreachRecords.add(PartnershipOutreachRecord(
              partnerBusinessId: partnerBusinessId,
              partnerBusinessName: conversation['partner_name'] as String?,
              businessId: businessId,
              message: firstMessage.content,
              sentAt: firstMessage.createdAt,
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

  /// Get recommended businesses for partnerships
  ///
  /// Returns businesses with high compatibility scores that haven't been contacted yet.
  Future<List<BusinessMatch>> getRecommendedBusinesses({
    required String businessId,
    double minCompatibilityScore = 0.7,
    int limit = 10,
  }) async {
    try {
      // Get all businesses
      final allBusinesses = await discoverBusinesses(
        businessId: businessId,
        minCompatibilityScore: minCompatibilityScore,
        limit: 100, // Get more to filter out contacted ones
      );

      // Get outreach history to exclude already contacted businesses
      final outreachHistory = await getOutreachHistory(businessId);
      final contactedBusinessIds =
          outreachHistory.map((record) => record.partnerBusinessId).toSet();

      // Filter out contacted businesses and sort by compatibility
      final recommended = allBusinesses
          .where(
              (business) => !contactedBusinessIds.contains(business.businessId))
          .toList()
        ..sort((a, b) => (b.compatibilityScore ?? 0.0)
            .compareTo(a.compatibilityScore ?? 0.0));

      return recommended.take(limit).toList();
    } catch (e) {
      developer.log('Error getting recommended businesses: $e', name: _logName);
      return [];
    }
  }
}

/// Business match result
class BusinessMatch {
  final String businessId;
  final String? businessName;
  final double? compatibilityScore;
  final Map<String, dynamic>? metadata; // Additional business info

  BusinessMatch({
    required this.businessId,
    this.businessName,
    this.compatibilityScore,
    this.metadata,
  });
}

/// Partnership outreach record
class PartnershipOutreachRecord {
  final String partnerBusinessId;
  final String? partnerBusinessName;
  final String businessId;
  final String message;
  final DateTime sentAt;
  final String conversationId;

  PartnershipOutreachRecord({
    required this.partnerBusinessId,
    this.partnerBusinessName,
    required this.businessId,
    required this.message,
    required this.sentAt,
    required this.conversationId,
  });
}
