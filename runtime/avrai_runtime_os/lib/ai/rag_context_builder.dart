import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/ai/ai2ai_context_provider.dart';
import 'package:avrai_runtime_os/ai/conversation_preferences.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/ai/network_cue_retrieval.dart';
import 'package:avrai_runtime_os/ai/network_retrieval_cue.dart';
import 'package:avrai_runtime_os/ai/retrieval_bias_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart'
    show UserVibeAnalyzer;
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';

/// Unified RAG context builder. All RAG entry points use this to build LLMContext
/// with facts, network cues, personality, vibe, ai2aiInsights, connectionMetrics, languageStyle.
///
/// RAG Phase 4: Consistent AI2AI context.
class RAGContextBuilder {
  RAGContextBuilder({
    FactsIndex? factsIndex,
    NetworkCueRetrieval? networkCueRetrieval,
    RetrievalBiasService? retrievalBiasService,
    pl.PersonalityLearning? personalityLearning,
    UserVibeAnalyzer? vibeAnalyzer,
    LanguagePatternLearningService? languageLearning,
    AI2AIContextProvider? ai2aiContextProvider,
  })  : _factsIndex = factsIndex ?? GetIt.instance<FactsIndex>(),
        _networkCueRetrieval =
            networkCueRetrieval ?? _get<NetworkCueRetrieval>(),
        _retrievalBiasService =
            retrievalBiasService ?? _get<RetrievalBiasService>(),
        _personalityLearning =
            personalityLearning ?? GetIt.instance<pl.PersonalityLearning>(),
        _vibeAnalyzer = vibeAnalyzer ?? _get<UserVibeAnalyzer>(),
        _languageLearning = _get<LanguagePatternLearningService>(),
        _ai2aiProvider = ai2aiContextProvider ?? _get<AI2AIContextProvider>();

  static const String _logName = 'RAGContextBuilder';

  final FactsIndex _factsIndex;
  final NetworkCueRetrieval? _networkCueRetrieval;
  final RetrievalBiasService? _retrievalBiasService;
  final pl.PersonalityLearning _personalityLearning;
  final UserVibeAnalyzer? _vibeAnalyzer;
  final LanguagePatternLearningService? _languageLearning;
  final AI2AIContextProvider? _ai2aiProvider;

  static T? _get<T extends Object>() {
    if (!GetIt.instance.isRegistered<T>()) return null;
    return GetIt.instance<T>();
  }

  /// Builds full LLMContext for [userId]. Optional [query] and [location] for future use.
  Future<LLMContext> buildContext({
    required String userId,
    String? query,
    Position? location,
  }) async {
    try {
      final facts = await _factsIndex.retrieveFacts(userId: userId);
      var cues = <NetworkRetrievalCue>[];
      if (_networkCueRetrieval != null) {
        cues = _networkCueRetrieval.retrieveCues(userId: userId, limit: 15);
      }
      if (_retrievalBiasService != null) {
        final reranked =
            _retrievalBiasService.reRank(facts, cues, cueLimit: 15);
        cues = reranked.cues;
      }

      final profile = await _personalityLearning.getCurrentPersonality(userId);
      final dimensionScores = profile?.dimensions ?? <String, double>{};

      UserVibe? vibe;
      if (_vibeAnalyzer != null && profile != null) {
        try {
          vibe = await _vibeAnalyzer.compileUserVibe(userId, profile);
        } catch (e) {
          developer.log('Vibe compile failed: $e', name: _logName);
        }
      }

      String? languageStyle;
      if (_languageLearning != null) {
        try {
          languageStyle =
              await _languageLearning.getLanguageStyleSummary(userId);
          if (languageStyle.isEmpty) languageStyle = null;
        } catch (e) {
          developer.log('Language style failed: $e', name: _logName);
        }
      }

      final ai2aiInsights = _ai2aiProvider?.getInsights(userId);
      ConnectionMetrics? connectionMetrics;
      if (_ai2aiProvider != null) {
        try {
          connectionMetrics = await _ai2aiProvider.getConnectionMetrics(userId);
        } catch (_) {}
      }

      final networkCuesSummary =
          cues.where((c) => c.strength >= 0.3).map((c) => c.summary).toList();

      Map<String, dynamic>? conversationPreferencesMap;
      final prefsStore = _get<ConversationPreferenceStore>();
      if (prefsStore != null) {
        try {
          String prefsKey = userId;
          final agentIdService = _get<AgentIdService>();
          if (agentIdService != null) {
            prefsKey = await agentIdService.getUserAgentId(userId);
          }
          final prefs = await prefsStore.get(prefsKey);
          if (prefs != null) {
            conversationPreferencesMap = prefs.toJson();
          }
        } catch (e) {
          developer.log('Conversation preferences fetch failed: $e',
              name: _logName);
        }
      }

      final preferences = <String, dynamic>{
        'traits': facts.traits,
        'places': facts.places,
        'social_graph': facts.socialGraph,
        'dimension_scores': dimensionScores,
      };
      if (networkCuesSummary.isNotEmpty) {
        preferences['network_cues'] = networkCuesSummary;
      }

      return LLMContext(
        userId: userId,
        location: location,
        preferences: preferences,
        personality: profile,
        vibe: vibe,
        ai2aiInsights: (ai2aiInsights != null && ai2aiInsights.isNotEmpty)
            ? ai2aiInsights
            : null,
        connectionMetrics: connectionMetrics,
        languageStyle: languageStyle,
        conversationPreferences: conversationPreferencesMap,
      );
    } catch (e, st) {
      developer.log(
        'RAGContextBuilder.buildContext failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      final profile = await _personalityLearning.getCurrentPersonality(userId);
      return LLMContext(
        userId: userId,
        location: location,
        preferences: {
          'traits': <String>[],
          'places': <String>[],
          'social_graph': <String>[],
          'dimension_scores': profile?.dimensions ?? <String, double>{},
        },
        personality: profile,
      );
    }
  }
}
