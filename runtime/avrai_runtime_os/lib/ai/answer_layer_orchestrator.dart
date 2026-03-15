import 'dart:async' as async;
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/bypass_intent_detector.dart';
import 'package:avrai_runtime_os/ai/conversation_preferences.dart';
import 'package:avrai_runtime_os/ai/rag_context_builder.dart';
import 'package:avrai_runtime_os/ai/rag_feedback_signals.dart';
import 'package:avrai_runtime_os/ai/rag_formatter.dart';
import 'package:avrai_runtime_os/ai/retrieval_service.dart';
import 'package:avrai_runtime_os/ai/scope_classifier.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

/// Orchestrates RAG-as-answer vs bypass path: scope -> bypass -> retrieve -> format.
///
/// Plan: RAG wiring + RAG-as-answer — AnswerLayerOrchestrator.
class AnswerLayerOrchestrator {
  AnswerLayerOrchestrator({
    ScopeClassifier? scopeClassifier,
    BypassIntentDetector? bypassDetector,
    RetrievalService? retrievalService,
    RAGFormatter? formatter,
    RAGContextBuilder? contextBuilder,
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    RAGSignalsCollector? signalsCollector,
    ConversationPreferenceStore? conversationPrefsStore,
  })  : _scopeClassifier = scopeClassifier ?? ScopeClassifier(),
        _bypassDetector = bypassDetector ?? BypassIntentDetector(),
        _retrievalService = retrievalService ?? _get<RetrievalService>(),
        _formatter = formatter ?? _get<RAGFormatter>(),
        _contextBuilder = contextBuilder ?? _get<RAGContextBuilder>(),
        _languageKernelOrchestrator = languageKernelOrchestrator ??
            _get<LanguageKernelOrchestratorService>() ??
            LanguageKernelOrchestratorService(),
        _signalsCollector = _get<RAGSignalsCollector>(),
        _conversationPrefsStore =
            conversationPrefsStore ?? _get<ConversationPreferenceStore>(),
        _languageLearning = _get<LanguagePatternLearningService>();

  static const String _logName = 'AnswerLayerOrchestrator';

  final ScopeClassifier _scopeClassifier;
  final BypassIntentDetector _bypassDetector;
  final RetrievalService? _retrievalService;
  final RAGFormatter? _formatter;
  final RAGContextBuilder? _contextBuilder;
  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final RAGSignalsCollector? _signalsCollector;
  final ConversationPreferenceStore? _conversationPrefsStore;
  final LanguagePatternLearningService? _languageLearning;

  static T? _get<T extends Object>() {
    if (!GetIt.instance.isRegistered<T>()) return null;
    return GetIt.instance<T>();
  }

  /// Runs the answer layer: scope -> bypass -> RAG-as-answer or full chat. Returns response text.
  /// [agentId] optional; when provided, used for conversation-preferences store (per-agent).
  Future<String> respond({
    required String userId,
    required String message,
    required List<LanguageTurnMessage> history,
    Position? location,
    bool searchUsed = false,
    String? agentId,
  }) async {
    if (_scopeClassifier.classify(message) == Scope.outOfScope) {
      return "I can only use what AVRAI knows about you and your world. That question is outside that scope. Try asking about your preferences, places you like, or people you’ve connected with.";
    }

    final lastAssistant =
        history.isNotEmpty && history.last.role == LanguageTurnRole.assistant
            ? history.last.content
            : null;
    if (_bypassDetector.bypassRequested(message,
        lastAssistantMessage: lastAssistant)) {
      return _bypassPath(
          userId: userId,
          agentId: agentId,
          message: message,
          history: history,
          location: location,
          searchUsed: searchUsed);
    }

    return _ragAsAnswerPath(
        userId: userId,
        agentId: agentId,
        message: message,
        searchUsed: searchUsed);
  }

  Future<String> _bypassPath({
    required String userId,
    String? agentId,
    required String message,
    required List<LanguageTurnMessage> history,
    Position? location,
    required bool searchUsed,
  }) async {
    if (_contextBuilder == null) {
      return "I can’t elaborate right now. Try again later.";
    }
    try {
      final context = await _contextBuilder.buildContext(
        userId: userId,
        query: message,
        location: location,
      );
      final response = _languageKernelOrchestrator.renderGroundedOutput(
        speechAct: ExpressionSpeechAct.clarify,
        audience: ExpressionAudience.userSafe,
        surfaceShape: ExpressionSurfaceShape.chatTurn,
        subjectLabel: message,
        allowedClaims: _claimsFromContext(context),
        evidenceRefs: _evidenceRefsFromContext(context),
        confidenceBand: _confidenceBandFromContext(context),
        toneProfile: context.languageStyle != null &&
                context.languageStyle!.trim().isNotEmpty
            ? 'adapted_to_user_style'
            : 'clear_calm',
        uncertaintyNotice:
            'This follow-up stays inside what AVRAI has already grounded.',
        cta:
            'Ask about a specific preference, place, or connection for a tighter answer.',
        adaptationProfileRef: 'answer_layer_bypass:$userId',
      );
      async.unawaited(_recordFeedback(
          userId: userId,
          agentId: agentId,
          usedBypass: true,
          searchUsed: searchUsed,
          retrievedFactGroups: []));
      return response.text;
    } catch (e, st) {
      developer.log('Bypass path failed: $e',
          name: _logName, error: e, stackTrace: st);
      return "Something went wrong. Please try again.";
    }
  }

  Future<String> _ragAsAnswerPath({
    required String userId,
    String? agentId,
    required String message,
    required bool searchUsed,
  }) async {
    if (_retrievalService == null || _formatter == null) {
      return "I don’t have enough about you yet to answer that. Share more and I’ll use it next time.";
    }
    try {
      String? languageStyle;
      if (_languageLearning != null) {
        try {
          final raw = await _languageLearning.getLanguageStyleSummary(userId);
          languageStyle = raw.isEmpty ? null : raw;
        } catch (e) {
          developer.log('Language style fetch failed: $e', name: _logName);
        }
      }
      final result = await _retrievalService.retrieve(userId: userId);
      final response = await _formatter.format(
        result: result,
        query: message,
        userId: userId,
        languageStyle: languageStyle,
      );
      final groups = <String>[];
      if (result.hasTraits) groups.add('traits');
      if (result.hasPlaces) groups.add('places');
      if (result.hasSocial) groups.add('social');
      if (result.hasCues) groups.add('cues');
      if (groups.isEmpty) groups.add('none');
      async.unawaited(_recordFeedback(
        userId: userId,
        agentId: agentId,
        usedBypass: false,
        searchUsed: searchUsed,
        retrievedFactGroups: groups,
      ));
      return response;
    } catch (e, st) {
      developer.log('RAG-as-answer path failed: $e',
          name: _logName, error: e, stackTrace: st);
      return "I don’t have enough about you yet to answer that. Try again later.";
    }
  }

  Future<void> _recordFeedback({
    required String userId,
    String? agentId,
    required bool usedBypass,
    required bool searchUsed,
    required List<String> retrievedFactGroups,
  }) async {
    try {
      if (_signalsCollector != null) {
        await _signalsCollector.record(
          userId: userId,
          retrievedFactGroups: retrievedFactGroups,
          networkCuesUsed: true,
          searchUsed: searchUsed,
          usedBypass: usedBypass,
        );
      }
      if (_conversationPrefsStore != null) {
        final prefsKey = agentId ?? userId;
        await _conversationPrefsStore.updateFromTurn(prefsKey,
            usedBypass: usedBypass);
      }
    } catch (e) {
      developer.log('RAG feedback record failed: $e', name: _logName);
    }
  }

  List<String> _claimsFromContext(LanguageRuntimeContext context) {
    final claims = <String>[];
    final preferences = context.preferences;
    if (preferences != null) {
      final traits = preferences['traits'];
      if (traits is List && traits.isNotEmpty) {
        claims.add('traits: ${traits.take(5).join(', ')}');
      }
      final places = preferences['places'];
      if (places is List && places.isNotEmpty) {
        claims.add('places: ${places.take(5).join(', ')}');
      }
      final socialGraph = preferences['social_graph'];
      if (socialGraph is List && socialGraph.isNotEmpty) {
        claims.add('social graph signals: ${socialGraph.take(3).join(', ')}');
      }
      final networkCues = preferences['network_cues'];
      if (networkCues is List && networkCues.isNotEmpty) {
        claims.add('network cues: ${networkCues.take(3).join('; ')}');
      }
      final dimensionScores = preferences['dimension_scores'];
      if (dimensionScores is Map && dimensionScores.isNotEmpty) {
        claims.add(
          'dimension scores are available for grounded follow-up guidance.',
        );
      }
    }
    final personality = context.personality;
    if (personality != null) {
      claims.add('personality archetype: ${personality.archetype}');
      final dominantTraits = personality.getDominantTraits().take(4).toList();
      if (dominantTraits.isNotEmpty) {
        claims.add('dominant personality traits: ${dominantTraits.join(', ')}');
      }
    }
    final vibe = context.vibe;
    if (vibe != null) {
      claims.add('vibe archetype: ${vibe.getVibeArchetype()}');
    }
    final insights = context.ai2aiInsights;
    if (insights != null && insights.isNotEmpty) {
      claims.add(
        'ai2ai learning insights are available from AVRAI’s prior grounded learning.',
      );
    }
    final connectionMetrics = context.connectionMetrics;
    if (connectionMetrics != null) {
      claims.add(
        'current compatibility score: ${connectionMetrics.currentCompatibility.toStringAsFixed(2)}',
      );
    }
    final conversationPreferences = context.conversationPreferences;
    if (conversationPreferences != null && conversationPreferences.isNotEmpty) {
      claims.add('conversation preferences are available for phrasing.');
    }
    return claims.isEmpty
        ? <String>[
            'AVRAI only has a limited grounded context for this follow-up right now.'
          ]
        : claims;
  }

  List<String> _evidenceRefsFromContext(LanguageRuntimeContext context) {
    final refs = <String>[];
    if (context.preferences != null && context.preferences!.isNotEmpty) {
      refs.add('preferences');
    }
    if (context.personality != null) {
      refs.add('personality');
    }
    if (context.vibe != null) {
      refs.add('vibe');
    }
    if (context.ai2aiInsights != null && context.ai2aiInsights!.isNotEmpty) {
      refs.add('ai2ai_insights');
    }
    if (context.connectionMetrics != null) {
      refs.add('connection_metrics');
    }
    if (context.conversationPreferences != null &&
        context.conversationPreferences!.isNotEmpty) {
      refs.add('conversation_preferences');
    }
    return refs;
  }

  String _confidenceBandFromContext(LanguageRuntimeContext context) {
    var evidenceCount = 0;
    if (context.preferences != null && context.preferences!.isNotEmpty) {
      evidenceCount++;
    }
    if (context.personality != null) {
      evidenceCount++;
    }
    if (context.vibe != null) {
      evidenceCount++;
    }
    if (context.ai2aiInsights != null && context.ai2aiInsights!.isNotEmpty) {
      evidenceCount++;
    }
    if (context.connectionMetrics != null) {
      evidenceCount++;
    }
    return evidenceCount >= 3 ? 'medium' : 'low';
  }
}
