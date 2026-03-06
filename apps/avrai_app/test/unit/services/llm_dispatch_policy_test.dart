import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:flutter_test/flutter_test.dart';
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
    String? responseFormat,
  }) async {
    throw Exception('local failed');
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
    return Stream<String>.error(Exception('local failed'));
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
    String? responseFormat,
  }) async {
    chatCalls += 1;
    return 'cloud-ok';
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
  group('LLMDispatchPolicy', () {
    test('human chat policy blocks silent cloud fallback on local failure',
        () async {
      final cloud = _RecordingBackend();
      final service = LLMService(
        SupabaseClient('http://localhost', 'anon'),
        cloudBackend: cloud,
        localBackend: _ThrowingBackend(),
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      await expectLater(
        () => service.chat(
          messages: [
            ChatMessage(role: ChatRole.user, content: 'hello'),
          ],
          dispatchPolicy: const LLMDispatchPolicy.humanChat(),
        ),
        throwsA(isA<Exception>()),
      );
      expect(cloud.chatCalls, equals(0));
    });

    test('standard policy allows cloud fallback on local failure', () async {
      final cloud = _RecordingBackend();
      final service = LLMService(
        SupabaseClient('http://localhost', 'anon'),
        cloudBackend: cloud,
        localBackend: _ThrowingBackend(),
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      final response = await service.chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: 'hello'),
        ],
      );

      expect(response, equals('cloud-ok'));
      expect(cloud.chatCalls, equals(1));
    });
  });
}
