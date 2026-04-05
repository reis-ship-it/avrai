import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_storage_helper.dart';

final class _RecordingBackend implements LanguageBackend {
  List<LanguageTurnMessage> lastMessages = const [];

  @override
  Future<String> chat({
    required LLMService service,
    required List<LanguageTurnMessage> messages,
    required LanguageRuntimeContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    lastMessages = List<LanguageTurnMessage>.from(messages);
    return 'ok';
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<LanguageTurnMessage> messages,
    required LanguageRuntimeContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) {
    lastMessages = List<LanguageTurnMessage>.from(messages);
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
  group('LanguageRuntimeService local system prompt injection', () {
    setUpAll(() async {
      await TestStorageHelper.initTestStorage();
      await GetStorage.init('local_llm_bootstrap');
      await GetStorage('local_llm_bootstrap').erase();
    });

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

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await GetStorage('local_llm_bootstrap').erase();
      await TestStorageHelper.clearTestStorage();
    });

    test('prepends system prompt for local backend when available', () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LanguageRuntimeService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          LanguageTurnMessage(
            role: LanguageTurnRole.user,
            content: 'hello',
          ),
        ],
        context: LanguageRuntimeContext(userId: 'user_1'),
      );

      expect(local.lastMessages, isNotEmpty);
      expect(local.lastMessages.first.role, equals(LanguageTurnRole.system));
      expect(local.lastMessages.first.content, equals('SYSTEM_PROMPT'));
      expect(local.lastMessages[1].role, equals(LanguageTurnRole.user));
    });

    test('injects governed locality timing into local system prompt', () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LanguageRuntimeService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          LanguageTurnMessage(
            role: LanguageTurnRole.user,
            content: 'hello',
          ),
        ],
        context: LanguageRuntimeContext(
          userId: 'user_1',
          conversationPreferences: <String, dynamic>{
            'governed_knowledge_timing_summary':
                'phase locality_personal_visit_captured, effective knowledge ${DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String()}',
            'governed_knowledge_captured_at': DateTime.now()
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
          },
        ),
      );

      expect(local.lastMessages, isNotEmpty);
      expect(
        local.lastMessages.first.content,
        contains('Local governed context timing:'),
      );
      expect(
        local.lastMessages.first.content,
        contains('current enough for grounded locality-aware guidance'),
      );
    });

    test('marks stale governed locality timing cautiously in local prompt',
        () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LanguageRuntimeService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => true,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          LanguageTurnMessage(
            role: LanguageTurnRole.user,
            content: 'hello',
          ),
        ],
        context: LanguageRuntimeContext(
          userId: 'user_1',
          conversationPreferences: <String, dynamic>{
            'governed_knowledge_timing_summary':
                'phase locality_personal_visit_captured, effective knowledge ${DateTime.now().toUtc().subtract(const Duration(days: 40)).toIso8601String()}',
            'governed_knowledge_captured_at': DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 40))
                .toIso8601String(),
          },
        ),
      );

      expect(local.lastMessages, isNotEmpty);
      expect(
        local.lastMessages.first.content,
        contains('may be stale relative to the user’s present state'),
      );
    });

    test('does not inject system prompt for cloud backend', () async {
      final sl = GetIt.instance;
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(
        _FakeBootstrap('SYSTEM_PROMPT'),
      );

      final cloud = _RecordingBackend();
      final local = _RecordingBackend();

      final client = SupabaseClient('http://localhost', 'anon');
      final service = LanguageRuntimeService(
        client,
        cloudBackend: cloud,
        localBackend: local,
        shouldUseLocalOverride: ({required bool isOnline}) async => false,
        isOnlineOverride: () async => true,
      );

      await service.chat(
        messages: [
          LanguageTurnMessage(
            role: LanguageTurnRole.user,
            content: 'hello',
          ),
        ],
        context: LanguageRuntimeContext(userId: 'user_1'),
      );

      expect(cloud.lastMessages, isNotEmpty);
      expect(cloud.lastMessages.first.role, equals(LanguageTurnRole.user));
    });
  });
}
