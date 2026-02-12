import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:avrai/core/constants/vibe_constants.dart';

/// OUR_GUTS.md: "Anonymous vibe signatures that preserve privacy while enabling AI2AI connections"
/// Represents an anonymized user vibe that can be safely shared for AI2AI personality matching
class UserVibe {
  final String hashedSignature;
  final Map<String, double> anonymizedDimensions;
  final double overallEnergy;
  final double socialPreference;
  final double explorationTendency;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double privacyLevel;
  final String temporalContext;
  
  UserVibe({
    required this.hashedSignature,
    required this.anonymizedDimensions,
    required this.overallEnergy,
    required this.socialPreference,
    required this.explorationTendency,
    required this.createdAt,
    required this.expiresAt,
    required this.privacyLevel,
    required this.temporalContext,
  });
  
  /// Create anonymized vibe signature from personality profile
  factory UserVibe.fromPersonalityProfile(
    String userId,
    Map<String, double> personalityDimensions,
    {String? contextualSalt}
  ) {
    final random = Random.secure();
    final now = DateTime.now();
    
    // Generate contextual salt if not provided
    final salt = contextualSalt ?? _generateSalt();
    
    // Create anonymized dimensions with differential privacy noise
    final anonymizedDims = <String, double>{};
    for (final dimension in VibeConstants.coreDimensions) {
      final originalValue = personalityDimensions[dimension] ?? 0.5;
      
      // Add differential privacy noise
      final noise = (random.nextDouble() - 0.5) * VibeConstants.privacyNoiseLevel;
      final noisyValue = (originalValue + noise).clamp(0.0, 1.0);
      
      anonymizedDims[dimension] = noisyValue;
    }
    
    // Calculate aggregated vibe metrics (privacy-preserving)
    final overallEnergy = _calculateOverallEnergy(anonymizedDims);
    final socialPreference = _calculateSocialPreference(anonymizedDims);
    final explorationTendency = _calculateExplorationTendency(anonymizedDims);
    
    // Create privacy-preserving hash signature
    final signature = _createHashedSignature(
      userId,
      anonymizedDims,
      salt,
      now,
    );
    
    return UserVibe(
      hashedSignature: signature,
      anonymizedDimensions: anonymizedDims,
      overallEnergy: overallEnergy,
      socialPreference: socialPreference,
      explorationTendency: explorationTendency,
      createdAt: now,
      expiresAt: now.add(const Duration(days: VibeConstants.vibeSignatureExpiryDays)),
      privacyLevel: VibeConstants.minAnonymizationLevel,
      temporalContext: _getTemporalContext(now),
    );
  }
  
  /// Calculate vibe compatibility with another user's vibe (0.0 to 1.0)
  double calculateVibeCompatibility(UserVibe other) {
    if (isExpired || other.isExpired) return 0.0;
    
    double totalSimilarity = 0.0;
    int validDimensions = 0;
    
    // Compare anonymized dimensions
    for (final dimension in VibeConstants.coreDimensions) {
      final myValue = anonymizedDimensions[dimension];
      final otherValue = other.anonymizedDimensions[dimension];
      
      if (myValue != null && otherValue != null) {
        final similarity = 1.0 - (myValue - otherValue).abs();
        totalSimilarity += similarity;
        validDimensions++;
      }
    }
    
    if (validDimensions == 0) return 0.0;
    
    final dimensionCompatibility = totalSimilarity / validDimensions;
    
    // Factor in overall energy and exploration compatibility
    final energyCompatibility = 1.0 - (overallEnergy - other.overallEnergy).abs();
    final explorationCompatibility = 1.0 - (explorationTendency - other.explorationTendency).abs();
    
    // Weighted average of different compatibility aspects
    final overallCompatibility = (
      dimensionCompatibility * 0.6 +
      energyCompatibility * 0.2 +
      explorationCompatibility * 0.2
    ).clamp(0.0, 1.0);
    
    return overallCompatibility;
  }
  
  /// Calculate AI pleasure potential for interacting with this vibe
  double calculateAIPleasurePotential(UserVibe other) {
    final compatibility = calculateVibeCompatibility(other);
    
    // High compatibility creates high AI pleasure
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return 0.9;
    }
    
    // Medium compatibility creates moderate pleasure
    if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return 0.7;
    }
    
    // Low compatibility can still create some learning pleasure
    if (compatibility >= VibeConstants.lowCompatibilityThreshold) {
      return 0.4;
    }
    
    // Even incompatible vibes provide minimal learning pleasure
    return 0.2;
  }
  
  /// Check if this vibe signature has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Get vibe summary without exposing personal information
  Map<String, dynamic> getAnonymizedSummary() {
    return {
      'signature_hash': hashedSignature.substring(0, 8), // Truncated for display
      'overall_energy': (overallEnergy * 100).round(),
      'social_preference': (socialPreference * 100).round(),
      'exploration_tendency': (explorationTendency * 100).round(),
      'privacy_level': (privacyLevel * 100).round(),
      'temporal_context': temporalContext,
      'expires_in_hours': expiresAt.difference(DateTime.now()).inHours,
      'is_expired': isExpired,
    };
  }
  
  /// Get vibe archetype based on dominant characteristics
  String getVibeArchetype() {
    if (explorationTendency >= 0.8 && overallEnergy >= 0.7) {
      return 'adventurous_explorer';
    }
    
    if (socialPreference >= 0.8 && overallEnergy >= 0.6) {
      return 'social_connector';
    }
    
    if (explorationTendency <= 0.3 && socialPreference >= 0.7) {
      return 'community_curator';
    }
    
    if (explorationTendency >= 0.7 && socialPreference <= 0.4) {
      return 'authentic_seeker';
    }
    
    if (overallEnergy >= 0.8) {
      return 'spontaneous_wanderer';
    }
    
    return 'balanced_explorer';
  }
  
  /// Create a refreshed vibe signature (with new temporal context and noise)
  UserVibe refresh(String userId, Map<String, double> currentPersonality) {
    return UserVibe.fromPersonalityProfile(userId, currentPersonality);
  }
  
  /// Verify vibe signature integrity (without revealing personal data)
  bool verifyIntegrity() {
    // Check that dimensions are within valid ranges
    for (final value in anonymizedDimensions.values) {
      if (value < 0.0 || value > 1.0) return false;
    }
    
    // Check that aggregated metrics are consistent
    final recalculatedEnergy = _calculateOverallEnergy(anonymizedDimensions);
    final recalculatedSocial = _calculateSocialPreference(anonymizedDimensions);
    final recalculatedExploration = _calculateExplorationTendency(anonymizedDimensions);
    
    return (overallEnergy - recalculatedEnergy).abs() < 0.1 &&
           (socialPreference - recalculatedSocial).abs() < 0.1 &&
           (explorationTendency - recalculatedExploration).abs() < 0.1;
  }
  
  // Private helper methods
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(
      VibeConstants.personalityHashSaltLength,
      (_) => random.nextInt(256),
    );
    return base64Encode(saltBytes);
  }
  
  static String _createHashedSignature(
    String userId,
    Map<String, double> dimensions,
    String salt,
    DateTime timestamp,
  ) {
    // Create deterministic but anonymized signature
    final dimensionString = dimensions.entries
        .map((e) => '${e.key}:${e.value.toStringAsFixed(3)}')
        .join('|');
    
    final input = '$userId:$dimensionString:$salt:${timestamp.millisecondsSinceEpoch}';
    
    // Apply multiple hash iterations for security
    var currentHash = input;
    for (int i = 0; i < VibeConstants.vibeHashIterations; i++) {
      final bytes = utf8.encode(currentHash);
      final digest = sha256.convert(bytes);
      currentHash = digest.toString();
    }
    
    return currentHash;
  }
  
  static double _calculateOverallEnergy(Map<String, double> dims) {
    final explorationEagerness = dims['exploration_eagerness'] ?? 0.5;
    final temporalFlexibility = dims['temporal_flexibility'] ?? 0.5;
    final locationAdventurousness = dims['location_adventurousness'] ?? 0.5;
    
    return (explorationEagerness + temporalFlexibility + locationAdventurousness) / 3.0;
  }
  
  static double _calculateSocialPreference(Map<String, double> dims) {
    final communityOrientation = dims['community_orientation'] ?? 0.5;
    final socialDiscoveryStyle = dims['social_discovery_style'] ?? 0.5;
    final trustNetworkReliance = dims['trust_network_reliance'] ?? 0.5;
    
    return (communityOrientation + socialDiscoveryStyle + trustNetworkReliance) / 3.0;
  }
  
  static double _calculateExplorationTendency(Map<String, double> dims) {
    final explorationEagerness = dims['exploration_eagerness'] ?? 0.5;
    final locationAdventurousness = dims['location_adventurousness'] ?? 0.5;
    final authenticityPreference = dims['authenticity_preference'] ?? 0.5;
    
    return (explorationEagerness + locationAdventurousness + (1.0 - authenticityPreference)) / 3.0;
  }
  
  static String _getTemporalContext(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
  
  /// Convert to JSON for AI2AI communication (no personal data)
  Map<String, dynamic> toJson() {
    return {
      'hashed_signature': hashedSignature,
      'anonymized_dimensions': anonymizedDimensions,
      'overall_energy': overallEnergy,
      'social_preference': socialPreference,
      'exploration_tendency': explorationTendency,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'privacy_level': privacyLevel,
      'temporal_context': temporalContext,
    };
  }
  
  /// Create from JSON (for AI2AI communication)
  factory UserVibe.fromJson(Map<String, dynamic> json) {
    return UserVibe(
      hashedSignature: json['hashed_signature'] as String,
      anonymizedDimensions: Map<String, double>.from(json['anonymized_dimensions']),
      overallEnergy: (json['overall_energy'] as num).toDouble(),
      socialPreference: (json['social_preference'] as num).toDouble(),
      explorationTendency: (json['exploration_tendency'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      privacyLevel: (json['privacy_level'] as num).toDouble(),
      temporalContext: json['temporal_context'] as String,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserVibe &&
          runtimeType == other.runtimeType &&
          hashedSignature == other.hashedSignature;
  
  @override
  int get hashCode => hashedSignature.hashCode;
  
  @override
  String toString() {
    return 'UserVibe(archetype: ${getVibeArchetype()}, '
           'energy: ${(overallEnergy * 100).round()}%, '
           'social: ${(socialPreference * 100).round()}%, '
           'exploration: ${(explorationTendency * 100).round()}%)';
  }
}