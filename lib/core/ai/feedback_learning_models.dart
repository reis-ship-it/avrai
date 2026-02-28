// Extracted models for feedback learning.

// Supporting classes for feedback learning
class FeedbackEvent {
  final FeedbackType type;
  final double satisfaction;
  final String? comment;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  FeedbackEvent({
    required this.type,
    required this.satisfaction,
    this.comment,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'satisfaction': satisfaction,
      'comment': comment,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FeedbackEvent.fromJson(Map<String, dynamic> json) {
    return FeedbackEvent(
      type: FeedbackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedbackType.spotExperience,
      ),
      satisfaction: (json['satisfaction'] as num).toDouble(),
      comment: json['comment'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum FeedbackType {
  spotExperience,
  socialInteraction,
  recommendation,
  discovery,
  curation,
}

class FeedbackAnalysisResult {
  final String userId;
  final FeedbackEvent feedback;
  final Map<String, double> implicitDimensions;
  final Map<String, double> discoveredDimensions;
  final Map<String, double> personalityAdjustments;
  final List<LearningInsight> learningInsights;
  final DateTime analysisTimestamp;
  final double confidenceScore;

  FeedbackAnalysisResult({
    required this.userId,
    required this.feedback,
    required this.implicitDimensions,
    required this.discoveredDimensions,
    required this.personalityAdjustments,
    required this.learningInsights,
    required this.analysisTimestamp,
    required this.confidenceScore,
  });

  static FeedbackAnalysisResult fallback(
      String userId, FeedbackEvent feedback) {
    return FeedbackAnalysisResult(
      userId: userId,
      feedback: feedback,
      implicitDimensions: {},
      discoveredDimensions: {},
      personalityAdjustments: {},
      learningInsights: [],
      analysisTimestamp: DateTime.now(),
      confidenceScore: 0.0,
    );
  }
}

class FeedbackPattern {
  final String userId;
  final Map<FeedbackType, double> satisfactionByType;
  final double overallSatisfaction;
  final double recentSatisfaction;
  final double satisfactionTrend;
  final double feedbackFrequency;
  final double patternConfidence;

  FeedbackPattern({
    required this.userId,
    required this.satisfactionByType,
    required this.overallSatisfaction,
    required this.recentSatisfaction,
    required this.satisfactionTrend,
    required this.feedbackFrequency,
    required this.patternConfidence,
  });

  static FeedbackPattern insufficient() {
    return FeedbackPattern(
      userId: '',
      satisfactionByType: {},
      overallSatisfaction: 0.5,
      recentSatisfaction: 0.5,
      satisfactionTrend: 0.0,
      feedbackFrequency: 0.0,
      patternConfidence: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'satisfactionByType':
          satisfactionByType.map((k, v) => MapEntry(k.name, v)),
      'overallSatisfaction': overallSatisfaction,
      'recentSatisfaction': recentSatisfaction,
      'satisfactionTrend': satisfactionTrend,
      'feedbackFrequency': feedbackFrequency,
      'patternConfidence': patternConfidence,
    };
  }

  factory FeedbackPattern.fromJson(Map<String, dynamic> json) {
    return FeedbackPattern(
      userId: json['userId'] as String,
      satisfactionByType:
          (json['satisfactionByType'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          FeedbackType.values.firstWhere(
            (e) => e.name == k,
            orElse: () => FeedbackType.spotExperience,
          ),
          (v as num).toDouble(),
        ),
      ),
      overallSatisfaction: (json['overallSatisfaction'] as num).toDouble(),
      recentSatisfaction: (json['recentSatisfaction'] as num).toDouble(),
      satisfactionTrend: (json['satisfactionTrend'] as num).toDouble(),
      feedbackFrequency: (json['feedbackFrequency'] as num).toDouble(),
      patternConfidence: (json['patternConfidence'] as num).toDouble(),
    );
  }
}

class BehavioralPattern {
  final String patternType;
  final Map<String, dynamic> characteristics;
  final double strength;
  final double confidence;

  BehavioralPattern({
    required this.patternType,
    required this.characteristics,
    required this.strength,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'patternType': patternType,
      'characteristics': characteristics,
      'strength': strength,
      'confidence': confidence,
    };
  }

  factory BehavioralPattern.fromJson(Map<String, dynamic> json) {
    return BehavioralPattern(
      patternType: json['patternType'] as String,
      characteristics:
          Map<String, dynamic>.from(json['characteristics'] as Map),
      strength: (json['strength'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class SatisfactionPrediction {
  final double predictedSatisfaction;
  final double confidence;
  final String explanation;
  final Map<String, double> factorsAnalyzed;
  final int basedOnFeedbackCount;
  final DateTime predictionTimestamp;

  SatisfactionPrediction({
    required this.predictedSatisfaction,
    required this.confidence,
    required this.explanation,
    required this.factorsAnalyzed,
    required this.basedOnFeedbackCount,
    required this.predictionTimestamp,
  });

  static SatisfactionPrediction uncertain() {
    return SatisfactionPrediction(
      predictedSatisfaction: 0.5,
      confidence: 0.1,
      explanation: 'Insufficient data for prediction',
      factorsAnalyzed: {},
      basedOnFeedbackCount: 0,
      predictionTimestamp: DateTime.now(),
    );
  }
}

class FeedbackLearningInsights {
  final String userId;
  final int totalFeedbackEvents;
  final List<BehavioralPattern> behavioralPatterns;
  final Map<String, double> discoveredDimensions;
  final LearningProgress learningProgress;
  final List<LearningOpportunity> learningOpportunities;
  final List<String> recommendations;
  final DateTime insightsGenerated;

  FeedbackLearningInsights({
    required this.userId,
    required this.totalFeedbackEvents,
    required this.behavioralPatterns,
    required this.discoveredDimensions,
    required this.learningProgress,
    required this.learningOpportunities,
    required this.recommendations,
    required this.insightsGenerated,
  });

  static FeedbackLearningInsights empty(String userId) {
    return FeedbackLearningInsights(
      userId: userId,
      totalFeedbackEvents: 0,
      behavioralPatterns: [],
      discoveredDimensions: {},
      learningProgress: LearningProgress(
        totalFeedbackEvents: 0,
        learningVelocity: 0.0,
        personalityEvolution: 0.0,
        insightAccuracy: 0.0,
      ),
      learningOpportunities: [],
      recommendations: [],
      insightsGenerated: DateTime.now(),
    );
  }
}

class LearningInsight {
  final InsightType type;
  final String message;
  final double confidence;
  final bool actionable;

  LearningInsight({
    required this.type,
    required this.message,
    required this.confidence,
    required this.actionable,
  });
}

enum InsightType { improvement, concern, strength, discovery }

class LearningProgress {
  final int totalFeedbackEvents;
  final double learningVelocity;
  final double personalityEvolution;
  final double insightAccuracy;

  LearningProgress({
    required this.totalFeedbackEvents,
    required this.learningVelocity,
    required this.personalityEvolution,
    required this.insightAccuracy,
  });
}

class LearningOpportunity {
  final String area;
  final String description;
  final double potential;

  LearningOpportunity({
    required this.area,
    required this.description,
    required this.potential,
  });
}
