import 'package:equatable/equatable.dart';
import 'package:avrai/core/models/business/business_expert_preferences.dart';

/// Business Patron Preferences Model
/// Defines preferences for the types of patrons/customers a business wants to attract
/// Used by the central AI in the AI2AI system to recommend businesses to appropriate users
class BusinessPatronPreferences extends Equatable {
  // Demographics Preferences
  final AgeRange? preferredAgeRange;
  final List<String>? preferredLanguages;
  final List<String>? preferredLocations; // Where patrons should be from
  
  // Interest & Lifestyle Preferences
  final List<String>? preferredInterests; // e.g., ["Food", "Art", "Music", "Outdoor"]
  final List<String>? preferredLifestyleTraits; // e.g., ["Health-conscious", "Eco-friendly", "Social"]
  final List<String>? preferredActivities; // e.g., ["Dining", "Socializing", "Working"]
  
  // Personality & Behavior Preferences
  final List<String>? preferredPersonalityTraits; // e.g., ["Outgoing", "Quiet", "Adventurous"]
  final List<String>? preferredSocialStyles; // e.g., ["Group-oriented", "Solo", "Family-friendly"]
  final List<String>? preferredVibePreferences; // e.g., ["Casual", "Upscale", "Trendy", "Cozy"]
  
  // Spending & Engagement Preferences
  final SpendingLevel? preferredSpendingLevel; // Budget, Mid-range, Premium
  final List<String>? preferredVisitFrequency; // e.g., ["Regular", "Occasional", "One-time"]
  final bool preferLoyalCustomers;
  final bool preferNewCustomers;
  
  // Expertise & Knowledge Preferences
  final List<String>? preferredExpertiseLevels; // e.g., ["Novice", "Intermediate", "Expert"]
  final bool preferEducatedPatrons; // Patrons who appreciate quality/knowledge
  final List<String>? preferredKnowledgeAreas; // e.g., ["Coffee", "Wine", "Food"]
  
  // Community & Social Preferences
  final bool preferCommunityMembers; // Patrons active in communities
  final List<String>? preferredCommunities; // Specific communities
  final bool preferLocalPatrons;
  final bool preferTourists;
  
  // Time & Availability Preferences
  final List<String>? preferredVisitTimes; // e.g., ["Morning", "Lunch", "Evening", "Late Night"]
  final List<String>? preferredDaysOfWeek; // e.g., ["Weekdays", "Weekends"]
  
  // Special Preferences
  final bool preferAgeVerified; // For 18+ venues
  final bool preferPetOwners; // Pet-friendly businesses
  final bool preferAccessibilityNeeds; // Accessible-friendly
  final List<String>? preferredSpecialNeeds; // Specific accommodations
  
  // AI/ML Specific Preferences
  final Map<String, dynamic> aiMatchingCriteria; // Custom criteria for AI matching
  final List<String>? aiKeywords; // Keywords for AI to consider
  final String? aiMatchingPrompt; // Custom prompt describing ideal patrons
  
  // Exclusion Criteria
  final List<String>? excludedInterests;
  final List<String>? excludedPersonalityTraits;
  final List<String>? excludedLocations;
  
  const BusinessPatronPreferences({
    this.preferredAgeRange,
    this.preferredLanguages,
    this.preferredLocations,
    this.preferredInterests,
    this.preferredLifestyleTraits,
    this.preferredActivities,
    this.preferredPersonalityTraits,
    this.preferredSocialStyles,
    this.preferredVibePreferences,
    this.preferredSpendingLevel,
    this.preferredVisitFrequency,
    this.preferLoyalCustomers = false,
    this.preferNewCustomers = false,
    this.preferredExpertiseLevels,
    this.preferEducatedPatrons = false,
    this.preferredKnowledgeAreas,
    this.preferCommunityMembers = false,
    this.preferredCommunities,
    this.preferLocalPatrons = false,
    this.preferTourists = false,
    this.preferredVisitTimes,
    this.preferredDaysOfWeek,
    this.preferAgeVerified = false,
    this.preferPetOwners = false,
    this.preferAccessibilityNeeds = false,
    this.preferredSpecialNeeds,
    this.aiMatchingCriteria = const {},
    this.aiKeywords,
    this.aiMatchingPrompt,
    this.excludedInterests,
    this.excludedPersonalityTraits,
    this.excludedLocations,
  });

  factory BusinessPatronPreferences.fromJson(Map<String, dynamic> json) {
    return BusinessPatronPreferences(
      preferredAgeRange: json['preferredAgeRange'] != null
          ? AgeRange.fromJson(json['preferredAgeRange'] as Map<String, dynamic>)
          : null,
      preferredLanguages: json['preferredLanguages'] != null
          ? List<String>.from(json['preferredLanguages'])
          : null,
      preferredLocations: json['preferredLocations'] != null
          ? List<String>.from(json['preferredLocations'])
          : null,
      preferredInterests: json['preferredInterests'] != null
          ? List<String>.from(json['preferredInterests'])
          : null,
      preferredLifestyleTraits: json['preferredLifestyleTraits'] != null
          ? List<String>.from(json['preferredLifestyleTraits'])
          : null,
      preferredActivities: json['preferredActivities'] != null
          ? List<String>.from(json['preferredActivities'])
          : null,
      preferredPersonalityTraits: json['preferredPersonalityTraits'] != null
          ? List<String>.from(json['preferredPersonalityTraits'])
          : null,
      preferredSocialStyles: json['preferredSocialStyles'] != null
          ? List<String>.from(json['preferredSocialStyles'])
          : null,
      preferredVibePreferences: json['preferredVibePreferences'] != null
          ? List<String>.from(json['preferredVibePreferences'])
          : null,
      preferredSpendingLevel: json['preferredSpendingLevel'] != null
          ? SpendingLevelExtension.fromString(json['preferredSpendingLevel'] as String)
          : null,
      preferredVisitFrequency: json['preferredVisitFrequency'] != null
          ? List<String>.from(json['preferredVisitFrequency'])
          : null,
      preferLoyalCustomers: json['preferLoyalCustomers'] as bool? ?? false,
      preferNewCustomers: json['preferNewCustomers'] as bool? ?? false,
      preferredExpertiseLevels: json['preferredExpertiseLevels'] != null
          ? List<String>.from(json['preferredExpertiseLevels'])
          : null,
      preferEducatedPatrons: json['preferEducatedPatrons'] as bool? ?? false,
      preferredKnowledgeAreas: json['preferredKnowledgeAreas'] != null
          ? List<String>.from(json['preferredKnowledgeAreas'])
          : null,
      preferCommunityMembers: json['preferCommunityMembers'] as bool? ?? false,
      preferredCommunities: json['preferredCommunities'] != null
          ? List<String>.from(json['preferredCommunities'])
          : null,
      preferLocalPatrons: json['preferLocalPatrons'] as bool? ?? false,
      preferTourists: json['preferTourists'] as bool? ?? false,
      preferredVisitTimes: json['preferredVisitTimes'] != null
          ? List<String>.from(json['preferredVisitTimes'])
          : null,
      preferredDaysOfWeek: json['preferredDaysOfWeek'] != null
          ? List<String>.from(json['preferredDaysOfWeek'])
          : null,
      preferAgeVerified: json['preferAgeVerified'] as bool? ?? false,
      preferPetOwners: json['preferPetOwners'] as bool? ?? false,
      preferAccessibilityNeeds: json['preferAccessibilityNeeds'] as bool? ?? false,
      preferredSpecialNeeds: json['preferredSpecialNeeds'] != null
          ? List<String>.from(json['preferredSpecialNeeds'])
          : null,
      aiMatchingCriteria: Map<String, dynamic>.from(json['aiMatchingCriteria'] ?? {}),
      aiKeywords: json['aiKeywords'] != null
          ? List<String>.from(json['aiKeywords'])
          : null,
      aiMatchingPrompt: json['aiMatchingPrompt'] as String?,
      excludedInterests: json['excludedInterests'] != null
          ? List<String>.from(json['excludedInterests'])
          : null,
      excludedPersonalityTraits: json['excludedPersonalityTraits'] != null
          ? List<String>.from(json['excludedPersonalityTraits'])
          : null,
      excludedLocations: json['excludedLocations'] != null
          ? List<String>.from(json['excludedLocations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredAgeRange': preferredAgeRange?.toJson(),
      'preferredLanguages': preferredLanguages,
      'preferredLocations': preferredLocations,
      'preferredInterests': preferredInterests,
      'preferredLifestyleTraits': preferredLifestyleTraits,
      'preferredActivities': preferredActivities,
      'preferredPersonalityTraits': preferredPersonalityTraits,
      'preferredSocialStyles': preferredSocialStyles,
      'preferredVibePreferences': preferredVibePreferences,
      'preferredSpendingLevel': preferredSpendingLevel?.name,
      'preferredVisitFrequency': preferredVisitFrequency,
      'preferLoyalCustomers': preferLoyalCustomers,
      'preferNewCustomers': preferNewCustomers,
      'preferredExpertiseLevels': preferredExpertiseLevels,
      'preferEducatedPatrons': preferEducatedPatrons,
      'preferredKnowledgeAreas': preferredKnowledgeAreas,
      'preferCommunityMembers': preferCommunityMembers,
      'preferredCommunities': preferredCommunities,
      'preferLocalPatrons': preferLocalPatrons,
      'preferTourists': preferTourists,
      'preferredVisitTimes': preferredVisitTimes,
      'preferredDaysOfWeek': preferredDaysOfWeek,
      'preferAgeVerified': preferAgeVerified,
      'preferPetOwners': preferPetOwners,
      'preferAccessibilityNeeds': preferAccessibilityNeeds,
      'preferredSpecialNeeds': preferredSpecialNeeds,
      'aiMatchingCriteria': aiMatchingCriteria,
      'aiKeywords': aiKeywords,
      'aiMatchingPrompt': aiMatchingPrompt,
      'excludedInterests': excludedInterests,
      'excludedPersonalityTraits': excludedPersonalityTraits,
      'excludedLocations': excludedLocations,
    };
  }

  BusinessPatronPreferences copyWith({
    AgeRange? preferredAgeRange,
    List<String>? preferredLanguages,
    List<String>? preferredLocations,
    List<String>? preferredInterests,
    List<String>? preferredLifestyleTraits,
    List<String>? preferredActivities,
    List<String>? preferredPersonalityTraits,
    List<String>? preferredSocialStyles,
    List<String>? preferredVibePreferences,
    SpendingLevel? preferredSpendingLevel,
    List<String>? preferredVisitFrequency,
    bool? preferLoyalCustomers,
    bool? preferNewCustomers,
    List<String>? preferredExpertiseLevels,
    bool? preferEducatedPatrons,
    List<String>? preferredKnowledgeAreas,
    bool? preferCommunityMembers,
    List<String>? preferredCommunities,
    bool? preferLocalPatrons,
    bool? preferTourists,
    List<String>? preferredVisitTimes,
    List<String>? preferredDaysOfWeek,
    bool? preferAgeVerified,
    bool? preferPetOwners,
    bool? preferAccessibilityNeeds,
    List<String>? preferredSpecialNeeds,
    Map<String, dynamic>? aiMatchingCriteria,
    List<String>? aiKeywords,
    String? aiMatchingPrompt,
    List<String>? excludedInterests,
    List<String>? excludedPersonalityTraits,
    List<String>? excludedLocations,
  }) {
    return BusinessPatronPreferences(
      preferredAgeRange: preferredAgeRange ?? this.preferredAgeRange,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      preferredInterests: preferredInterests ?? this.preferredInterests,
      preferredLifestyleTraits: preferredLifestyleTraits ?? this.preferredLifestyleTraits,
      preferredActivities: preferredActivities ?? this.preferredActivities,
      preferredPersonalityTraits: preferredPersonalityTraits ?? this.preferredPersonalityTraits,
      preferredSocialStyles: preferredSocialStyles ?? this.preferredSocialStyles,
      preferredVibePreferences: preferredVibePreferences ?? this.preferredVibePreferences,
      preferredSpendingLevel: preferredSpendingLevel ?? this.preferredSpendingLevel,
      preferredVisitFrequency: preferredVisitFrequency ?? this.preferredVisitFrequency,
      preferLoyalCustomers: preferLoyalCustomers ?? this.preferLoyalCustomers,
      preferNewCustomers: preferNewCustomers ?? this.preferNewCustomers,
      preferredExpertiseLevels: preferredExpertiseLevels ?? this.preferredExpertiseLevels,
      preferEducatedPatrons: preferEducatedPatrons ?? this.preferEducatedPatrons,
      preferredKnowledgeAreas: preferredKnowledgeAreas ?? this.preferredKnowledgeAreas,
      preferCommunityMembers: preferCommunityMembers ?? this.preferCommunityMembers,
      preferredCommunities: preferredCommunities ?? this.preferredCommunities,
      preferLocalPatrons: preferLocalPatrons ?? this.preferLocalPatrons,
      preferTourists: preferTourists ?? this.preferTourists,
      preferredVisitTimes: preferredVisitTimes ?? this.preferredVisitTimes,
      preferredDaysOfWeek: preferredDaysOfWeek ?? this.preferredDaysOfWeek,
      preferAgeVerified: preferAgeVerified ?? this.preferAgeVerified,
      preferPetOwners: preferPetOwners ?? this.preferPetOwners,
      preferAccessibilityNeeds: preferAccessibilityNeeds ?? this.preferAccessibilityNeeds,
      preferredSpecialNeeds: preferredSpecialNeeds ?? this.preferredSpecialNeeds,
      aiMatchingCriteria: aiMatchingCriteria ?? this.aiMatchingCriteria,
      aiKeywords: aiKeywords ?? this.aiKeywords,
      aiMatchingPrompt: aiMatchingPrompt ?? this.aiMatchingPrompt,
      excludedInterests: excludedInterests ?? this.excludedInterests,
      excludedPersonalityTraits: excludedPersonalityTraits ?? this.excludedPersonalityTraits,
      excludedLocations: excludedLocations ?? this.excludedLocations,
    );
  }

  /// Check if preferences are empty/minimal
  bool get isEmpty {
    return preferredAgeRange == null &&
        (preferredLanguages?.isEmpty ?? true) &&
        (preferredLocations?.isEmpty ?? true) &&
        (preferredInterests?.isEmpty ?? true) &&
        preferredSpendingLevel == null;
  }

  /// Get a summary description for display
  String getSummary() {
    final parts = <String>[];
    
    if (preferredAgeRange != null) {
      parts.add('Age: ${preferredAgeRange!.displayText}');
    }
    if (preferredInterests?.isNotEmpty == true) {
      parts.add('Interests: ${preferredInterests!.take(3).join(', ')}');
    }
    if (preferredSpendingLevel != null) {
      parts.add('Spending: ${preferredSpendingLevel!.displayName}');
    }
    if (preferredVibePreferences?.isNotEmpty == true) {
      parts.add('Vibe: ${preferredVibePreferences!.take(2).join(', ')}');
    }
    
    return parts.isEmpty ? 'No patron preferences set' : parts.join(' • ');
  }

  @override
  List<Object?> get props => [
        preferredAgeRange,
        preferredLanguages,
        preferredLocations,
        preferredInterests,
        preferredLifestyleTraits,
        preferredActivities,
        preferredPersonalityTraits,
        preferredSocialStyles,
        preferredVibePreferences,
        preferredSpendingLevel,
        preferredVisitFrequency,
        preferLoyalCustomers,
        preferNewCustomers,
        preferredExpertiseLevels,
        preferEducatedPatrons,
        preferredKnowledgeAreas,
        preferCommunityMembers,
        preferredCommunities,
        preferLocalPatrons,
        preferTourists,
        preferredVisitTimes,
        preferredDaysOfWeek,
        preferAgeVerified,
        preferPetOwners,
        preferAccessibilityNeeds,
        preferredSpecialNeeds,
        aiMatchingCriteria,
        aiKeywords,
        aiMatchingPrompt,
        excludedInterests,
        excludedPersonalityTraits,
        excludedLocations,
      ];
}

/// Spending Level Enum
enum SpendingLevel {
  budget,      // Budget-conscious
  midRange,    // Mid-range spending
  premium,     // Premium/high-end
  any,         // Any spending level
}

extension SpendingLevelExtension on SpendingLevel {
  String get displayName {
    switch (this) {
      case SpendingLevel.budget:
        return 'Budget';
      case SpendingLevel.midRange:
        return 'Mid-Range';
      case SpendingLevel.premium:
        return 'Premium';
      case SpendingLevel.any:
        return 'Any';
    }
  }

  static SpendingLevel? fromString(String? value) {
    if (value == null) return null;
    try {
      final normalized = value.toLowerCase().replaceAll('_', '').replaceAll('-', '');
      return SpendingLevel.values.firstWhere(
        (level) => level.name.toLowerCase() == normalized,
      );
    } catch (e) {
      return null;
    }
  }
}

