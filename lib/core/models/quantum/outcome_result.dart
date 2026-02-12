/// Outcome Result
/// 
/// Represents the result of a real-world action taken by a user
/// after being "called" to an opportunity.
/// 
/// This is used for outcome-based learning in the AI2AI convergence system.
class OutcomeResult {
  final String userId;
  final String opportunityId; // Spot, event, list, etc.
  final OutcomeType outcomeType;
  final double outcomeScore; // 0.0 (negative) to 1.0 (positive)
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  OutcomeResult({
    required this.userId,
    required this.opportunityId,
    required this.outcomeType,
    required this.outcomeScore,
    required this.timestamp,
    this.metadata = const {},
  });
  
  /// Create outcome from user action
  factory OutcomeResult.fromAction({
    required String userId,
    required String opportunityId,
    required UserAction action,
    required DateTime timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    OutcomeType outcomeType;
    double outcomeScore;
    
    switch (action) {
      case UserAction.spotVisit:
        // Positive action - user visited the spot
        outcomeType = OutcomeType.positive;
        outcomeScore = 0.8; // Default positive score
        break;
      case UserAction.recommendationAccept:
        // Positive action - user accepted recommendation
        outcomeType = OutcomeType.positive;
        outcomeScore = 0.9;
        break;
      case UserAction.recommendationReject:
        // Negative action - user rejected recommendation
        outcomeType = OutcomeType.negative;
        outcomeScore = 0.2;
        break;
      default:
        // Neutral
        outcomeType = OutcomeType.neutral;
        outcomeScore = 0.5;
    }
    
    return OutcomeResult(
      userId: userId,
      opportunityId: opportunityId,
      outcomeType: outcomeType,
      outcomeScore: outcomeScore,
      timestamp: timestamp,
      metadata: metadata,
    );
  }
  
  /// Create outcome from feedback
  factory OutcomeResult.fromFeedback({
    required String userId,
    required String opportunityId,
    required double feedbackScore, // 0.0 to 1.0
    required DateTime timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    OutcomeType outcomeType;
    if (feedbackScore >= 0.7) {
      outcomeType = OutcomeType.positive;
    } else if (feedbackScore <= 0.3) {
      outcomeType = OutcomeType.negative;
    } else {
      outcomeType = OutcomeType.neutral;
    }
    
    return OutcomeResult(
      userId: userId,
      opportunityId: opportunityId,
      outcomeType: outcomeType,
      outcomeScore: feedbackScore,
      timestamp: timestamp,
      metadata: metadata,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'opportunityId': opportunityId,
      'outcomeType': outcomeType.toString(),
      'outcomeScore': outcomeScore,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  factory OutcomeResult.fromJson(Map<String, dynamic> json) {
    return OutcomeResult(
      userId: json['userId'] as String,
      opportunityId: json['opportunityId'] as String,
      outcomeType: OutcomeType.values.firstWhere(
        (e) => e.toString() == json['outcomeType'],
        orElse: () => OutcomeType.neutral,
      ),
      outcomeScore: (json['outcomeScore'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Outcome Type
enum OutcomeType {
  positive, // User had positive experience
  negative, // User had negative experience
  neutral,  // Neutral or no action
}

/// User Action (from unified models)
enum UserAction {
  spotVisit,
  listCreate,
  feedbackGiven,
  spotRespect,
  listRespect,
  profileUpdate,
  locationChange,
  searchQuery,
  filterApplied,
  mapInteraction,
  onboardingComplete,
  aiInteraction,
  communityJoin,
  eventAttend,
  recommendationAccept,
  recommendationReject,
}

