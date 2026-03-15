import 'dart:developer' as developer;
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/ai/ai2ai_learning/orchestrator.dart';

class ExpectedOutcome {
  final String id;
  final String description;
  final double probability;

  ExpectedOutcome({
    required this.id,
    required this.description,
    required this.probability,
  });
}

/// OUR_GUTS.md: "AI2AI chat learning that builds collective intelligence through cross-personality interactions"
/// Advanced AI2AI chat analysis system that extracts learning insights from personality conversations
/// Phase 1.5: Refactored to use orchestrator for core functionality
class AI2AIChatAnalyzer {
  static const String _logName = 'AI2AIChatAnalyzer';

  // Storage keys for AI2AI learning data
  // ignore: unused_field
  static const String _chatHistoryKey = 'ai2ai_chat_history';
  // ignore: unused_field
  static const String _learningInsightsKey = 'ai2ai_learning_insights';
  // ignore: unused_field
  static const String _collectiveKnowledgeKey = 'collective_knowledge';

  // ignore: unused_field
  final SharedPreferencesCompat _prefs;
  final PersonalityLearning _personalityLearning;

  // Phase 1.5: Refactored to use orchestrator
  final AI2AILearningOrchestrator _orchestrator;

  AI2AIChatAnalyzer({
    required SharedPreferencesCompat prefs,
    required PersonalityLearning personalityLearning,
    AI2AILearningOrchestrator? orchestrator,
  })  : _prefs = prefs,
        _personalityLearning = personalityLearning,
        _orchestrator = orchestrator ?? AI2AILearningOrchestrator();

  /// Analyze AI2AI chat conversation for learning insights
  /// Phase 1.5: Delegates to orchestrator
  Future<AI2AIChatAnalysisResult> analyzeChatConversation(
    String localUserId,
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    try {
      final result = await _orchestrator.analyzeChatConversation(
        localUserId,
        chatEvent,
        connectionContext,
      );

      // Apply learning if confidence is sufficient
      if (result.analysisConfidence >= 0.6) {
        await _applyAI2AILearning(localUserId, result);
      }

      return result;
    } catch (e) {
      developer.log('Error analyzing AI2AI chat: $e', name: _logName);
      return AI2AIChatAnalysisResult.fallback(localUserId, chatEvent);
    }
  }

  /// Build collective knowledge from multiple AI2AI interactions
  /// Phase 1.5: Delegates to orchestrator
  Future<CollectiveKnowledge> buildCollectiveKnowledge(
    String communityId,
    List<AI2AIChatEvent> communityChats,
  ) async {
    return await _orchestrator.buildCollectiveKnowledge(
      communityId,
      communityChats,
    );
  }

  /// Extract cross-personality learning patterns
  /// Phase 1.5: Delegates to orchestrator
  Future<List<CrossPersonalityLearningPattern>> extractLearningPatterns(
    String userId,
    List<AI2AIChatEvent> recentChats,
  ) async {
    return await _orchestrator.extractLearningPatterns(userId, recentChats);
  }

  /// Generate AI2AI learning recommendations
  /// Phase 1.5: Delegates to orchestrator
  Future<AI2AILearningRecommendations> generateLearningRecommendations(
    String userId,
    PersonalityProfile currentPersonality,
  ) async {
    return await _orchestrator.generateLearningRecommendations(
      userId,
      currentPersonality,
    );
  }

  /// Measure AI2AI learning effectiveness
  /// Phase 1.5: Delegates to orchestrator
  Future<LearningEffectivenessMetrics> measureLearningEffectiveness(
    String userId,
    Duration timeWindow,
  ) async {
    return await _orchestrator.measureLearningEffectiveness(userId, timeWindow);
  }

  // Phase 1.5: Legacy methods removed - functionality moved to orchestrator and modules

  Future<void> _applyAI2AILearning(
      String userId, AI2AIChatAnalysisResult result) async {
    // Apply evolution recommendations if they exist
    if (result.evolutionRecommendations.isNotEmpty) {
      final dimensionAdjustments = <String, double>{};

      for (final recommendation in result.evolutionRecommendations) {
        if (recommendation.confidence >= 0.7) {
          final adjustment =
              recommendation.magnitude * VibeConstants.ai2aiLearningRate;
          final directionMultiplier =
              recommendation.direction == 'increase' ? 1.0 : -1.0;
          dimensionAdjustments[recommendation.dimension] =
              adjustment * directionMultiplier;
        }
      }

      if (dimensionAdjustments.isNotEmpty) {
        final ai2aiInsight = AI2AILearningInsight(
          type: AI2AIInsightType.communityInsight,
          dimensionInsights: dimensionAdjustments,
          learningQuality: result.analysisConfidence,
          timestamp: DateTime.now(),
        );

        await _personalityLearning.evolveFromAI2AILearning(
            userId, ai2aiInsight);

        developer.log(
            'Applied AI2AI chat learning with ${dimensionAdjustments.length} adjustments',
            name: _logName);
      }
    }
  }

  /// Get chat history for admin access
  /// Returns all chat events for a given user ID
  /// Phase 1.5: Delegates to orchestrator
  Future<List<AI2AIChatEvent>> getChatHistoryForAdmin(String userId) async {
    return await _orchestrator.getChatHistory(userId);
  }

  /// Get all chat history across all users (admin access)
  /// Returns a map of userId -> chat events
  /// Phase 1.5: Delegates to orchestrator
  Map<String, List<AI2AIChatEvent>> getAllChatHistoryForAdmin() {
    return _orchestrator.getAllChatHistory();
  }

  /// Analyze collaborative activity patterns from AI2AI conversations
  /// Phase 7 Week 40: Track list creation during AI2AI conversations
  /// Privacy-safe: Returns aggregate metrics only, no user data
  // ignore: unused_element
  Future<CollaborativeActivityMetrics> _analyzeCollaborativeActivity(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    try {
      if (chats.isEmpty) {
        return CollaborativeActivityMetrics.empty();
      }

      developer.log(
          'Analyzing collaborative activity for user: $userId (${chats.length} chats)',
          name: _logName);

      // Track collaborative list creation
      int totalCollaborativeLists = 0;
      int groupChatLists = 0;
      int dmLists = 0;
      final groupSizes = <int, int>{};
      final activityByHour = <int, int>{};
      int totalPlanningSessions = 0;
      double totalSessionDuration = 0.0;
      int listsWithSpots = 0;
      final timeDeltas = <Duration>[];

      // Get action history service (if available)
      // Note: This is a simplified implementation - in production would inject service
      // For now, we'll analyze based on chat patterns and metadata

      for (final chat in chats) {
        // Check if this chat led to list creation
        // Look for planning keywords in messages
        bool hasPlanningKeywords = false;
        for (final message in chat.messages) {
          final content = message.learnablePatternText.toLowerCase();
          if (content.contains('list') ||
              content.contains('plan') ||
              content.contains('create') ||
              content.contains('collaborate') ||
              content.contains('together')) {
            hasPlanningKeywords = true;
            break;
          }
        }

        if (hasPlanningKeywords) {
          totalPlanningSessions++;
          totalSessionDuration += chat.duration.inMinutes.toDouble();
        }

        // Detect list creation (simplified - would check action history in production)
        // For now, estimate based on chat characteristics
        final groupSize = chat.participants.length;
        final isGroupChat = groupSize >= 3;

        // Estimate list creation probability based on chat depth and planning keywords
        final listCreationProbability =
            hasPlanningKeywords && chat.messages.length >= 3 ? 0.3 : 0.0;

        if (listCreationProbability > 0.1) {
          totalCollaborativeLists++;

          // Categorize by group size
          groupSizes[groupSize] = (groupSizes[groupSize] ?? 0) + 1;

          if (isGroupChat) {
            groupChatLists++;
          } else {
            dmLists++;
          }

          // Track activity by hour
          final hour = chat.timestamp.hour;
          activityByHour[hour] = (activityByHour[hour] ?? 0) + 1;

          // Estimate follow-through (lists with spots added)
          if (chat.messages.length >= 5) {
            listsWithSpots++;
          }

          // Estimate time delta (simplified)
          timeDeltas.add(const Duration(minutes: 5)); // Placeholder
        }
      }

      if (totalCollaborativeLists == 0) {
        return CollaborativeActivityMetrics.empty();
      }

      // Calculate metrics
      final collaborationRate = totalCollaborativeLists / chats.length;
      final avgSessionDuration = totalPlanningSessions > 0
          ? totalSessionDuration / totalPlanningSessions
          : 0.0;
      final followThroughRate = totalCollaborativeLists > 0
          ? listsWithSpots / totalCollaborativeLists
          : 0.0;

      // Estimate average list size and collaborator count (simplified)
      const avgListSize =
          8.3; // Placeholder - would calculate from actual lists
      final avgCollaboratorCount = groupSizes.entries
              .map((e) => e.key * e.value)
              .fold(0, (sum, val) => sum + val) /
          totalCollaborativeLists;

      return CollaborativeActivityMetrics(
        totalCollaborativeLists: totalCollaborativeLists,
        groupChatLists: groupChatLists,
        dmLists: dmLists,
        avgListSize: avgListSize,
        avgCollaboratorCount: avgCollaboratorCount,
        groupSizeDistribution: groupSizes,
        collaborationRate: collaborationRate,
        totalPlanningSessions: totalPlanningSessions,
        avgSessionDuration: avgSessionDuration,
        followThroughRate: followThroughRate,
        activityByHour: activityByHour,
        collectionStart: chats.isNotEmpty
            ? chats
                .map((c) => c.timestamp)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now(),
        lastUpdated: DateTime.now(),
        measurementWindow: chats.isNotEmpty
            ? chats
                .map((c) => c.timestamp)
                .reduce((a, b) => a.isAfter(b) ? a : b)
                .difference(chats
                    .map((c) => c.timestamp)
                    .reduce((a, b) => a.isBefore(b) ? a : b))
            : Duration.zero,
        totalUsersContributing: 1, // Count only, no IDs
        containsUserData: false,
        isAnonymized: true,
      );
    } catch (e) {
      developer.log('Error analyzing collaborative activity: $e',
          name: _logName);
      return CollaborativeActivityMetrics.empty();
    }
  }
}

// Supporting classes for AI2AI chat learning
class AI2AIChatEvent {
  final String eventId;
  final List<String> participants;
  final List<ChatMessage> messages;
  final ChatMessageType messageType;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic> metadata;

  AI2AIChatEvent({
    required this.eventId,
    required this.participants,
    required this.messages,
    required this.messageType,
    required this.timestamp,
    required this.duration,
    required this.metadata,
  });
}

class ChatMessage {
  static const String humanLanguageBoundaryMetadataKey =
      'human_language_boundary';
  static const String humanLanguageLearningMetadataKey =
      'human_language_learning_boundary';

  final String senderId;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.context,
  });

  Map<String, dynamic>? get humanLanguageLearningMetadata =>
      _readMetadataMap(humanLanguageLearningMetadataKey);

  Map<String, dynamic>? get humanLanguageBoundaryMetadata {
    return _readMetadataMap(humanLanguageBoundaryMetadataKey);
  }

  Map<String, dynamic>? get effectiveHumanLanguageMetadata =>
      humanLanguageLearningMetadata ?? humanLanguageBoundaryMetadata;

  Map<String, dynamic>? _readMetadataMap(String key) {
    final raw = context[key];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  BoundarySanitizedArtifact? get learnableArtifact {
    final metadata = effectiveHumanLanguageMetadata;
    if (metadata == null) {
      return null;
    }

    final rawArtifact = metadata['sanitized_artifact'];
    if (rawArtifact is Map<String, dynamic>) {
      return BoundarySanitizedArtifact.fromJson(rawArtifact);
    }
    if (rawArtifact is Map) {
      return BoundarySanitizedArtifact.fromJson(
        Map<String, dynamic>.from(rawArtifact),
      );
    }

    final summary = metadata['sanitized_summary']?.toString().trim();
    if (summary == null || summary.isEmpty) {
      return null;
    }

    return BoundarySanitizedArtifact(
      pseudonymousActorRef:
          metadata['pseudonymous_actor_ref']?.toString() ?? 'anon_unknown',
      summary: summary,
      safeClaims: <String>[summary],
      safeQuestions: const <String>[],
      safePreferenceSignals: const <InterpretationPreferenceSignal>[],
      learningVocabulary: const <String>[],
      learningPhrases: const <String>[],
      redactedText: metadata['redacted_text']?.toString() ?? summary,
    );
  }

  bool get hasStructuredLearnableArtifact => learnableArtifact != null;

  bool get usesLegacyRawFallback =>
      !hasStructuredLearnableArtifact && content.trim().isNotEmpty;

  String get learnableArtifactSource {
    if (!hasStructuredLearnableArtifact) {
      return 'legacy_raw_fallback';
    }
    if (humanLanguageLearningMetadata != null) {
      return humanLanguageLearningMetadataKey;
    }
    return humanLanguageBoundaryMetadataKey;
  }

  double get learnableReliabilityWeight =>
      hasStructuredLearnableArtifact ? 1.0 : 0.7;

  String get learnableSummaryText {
    final artifact = learnableArtifact;
    if (artifact != null && artifact.summary.trim().isNotEmpty) {
      return artifact.summary.trim();
    }
    return content.trim();
  }

  String get learnablePatternText {
    final artifact = learnableArtifact;
    if (artifact == null) {
      return content;
    }

    final segments = <String>[
      artifact.summary,
      ...artifact.safeClaims,
      ...artifact.safeQuestions,
      ...artifact.safePreferenceSignals.expand(
        (entry) => <String>[entry.kind, entry.value],
      ),
      ...artifact.learningVocabulary,
      ...artifact.learningPhrases,
      artifact.redactedText,
    ];

    return segments
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .join(' ');
  }

  List<String> get learnableTopicTerms {
    final artifact = learnableArtifact;
    final topicTerms = <String>{};
    if (artifact != null) {
      for (final token in artifact.learningVocabulary) {
        final normalized = _normalizeTopicToken(token);
        if (normalized != null) {
          topicTerms.add(normalized);
        }
      }
      for (final phrase in <String>[
        artifact.summary,
        ...artifact.safeClaims,
        ...artifact.safeQuestions,
        ...artifact.learningPhrases,
        artifact.redactedText,
      ]) {
        for (final token in phrase.split(RegExp(r'\s+'))) {
          final normalized = _normalizeTopicToken(token);
          if (normalized != null) {
            topicTerms.add(normalized);
          }
        }
      }
      for (final signal in artifact.safePreferenceSignals) {
        for (final token in <String>[signal.kind, signal.value]) {
          final normalized = _normalizeTopicToken(token);
          if (normalized != null) {
            topicTerms.add(normalized);
          }
        }
      }
    } else {
      for (final token in content.split(RegExp(r'\s+'))) {
        final normalized = _normalizeTopicToken(token);
        if (normalized != null) {
          topicTerms.add(normalized);
        }
      }
    }
    return topicTerms.toList(growable: false);
  }

  String? _normalizeTopicToken(String token) {
    final cleaned = token.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
    if (cleaned.length <= 3) {
      return null;
    }
    return cleaned;
  }
}

enum ChatMessageType {
  personalitySharing,
  experienceSharing,
  insightExchange,
  trustBuilding
}

class AI2AIChatAnalysisResult {
  final String localUserId;
  final AI2AIChatEvent chatEvent;
  final ConversationPatterns conversationPatterns;
  final List<SharedInsight> sharedInsights;
  final List<AI2AILearningOpportunity> learningOpportunities;
  final CollectiveIntelligence collectiveIntelligence;
  final List<PersonalityEvolutionRecommendation> evolutionRecommendations;
  final TrustMetrics trustMetrics;
  final DateTime analysisTimestamp;
  final double analysisConfidence;

  AI2AIChatAnalysisResult({
    required this.localUserId,
    required this.chatEvent,
    required this.conversationPatterns,
    required this.sharedInsights,
    required this.learningOpportunities,
    required this.collectiveIntelligence,
    required this.evolutionRecommendations,
    required this.trustMetrics,
    required this.analysisTimestamp,
    required this.analysisConfidence,
  });

  static AI2AIChatAnalysisResult fallback(
      String userId, AI2AIChatEvent chatEvent) {
    return AI2AIChatAnalysisResult(
      localUserId: userId,
      chatEvent: chatEvent,
      conversationPatterns: ConversationPatterns.empty(),
      sharedInsights: [],
      learningOpportunities: [],
      collectiveIntelligence: CollectiveIntelligence.empty(),
      evolutionRecommendations: [],
      trustMetrics: TrustMetrics.empty(),
      analysisTimestamp: DateTime.now(),
      analysisConfidence: 0.0,
    );
  }
}

// Additional supporting classes
class ConversationPatterns {
  final double exchangeFrequency;
  final double responseLatency;
  final double conversationDepth;
  final double topicConsistency;
  final double patternStrength;

  ConversationPatterns({
    required this.exchangeFrequency,
    required this.responseLatency,
    required this.conversationDepth,
    required this.topicConsistency,
    required this.patternStrength,
  });

  static ConversationPatterns empty() {
    return ConversationPatterns(
      exchangeFrequency: 0.0,
      responseLatency: 0.0,
      conversationDepth: 0.0,
      topicConsistency: 0.0,
      patternStrength: 0.0,
    );
  }
}

class SharedInsight {
  final String category;
  final String dimension;
  final double value;
  final String description;
  final double reliability;
  final DateTime timestamp;

  SharedInsight({
    required this.category,
    required this.dimension,
    required this.value,
    required this.description,
    required this.reliability,
    required this.timestamp,
  });
}

class CollectiveIntelligence {
  final double individualContribution;
  final double insightQuality;
  final double networkEffect;
  final double knowledgeSynergy;
  final double emergenceScore;

  CollectiveIntelligence({
    required this.individualContribution,
    required this.insightQuality,
    required this.networkEffect,
    required this.knowledgeSynergy,
    required this.emergenceScore,
  });

  static CollectiveIntelligence empty() {
    return CollectiveIntelligence(
      individualContribution: 0.0,
      insightQuality: 0.0,
      networkEffect: 0.0,
      knowledgeSynergy: 0.0,
      emergenceScore: 0.0,
    );
  }
}

class PersonalityEvolutionRecommendation {
  final String dimension;
  final String direction;
  final double magnitude;
  final double confidence;
  final String reasoning;

  PersonalityEvolutionRecommendation({
    required this.dimension,
    required this.direction,
    required this.magnitude,
    required this.confidence,
    required this.reasoning,
  });
}

class TrustMetrics {
  final double trustBuilding;
  final double trustEvolution;
  final double communicationQuality;
  final double mutualBenefit;
  final double overallTrust;

  TrustMetrics({
    required this.trustBuilding,
    required this.trustEvolution,
    required this.communicationQuality,
    required this.mutualBenefit,
    required this.overallTrust,
  });

  static TrustMetrics empty() {
    return TrustMetrics(
      trustBuilding: 0.0,
      trustEvolution: 0.0,
      communicationQuality: 0.0,
      mutualBenefit: 0.0,
      overallTrust: 0.0,
    );
  }
}

class CollectiveKnowledge {
  final String communityId;
  final List<SharedInsight> aggregatedInsights;
  final List<EmergingPattern> emergingPatterns;
  final Map<String, dynamic> consensusKnowledge;
  final List<CommunityTrend> communityTrends;
  final Map<String, double> reliabilityScores;
  final int contributingChats;
  final double knowledgeDepth;
  final DateTime lastUpdated;

  CollectiveKnowledge({
    required this.communityId,
    required this.aggregatedInsights,
    required this.emergingPatterns,
    required this.consensusKnowledge,
    required this.communityTrends,
    required this.reliabilityScores,
    required this.contributingChats,
    required this.knowledgeDepth,
    required this.lastUpdated,
  });

  static CollectiveKnowledge insufficient() {
    return CollectiveKnowledge(
      communityId: '',
      aggregatedInsights: [],
      emergingPatterns: [],
      consensusKnowledge: {},
      communityTrends: [],
      reliabilityScores: {},
      contributingChats: 0,
      knowledgeDepth: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

class CrossPersonalityLearningPattern {
  final String patternType;
  final Map<String, dynamic> characteristics;
  final double strength;
  final double confidence;
  final DateTime identified;

  CrossPersonalityLearningPattern({
    required this.patternType,
    required this.characteristics,
    required this.strength,
    required this.confidence,
    required this.identified,
  });
}

class AI2AILearningRecommendations {
  final String userId;
  final List<OptimalPartner> optimalPartners;
  final List<LearningTopic> learningTopics;
  final List<DevelopmentArea> developmentAreas;
  final InteractionStrategy interactionStrategy;
  final List<ExpectedOutcome> expectedOutcomes;
  final double confidenceScore;
  final DateTime generatedAt;

  AI2AILearningRecommendations({
    required this.userId,
    required this.optimalPartners,
    required this.learningTopics,
    required this.developmentAreas,
    required this.interactionStrategy,
    required this.expectedOutcomes,
    required this.confidenceScore,
    required this.generatedAt,
  });

  static AI2AILearningRecommendations empty(String userId) {
    return AI2AILearningRecommendations(
      userId: userId,
      optimalPartners: [],
      learningTopics: [],
      developmentAreas: [],
      interactionStrategy: InteractionStrategy.balanced(),
      expectedOutcomes: [],
      confidenceScore: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}

class LearningEffectivenessMetrics {
  final String userId;
  final Duration timeWindow;
  final double evolutionRate;
  final double knowledgeAcquisition;
  final double insightQuality;
  final double trustNetworkGrowth;
  final double collectiveContribution;
  final int totalInteractions;
  final double overallEffectiveness;
  final DateTime measuredAt;

  LearningEffectivenessMetrics({
    required this.userId,
    required this.timeWindow,
    required this.evolutionRate,
    required this.knowledgeAcquisition,
    required this.insightQuality,
    required this.trustNetworkGrowth,
    required this.collectiveContribution,
    required this.totalInteractions,
    required this.overallEffectiveness,
    required this.measuredAt,
  });

  static LearningEffectivenessMetrics zero(String userId, Duration timeWindow) {
    return LearningEffectivenessMetrics(
      userId: userId,
      timeWindow: timeWindow,
      evolutionRate: 0.0,
      knowledgeAcquisition: 0.0,
      insightQuality: 0.0,
      trustNetworkGrowth: 0.0,
      collectiveContribution: 0.0,
      totalInteractions: 0,
      overallEffectiveness: 0.0,
      measuredAt: DateTime.now(),
    );
  }
}

// Placeholder classes for complex data structures
class EmergingPattern {
  final String pattern;
  final double strength;
  EmergingPattern(this.pattern, this.strength);
}

class CommunityTrend {
  final String trend;
  final double direction;
  CommunityTrend(this.trend, this.direction);
}

class CrossPersonalityInsight {
  final String insight;
  final double value;
  final double reliability;
  final String type;
  final DateTime timestamp;

  CrossPersonalityInsight({
    required this.insight,
    required this.value,
    required this.reliability,
    required this.type,
    required this.timestamp,
  });
}

class OptimalPartner {
  final String archetype;
  final double compatibility;
  OptimalPartner(this.archetype, this.compatibility);
}

class LearningTopic {
  final String topic;
  final double potential;
  LearningTopic(this.topic, this.potential);
}

class DevelopmentArea {
  final String area;
  final double priority;
  DevelopmentArea(this.area, this.priority);
}

class InteractionStrategy {
  final String strategy;
  final Map<String, dynamic> parameters;
  InteractionStrategy(this.strategy, this.parameters);

  static InteractionStrategy balanced() => InteractionStrategy('balanced', {});
}

class AI2AILearningOpportunity {
  final String area;
  final String description;
  final double potential;

  AI2AILearningOpportunity({
    required this.area,
    required this.description,
    required this.potential,
  });
}
