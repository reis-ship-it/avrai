import 'dart:developer' as developer;
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/user/language_profile_diagnostics.dart';
import 'package:avrai_core/models/user/language_profile.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math' as math;

/// LanguagePatternLearningService
///
/// Analyzes user messages from agent chat to learn language patterns.
/// Privacy-preserving: All learning happens on-device.
///
/// Philosophy: "Doors, not badges" - Authentic language learning, not gamification.
///
/// Phase 1.2: Language Pattern Learning System
///
/// **CRITICAL:** Only learns from agent chat messages (chatType == 'agent').
/// Friends and community chats are NOT analyzed for language learning.
class LanguagePatternLearningService {
  static const String _logName = 'LanguagePatternLearningService';
  static const String _dataKeyPrefix = 'language_profile_';
  static const String _eventKeyPrefix = 'language_profile_events_';
  static const int _maxStoredEventsPerProfile = 24;
  final GetStorage _box = GetStorage('language_patterns');

  final AgentIdService _agentIdService;

  LanguagePatternLearningService({
    AgentIdService? agentIdService,
  }) : _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>();

  /// Analyze a message and update language profile
  ///
  /// [userId] - User-facing identifier
  /// [message] - Message text to analyze
  /// [chatType] - Type of chat ('agent', 'friend', 'community')
  ///
  /// **Only processes messages from agent chat** (chatType == 'agent').
  /// Returns true if message was analyzed, false if ignored.
  Future<bool> analyzeMessage(
    String userId,
    String message,
    String chatType,
  ) async {
    try {
      // CRITICAL: Only learn from agent chat
      if (chatType != 'agent') {
        developer.log(
          'Skipping language analysis: chatType=$chatType (only "agent" chat is analyzed)',
          name: _logName,
        );
        return false;
      }

      developer.log(
        'Analyzing message for language patterns: userId=$userId, length=${message.length}',
        name: _logName,
      );

      // Convert userId → agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get or create language profile
      final profile = await getLanguageProfile(userId) ??
          LanguageProfile.initial(agentId, userId);

      // Analyze message
      final analysis = _analyzeMessageContent(message);

      // Update profile with new learning
      final updatedProfile = _updateProfileWithAnalysis(profile, analysis);

      // Save updated profile
      await _saveLanguageProfile(agentId, updatedProfile);
      await _appendLearningEvent(
        LanguageLearningEvent(
          profileRef: agentId,
          displayRef: userId,
          learningScope: 'user_runtime_learning',
          surface: 'agent_chat',
          source: 'agent_message',
          summary: 'Learned from a direct agent-chat message.',
          vocabularySample: _topScoredKeys(analysis.vocabulary, limit: 4),
          phraseSample: _topScoredKeys(analysis.phrases, limit: 3),
          toneSnapshot: Map<String, double>.from(analysis.tone),
          messageCountAfter: updatedProfile.messageCount,
          confidenceAfter: updatedProfile.learningConfidence,
          timestamp: updatedProfile.lastUpdated,
        ),
      );

      developer.log(
        '✅ Language profile updated: messages=${updatedProfile.messageCount}, confidence=${updatedProfile.learningConfidence.toStringAsFixed(2)}',
        name: _logName,
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error analyzing message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Analyze a sanitized boundary artifact and update a governance/operator
  /// language profile without storing raw text.
  Future<bool> analyzeSanitizedArtifact({
    required String profileRef,
    required BoundarySanitizedArtifact artifact,
    String? displayRef,
    String learningScope = 'governance',
    String surface = 'admin',
  }) async {
    try {
      final effectiveProfileRef = profileRef.trim();
      if (effectiveProfileRef.isEmpty) {
        return false;
      }

      final hasLearningMaterial = artifact.redactedText.trim().isNotEmpty ||
          artifact.learningVocabulary.isNotEmpty ||
          artifact.learningPhrases.isNotEmpty ||
          artifact.safeQuestions.isNotEmpty ||
          artifact.safePreferenceSignals.isNotEmpty;
      if (!hasLearningMaterial) {
        developer.log(
          'Skipping sanitized analysis: no learning material for $effectiveProfileRef',
          name: _logName,
        );
        return false;
      }

      developer.log(
        'Analyzing sanitized language artifact: profileRef=$effectiveProfileRef, surface=$surface, scope=$learningScope',
        name: _logName,
      );

      final profile = await getLanguageProfileByRef(effectiveProfileRef) ??
          LanguageProfile.initial(
            effectiveProfileRef,
            displayRef ?? effectiveProfileRef,
          );

      final analysis = _analyzeSanitizedArtifact(artifact);
      final updatedProfile = _updateProfileWithAnalysis(
        profile,
        analysis,
        metadata: <String, dynamic>{
          'learningScope': learningScope,
          'lastSurface': surface,
          'profileRef': effectiveProfileRef,
        },
      );

      await _saveLanguageProfile(effectiveProfileRef, updatedProfile);
      await _appendLearningEvent(
        LanguageLearningEvent(
          profileRef: effectiveProfileRef,
          displayRef: profile.userId,
          learningScope: learningScope,
          surface: surface,
          source: 'sanitized_artifact',
          summary: _buildSanitizedLearningSummary(
            learningScope: learningScope,
            surface: surface,
          ),
          vocabularySample: _topScoredKeys(analysis.vocabulary, limit: 4),
          phraseSample: _topScoredKeys(analysis.phrases, limit: 3),
          toneSnapshot: Map<String, double>.from(analysis.tone),
          messageCountAfter: updatedProfile.messageCount,
          confidenceAfter: updatedProfile.learningConfidence,
          timestamp: updatedProfile.lastUpdated,
        ),
      );

      developer.log(
        '✅ Sanitized language profile updated: profileRef=$effectiveProfileRef, messages=${updatedProfile.messageCount}, confidence=${updatedProfile.learningConfidence.toStringAsFixed(2)}',
        name: _logName,
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error analyzing sanitized language artifact: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get language profile for user
  ///
  /// [userId] - User-facing identifier
  /// Returns LanguageProfile if found, null otherwise
  Future<LanguageProfile?> getLanguageProfile(String userId) async {
    try {
      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Retrieve using agentId
      final data = _box.read<Map<String, dynamic>>('$_dataKeyPrefix$agentId');

      if (data == null) {
        return null;
      }

      return LanguageProfile.fromJson(data);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting language profile: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<List<LanguageLearningEvent>> getRecentLearningEventsByUser(
    String userId, {
    int limit = 8,
  }) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      return getRecentLearningEventsByRef(agentId, limit: limit);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting learning events for user: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return const <LanguageLearningEvent>[];
    }
  }

  Future<List<LanguageLearningEvent>> getRecentLearningEventsByRef(
    String profileRef, {
    int limit = 8,
  }) async {
    try {
      final normalizedRef = profileRef.trim();
      if (normalizedRef.isEmpty) {
        return const <LanguageLearningEvent>[];
      }

      final stored =
          _box.read<List<dynamic>>('$_eventKeyPrefix$normalizedRef') ??
              const <dynamic>[];
      final events = stored
          .map((entry) => LanguageLearningEvent.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ))
          .toList(growable: false)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (events.length <= limit) {
        return events;
      }
      return events.take(limit).toList(growable: false);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting learning events by ref: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return const <LanguageLearningEvent>[];
    }
  }

  /// Get a language profile directly by profile ref.
  ///
  /// Used for governance/operator profiles that should not derive from a
  /// user-facing identifier.
  Future<LanguageProfile?> getLanguageProfileByRef(String profileRef) async {
    try {
      final normalizedRef = profileRef.trim();
      if (normalizedRef.isEmpty) {
        return null;
      }

      final data =
          _box.read<Map<String, dynamic>>('$_dataKeyPrefix$normalizedRef');
      if (data == null) {
        return null;
      }

      return LanguageProfile.fromJson(data);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting language profile by ref: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get current language style summary for LLM context
  ///
  /// Returns a formatted string describing the user's language style,
  /// suitable for inclusion in LLM system prompts.
  Future<String> getLanguageStyleSummary(String userId) async {
    final profile = await getLanguageProfile(userId);

    if (profile == null || !profile.isReadyForAdaptation) {
      return ''; // Not enough data yet
    }

    final buffer = StringBuffer();
    buffer.writeln('User\'s Communication Style:');

    // Vocabulary (top 10 most frequent words)
    if (profile.vocabulary.isNotEmpty) {
      final topWords = profile.vocabulary.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top10 = topWords.take(10).map((e) => e.key).join(', ');
      buffer.writeln('- Vocabulary: $top10');
    }

    // Phrases (top 5 most frequent phrases)
    if (profile.phrases.isNotEmpty) {
      final topPhrases = profile.phrases.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = topPhrases.take(5).map((e) => e.key).join(', ');
      buffer.writeln('- Common phrases: $top5');
    }

    // Sentence structure
    if (profile.averageSentenceLength > 0) {
      buffer.writeln(
          '- Average sentence length: ${profile.averageSentenceLength.toStringAsFixed(1)} words');
    }

    // Tone
    buffer.writeln(
        '- Formality: ${_formatTone(profile.tone['formality'] ?? 0.5)}');
    buffer.writeln(
        '- Enthusiasm: ${_formatTone(profile.tone['enthusiasm'] ?? 0.5)}');
    buffer.writeln(
        '- Directness: ${_formatTone(profile.tone['directness'] ?? 0.5)}');

    buffer.writeln(
        '\nMatch the user\'s style gradually - do not copy exactly, but adapt naturally.');

    return buffer.toString();
  }

  /// Calculate how well a text matches user's language style
  ///
  /// Returns a score from 0.0-1.0 indicating style match
  Future<double> calculateStyleMatch(String userId, String text) async {
    final profile = await getLanguageProfile(userId);

    if (profile == null || !profile.isReadyForAdaptation) {
      return 0.5; // Neutral if no profile yet
    }

    final textAnalysis = _analyzeMessageContent(text);
    double matchScore = 0.0;
    int factors = 0;

    // Check vocabulary match
    if (profile.vocabulary.isNotEmpty && textAnalysis.vocabulary.isNotEmpty) {
      int matches = 0;
      for (final word in textAnalysis.vocabulary.keys) {
        if (profile.vocabulary.containsKey(word)) {
          matches++;
        }
      }
      if (textAnalysis.vocabulary.isNotEmpty) {
        matchScore += matches / textAnalysis.vocabulary.length;
        factors++;
      }
    }

    // Check phrase match
    if (profile.phrases.isNotEmpty && textAnalysis.phrases.isNotEmpty) {
      int matches = 0;
      for (final phrase in textAnalysis.phrases.keys) {
        if (profile.phrases.containsKey(phrase)) {
          matches++;
        }
      }
      if (textAnalysis.phrases.isNotEmpty) {
        matchScore += matches / textAnalysis.phrases.length;
        factors++;
      }
    }

    // Check tone match (similarity)
    if (profile.tone.isNotEmpty && textAnalysis.tone.isNotEmpty) {
      double toneMatch = 0.0;
      int toneFactors = 0;
      for (final indicator in ['formality', 'enthusiasm', 'directness']) {
        final profileValue = profile.tone[indicator] ?? 0.5;
        final textValue = textAnalysis.tone[indicator] ?? 0.5;
        final similarity = 1.0 - (profileValue - textValue).abs();
        toneMatch += similarity;
        toneFactors++;
      }
      if (toneFactors > 0) {
        matchScore += toneMatch / toneFactors;
        factors++;
      }
    }

    return factors > 0 ? matchScore / factors : 0.5;
  }

  // ========================================================================
  // PRIVATE METHODS
  // ========================================================================

  /// Analyze message content and extract language patterns
  MessageAnalysis _analyzeMessageContent(String message) {
    final words = _tokenize(message);
    final sentences = _splitIntoSentences(message);

    // Extract vocabulary (common words, excluding stop words)
    final vocabulary = _extractVocabulary(words);

    // Extract phrases (2-3 word combinations)
    final phrases = _extractPhrases(words);

    // Analyze sentence structure
    final sentenceStructure = _analyzeSentenceStructure(sentences);

    // Analyze tone
    final tone = _analyzeTone(message, words);

    return MessageAnalysis(
      vocabulary: vocabulary,
      phrases: phrases,
      sentenceStructure: sentenceStructure,
      tone: tone,
    );
  }

  MessageAnalysis _analyzeSanitizedArtifact(
    BoundarySanitizedArtifact artifact,
  ) {
    final synthesizedMessageParts = <String>[
      artifact.redactedText,
      artifact.summary,
      ...artifact.safeQuestions,
      ...artifact.safePreferenceSignals.map((entry) => entry.value),
      ...artifact.learningPhrases,
    ].where((entry) => entry.trim().isNotEmpty).toList(growable: false);

    final baseAnalysis = _analyzeMessageContent(
      synthesizedMessageParts.join('. '),
    );

    final mergedVocabulary = Map<String, double>.from(baseAnalysis.vocabulary);
    for (final token in artifact.learningVocabulary) {
      final normalized = token.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      final existing = mergedVocabulary[normalized] ?? 0.0;
      mergedVocabulary[normalized] = math.max(existing, 1.0);
    }

    final mergedPhrases = Map<String, double>.from(baseAnalysis.phrases);
    for (final phrase in artifact.learningPhrases) {
      final normalized = phrase.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      final existing = mergedPhrases[normalized] ?? 0.0;
      mergedPhrases[normalized] = math.max(existing, 1.0);
    }

    final mergedTone = Map<String, double>.from(baseAnalysis.tone);
    if (artifact.safeQuestions.isNotEmpty) {
      mergedTone['directness'] =
          math.max(mergedTone['directness'] ?? 0.5, 0.62);
    }
    if (artifact.safePreferenceSignals.isNotEmpty) {
      mergedTone['enthusiasm'] =
          math.max(mergedTone['enthusiasm'] ?? 0.5, 0.55);
    }

    return MessageAnalysis(
      vocabulary: mergedVocabulary,
      phrases: mergedPhrases,
      sentenceStructure: baseAnalysis.sentenceStructure,
      tone: mergedTone,
    );
  }

  /// Tokenize message into words (lowercase, remove punctuation)
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.length > 1)
        .toList();
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Extract vocabulary patterns (common words, excluding stop words)
  Map<String, double> _extractVocabulary(List<String> words) {
    // Common stop words to exclude
    const stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'was',
      'are',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'can',
      'this',
      'that',
      'these',
      'those',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'me',
      'him',
      'her',
      'us',
      'them',
      'my',
      'your',
      'his',
      'its',
      'our',
      'their',
      'what',
      'which',
      'who',
      'whom',
      'whose',
      'where',
      'when',
      'why',
      'how',
      'all',
      'each',
      'every',
      'both',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'no',
      'nor',
      'not',
      'only',
      'own',
      'same',
      'so',
      'than',
      'too',
      'very',
      'just',
      'now',
    };

    final wordFreq = <String, int>{};
    for (final word in words) {
      if (!stopWords.contains(word) && word.length > 2) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    // Convert to frequency scores (0.0-1.0)
    final maxFreq =
        wordFreq.values.isEmpty ? 1 : wordFreq.values.reduce(math.max);
    return wordFreq.map((word, freq) => MapEntry(word, freq / maxFreq));
  }

  /// Extract phrase patterns (2-3 word combinations)
  Map<String, double> _extractPhrases(List<String> words) {
    final phraseFreq = <String, int>{};

    // Extract 2-word phrases
    for (int i = 0; i < words.length - 1; i++) {
      final phrase = '${words[i]} ${words[i + 1]}';
      phraseFreq[phrase] = (phraseFreq[phrase] ?? 0) + 1;
    }

    // Extract 3-word phrases
    for (int i = 0; i < words.length - 2; i++) {
      final phrase = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
      phraseFreq[phrase] = (phraseFreq[phrase] ?? 0) + 1;
    }

    // Convert to frequency scores (0.0-1.0)
    if (phraseFreq.isEmpty) return {};
    final maxFreq = phraseFreq.values.reduce(math.max);
    return phraseFreq.map((phrase, freq) => MapEntry(phrase, freq / maxFreq));
  }

  /// Analyze sentence structure
  Map<String, dynamic> _analyzeSentenceStructure(List<String> sentences) {
    if (sentences.isEmpty) {
      return {
        'averageLength': 0.0,
        'punctuationUsage': <String, double>{},
      };
    }

    // Calculate average sentence length
    final totalWords = sentences.fold<int>(
      0,
      (sum, sentence) =>
          sum +
          sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
    final avgLength = totalWords / sentences.length;

    // Analyze punctuation usage
    final punctFreq = <String, int>{};
    for (final sentence in sentences) {
      if (sentence.contains('!')) punctFreq['!'] = (punctFreq['!'] ?? 0) + 1;
      if (sentence.contains('?')) punctFreq['?'] = (punctFreq['?'] ?? 0) + 1;
      if (sentence.contains('...')) {
        punctFreq['...'] = (punctFreq['...'] ?? 0) + 1;
      }
      if (sentence.contains(',')) punctFreq[','] = (punctFreq[','] ?? 0) + 1;
    }

    // Convert to frequency scores
    final maxPunctFreq =
        punctFreq.values.isEmpty ? 1 : punctFreq.values.reduce(math.max);
    final punctUsage =
        punctFreq.map((punct, freq) => MapEntry(punct, freq / maxPunctFreq));

    return {
      'averageLength': avgLength,
      'punctuationUsage': punctUsage,
    };
  }

  /// Analyze tone indicators
  Map<String, double> _analyzeTone(String message, List<String> words) {
    // Formality indicators
    final formalWords = {
      'please',
      'thank',
      'appreciate',
      'regarding',
      'furthermore',
      'however'
    };
    final casualWords = {
      'yeah',
      'yep',
      'nah',
      'gonna',
      'wanna',
      'gotta',
      'cool',
      'awesome'
    };

    int formalCount = 0;
    int casualCount = 0;
    for (final word in words) {
      if (formalWords.contains(word)) formalCount++;
      if (casualWords.contains(word)) casualCount++;
    }

    // Formality score: 0.0 = very casual, 1.0 = very formal
    final formality = formalCount > casualCount
        ? math.min(0.9, 0.5 + (formalCount - casualCount) * 0.1)
        : math.max(0.1, 0.5 - (casualCount - formalCount) * 0.1);

    // Enthusiasm indicators
    final enthusiasticWords = {
      'awesome',
      'amazing',
      'love',
      'great',
      'fantastic',
      'excited'
    };
    final reservedWords = {'okay', 'fine', 'sure', 'maybe', 'perhaps'};

    int enthusiasticCount = 0;
    int reservedCount = 0;
    for (final word in words) {
      if (enthusiasticWords.contains(word)) enthusiasticCount++;
      if (reservedWords.contains(word)) reservedCount++;
    }
    if (message.contains('!')) enthusiasticCount++;

    // Enthusiasm score: 0.0 = low energy, 1.0 = high energy
    final enthusiasm = enthusiasticCount > reservedCount
        ? math.min(0.9, 0.5 + enthusiasticCount * 0.1)
        : math.max(0.1, 0.5 - reservedCount * 0.1);

    // Directness indicators
    final directWords = {'yes', 'no', 'definitely', 'absolutely', 'exactly'};
    final indirectWords = {
      'maybe',
      'perhaps',
      'might',
      'could',
      'possibly',
      'sort of',
      'kind of'
    };

    int directCount = 0;
    int indirectCount = 0;
    for (final word in words) {
      if (directWords.contains(word)) directCount++;
      if (indirectWords.contains(word)) indirectCount++;
    }

    // Directness score: 0.0 = indirect, 1.0 = very direct
    final directness = directCount > indirectCount
        ? math.min(0.9, 0.5 + directCount * 0.1)
        : math.max(0.1, 0.5 - indirectCount * 0.1);

    return {
      'formality': formality.clamp(0.0, 1.0),
      'enthusiasm': enthusiasm.clamp(0.0, 1.0),
      'directness': directness.clamp(0.0, 1.0),
    };
  }

  /// Update profile with new analysis
  LanguageProfile _updateProfileWithAnalysis(
      LanguageProfile profile, MessageAnalysis analysis,
      {Map<String, dynamic>? metadata}) {
    // Calculate confidence based on message count
    final newMessageCount = profile.messageCount + 1;
    final confidence = math.min(
        1.0, newMessageCount / 100.0); // Max confidence at 100 messages

    final mergedMetadata = <String, dynamic>{
      'messageCount': 1,
      'learningConfidence': confidence,
      ...?metadata,
    };

    return profile.copyWith(
      vocabulary: analysis.vocabulary,
      phrases: analysis.phrases,
      sentenceStructure: analysis.sentenceStructure,
      tone: analysis.tone,
      metadata: mergedMetadata,
    );
  }

  /// Save language profile to storage
  Future<void> _saveLanguageProfile(
      String profileRef, LanguageProfile profile) async {
    try {
      await _box.write('$_dataKeyPrefix$profileRef', profile.toJson());
    } catch (e, stackTrace) {
      developer.log(
        'Error saving language profile: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _appendLearningEvent(LanguageLearningEvent event) async {
    try {
      final key = '$_eventKeyPrefix${event.profileRef}';
      final stored = _box.read<List<dynamic>>(key) ?? const <dynamic>[];
      final events = stored
          .map((entry) => LanguageLearningEvent.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ))
          .toList();
      events.add(event);
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final bounded = events
          .take(_maxStoredEventsPerProfile)
          .map((entry) => entry.toJson())
          .toList(growable: false);
      await _box.write(key, bounded);
    } catch (e, stackTrace) {
      developer.log(
        'Error appending learning event: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<String> _topScoredKeys(
    Map<String, double> scoredEntries, {
    int limit = 4,
  }) {
    final entries = scoredEntries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((entry) => entry.key)
        .where((entry) => entry.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _buildSanitizedLearningSummary({
    required String learningScope,
    required String surface,
  }) {
    if (learningScope == 'governance_feedback_rewrite') {
      return 'Learned from an approved admin rewrite.';
    }
    if (learningScope == 'governance_feedback_acceptance') {
      return 'Learned from an approved admin response.';
    }
    if (surface.contains('check_in')) {
      return 'Learned from a governance check-in prompt.';
    }
    return 'Learned from a sanitized ${surface.replaceAll('_', ' ')} interaction.';
  }

  /// Format tone value for display
  String _formatTone(double? value) {
    if (value == null) return 'neutral';
    if (value < 0.3) return 'low';
    if (value < 0.7) return 'medium';
    return 'high';
  }
}

/// Internal class for message analysis results
class MessageAnalysis {
  final Map<String, double> vocabulary;
  final Map<String, double> phrases;
  final Map<String, dynamic> sentenceStructure;
  final Map<String, double> tone;

  MessageAnalysis({
    required this.vocabulary,
    required this.phrases,
    required this.sentenceStructure,
    required this.tone,
  });
}
