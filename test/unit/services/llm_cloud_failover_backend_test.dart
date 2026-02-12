/// SPOTS CloudFailoverBackend Tests
/// Date: January 2, 2026
/// Purpose: Ensure cloud provider routing/failover works for chat.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _ThrowingBackend implements LlmBackend {
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    throw DataCenterFailureException('primary down');
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
    return Stream<String>.error(DataCenterFailureException('primary down'));
  }
}

final class _RecordingBackend implements LlmBackend {
  int chatCalls = 0;

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    chatCalls += 1;
    return 'ok';
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
    return const Stream<String>.empty();
  }
}

void main() {
  test('falls back to secondary cloud backend on data center failure', () async {
    final fallback = _RecordingBackend();
    final cloud = CloudFailoverBackend(
      primary: _ThrowingBackend(),
      fallback: fallback,
    );

    final client = SupabaseClient('http://localhost', 'anon');
    final dummyService = LLMService(
      client,
      cloudBackend: _RecordingBackend(),
      localBackend: _RecordingBackend(),
      shouldUseLocalOverride: ({required bool isOnline}) async => false,
    );

    final res = await cloud.chat(
      service: dummyService,
      messages: [
        ChatMessage(role: ChatRole.user, content: 'hello'),
      ],
      context: LLMContext(userId: 'user_1'),
      temperature: 0.7,
      maxTokens: 100,
      timeout: const Duration(seconds: 5),
    );

    expect(res, equals('ok'));
    expect(fallback.chatCalls, equals(1));
  });
}

