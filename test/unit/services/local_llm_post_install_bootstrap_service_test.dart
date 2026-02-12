import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/services/onboarding/onboarding_data_service.dart';
import 'package:avrai/core/services/onboarding/onboarding_suggestion_event_store.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;


import '../../helpers/platform_channel_helper.dart';

/// Unit tests for LocalLlmPostInstallBootstrapService
///
/// Focus: deterministic system prompt build from onboarding signals once a local
/// model pack is installed.
void main() {
  group('LocalLlmPostInstallBootstrapService', () {
    setUp(() async {
      // No-op: Sembast removed in Phase 26
    });

    test('returns null when local pack is not installed', () async {
      final bootstrap = LocalLlmPostInstallBootstrapService(
        packs: LocalLlmModelPackManager(
          prefs: await SharedPreferencesCompat.getInstance(
            storage: getTestStorage(boxName: 'local_llm_prefs_uninstalled'),
          ),
        ),
        agentIdService: AgentIdService(),
        onboardingDataService: OnboardingDataService(agentIdService: AgentIdService()),
        suggestionEventStore:
            OnboardingSuggestionEventStore(agentIdService: AgentIdService()),
      );

      final prompt = await bootstrap.getOrBuildSystemPromptForUser('user_1');
      expect(prompt, isNull);
    });

    test('builds a non-empty deterministic system prompt from onboarding data',
        () async {
      // Arrange: local pack installed (via prefs + existing dir).
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'local_llm_prefs'),
      );
      final activeDir =
          Directory('/Users/reisgordon/SPOTS/tmp/local_llm_test_active_pack');
      if (!await activeDir.exists()) {
        await activeDir.create(recursive: true);
      }
      await prefs.setString(LocalLlmModelPackManager.prefsKeyActiveModelDir, activeDir.path);
      await prefs.setString(LocalLlmModelPackManager.prefsKeyActiveModelId, 'pack_test_v1');

      final packs = LocalLlmModelPackManager(prefs: prefs);

      // Arrange: onboarding data + suggestion events exist.
      final agentIdService = AgentIdService();
      final onboardingDataService =
          OnboardingDataService(agentIdService: agentIdService);
      final suggestionStore =
          OnboardingSuggestionEventStore(agentIdService: agentIdService);

      const userId = 'user_1';
      await onboardingDataService.saveOnboardingData(
        userId,
        OnboardingData(
          agentId: 'agent_placeholder',
          homebase: 'Test City',
          favoritePlaces: const ['Coffee Shop'],
          preferences: const {
            'Food & Drink': ['Coffee & Tea'],
          },
          baselineLists: const ['Hidden Gems'],
          completedAt: DateTime.now(),
        ),
      );

      await suggestionStore.appendForUser(
        userId: userId,
        event: const OnboardingSuggestionEvent(
          eventId: 'evt1',
          createdAtMs: 1,
          surface: 'baseline_lists',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: 'baseline_lists_quick_suggestions',
          suggestions: [
            OnboardingSuggestionItem(id: 'Hidden Gems', label: 'Hidden Gems'),
          ],
          userAction: OnboardingSuggestionUserAction(
            type: OnboardingSuggestionActionType.select,
            item: OnboardingSuggestionItem(id: 'Hidden Gems', label: 'Hidden Gems'),
          ),
        ),
      );

      final bootstrap = LocalLlmPostInstallBootstrapService(
        agentIdService: agentIdService,
        packs: packs,
        onboardingDataService: onboardingDataService,
        suggestionEventStore: suggestionStore,
      );

      // Act: build prompt twice (should be stable / cached).
      final prompt1 = await bootstrap.getOrBuildSystemPromptForUser(userId);
      final prompt2 = await bootstrap.getOrBuildSystemPromptForUser(userId);

      // Assert.
      expect(prompt1, isNotNull);
      expect(prompt1, isNotEmpty);
      expect(prompt1, equals(prompt2));
      expect(prompt1, contains('Homebase'));
      expect(prompt1, contains('Test City'));
      expect(prompt1, contains('Seed lists'));
    });
  });
}

