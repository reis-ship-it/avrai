part of 'llm_service.dart';
// MIGRATION_SHIM: Backend implementations remain in legacy path until runtime
// kernel/service contracts are fully promoted and consumers are rewired.

/// Chat message with role and content
class ChatMessage {
  final ChatRole role;
  final String content;

  ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, String> toJson() => {
        'role': role.name,
        'content': content,
      };
}

/// Chat message roles
enum ChatRole {
  user,
  assistant,
  system,
}

/// Context for LLM requests with full AI/ML system integration
class LLMContext {
  final String? userId;
  final Position? location;
  final Map<String, dynamic>? preferences;
  final List<Map<String, dynamic>>? recentSpots;

  // AI/ML System Integration
  final PersonalityProfile? personality;
  final UserVibe? vibe;
  final List<pl.AI2AILearningInsight>? ai2aiInsights;
  final ConnectionMetrics? connectionMetrics;

  // Language Learning Integration (Phase 2.4)
  final String?
      languageStyle; // Formatted language style summary from LanguageProfile

  // Conversation preferences from ConversationPreferenceStore
  final Map<String, dynamic>? conversationPreferences;

  LLMContext({
    this.userId,
    this.location,
    this.preferences,
    this.recentSpots,
    // AI/ML Integration
    this.personality,
    this.vibe,
    this.ai2aiInsights,
    this.connectionMetrics,
    // Language Learning
    this.languageStyle,
    // Conversation preferences
    this.conversationPreferences,
  });

  Map<String, dynamic>? get conversationPreferenceTiming {
    final preferences = conversationPreferences;
    if (preferences == null || preferences.isEmpty) {
      return null;
    }

    final effectiveKnowledgeAt = _parseKnowledgeTime(
            preferences['governed_knowledge_captured_at']) ??
        _parseKnowledgeTime(preferences['governed_knowledge_occurred_at']) ??
        _parseKnowledgeTime(
          preferences['governed_knowledge_integrated_at'],
        ) ??
        _parseKnowledgeTime(preferences['governed_knowledge_synced_at']);
    final freshness = switch (_conversationKnowledgeFreshness(preferences)) {
      _ConversationKnowledgeFreshness.none => null,
      _ConversationKnowledgeFreshness.presentUnknownAge => 'unknown_age',
      _ConversationKnowledgeFreshness.fresh => 'fresh',
      _ConversationKnowledgeFreshness.stale => 'stale',
    };

    final timing = <String, dynamic>{
      if (preferences['governed_knowledge_timing_summary'] != null)
        'summary': preferences['governed_knowledge_timing_summary'],
      if (preferences['governed_knowledge_phase'] != null)
        'phase': preferences['governed_knowledge_phase'],
      if (effectiveKnowledgeAt != null)
        'effectiveKnowledgeAt': effectiveKnowledgeAt.toUtc().toIso8601String(),
      if (_parseKnowledgeTime(preferences['governed_knowledge_occurred_at'])
          case final occurredAt?)
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      if (_parseKnowledgeTime(preferences['governed_knowledge_captured_at'])
          case final capturedAt?)
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      if (_parseKnowledgeTime(preferences['governed_knowledge_integrated_at'])
          case final integratedAt?)
        'integratedAt': integratedAt.toUtc().toIso8601String(),
      if (_parseKnowledgeTime(preferences['governed_knowledge_synced_at'])
          case final syncedAt?)
        'syncedAt': syncedAt.toUtc().toIso8601String(),
      if (freshness != null) 'freshness': freshness,
    };
    return timing.isEmpty ? null : timing;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (userId != null) json['userId'] = userId;
    if (location != null) {
      json['location'] = {
        'lat': location!.latitude,
        'lng': location!.longitude,
      };
    }
    if (preferences != null) json['preferences'] = preferences;
    if (recentSpots != null) json['recentSpots'] = recentSpots;

    // Personality integration
    if (personality != null) {
      json['personality'] = {
        'archetype': personality!.archetype,
        'dimensions': personality!.dimensions,
        'dimensionConfidence': personality!.dimensionConfidence,
        'authenticity': personality!.authenticity,
        'evolutionGeneration': personality!.evolutionGeneration,
        'dominantTraits': personality!.getDominantTraits(),
      };
    }

    // Vibe integration
    if (vibe != null) {
      json['vibe'] = {
        'archetype': vibe!.getVibeArchetype(),
        'overallEnergy': vibe!.overallEnergy,
        'socialPreference': vibe!.socialPreference,
        'explorationTendency': vibe!.explorationTendency,
        'anonymizedDimensions': vibe!.anonymizedDimensions,
        'temporalContext': vibe!.temporalContext,
      };
    }

    // AI2AI insights integration
    if (ai2aiInsights != null && ai2aiInsights!.isNotEmpty) {
      json['ai2aiInsights'] = ai2aiInsights!
          .map((insight) => {
                'type': insight.type.toString(),
                'dimensionInsights': insight.dimensionInsights,
                'learningQuality': insight.learningQuality,
                'timestamp': insight.timestamp.toIso8601String(),
              })
          .toList();
    }

    // Connection metrics integration
    if (connectionMetrics != null) {
      json['connectionMetrics'] = {
        'initialCompatibility': connectionMetrics!.initialCompatibility,
        'currentCompatibility': connectionMetrics!.currentCompatibility,
        'learningEffectiveness': connectionMetrics!.learningEffectiveness,
        'aiPleasureScore': connectionMetrics!.aiPleasureScore,
        'status': connectionMetrics!.status.toString(),
        'learningOutcomes': connectionMetrics!.learningOutcomes,
      };
    }

    // Language style integration (Phase 2.4)
    if (languageStyle != null && languageStyle!.isNotEmpty) {
      json['languageStyle'] = languageStyle;
    }

    // Conversation preferences
    if (conversationPreferences != null &&
        conversationPreferences!.isNotEmpty) {
      json['conversationPreferences'] = conversationPreferences;
      if (conversationPreferenceTiming case final timing?) {
        json['conversationPreferenceTiming'] = timing;
      }
    }

    return json;
  }

  static _ConversationKnowledgeFreshness _conversationKnowledgeFreshness(
    Map<String, dynamic> preferences,
  ) {
    final effectiveKnowledgeAt = _parseKnowledgeTime(
            preferences['governed_knowledge_captured_at']) ??
        _parseKnowledgeTime(preferences['governed_knowledge_occurred_at']) ??
        _parseKnowledgeTime(
          preferences['governed_knowledge_integrated_at'],
        ) ??
        _parseKnowledgeTime(preferences['governed_knowledge_synced_at']);
    if (effectiveKnowledgeAt == null) {
      return _ConversationKnowledgeFreshness.presentUnknownAge;
    }
    final age = DateTime.now().toUtc().difference(effectiveKnowledgeAt);
    if (age <= const Duration(days: 14)) {
      return _ConversationKnowledgeFreshness.fresh;
    }
    return _ConversationKnowledgeFreshness.stale;
  }

  static DateTime? _parseKnowledgeTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString())?.toUtc();
  }
}

/// Exception thrown when cloud AI is requested but device is offline
class OfflineException implements Exception {
  final String message;

  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}

/// Exception thrown when AI data center is unavailable or experiencing issues
class DataCenterFailureException implements Exception {
  final String message;

  DataCenterFailureException(this.message);

  @override
  String toString() => 'DataCenterFailureException: $message';
}

/// Controls how the service is allowed to route requests across backends.
class LLMDispatchPolicy {
  final bool allowCloudFallbackOnLocalFailure;

  const LLMDispatchPolicy({
    required this.allowCloudFallbackOnLocalFailure,
  });

  const LLMDispatchPolicy.standard() : allowCloudFallbackOnLocalFailure = true;

  const LLMDispatchPolicy.humanChat()
      : allowCloudFallbackOnLocalFailure = false;
}

// ============================================================================
// Backends (Cloud vs Local)
// ============================================================================

/// Backend abstraction so we can route to cloud (Gemini) or local runtime
/// (Option B: CoreML on iOS, llama.cpp on Android).
abstract class LlmBackend {
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat, // Optional JSON schema enforcement
  });

  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  });
}

/// Cloud Gemini backend using Supabase Edge Functions (existing behavior).
class CloudGeminiBackend implements LlmBackend {
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    // Connectivity check before making request.
    final isOnline = await service._isOnline();
    if (!isOnline) {
      developer.log('Device is offline, cannot use cloud AI',
          name: LLMService._logName);
      throw OfflineException(
        'Cloud AI requires internet connection. Please check your connection and try again.',
      );
    }

    developer.log('Sending cloud chat request: ${messages.length} messages',
        name: LLMService._logName);

    final response = await service.client.functions
        .invoke(
      'llm-chat',
      body: jsonEncode({
        // IMPORTANT: role must be JSON-encodable (string), not the enum itself.
        'messages': messages.map((m) => m.toJson()).toList(),
        'context': context?.toJson(),
        'temperature': temperature,
        'maxTokens': maxTokens,
      }),
    )
        .timeout(
      timeout,
      onTimeout: () {
        developer.log('LLM request timed out after $timeout',
            name: LLMService._logName);
        throw TimeoutException(
          'LLM request timed out. The AI service may be experiencing issues.',
        );
      },
    );

    if (response.status != 200) {
      final errorData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final errorMessage = errorData['error'] ?? 'Unknown error';

      // Check if it's a data center failure (5xx errors)
      if (response.status >= 500) {
        throw DataCenterFailureException(
          'AI data center is experiencing issues (${response.status}). Please try again later.',
        );
      }

      throw Exception('LLM request failed: ${response.status} - $errorMessage');
    }

    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    final responseText = data['response'] as String?;
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from LLM');
    }

    developer.log('Received cloud LLM response: ${responseText.length} chars',
        name: LLMService._logName);
    return responseText;
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    // Preserve existing streaming behavior: use SSE or simulated.
    if (useRealSse) {
      yield* service._chatStreamSSE(messages, context, temperature, maxTokens);
    } else {
      yield* service._chatStreamSimulated(
          messages, context, temperature, maxTokens);
    }
  }
}

/// Fallback cloud backend using `llm-generation`.
///
/// This is a **provider-routing/failover** path. It intentionally degrades
/// conversation-history fidelity (query-first) in exchange for availability.
class CloudGeminiGenerationBackend implements LlmBackend {
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    final isOnline = await service._isOnline();
    if (!isOnline) {
      throw OfflineException(
        'Cloud AI requires internet connection. Please check your connection and try again.',
      );
    }

    final query = _extractQuery(messages);
    final structuredContext = <String, dynamic>{
      'traits': context?.personality?.getDominantTraits() ?? const <String>[],
      'places': context?.recentSpots ?? const <Map<String, dynamic>>[],
      'social_graph': const <dynamic>[],
      'onboarding_data': <String, dynamic>{
        if (context?.preferences != null) 'preferences': context!.preferences,
      },
      if (context?.conversationPreferences != null &&
          context!.conversationPreferences!.isNotEmpty)
        'conversation_preferences': context.conversationPreferences,
      if (context?.conversationPreferenceTiming != null)
        'conversation_preference_timing': context!.conversationPreferenceTiming,
    };

    final response = await service.client.functions
        .invoke(
          'llm-generation',
          body: jsonEncode({
            'query': query,
            'structuredContext': structuredContext,
            'dimensionScores':
                context?.personality?.dimensions ?? const <String, double>{},
            'personalityProfile': context?.personality?.toJson(),
          }),
        )
        .timeout(timeout);

    if (response.status != 200) {
      final errorData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final errorMessage = errorData['error'] ?? 'Unknown error';
      throw Exception(
        'LLM fallback request failed: ${response.status} - $errorMessage',
      );
    }

    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final responseText = data['response'] as String?;
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from fallback LLM');
    }
    return responseText;
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    // No streaming support for this backend; callers can use simulated streaming.
    yield await chat(
      service: service,
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
      timeout: const Duration(seconds: 30),
    );
  }

  static String _extractQuery(List<ChatMessage> messages) {
    // Prefer the most recent user message.
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == ChatRole.user) return messages[i].content;
    }
    // Fallback: last message or empty.
    return messages.isNotEmpty ? messages.last.content : '';
  }
}

/// Cloud backend wrapper that attempts a fallback backend on transient failures.
class CloudFailoverBackend implements LlmBackend {
  final LlmBackend primary;
  final LlmBackend fallback;

  const CloudFailoverBackend({
    required this.primary,
    required this.fallback,
  });

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    try {
      return await primary.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } on OfflineException {
      rethrow;
    } on DataCenterFailureException catch (e) {
      developer.log('Primary cloud backend unavailable, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } on TimeoutException catch (e) {
      developer.log('Primary cloud backend timed out, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } catch (e) {
      // Best-effort: also fail over on obvious rate limiting.
      final msg = e.toString();
      final looksRateLimited =
          msg.contains('429') || msg.toLowerCase().contains('rate');
      if (!looksRateLimited) rethrow;

      developer.log('Primary cloud backend rate-limited, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    }
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) {
    // Keep streaming behavior stable: use primary stream path.
    // (SSE already has non-streaming fallback higher up.)
    return primary.chatStream(
      service: service,
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
      useRealSse: useRealSse,
      autoFallback: autoFallback,
    );
  }
}

/// Unified Mobile/Edge backend using MLC-LLM (Machine Learning Compilation).
/// Runs Qwen 2.5 3B / Llama 3.2 1B natively on iOS (Metal) and Android (Vulkan/OpenCL).
class MlcLlmBackend implements LlmBackend {
  static const MethodChannel _channel = MethodChannel('avrai/mlc_llm');
  static const EventChannel _streamChannel =
      EventChannel('avrai/mlc_llm_stream');

  String? _loadedModelDir;

  Future<void> _ensureLoaded(String modelDir) async {
    if (_loadedModelDir == modelDir) return;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'loadModel',
        <String, dynamic>{'model_dir': modelDir},
      );
      if (ok != true) {
        throw Exception('MLC-LLM loadModel returned false');
      }
      _loadedModelDir = modelDir;
    } on PlatformException catch (e) {
      throw Exception(
          'MLC-LLM loadModel platform error: ${e.code} ${e.message}');
    }
  }

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      final modelDir =
          prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
      if (modelDir.isEmpty) {
        throw Exception('MLC model not installed (missing model_dir)');
      }
      await _ensureLoaded(modelDir);

      final payload = <String, dynamic>{
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': temperature,
        'maxTokens': maxTokens,
        if (responseFormat != null) 'response_format': responseFormat,
      };

      final res = await _channel
          .invokeMethod<String>('generate', payload)
          .timeout(timeout);

      if (res == null || res.isEmpty) {
        throw Exception('Empty MLC-LLM response');
      }
      return res;
    } on PlatformException catch (e) {
      throw Exception('MLC-LLM platform error: ${e.code} ${e.message}');
    } on TimeoutException {
      throw TimeoutException('MLC-LLM timed out');
    }
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    final prefs = await SharedPreferencesCompat.getInstance();
    final modelDir =
        prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    if (modelDir.isEmpty) {
      throw Exception('MLC model not installed (missing model_dir)');
    }
    await _ensureLoaded(modelDir);

    final payload = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'maxTokens': maxTokens,
    };

    String acc = '';
    try {
      await _channel.invokeMethod<void>('startStream', payload);
      final stream = _streamChannel.receiveBroadcastStream();
      await for (final event in stream) {
        if (event is Map) {
          final type = event['type'];
          if (type == 'token') {
            final token = event['text'];
            if (token is String && token.isNotEmpty) {
              acc += token;
              yield acc;
            }
          } else if (type == 'done') {
            return;
          } else if (type == 'error') {
            throw Exception(event['message']?.toString() ?? 'MLC stream error');
          }
        }
      }
    } on PlatformException catch (e) {
      throw Exception('MLC stream platform error: ${e.code} ${e.message}');
    }
  }
}

/// Dedicated desktop node backend (macOS, Windows, Linux)
/// Optimized for running larger models like Phi-4 Mini (3.8B) for high-density reasoning
class DesktopPhi4LlmBackend implements LlmBackend {
  // Stub implementation mirroring MLC, can use FFI or desktop channels
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    return "Desktop Phi-4 Backend Output (Stub)";
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    yield "Desktop Phi-4 Stream Output (Stub)";
  }
}
