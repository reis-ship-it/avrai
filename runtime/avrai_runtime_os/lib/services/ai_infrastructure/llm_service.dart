import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
// MIGRATION_SHIM: Legacy ai_infrastructure path is temporarily retained while
// runtime/app-layer LLM contracts are migrated in controlled slices.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/services/infrastructure/config_service.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/on_device_ai_capability_gate.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/bert_squad/bert_squad_backend.dart';
import 'package:avrai_runtime_os/services/bert_squad/query_classifier.dart';
import 'package:http/http.dart' as http;

part 'llm_service_backends.dart';

/// LLM Service for Google Gemini integration
/// Provides LLM-powered chat and text generation for SPOTS AI features
/// Handles offline scenarios gracefully with connectivity checks
/// Implements resilience patterns: timeouts, circuit breaker, error handling
///
/// TODO: Standardize error handling to use AppLogger (see week_42_error_handling_standard.md)
class LLMService {
  static const String _logName = 'LLMService';
  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';
  static const String _prefsKeyLocalLlmActiveModelDir =
      'local_llm_active_model_dir_v1';
  static const String _prefsKeyLocalLlmActiveModelId =
      'local_llm_active_model_id_v1';

  // Resilience configuration
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _circuitBreakerOpenDuration = Duration(minutes: 5);
  static const int _circuitBreakerFailureThreshold = 5;

  final SupabaseClient client;
  final Connectivity connectivity;

  // Local LLM backend (Option B: iOS CoreML + Android llama.cpp).
  // This is intentionally optional: if the platform integration isn't present,
  // we fall back to cloud (when online).
  final LlmBackend _cloudBackend;
  final LlmBackend _localBackend;
  final LlmBackend? _bertSquadBackend; // Optional BERT-SQuAD for dataset Q&A
  final Future<bool> Function({required bool isOnline})?
      _shouldUseLocalOverride;
  final Future<bool> Function()? _isOnlineOverride;

  // Circuit breaker state
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenedAt;
  bool _circuitBreakerOpen = false;

  LLMService(
    this.client, {
    Connectivity? connectivity,
    LlmBackend? cloudBackend,
    LlmBackend? localBackend,
    LlmBackend? bertSquadBackend,
    Future<bool> Function({required bool isOnline})? shouldUseLocalOverride,
    Future<bool> Function()? isOnlineOverride,
  })  : connectivity = connectivity ?? Connectivity(),
        _cloudBackend = cloudBackend ??
            CloudFailoverBackend(
              primary: CloudGeminiBackend(),
              fallback: CloudGeminiGenerationBackend(),
            ),
        _localBackend = localBackend ?? _createLocalBackend(),
        _bertSquadBackend = bertSquadBackend ?? _createBertSquadBackend(),
        _shouldUseLocalOverride = shouldUseLocalOverride,
        _isOnlineOverride = isOnlineOverride;

  static LlmBackend _createLocalBackend() {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return DesktopPhi4LlmBackend();
    }
    // iOS and Android use unified MLC-LLM engine
    return MlcLlmBackend();
  }

  /// Create BERT-SQuAD backend if available (macOS only).
  static LlmBackend? _createBertSquadBackend() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        return BertSquadBackend();
      } catch (e) {
        developer.log('BERT-SQuAD backend not available: $e', name: _logName);
        return null;
      }
    }
    return null;
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    final override = _isOnlineOverride;
    if (override != null) {
      try {
        return await override();
      } catch (_) {
        // Fall through to connectivity-based check.
      }
    }
    try {
      final result = await connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      developer.log('Connectivity check failed, assuming offline: $e',
          name: _logName);
      return false;
    }
  }

  Future<SharedPreferencesCompat> _getPrefs() async {
    return SharedPreferencesCompat.getInstance();
  }

  Future<bool> _shouldUseLocalLlm({required bool isOnline}) async {
    final override = _shouldUseLocalOverride;
    if (override != null) {
      return await override(isOnline: isOnline);
    }

    // Local LLM is opt-in and device-gated. If not enabled or not eligible,
    // keep using cloud (when online).
    try {
      final prefs = await _getPrefs();
      final enabled = prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;
      if (!enabled) return false;

      // Require a locally installed/activated model directory.
      final activeDir = prefs.getString(_prefsKeyLocalLlmActiveModelDir);
      if (activeDir == null || activeDir.isEmpty) return false;
      final activeModelId = prefs.getString(_prefsKeyLocalLlmActiveModelId);
      if (activeModelId == null || activeModelId.isEmpty) return false;

      // Enforce device capability gate (mid/high only).
      final caps = await DeviceCapabilityService().getCapabilities();
      final gate = OnDeviceAiCapabilityGate().evaluate(caps);
      if (!gate.eligible) return false;

      // If we're offline, local is the only way to do real chat.
      // If we're online, we still prefer local when enabled (quality + privacy),
      // but will fall back to cloud if local errors.
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LlmBackend> _selectBackend({
    required List<ChatMessage> messages,
    LLMContext? context,
  }) async {
    // Check if query should use BERT-SQuAD (for dataset questions)
    if (_bertSquadBackend != null && messages.isNotEmpty) {
      final lastMessage = messages.lastWhere(
        (m) => m.role == ChatRole.user,
        orElse: () => messages.last,
      );

      final queryClassifier = QueryClassifier();
      final isDatasetQuestion =
          await queryClassifier.isDatasetQuestion(lastMessage.content);

      if (isDatasetQuestion) {
        try {
          // Try BERT-SQuAD first for dataset questions
          return _bertSquadBackend;
        } catch (e) {
          developer.log(
            'BERT-SQuAD not available, falling back to other backend: $e',
            name: _logName,
          );
          // Fall through to normal backend selection
        }
      }
    }

    // Normal backend selection (local vs cloud)
    final online = await _isOnline();
    final useLocal = await _shouldUseLocalLlm(isOnline: online);
    if (!online && !useLocal) {
      // Offline and local LLM is not available/enabled.
      // Do not attempt cloud calls when we already know they cannot succeed.
      throw OfflineException(
        'No internet connection. Enable the offline LLM to use AI features offline.',
      );
    }
    return useLocal ? _localBackend : _cloudBackend;
  }

  Future<List<ChatMessage>> _augmentMessagesForLocalIfPossible(
    List<ChatMessage> messages,
    LLMContext? context,
  ) async {
    // Only inject memory for local backends.
    // Cloud already has a dedicated system-context builder in the Edge Function.
    final userId = context?.userId ?? client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return messages;

    try {
      final sl = GetIt.instance;
      final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
          ? sl<LocalLlmPostInstallBootstrapService>()
          : LocalLlmPostInstallBootstrapService();
      final prompt = await bootstrap.getOrBuildSystemPromptForUser(userId);
      if (prompt == null || prompt.trim().isEmpty) return messages;

      // Avoid duplicating system prompts if caller already provided one.
      if (messages.isNotEmpty && messages.first.role == ChatRole.system) {
        return messages;
      }

      return [
        ChatMessage(role: ChatRole.system, content: prompt),
        ...messages,
      ];
    } catch (e, st) {
      developer.log('Failed to augment local messages: $e',
          name: _logName, error: e, stackTrace: st);
      return messages;
    }
  }

  /// Chat with the LLM
  ///
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// [timeout] - Request timeout, default 30 seconds
  ///
  /// Throws [OfflineException] if device is offline
  /// Throws [TimeoutException] if request times out
  /// Throws [DataCenterFailureException] if data center is unavailable
  Future<String> chat({
    required List<ChatMessage> messages,
    LLMContext? context,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
    double temperature = 0.7,
    int maxTokens = 500,
    Duration? timeout,
    String? responseFormat,
  }) async {
    final backend = await _selectBackend(messages: messages, context: context);
    // Treat the configured cloud backend as “cloud” even in tests where we
    // inject a recording backend.
    final isCloud = identical(backend, _cloudBackend);
    final messagesToSend = isCloud
        ? messages
        : await _augmentMessagesForLocalIfPossible(messages, context);

    if (isCloud) {
      // Check circuit breaker (cloud-only).
      if (_circuitBreakerOpen) {
        final timeSinceOpen =
            DateTime.now().difference(_circuitBreakerOpenedAt!);
        if (timeSinceOpen < _circuitBreakerOpenDuration) {
          developer.log('Circuit breaker is open, rejecting request',
              name: _logName);
          throw DataCenterFailureException(
            'AI service temporarily unavailable. Please try again later.',
          );
        } else {
          // Try to close circuit breaker (half-open state)
          developer.log('Attempting to close circuit breaker', name: _logName);
          _circuitBreakerOpen = false;
          _consecutiveFailures = 0;
        }
      }
    }

    try {
      final result = await backend.chat(
        service: this,
        messages: messagesToSend,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout ?? _defaultTimeout,
        responseFormat: responseFormat,
      );
      if (isCloud) _recordSuccess();
      return result;
    } on TimeoutException {
      if (isCloud) _recordFailure();
      rethrow;
    } on DataCenterFailureException {
      if (isCloud) _recordFailure();
      rethrow;
    } on OfflineException {
      rethrow;
    } catch (e) {
      developer.log('LLM service error: $e', name: _logName);

      // Record failure for circuit breaker
      if (isCloud) _recordFailure();

      // If local failed and we are online, fall back to cloud once.
      if (!isCloud && dispatchPolicy.allowCloudFallbackOnLocalFailure) {
        final online = await _isOnline();
        if (online) {
          developer.log('Local LLM failed; falling back to cloud once',
              name: _logName);
          return await _cloudBackend.chat(
            service: this,
            messages: messages,
            context: context,
            temperature: temperature,
            maxTokens: maxTokens,
            timeout: timeout ?? _defaultTimeout,
            responseFormat: responseFormat,
          );
        }
      }

      // Ensure we throw an Exception type (some Dart errors are not Exception).
      throw Exception(e.toString());
    }
  }

  /// Record a successful request (reset circuit breaker)
  void _recordSuccess() {
    _consecutiveFailures = 0;
    _circuitBreakerOpen = false;
    _circuitBreakerOpenedAt = null;
  }

  /// Record a failed request (update circuit breaker)
  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _circuitBreakerFailureThreshold) {
      _circuitBreakerOpen = true;
      _circuitBreakerOpenedAt = DateTime.now();
      developer.log(
        'Circuit breaker opened after $_consecutiveFailures consecutive failures',
        name: _logName,
      );
    }
  }

  /// Generate a recommendation or response based on user query
  ///
  /// [userQuery] - The user's question or request
  /// [userContext] - Context about the user (location, preferences, etc.)
  Future<String> generateRecommendation({
    required String userQuery,
    LLMContext? userContext,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
  }) async {
    return chat(
      messages: [
        ChatMessage(
          role: ChatRole.user,
          content: userQuery,
        )
      ],
      context: userContext,
      dispatchPolicy: dispatchPolicy,
    );
  }

  /// Generate a response in a conversation
  ///
  /// [conversationHistory] - Previous messages in the conversation
  /// [userMessage] - Current user message
  /// [context] - User context
  Future<String> continueConversation({
    required List<ChatMessage> conversationHistory,
    required String userMessage,
    LLMContext? context,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
  }) async {
    final messages = [
      ...conversationHistory,
      ChatMessage(role: ChatRole.user, content: userMessage),
    ];

    return chat(
      messages: messages,
      context: context,
      dispatchPolicy: dispatchPolicy,
    );
  }

  /// Generate list name suggestions based on user intent
  Future<List<String>> suggestListNames({
    required String userIntent,
    LLMContext? context,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
  }) async {
    try {
      final prompt =
          'Based on this user request: "$userIntent", suggest 3-5 creative list names for a location discovery app. Return only the list names, one per line, no numbering or bullets.';

      final response = await chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: prompt),
        ],
        context: context,
        dispatchPolicy: dispatchPolicy,
        maxTokens: 200,
      );

      // Parse response into list names
      final names = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) =>
              line.isNotEmpty && !line.startsWith(RegExp(r'[0-9\-•]')))
          .take(5)
          .toList();

      return names.isEmpty ? ['New List'] : names;
    } catch (e) {
      developer.log('Error generating list names: $e', name: _logName);
      return ['New List'];
    }
  }

  /// Generate spot recommendations based on query
  Future<String> generateSpotRecommendations({
    required String query,
    LLMContext? context,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
  }) async {
    final prompt =
        'User is looking for: "$query". Provide helpful, concise recommendations for places to visit. Focus on authentic local spots.';

    return chat(
      messages: [
        ChatMessage(role: ChatRole.user, content: prompt),
      ],
      context: context,
      dispatchPolicy: dispatchPolicy,
      maxTokens: 300,
    );
  }

  /// Generate LLM response with structured facts context
  ///
  /// Phase 11 Section 5: Retrieval + LLM Fusion
  /// Retrieves structured facts from FactsIndex and personality profile,
  /// then prepares distilled context for LLM.
  ///
  /// [query] - User query
  /// [userId] - Authenticated user ID
  /// [messages] - Optional conversation history (if provided, uses chat() with history)
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  ///
  /// Returns LLM-generated response with enriched context
  ///
  /// Note: If [messages] is provided, uses conversation history. Otherwise, uses single query.
  Future<String> generateWithContext({
    required String query,
    required String userId,
    List<ChatMessage>? messages,
    LLMDispatchPolicy dispatchPolicy = const LLMDispatchPolicy.standard(),
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      developer.log(
          'Generating with structured facts context for user: $userId',
          name: _logName);

      // Get dependencies from GetIt (already imported)
      final factsIndex = GetIt.instance<FactsIndex>();
      final personalityLearning = GetIt.instance<pl.PersonalityLearning>();

      // Step 1: Retrieve structured facts
      final facts = await factsIndex.retrieveFacts(userId: userId);

      // Step 2: Get dimension scores (from PersonalityProfile)
      final profile = await personalityLearning.getCurrentPersonality(userId);
      final dimensionScores = profile?.dimensions ?? {};

      // Step 3: Prepare distilled context for LLM
      final context = LLMContext(
        userId: userId,
        preferences: {
          'traits': facts.traits,
          'places': facts.places,
          'social_graph': facts.socialGraph,
          'dimension_scores': dimensionScores,
        },
        personality: profile,
      );

      // Step 4: Call LLM with distilled context
      // Use conversation history if provided, otherwise use single query
      final messagesToSend = messages ??
          [
            ChatMessage(role: ChatRole.user, content: query),
          ];

      return await chat(
        messages: messagesToSend,
        context: context,
        dispatchPolicy: dispatchPolicy,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error generating with context: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to basic chat without structured context
      final messagesToSend = messages ??
          [
            ChatMessage(role: ChatRole.user, content: query),
          ];
      return await chat(
        messages: messagesToSend,
        dispatchPolicy: dispatchPolicy,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
  }

  /// Chat with the LLM using streaming for real-time response display
  ///
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  ///
  /// Returns a Stream&lt;String&gt; that emits chunks of text as they arrive
  /// Throws [OfflineException] if device is offline
  ///
  /// Note: Streaming support depends on Edge Function configuration
  /// Falls back to non-streaming if streaming not available
  /// Chat with the LLM using streaming responses
  /// Returns a stream of progressive text chunks for real-time display
  ///
  /// Optional Enhancement: Real SSE Streaming
  /// Set useRealSSE=true to use actual Server-Sent Events from Gemini API
  /// Set useRealSSE=false to use simulated streaming (faster to implement, still smooth UX)
  ///
  /// The SSE implementation includes automatic reconnection and fallback to non-streaming
  /// if SSE fails after retries.
  Stream<String> chatStream({
    required List<ChatMessage> messages,
    LLMContext? context,
    double temperature = 0.7,
    int maxTokens = 500,
    bool useRealSSE = true, // Toggle between real and simulated streaming
    bool autoFallback =
        true, // Automatically fallback to non-streaming if SSE fails
  }) async* {
    final backend = await _selectBackend(messages: messages, context: context);
    final isCloud = identical(backend, _cloudBackend);
    final messagesToSend = isCloud
        ? messages
        : await _augmentMessagesForLocalIfPossible(messages, context);

    if (isCloud) {
      // Check connectivity before making request (cloud-only).
      final isOnline = await _isOnline();
      if (!isOnline) {
        developer.log('Device is offline, cannot use cloud AI', name: _logName);
        throw OfflineException(
            'Cloud AI requires internet connection. Please check your connection and try again.');
      }
    }

    try {
      developer.log(
          'Sending streaming chat request to LLM: ${messages.length} messages (realSSE: $useRealSSE, autoFallback: $autoFallback)',
          name: _logName);

      yield* backend.chatStream(
        service: this,
        messages: messagesToSend,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        useRealSse: useRealSSE,
        autoFallback: autoFallback,
      );

      developer.log('Completed streaming response', name: _logName);
    } catch (e) {
      developer.log('LLM streaming error: $e', name: _logName);

      // If autoFallback is enabled and SSE failed, try non-streaming
      if (autoFallback && useRealSSE) {
        developer.log('Auto-fallback: Attempting non-streaming chat',
            name: _logName);
        try {
          final response = await chat(
            messages: messages,
            context: context,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          yield response;
          return;
        } catch (fallbackError) {
          developer.log('Fallback chat also failed: $fallbackError',
              name: _logName);
          // If fallback also fails, throw original error
        }
      }

      rethrow;
    }
  }

  /// Real SSE streaming from Edge Function with reconnection and error handling
  Stream<String> _chatStreamSSE(
    List<ChatMessage> messages,
    LLMContext? context,
    double temperature,
    int maxTokens,
  ) async* {
    const maxReconnectAttempts = 3;
    const reconnectDelay = Duration(seconds: 2);
    const streamTimeout = Duration(minutes: 5);

    String accumulatedText = '';
    int reconnectAttempts = 0;
    bool shouldFallback = false;

    while (reconnectAttempts <= maxReconnectAttempts) {
      try {
        // Get Supabase URL and key from ConfigService
        // Note: SupabaseClient doesn't expose these directly, so we get from config
        final configService = GetIt.instance<ConfigService>();
        final supabaseUrl = configService.supabaseUrl;
        final supabaseKey = configService.supabaseAnonKey;
        final url = '$supabaseUrl/functions/v1/llm-chat-stream';

        final request = http.Request('POST', Uri.parse(url));
        request.headers.addAll({
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        });
        request.body = jsonEncode({
          'messages': messages.map((m) => m.toJson()).toList(),
          if (context != null) 'context': context.toJson(),
          'temperature': temperature,
          'maxTokens': maxTokens,
        });

        // Create timeout for the entire stream
        final streamedResponse = await request.send().timeout(
          streamTimeout,
          onTimeout: () {
            throw TimeoutException(
                'SSE stream timeout after ${streamTimeout.inMinutes} minutes');
          },
        );

        if (streamedResponse.statusCode != 200) {
          final error = await streamedResponse.stream.bytesToString();
          final errorMessage =
              'SSE stream error: ${streamedResponse.statusCode} - $error';
          developer.log(errorMessage, name: _logName);

          // For 4xx errors, don't retry - fallback immediately
          if (streamedResponse.statusCode >= 400 &&
              streamedResponse.statusCode < 500) {
            shouldFallback = true;
            break;
          }

          // For 5xx errors, retry
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            developer.log(
                'Retrying SSE connection (attempt $reconnectAttempts/$maxReconnectAttempts)...',
                name: _logName);
            await Future.delayed(reconnectDelay);
            continue;
          } else {
            shouldFallback = true;
            break;
          }
        }

        // Process SSE stream
        bool streamCompleted = false;
        bool hasError = false;
        String? streamError;

        await for (final chunk in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(streamTimeout, onTimeout: (sink) {
          developer.log('SSE stream chunk timeout', name: _logName);
          sink.close();
        })) {
          // Parse SSE events
          if (chunk.startsWith('data: ')) {
            final data = chunk.substring(6);

            try {
              final event = jsonDecode(data) as Map<String, dynamic>;

              // Check for completion
              if (event['done'] == true) {
                streamCompleted = true;
                break;
              }

              // Check for error
              if (event['error'] != null) {
                streamError = event['error'] as String? ?? 'Unknown SSE error';
                hasError = true;
                developer.log('SSE error event: $streamError', name: _logName);

                // For certain errors, don't retry
                if (streamError.contains('timeout') ||
                    streamError.contains('safety') ||
                    streamError.contains('blocked')) {
                  shouldFallback = true;
                  break;
                }

                // For connection errors, retry
                if (reconnectAttempts < maxReconnectAttempts) {
                  reconnectAttempts++;
                  developer.log(
                      'Retrying after SSE error (attempt $reconnectAttempts/$maxReconnectAttempts)...',
                      name: _logName);
                  await Future.delayed(reconnectDelay);
                  break; // Break out of stream processing to retry
                } else {
                  shouldFallback = true;
                  break;
                }
              }

              // Extract text chunk
              if (event['text'] != null) {
                final text = event['text'] as String;
                accumulatedText += text;
                yield accumulatedText; // Yield cumulative text

                // Reset reconnect attempts on successful data
                reconnectAttempts = 0;
              }
            } catch (e) {
              developer.log('Error parsing SSE event: $e', name: _logName);
              // Continue processing other events - don't break on parse errors
            }
          }
        }

        // If stream completed successfully, we're done
        if (streamCompleted) {
          // Ensure final text is yielded
          if (accumulatedText.isNotEmpty) {
            yield accumulatedText;
          }
          return;
        }

        // If we got here and have accumulated text, yield it before retrying/falling back
        if (accumulatedText.isNotEmpty && !hasError) {
          yield accumulatedText;
        }

        // If we have an error and exhausted retries, fallback
        if (hasError && reconnectAttempts >= maxReconnectAttempts) {
          shouldFallback = true;
          break;
        }

        // If stream ended unexpectedly but we have text, we're done
        if (accumulatedText.isNotEmpty && !hasError) {
          return;
        }
      } catch (e) {
        developer.log('SSE connection error: $e', name: _logName);

        // Check if it's a timeout
        if (e is TimeoutException) {
          // If we have accumulated text, yield it before falling back
          if (accumulatedText.isNotEmpty) {
            yield accumulatedText;
            return;
          }
          shouldFallback = true;
          break;
        }

        // For other errors, retry if we haven't exhausted attempts
        if (reconnectAttempts < maxReconnectAttempts) {
          reconnectAttempts++;
          developer.log(
              'Retrying after connection error (attempt $reconnectAttempts/$maxReconnectAttempts)...',
              name: _logName);
          await Future.delayed(reconnectDelay);
          continue;
        } else {
          shouldFallback = true;
          break;
        }
      }
    }

    // Fallback to non-streaming if SSE failed
    if (shouldFallback) {
      developer.log('Falling back to non-streaming chat due to SSE failures',
          name: _logName);

      // If we have partial text, yield it first
      if (accumulatedText.isNotEmpty) {
        yield accumulatedText;
      }

      // Fallback to regular chat
      try {
        final response = await chat(
          messages: messages,
          context: context,
          temperature: temperature,
          maxTokens: maxTokens,
        );

        // Yield the complete response
        yield response;
      } catch (e) {
        developer.log('Fallback chat also failed: $e', name: _logName);
        rethrow;
      }
    }
  }

  /// Simulated streaming (fallback for offline or testing)
  Stream<String> _chatStreamSimulated(
    List<ChatMessage> messages,
    LLMContext? context,
    double temperature,
    int maxTokens,
  ) async* {
    // Use regular chat and simulate streaming
    final response = await chat(
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    // Simulate streaming by yielding chunks
    const chunkSize = 5; // Characters per chunk
    for (int i = 0; i < response.length; i += chunkSize) {
      final end =
          (i + chunkSize < response.length) ? i + chunkSize : response.length;
      yield response.substring(0, end); // Yield cumulative text

      // Small delay to simulate streaming
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }
}
