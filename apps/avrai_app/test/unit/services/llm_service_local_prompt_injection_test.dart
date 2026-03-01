import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _RecordingBackend implements LlmBackend {
  List<ChatMessage> lastMessages = const [];

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    lastMessages = List<ChatMessage>.from(messages);
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
    lastMessages = List<ChatMessage>.from(messages);
    return const Stream<String>.empty();
  }
}

final class _FakeBootstrap extends LocalLlmPostInstallBootstrapService {
  final String? prompt;

  _FakeBootstrap(this.prompt);

  @override
  Future<String?> getOrBuildSystemPromptForUser(String userId) async {
    return prompt;
  }
}

void main() {
  group('LLMService local system prompt injection', () {
    setUp(() {
      // Ensure clean DI state for each test.
      final sl = GetIt.instance;
      if (sl.isRegistered<LocalLlmPostInstallBootstrapService>()) {
        sl.unregister<LocalLlmPostInstallBootstrapService>();
      }
    });

    tearDown(() {
      final sl = GetIt.instance;
      if (sl.isRegistered<LocalLlmPostInstallBootstrapService>()) {
        sl.unregister<LocalLlmPostInstallBootstrapService>();
      }
    });

    test('prepends system prompt for local backend when available', () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LLMService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: 'hello'),
        ],
        context: LLMContext(userId: 'user_1'),
      );

      expect(local.lastMessages, isNotEmpty);
      expect(local.lastMessages.first.role, equals(ChatRole.system));
      expect(local.lastMessages.first.content, equals('SYSTEM_PROMPT'));
      expect(local.lastMessages[1].role, equals(ChatRole.user));
    });

    test('does not inject system prompt for cloud backend', () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LLMService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => false,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: 'hello'),
        ],
        context: LLMContext(userId: 'user_1'),
      );

      expect(cloud.lastMessages, isNotEmpty);
      expect(cloud.lastMessages.first.role, equals(ChatRole.user));
    });
  });
}
