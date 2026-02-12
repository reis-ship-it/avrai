import 'package:avrai/core/models/business/business_member.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/business/business_member_service.dart';
import 'package:avrai/core/ai/personality_learning.dart' as pl;
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:uuid/uuid.dart';

/// Business Shared Agent Service
/// 
/// Manages the shared AI agent for a business account.
/// Aggregates learning from all business members into a unified business personality.
/// 
/// **Architecture:**
/// ```
/// Individual Member Agents
///     ↓
/// Feed Learning Data
///     ↓
/// Shared Business Agent (Neural Network)
///     ↓
/// Aggregates Learning
///     ↓
/// Evolves Business Personality
///     ↓
/// Used for Business Matching & Recommendations
/// ```
class BusinessSharedAgentService {
  static const String _logName = 'BusinessSharedAgentService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final BusinessAccountService _businessAccountService;
  final BusinessMemberService _memberService;
  final pl.PersonalityLearning _personalityLearning;

  BusinessSharedAgentService({
    required BusinessAccountService businessAccountService,
    required BusinessMemberService memberService,
    required pl.PersonalityLearning personalityLearning,
  })  : _businessAccountService = businessAccountService,
        _memberService = memberService,
        _personalityLearning = personalityLearning;

  /// Initialize shared agent for a business
  /// 
  /// **Flow:**
  /// 1. Check if agent already exists
  /// 2. Create agent ID
  /// 3. Initialize personality profile from business data
  /// 4. Update business account with agent ID
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// 
  /// **Returns:**
  /// Agent ID
  Future<String> initializeSharedAgent(String businessId) async {
    try {
      _logger.info('Initializing shared agent for business: $businessId', tag: _logName);

      // Step 1: Get business account
      final business = await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Step 2: Check if agent already exists
      if (business.sharedAgentId != null) {
        _logger.info('Shared agent already exists: ${business.sharedAgentId}', tag: _logName);
        return business.sharedAgentId!;
      }

      // Step 3: Create agent ID
      final agentId = _uuid.v4();

      // Step 4: Initialize personality profile
      // Start with a neutral profile that will be shaped by member interactions
      await _personalityLearning.initializePersonality(
        'business_$businessId',
      );

      // Step 5: Update business account with agent ID
      // Note: Would need to update BusinessAccountService to support sharedAgentId update
      // For now, this is a placeholder

      _logger.info('Initialized shared agent: $agentId', tag: _logName);
      return agentId;
    } catch (e) {
      _logger.error('Error initializing shared agent', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Feed member learning into shared agent
  /// 
  /// **Flow:**
  /// 1. Get business account and shared agent
  /// 2. Get member's individual agent learning data
  /// 3. Aggregate learning data from all members
  /// 4. Apply aggregated learning to shared agent
  /// 5. Update shared agent personality profile
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `memberUserId`: User ID of the member whose learning to incorporate
  /// - `learningData`: Learning data from member's individual agent
  /// 
  /// **Returns:**
  /// Updated PersonalityProfile
  Future<PersonalityProfile> feedMemberLearning({
    required String businessId,
    required String memberUserId,
    required Map<String, dynamic> learningData,
  }) async {
    try {
      _logger.info(
        'Feeding member learning into shared agent: business=$businessId, member=$memberUserId',
        tag: _logName,
      );

      // Step 1: Get business account
      final business = await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Step 2: Validate member exists
      final member = await _memberService.getMember(
        businessId: businessId,
        userId: memberUserId,
      );
      if (member == null) {
        throw Exception('User is not a member of this business');
      }

      // Step 3: Validate shared agent exists
      await getSharedAgentProfile(businessId);

      // Step 4: Aggregate learning from all members
      final aggregatedLearning = await _aggregateMemberLearning(
        businessId: businessId,
        newMemberLearning: learningData,
        memberUserId: memberUserId,
      );

      // Step 5: Apply aggregated learning to shared agent
      // Convert learning data to AI2AI insight format
      // Use communityInsight type for member contributions
      final insight = pl.AI2AILearningInsight(
        type: pl.AI2AIInsightType.communityInsight,
        dimensionInsights: aggregatedLearning['dimensionInsights'] as Map<String, double>? ?? {},
        learningQuality: aggregatedLearning['confidenceScore'] as double? ?? 0.5,
        timestamp: DateTime.now(),
      );

      // Evolve shared agent personality
      final evolvedProfile = await _personalityLearning.evolveFromAI2AILearning(
        'business_$businessId',
        insight,
      );

      _logger.info(
        'Fed member learning into shared agent: generation=${evolvedProfile.evolutionGeneration}',
        tag: _logName,
      );

      return evolvedProfile;
    } catch (e) {
      _logger.error('Error feeding member learning', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get shared agent personality profile
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// 
  /// **Returns:**
  /// PersonalityProfile for the shared agent
  Future<PersonalityProfile> getSharedAgentProfile(String businessId) async {
    try {
      final business = await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Initialize agent if it doesn't exist
      if (business.sharedAgentId == null) {
        await initializeSharedAgent(businessId);
      }

      // Get personality profile for business agent
      return await _personalityLearning.initializePersonality('business_$businessId');
    } catch (e) {
      _logger.error('Error getting shared agent profile', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Aggregate learning from all business members
  /// 
  /// **Flow:**
  /// 1. Get all active members
  /// 2. Collect learning data from each member's individual agent
  /// 3. Weight learning by member role (owner > admin > member)
  /// 4. Aggregate dimension insights
  /// 5. Calculate confidence score
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `newMemberLearning`: New learning data from a member
  /// - `memberUserId`: User ID of the member contributing learning
  /// 
  /// **Returns:**
  /// Aggregated learning data
  Future<Map<String, dynamic>> _aggregateMemberLearning({
    required String businessId,
    required Map<String, dynamic> newMemberLearning,
    required String memberUserId,
  }) async {
    try {
      // Step 1: Get all active members
      final members = await _memberService.getBusinessMembers(businessId: businessId);

      // Step 2: Calculate role weights
      final roleWeights = <BusinessMemberRole, double>{
        BusinessMemberRole.owner: 1.0,
        BusinessMemberRole.admin: 0.8,
        BusinessMemberRole.member: 0.6,
      };

      // Step 3: Get member role
      final member = members.firstWhere(
        (m) => m.userId == memberUserId,
        orElse: () => throw Exception('Member not found'),
      );

      final memberWeight = roleWeights[member.role] ?? 0.6;

      // Step 4: Extract dimension insights from learning data
      final dimensionInsights = <String, double>{};
      if (newMemberLearning.containsKey('dimensionInsights')) {
        final insights = newMemberLearning['dimensionInsights'];
        if (insights is Map<String, dynamic>) {
          insights.forEach((dimension, value) {
            if (value is num) {
              dimensionInsights[dimension] = value.toDouble() * memberWeight;
            }
          });
        }
      }

      // Step 5: Calculate confidence score
      final confidenceScore = (newMemberLearning['confidenceScore'] as num? ?? 0.5).toDouble() * memberWeight;

      return {
        'dimensionInsights': dimensionInsights,
        'confidenceScore': confidenceScore.clamp(0.0, 1.0),
        'memberCount': members.length,
        'weightedBy': member.role.name,
      };
    } catch (e) {
      _logger.error('Error aggregating member learning', error: e, tag: _logName);
      return {
        'dimensionInsights': <String, double>{},
        'confidenceScore': 0.5,
        'memberCount': 0,
      };
    }
  }

  /// Get business personality for matching
  /// 
  /// Uses the shared agent's personality profile for business-expert matching.
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// 
  /// **Returns:**
  /// PersonalityProfile for matching
  Future<PersonalityProfile> getBusinessPersonalityForMatching(String businessId) async {
    return await getSharedAgentProfile(businessId);
  }

  /// Reset shared agent (for testing/debugging)
  /// 
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// 
  /// **Returns:**
  /// New agent ID
  Future<String> resetSharedAgent(String businessId) async {
    try {
      _logger.warn('Resetting shared agent for business: $businessId', tag: _logName);

      // Create new agent ID
      final newAgentId = _uuid.v4();

      // Re-initialize personality
      await _personalityLearning.initializePersonality('business_$businessId');

      // Update business account
      // Note: Would need to update BusinessAccountService

      _logger.info('Reset shared agent: $newAgentId', tag: _logName);
      return newAgentId;
    } catch (e) {
      _logger.error('Error resetting shared agent', error: e, tag: _logName);
      rethrow;
    }
  }
}

