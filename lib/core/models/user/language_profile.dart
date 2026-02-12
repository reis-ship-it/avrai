/// LanguageProfile Model
/// 
/// Represents learned language patterns from user's agent chat conversations.
/// Used to adapt the AI agent's communication style to match the user's natural language.
/// 
/// Philosophy: "Doors, not badges" - Authentic language learning, not gamification.
/// Privacy: All learning happens on-device. No cloud sync unless user opts in.
/// 
/// Phase 1.1: Language Pattern Learning System
class LanguageProfile {
  /// Privacy-protected identifier (agentId, not userId)
  /// Format: agent_[32+ character base64url string]
  final String agentId;
  
  /// User-facing identifier (for UI display)
  final String userId;
  
  /// Common vocabulary words with frequency scores (0.0-1.0)
  /// Higher score = more frequently used by user
  /// Example: {"awesome": 0.85, "totally": 0.72, "yeah": 0.91}
  final Map<String, double> vocabulary;
  
  /// Common phrases with frequency scores (0.0-1.0)
  /// Example: {"you know": 0.65, "I mean": 0.58, "that's cool": 0.72}
  final Map<String, double> phrases;
  
  /// Sentence structure patterns
  /// - averageLength: Average words per sentence
  /// - punctuationUsage: Map of punctuation marks to frequency
  ///   Example: {"!": 0.15, "?": 0.08, "...": 0.12}
  final Map<String, dynamic> sentenceStructure;
  
  /// Tone indicators (0.0-1.0 scale)
  /// - formality: 0.0 = very casual, 1.0 = very formal
  /// - enthusiasm: 0.0 = low energy, 1.0 = high energy
  /// - directness: 0.0 = indirect/roundabout, 1.0 = very direct
  final Map<String, double> tone;
  
  /// Learning metadata
  /// - messageCount: Total messages analyzed
  /// - lastUpdated: Last time profile was updated
  /// - learningConfidence: Overall confidence in learned patterns (0.0-1.0)
  final Map<String, dynamic> metadata;
  
  /// When this profile was created
  final DateTime createdAt;
  
  /// Last time profile was updated
  final DateTime lastUpdated;

  LanguageProfile({
    required this.agentId,
    required this.userId,
    this.vocabulary = const {},
    this.phrases = const {},
    this.sentenceStructure = const {},
    this.tone = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create initial empty language profile
  factory LanguageProfile.initial(String agentId, String userId) {
    final now = DateTime.now();
    return LanguageProfile(
      agentId: agentId,
      userId: userId,
      vocabulary: {},
      phrases: {},
      sentenceStructure: {
        'averageLength': 0.0,
        'punctuationUsage': <String, double>{},
      },
      tone: {
        'formality': 0.5, // Neutral default
        'enthusiasm': 0.5, // Neutral default
        'directness': 0.5, // Neutral default
      },
      metadata: {
        'messageCount': 0,
        'learningConfidence': 0.0,
      },
      createdAt: now,
      lastUpdated: now,
    );
  }

  /// Create updated profile with new learning data
  LanguageProfile copyWith({
    Map<String, double>? vocabulary,
    Map<String, double>? phrases,
    Map<String, dynamic>? sentenceStructure,
    Map<String, double>? tone,
    Map<String, dynamic>? metadata,
  }) {
    // Merge vocabulary (weighted average for existing words)
    final updatedVocabulary = Map<String, double>.from(this.vocabulary);
    if (vocabulary != null) {
      vocabulary.forEach((word, newScore) {
        final existingScore = updatedVocabulary[word] ?? 0.0;
        // Weighted average: existing * 0.7 + new * 0.3 (gradual learning)
        updatedVocabulary[word] = (existingScore * 0.7 + newScore * 0.3).clamp(0.0, 1.0);
      });
    }

    // Merge phrases (weighted average)
    final updatedPhrases = Map<String, double>.from(this.phrases);
    if (phrases != null) {
      phrases.forEach((phrase, newScore) {
        final existingScore = updatedPhrases[phrase] ?? 0.0;
        updatedPhrases[phrase] = (existingScore * 0.7 + newScore * 0.3).clamp(0.0, 1.0);
      });
    }

    // Merge sentence structure
    final updatedSentenceStructure = Map<String, dynamic>.from(this.sentenceStructure);
    if (sentenceStructure != null) {
      sentenceStructure.forEach((key, value) {
        if (key == 'averageLength' && value is num) {
          final existing = (updatedSentenceStructure['averageLength'] as num?)?.toDouble() ?? 0.0;
          updatedSentenceStructure[key] = (existing * 0.7 + value.toDouble() * 0.3);
        } else if (key == 'punctuationUsage' && value is Map) {
          final existingPunct = Map<String, double>.from(
            (updatedSentenceStructure['punctuationUsage'] as Map?)?.cast<String, double>() ?? <String, double>{},
          );
          value.forEach((punct, freq) {
            final existingFreq = existingPunct[punct] ?? 0.0;
            existingPunct[punct] = (existingFreq * 0.7 + (freq as num).toDouble() * 0.3).clamp(0.0, 1.0);
          });
          updatedSentenceStructure['punctuationUsage'] = existingPunct;
        } else {
          updatedSentenceStructure[key] = value;
        }
      });
    }

    // Merge tone (weighted average)
    final updatedTone = Map<String, double>.from(this.tone);
    if (tone != null) {
      tone.forEach((indicator, newValue) {
        final existingValue = updatedTone[indicator] ?? 0.5;
        updatedTone[indicator] = (existingValue * 0.7 + newValue * 0.3).clamp(0.0, 1.0);
      });
    }

    // Merge metadata
    final updatedMetadata = Map<String, dynamic>.from(this.metadata);
    if (metadata != null) {
      metadata.forEach((key, value) {
        if (key == 'messageCount' && value is int) {
          updatedMetadata[key] = (updatedMetadata[key] as int? ?? 0) + value;
        } else if (key == 'learningConfidence' && value is num) {
          final existing = (updatedMetadata[key] as num?)?.toDouble() ?? 0.0;
          updatedMetadata[key] = (existing * 0.7 + value.toDouble() * 0.3).clamp(0.0, 1.0);
        } else {
          updatedMetadata[key] = value;
        }
      });
    }

    return LanguageProfile(
      agentId: agentId,
      userId: userId,
      vocabulary: updatedVocabulary,
      phrases: updatedPhrases,
      sentenceStructure: updatedSentenceStructure,
      tone: updatedTone,
      metadata: updatedMetadata,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get learning confidence (0.0-1.0)
  double get learningConfidence => (metadata['learningConfidence'] as num?)?.toDouble() ?? 0.0;

  /// Get total messages analyzed
  int get messageCount => (metadata['messageCount'] as int?) ?? 0;

  /// Get average sentence length
  double get averageSentenceLength => 
      (sentenceStructure['averageLength'] as num?)?.toDouble() ?? 0.0;

  /// Check if profile has enough data for meaningful adaptation
  /// Requires at least 50 messages analyzed and confidence > 0.3
  bool get isReadyForAdaptation => messageCount >= 50 && learningConfidence > 0.3;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'userId': userId,
      'vocabulary': vocabulary,
      'phrases': phrases,
      'sentenceStructure': sentenceStructure,
      'tone': tone,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON storage
  factory LanguageProfile.fromJson(Map<String, dynamic> json) {
    // Handle punctuationUsage deserialization
    final sentenceStructure = Map<String, dynamic>.from(json['sentenceStructure'] ?? {});
    if (sentenceStructure.containsKey('punctuationUsage')) {
      final punctData = sentenceStructure['punctuationUsage'];
      if (punctData is Map) {
        sentenceStructure['punctuationUsage'] = 
            Map<String, double>.from(punctData.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
      }
    }

    return LanguageProfile(
      agentId: json['agentId'] as String,
      userId: json['userId'] as String,
      vocabulary: Map<String, double>.from(
        (json['vocabulary'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      phrases: Map<String, double>.from(
        (json['phrases'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      sentenceStructure: sentenceStructure,
      tone: Map<String, double>.from(
        (json['tone'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageProfile &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => agentId.hashCode ^ lastUpdated.hashCode;

  @override
  String toString() {
    return 'LanguageProfile(agentId: ${agentId.substring(0, 10)}..., '
        'messages: $messageCount, confidence: ${learningConfidence.toStringAsFixed(2)})';
  }
}

