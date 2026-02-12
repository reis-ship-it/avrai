import 'dart:developer' as developer;
import 'package:avrai/core/models/spots/spot.dart' as app_spot;
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/behavior/behavior_assessment_service.dart';
import 'package:avrai_core/models/spot.dart' as spots_core;

/// Age-based compatibility filter for AI2AI system
/// Ensures age-appropriate connections and recommendations
/// OUR_GUTS.md: "Age should be considered regardless, but actions can override"
class AgeCompatibilityFilter {
  static const String _logName = 'AgeCompatibilityFilter';
  
  // Age restriction thresholds
  static const int childMaxAge = 12;      // Under 13
  static const int teenMaxAge = 17;       // 13-17
  static const int youngAdultMaxAge = 20; // 18-20
  static const int adultMinAge = 21;      // 21+
  
  // Age restriction levels for spots
  static const int spotRestriction18 = 18;
  static const int spotRestriction21 = 21;
  
  /// Calculate age compatibility multiplier for AI2AI connections
  /// IMPORTANT: All age groups CAN connect (for positive influence)
  /// Returns 0.5 (neutral) to 1.0 (fully compatible)
  /// Age does NOT block connections - it only affects learning selectivity
  double calculateAgeCompatibility(
    UnifiedUser user1,
    UnifiedUser user2, {
    bool allowOverride = false, // Set to true if actions indicate compatibility
  }) {
    final age1 = user1.age;
    final age2 = user2.age;
    
    // If age is unknown, return neutral compatibility (0.5)
    // This allows connections but doesn't boost them
    if (age1 == null || age2 == null) {
      developer.log('Age unknown for one or both users, returning neutral compatibility', name: _logName);
      return 0.5;
    }
    
    // If override is allowed (e.g., parent with child), return full compatibility
    if (allowOverride) {
      developer.log('Age override allowed (e.g., parent-child scenario), returning full compatibility', name: _logName);
      return 1.0;
    }
    
    // Calculate age compatibility based on age groups
    final group1 = user1.ageGroup;
    final group2 = user2.ageGroup;
    
    if (group1 == null || group2 == null) {
      return 0.5; // Neutral if age group can't be determined
    }
    
    // ALL AGE GROUPS CAN CONNECT - no hard blocks
    // Age compatibility affects connection strength, not blocking
    
    // Calculate compatibility based on age difference
    final ageDifference = (age1 - age2).abs();
    
    // Same age group: high compatibility
    if (group1 == group2) {
      return 1.0;
    }
    
    // Cross-age connections: moderate to high compatibility
    // Kids/teens can connect with adults for positive influence
    // Compatibility reduces slightly with age difference, but never blocks
    final compatibility = 1.0 - (ageDifference / 30.0).clamp(0.0, 0.3);
    developer.log('Cross-age connection: $group1 and $group2, compatibility: $compatibility', name: _logName);
    return compatibility;
  }
  
  
  /// Check if a spot is age-appropriate for a user
  /// Returns true if user can access the spot, false if blocked
  bool isSpotAgeAppropriate(spots_core.Spot spot, UnifiedUser user) {
    final userAge = user.age;
    
    // If age is unknown, allow access (but log warning)
    if (userAge == null) {
      developer.log('User age unknown, allowing spot access (may need age verification)', name: _logName);
      return true;
    }
    
    // Check spot age restrictions
    if (spot.isAgeRestricted) {
      // Check if spot requires 21+
      if (_requiresAge21(spot)) {
        if (userAge < spotRestriction21) {
          developer.log('Spot requires 21+, user is $userAge, blocking access', name: _logName);
          return false;
        }
      }
      // Check if spot requires 18+
      else if (_requiresAge18(spot)) {
        if (userAge < spotRestriction18) {
          developer.log('Spot requires 18+, user is $userAge, blocking access', name: _logName);
          return false;
        }
      }
    }
    
    // Check if spot is child-appropriate (children shouldn't get adult spots)
    if (userAge <= childMaxAge) {
      if (_isAdultOnlySpot(spot)) {
        developer.log('User is child ($userAge), spot is adult-only, blocking access', name: _logName);
        return false;
      }
    }
    
    return true;
  }
  
  /// Check if spot requires age 21+
  bool _requiresAge21(spots_core.Spot spot) {
    // Check spot metadata or category for 21+ requirement
    final metadata = spot.metadata;
    if (metadata.containsKey('ageRestriction')) {
      final restriction = metadata['ageRestriction'];
      if (restriction is int && restriction >= spotRestriction21) {
        return true;
      }
      if (restriction is String && restriction.contains('21')) {
        return true;
      }
    }
    
    // Check category for adult-only categories
    final category = spot.category.toLowerCase();
    final adultCategories = ['bar', 'nightclub', 'lounge', 'brewery', 'wine', 'casino'];
    return adultCategories.any((adultCat) => category.contains(adultCat));
  }
  
  /// Check if spot requires age 18+
  bool _requiresAge18(spots_core.Spot spot) {
    // Check spot metadata
    final metadata = spot.metadata;
    if (metadata.containsKey('ageRestriction')) {
      final restriction = metadata['ageRestriction'];
      if (restriction is int && restriction >= spotRestriction18 && restriction < spotRestriction21) {
        return true;
      }
      if (restriction is String && restriction.contains('18')) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if spot is adult-only (not appropriate for children)
  bool _isAdultOnlySpot(spots_core.Spot spot) {
    // Check if it requires 18+ or 21+
    if (_requiresAge21(spot) || _requiresAge18(spot)) {
      return true;
    }
    
    // Check category for adult-oriented categories
    final category = spot.category.toLowerCase();
    final adultKeywords = ['bar', 'pub', 'nightclub', 'lounge', 'wine', 'cocktail', 'brewery', 'alcohol', 'drinking', 'nightlife', 'adult'];
    return adultKeywords.any((keyword) => category.contains(keyword) || spot.name.toLowerCase().contains(keyword));
  }
  
  /// Apply age compatibility multiplier to existing compatibility score
  /// IMPORTANT: Age does NOT block connections - all age groups can connect
  /// Age compatibility affects connection strength, not blocking
  /// This integrates age into the identity matrix compatibility calculation
  double applyAgeMultiplier(
    double baseCompatibility,
    UnifiedUser user1,
    UnifiedUser user2, {
    bool allowOverride = false,
  }) {
    final ageCompatibility = calculateAgeCompatibility(user1, user2, allowOverride: allowOverride);
    
    // Age compatibility never blocks (minimum 0.5), so we blend it with base compatibility
    // Formula: weighted average (age affects but doesn't dominate)
    final adjustedCompatibility = (baseCompatibility * 0.7) + (ageCompatibility * 0.3);
    
    developer.log(
      'Age-adjusted compatibility: base=$baseCompatibility, age=$ageCompatibility, final=$adjustedCompatibility',
      name: _logName,
    );
    
    return adjustedCompatibility.clamp(0.0, 1.0);
  }
  
  /// Determine if a behavior/dimension can be learned by a younger user from an older user
  /// DEPRECATED: Use BehaviorAssessmentService.calculateLearningFilter() instead
  /// This method is kept for backward compatibility but uses the new multidimensional assessment
  bool canLearnBehavior(
    UnifiedUser youngerUser,
    UnifiedUser olderUser,
    String behaviorType,
    Map<String, dynamic>? behaviorContext,
  ) {
    // Use the new multidimensional assessment service
    final assessmentService = BehaviorAssessmentService();
    final learningFilter = assessmentService.calculateLearningFilter(
      youngerUser,
      olderUser,
      behaviorType,
      behaviorContext,
    );
    
    // Threshold-based (not binary) - allow learning if filter > 0.3
    // This allows some learning even for moderate behaviors
    return learningFilter > 0.3;
  }
  
  /// Calculate learning filter for convergence formula
  /// Returns 0.0 (block learning) to 1.0 (allow full learning)
  /// Uses multidimensional behavior assessment instead of binary classification
  double calculateLearningFilter(
    UnifiedUser learner,
    UnifiedUser influencer,
    String dimension, // Personality dimension being learned
    Object? behaviorContext, // Optional: what behavior triggered this learning (String or Map)
  ) {
    final learnerAge = learner.age;
    final influencerAge = influencer.age;
    
    // If ages unknown, allow moderate learning (default to neutral)
    if (learnerAge == null || influencerAge == null) {
      return 0.5;
    }
    
    // If learner is not younger, allow full learning
    if (learnerAge >= influencerAge) {
      return 1.0;
    }
    
    // If behavior context is provided, use multidimensional assessment
    if (behaviorContext != null) {
      final assessmentService = BehaviorAssessmentService();
      // Convert behaviorContext to Map if it's a string
      final Map<String, dynamic> contextMap;
      final String behaviorType;
      
      if (behaviorContext is String) {
        behaviorType = behaviorContext;
        contextMap = {'behaviorType': behaviorContext};
      } else if (behaviorContext is Map<String, dynamic>) {
        contextMap = behaviorContext;
        behaviorType = contextMap['behaviorType'] as String? ?? dimension;
      } else {
        // Convert to string as fallback
        behaviorType = behaviorContext.toString();
        contextMap = {'behaviorType': behaviorType};
      }
      
      return assessmentService.calculateLearningFilter(
        learner,
        influencer,
        behaviorType,
        contextMap,
      );
    }
    
    // For dimension-based learning without specific behavior context:
    // Use dimension characteristics to estimate appropriateness
    
    // Dimensions that are generally positive for cross-age learning
    final generallyPositiveDimensions = [
      'exploration_eagerness', // Exploring new places
      'community_orientation', // Community involvement
      'authenticity_preference', // Being authentic
      'curation_tendency', // Curating quality spots
      'novelty_seeking', // Seeking new experiences
    ];
    
    if (generallyPositiveDimensions.contains(dimension)) {
      return 0.9; // High learning filter (not 1.0 - still context-dependent)
    }
    
    // Social dimensions - moderate learning (context-dependent)
    final socialDimensions = [
      'social_discovery_style', // How social you are
      'trust_network_reliance', // Trust in network
    ];
    
    if (socialDimensions.contains(dimension)) {
      return 0.6; // Moderate learning filter
    }
    
    // Dimensions that might have adult-oriented aspects
    final potentiallyAdultDimensions = [
      'energy_preference', // Might include nightlife preferences
      'value_orientation', // Might include adult spending patterns
    ];
    
    if (potentiallyAdultDimensions.contains(dimension)) {
      // Age-dependent probability curve (not binary)
      if (learnerAge < 13) return 0.2; // Low for children
      if (learnerAge < 16) return 0.4; // Moderate for young teens
      if (learnerAge < 18) return 0.6; // Higher for older teens
      return 0.8; // High for adults
    }
    
    // Default: moderate learning (not permissive, not restrictive)
    return 0.5;
  }
  
  /// Check if actions indicate age override (e.g., parent with child)
  /// This allows parents to take children to child-appropriate activities
  bool shouldAllowAgeOverride(
    UnifiedUser user1,
    UnifiedUser user2,
    List<String> recentActions, // Action history that might indicate parent-child relationship
  ) {
    // Check if one user is significantly older (potential parent)
    final age1 = user1.age;
    final age2 = user2.age;
    
    if (age1 == null || age2 == null) {
      return false;
    }
    
    final ageDifference = (age1 - age2).abs();
    
    // If age difference is 18+ years, might be parent-child
    if (ageDifference >= 18) {
      // Check if actions indicate child-appropriate activities
      final childKeywords = ['children', 'kids', 'family', 'playground', 'museum', 'zoo', 'park', 'school', 'toy'];
      final hasChildActions = recentActions.any((action) =>
          childKeywords.any((keyword) => action.toLowerCase().contains(keyword)));
      
      if (hasChildActions) {
        developer.log('Age override allowed: potential parent-child relationship with child-appropriate actions', name: _logName);
        return true;
      }
    }
    
    return false;
  }
  
  /// Filter spots by age appropriateness
  List<spots_core.Spot> filterSpotsByAge(List<spots_core.Spot> spots, UnifiedUser user) {
    return spots.where((spot) => isSpotAgeAppropriate(spot, user)).toList();
  }

  /// Filter app spots (`lib/core/models/spots/spot.dart`) by age appropriateness.
  ///
  /// Note: The app Spot model does not currently expose `isAgeRestricted` directly like `spots_core.Spot`,
  /// so we infer restriction from metadata + category keywords.
  List<app_spot.Spot> filterAppSpotsByAge(List<app_spot.Spot> spots, UnifiedUser user) {
    return spots.where((spot) => _isAppSpotAgeAppropriate(spot, user)).toList();
  }

  bool _isAppSpotAgeAppropriate(app_spot.Spot spot, UnifiedUser user) {
    final userAge = user.age;

    if (userAge == null) {
      developer.log('User age unknown, allowing spot access (app spot)', name: _logName);
      return true;
    }

    final isAgeRestricted = _isAppSpotAgeRestricted(spot);

    if (isAgeRestricted) {
      if (_requiresAge21FromMetadataAndCategory(spot.metadata, spot.category)) {
        if (userAge < spotRestriction21) {
          developer.log('App spot requires 21+, user is $userAge, blocking access', name: _logName);
          return false;
        }
      } else if (_requiresAge18FromMetadata(spot.metadata)) {
        if (userAge < spotRestriction18) {
          developer.log('App spot requires 18+, user is $userAge, blocking access', name: _logName);
          return false;
        }
      }
    }

    if (userAge <= childMaxAge) {
      if (_isAdultOnlyAppSpot(spot)) {
        developer.log('User is child ($userAge), app spot is adult-only, blocking access', name: _logName);
        return false;
      }
    }

    return true;
  }

  bool _isAppSpotAgeRestricted(app_spot.Spot spot) {
    final metadata = spot.metadata;
    final restriction = metadata['ageRestriction'];
    final ageRestrictedFlag = metadata['isAgeRestricted'] ?? metadata['ageRestricted'];
    if (ageRestrictedFlag is bool && ageRestrictedFlag == true) return true;
    if (restriction != null) return true;

    // Fall back to category-based inference (bars/nightlife are typically age-gated).
    return _requiresAge21FromMetadataAndCategory(metadata, spot.category) ||
        _requiresAge18FromMetadata(metadata);
  }

  bool _requiresAge21FromMetadataAndCategory(Map<String, dynamic> metadata, String category) {
    if (metadata.containsKey('ageRestriction')) {
      final restriction = metadata['ageRestriction'];
      if (restriction is int && restriction >= spotRestriction21) return true;
      if (restriction is String && restriction.contains('21')) return true;
    }

    final lc = category.toLowerCase();
    const adultCategories = ['bar', 'nightclub', 'lounge', 'brewery', 'wine', 'casino'];
    return adultCategories.any((adultCat) => lc.contains(adultCat));
  }

  bool _requiresAge18FromMetadata(Map<String, dynamic> metadata) {
    if (metadata.containsKey('ageRestriction')) {
      final restriction = metadata['ageRestriction'];
      if (restriction is int && restriction >= spotRestriction18 && restriction < spotRestriction21) {
        return true;
      }
      if (restriction is String && restriction.contains('18')) {
        return true;
      }
    }
    return false;
  }

  bool _isAdultOnlyAppSpot(app_spot.Spot spot) {
    if (_requiresAge21FromMetadataAndCategory(spot.metadata, spot.category) ||
        _requiresAge18FromMetadata(spot.metadata)) {
      return true;
    }

    final category = spot.category.toLowerCase();
    final name = spot.name.toLowerCase();
    const adultKeywords = [
      'bar',
      'pub',
      'nightclub',
      'lounge',
      'wine',
      'cocktail',
      'brewery',
      'alcohol',
      'drinking',
      'nightlife',
      'adult',
    ];
    return adultKeywords.any((k) => category.contains(k) || name.contains(k));
  }
}

