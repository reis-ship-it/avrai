import 'dart:developer' as developer;
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// OnboardingRecommendationService
/// 
/// Recommends lists and accounts to follow based on onboarding data
/// and personality dimensions.
/// 
/// Uses agentId internally for privacy protection per Master Plan Phase 7.3.
/// Accepts userId in public API but converts to agentId internally.
class OnboardingRecommendationService {
  static const String _logName = 'OnboardingRecommendationService';
  
  final AgentIdService _agentIdService;
  
  OnboardingRecommendationService({
    AgentIdService? agentIdService,
  }) : _agentIdService = agentIdService ?? di.sl<AgentIdService>();
  
  /// Get recommended lists to follow based on onboarding
  /// 
  /// [userId] - Authenticated user ID from UI layer
  /// [onboardingData] - User's onboarding data
  /// [personalityDimensions] - User's personality dimensions
  /// [maxRecommendations] - Maximum number of recommendations
  /// 
  /// Returns list of recommended lists
  Future<List<ListRecommendation>> getRecommendedLists({
    required String userId,
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    try {
      developer.log(
        'Getting recommended lists for user: $userId',
        name: _logName,
      );
      
      // Convert userId → agentId for privacy-protected operations
      // agentId reserved for future privacy-protected matching operations
      // ignore: unused_local_variable
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      final recommendations = <ListRecommendation>[];
      
      // Find lists by preferences
      final prefLists = _findListsByPreferences(
        onboardingData,
        personalityDimensions,
        maxRecommendations: maxRecommendations ~/ 3,
      );
      recommendations.addAll(prefLists);
      
      // Find lists by homebase
      if (recommendations.length < maxRecommendations) {
        final homebaseLists = _findListsByHomebase(
          onboardingData,
          personalityDimensions,
          maxRecommendations: maxRecommendations ~/ 3,
        );
        recommendations.addAll(homebaseLists);
      }
      
      // Find lists by archetype
      if (recommendations.length < maxRecommendations) {
        final archetypeLists = _findListsByArchetype(
          personalityDimensions,
          maxRecommendations: maxRecommendations - recommendations.length,
        );
        recommendations.addAll(archetypeLists);
      }
      
      // Sort by compatibility score
      recommendations.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      
      developer.log(
        '✅ Found ${recommendations.length} list recommendations',
        name: _logName,
      );
      
      return recommendations.take(maxRecommendations).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting recommended lists: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Get recommended accounts to follow based on onboarding
  /// 
  /// [userId] - Authenticated user ID from UI layer
  /// [onboardingData] - User's onboarding data
  /// [personalityDimensions] - User's personality dimensions
  /// [maxRecommendations] - Maximum number of recommendations
  /// 
  /// Returns list of recommended accounts
  Future<List<AccountRecommendation>> getRecommendedAccounts({
    required String userId,
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    try {
      developer.log(
        'Getting recommended accounts for user: $userId',
        name: _logName,
      );
      
      // Convert userId → agentId for privacy-protected operations
      // agentId reserved for future privacy-protected matching operations
      // ignore: unused_local_variable
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      final recommendations = <AccountRecommendation>[];
      
      // Find accounts by interests
      final interestAccounts = _findAccountsByInterests(
        onboardingData,
        personalityDimensions,
        maxRecommendations: maxRecommendations ~/ 2,
      );
      recommendations.addAll(interestAccounts);
      
      // Find accounts by location
      if (recommendations.length < maxRecommendations) {
        final locationAccounts = _findAccountsByLocation(
          onboardingData,
          personalityDimensions,
          maxRecommendations: maxRecommendations - recommendations.length,
        );
        recommendations.addAll(locationAccounts);
      }
      
      // Sort by compatibility score
      recommendations.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      
      developer.log(
        '✅ Found ${recommendations.length} account recommendations',
        name: _logName,
      );
      
      return recommendations.take(maxRecommendations).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting recommended accounts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Calculate compatibility score between user and list/account
  /// 
  /// [userDimensions] - User's personality dimensions
  /// [listDimensions] - List/account's personality dimensions
  /// 
  /// Returns compatibility score (0.0-1.0)
  double calculateCompatibility({
    required Map<String, double> userDimensions,
    required Map<String, double> listDimensions,
  }) {
    if (userDimensions.isEmpty || listDimensions.isEmpty) {
      return 0.0;
    }
    
    // Calculate cosine similarity or simple average difference
    double totalSimilarity = 0.0;
    int matchingDimensions = 0;
    
    for (final dimension in userDimensions.keys) {
      if (listDimensions.containsKey(dimension)) {
        final userValue = userDimensions[dimension] ?? 0.0;
        final listValue = listDimensions[dimension] ?? 0.0;
        
        // Calculate similarity (1.0 - absolute difference)
        final similarity = 1.0 - (userValue - listValue).abs();
        totalSimilarity += similarity;
        matchingDimensions++;
      }
    }
    
    if (matchingDimensions == 0) {
      return 0.0;
    }
    
    return (totalSimilarity / matchingDimensions).clamp(0.0, 1.0);
  }
  
  /// Find lists by preferences
  List<ListRecommendation> _findListsByPreferences(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    int maxRecommendations = 5,
  }) {
    // TODO: Implement actual list search/matching
    // For now, return empty list
    // This can be implemented when list data source is available
    return [];
  }
  
  /// Find lists by homebase
  List<ListRecommendation> _findListsByHomebase(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    int maxRecommendations = 5,
  }) {
    // TODO: Implement actual list search by location
    // For now, return empty list
    return [];
  }
  
  /// Find lists by archetype
  List<ListRecommendation> _findListsByArchetype(
    Map<String, double> personalityDimensions, {
    int maxRecommendations = 5,
  }) {
    // TODO: Implement actual list search by archetype
    // For now, return empty list
    return [];
  }
  
  /// Find accounts by interests
  List<AccountRecommendation> _findAccountsByInterests(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    int maxRecommendations = 5,
  }) {
    // TODO: Implement actual account search by interests
    // For now, return empty list
    return [];
  }
  
  /// Find accounts by location
  List<AccountRecommendation> _findAccountsByLocation(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    int maxRecommendations = 5,
  }) {
    // TODO: Implement actual account search by location
    // For now, return empty list
    return [];
  }
}

/// List Recommendation
/// 
/// Represents a recommended list to follow
class ListRecommendation {
  final String listId;
  final String listName;
  final String curatorName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this list matches
  final Map<String, dynamic> metadata;
  
  ListRecommendation({
    required this.listId,
    required this.listName,
    required this.curatorName,
    required this.description,
    required this.compatibilityScore,
    required this.matchingReasons,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'listId': listId,
      'listName': listName,
      'curatorName': curatorName,
      'description': description,
      'compatibilityScore': compatibilityScore,
      'matchingReasons': matchingReasons,
      'metadata': metadata,
    };
  }
}

/// Account Recommendation
/// 
/// Represents a recommended account to follow
class AccountRecommendation {
  final String accountId;
  final String accountName;
  final String displayName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this account matches
  final Map<String, dynamic> metadata;
  
  AccountRecommendation({
    required this.accountId,
    required this.accountName,
    required this.displayName,
    required this.description,
    required this.compatibilityScore,
    required this.matchingReasons,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'displayName': displayName,
      'description': description,
      'compatibilityScore': compatibilityScore,
      'matchingReasons': matchingReasons,
      'metadata': metadata,
    };
  }
}

