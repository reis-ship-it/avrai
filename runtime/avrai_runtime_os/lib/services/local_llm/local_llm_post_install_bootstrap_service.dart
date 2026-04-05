import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:get_storage/get_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/misc/local_llm_bootstrap_state.dart';
import 'package:avrai_core/models/misc/local_llm_memory_profile.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/local_llm/model_pack_manager.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_suggestion_event_store.dart';

/// Builds a stable local “memory/system prompt” from onboarding signals once the
/// local model pack is installed.
///
/// This is intentionally deterministic and conservative: we do not try to do
/// any generative “summarization” inside the bootstrap itself yet.
class LocalLlmPostInstallBootstrapService {
  static const String _logName = 'LocalLlmPostInstallBootstrapService';

  static const String _bootstrapKeyPrefix = 'local_llm_bootstrap_state_';
  static const String _refinementKeyPrefix = 'local_llm_refinement_prompts_';

  final AgentIdService _agentIdService;
  final LocalLlmModelPackManager _packs;
  final OnboardingDataService _onboardingData;
  final OnboardingSuggestionEventStore _suggestionEvents;

  static T? _tryGet<T extends Object>() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<T>()) return sl<T>();
    } catch (_) {}
    return null;
  }

  LocalLlmPostInstallBootstrapService({
    AgentIdService? agentIdService,
    LocalLlmModelPackManager? packs,
    OnboardingDataService? onboardingDataService,
    OnboardingSuggestionEventStore? suggestionEventStore,
  })  : _agentIdService =
            agentIdService ?? (_tryGet<AgentIdService>() ?? AgentIdService()),
        _packs = packs ?? LocalLlmModelPackManager(),
        _onboardingData = onboardingDataService ??
            (_tryGet<OnboardingDataService>() ?? OnboardingDataService()),
        _suggestionEvents = suggestionEventStore ??
            (_tryGet<OnboardingSuggestionEventStore>() ??
                OnboardingSuggestionEventStore());

  final GetStorage _box = GetStorage('local_llm_bootstrap');

  Future<LocalLlmBootstrapState?> getBootstrapStateForUser(
      String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final record =
          _box.read<Map<String, dynamic>>('$_bootstrapKeyPrefix$agentId');
      if (record == null) return null;
      return LocalLlmBootstrapState.fromJson(record);
    } catch (e, st) {
      developer.log('Failed to read bootstrap state: $e',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> applyRefinementSelection({
    required String userId,
    required String promptId,
    required List<String> selectedOptionIds,
  }) async {
    try {
      final status = await _packs.getStatus();
      if (!status.isInstalled || status.activePackId == null) return;

      // Ensure base bootstrap exists.
      var state = await getBootstrapStateForUser(userId);
      state ??= await maybeBootstrapForUser(userId);
      if (state == null) return;

      final onboarding = await _onboardingData.getOnboardingData(userId);
      if (onboarding == null) return;
      final events = await _suggestionEvents.getAllForUser(userId);
      final prompts = await getRefinementPromptsForUser(userId);
      final promptById = {for (final p in prompts) p.id: p};

      final selections = <String, List<String>>{
        ...state.refinementSelections,
      };
      selections[promptId] = selectedOptionIds.toSet().toList()..sort();

      final pending = state.pendingRefinementPromptIds.toList()
        ..remove(promptId);

      final optionLabelsByPromptId = <String, Map<String, String>>{};
      for (final p in prompts) {
        optionLabelsByPromptId[p.id] = {
          for (final o in p.options) o.id: o.label,
        };
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final memory = _buildMemoryProfile(
        onboarding,
        events,
        refinementSelections: selections,
      );
      final updatedPrompt = _buildSystemPrompt(
        onboarding,
        events,
        refinementSelections: selections,
        refinementOptionLabelsByPromptId: optionLabelsByPromptId,
      );

      final next = LocalLlmBootstrapState(
        agentId: state.agentId,
        modelPackId: status.activePackId!,
        createdAtMs: state.createdAtMs,
        updatedAtMs: now,
        systemPrompt: updatedPrompt,
        memoryProfile: memory,
        needsRefinementPicks: pending.isNotEmpty,
        pendingRefinementPromptIds: pending,
        refinementSelections: selections,
      );

      await _box.write('$_bootstrapKeyPrefix${state.agentId}', next.toJson());

      // Optional: log refinement selection as a suggestion event for later learning.
      final p = promptById[promptId];
      final selectedItems = selectedOptionIds.map((id) {
        final label = optionLabelsByPromptId[promptId]?[id] ?? id;
        return OnboardingSuggestionItem(id: id, label: label);
      }).toList();
      await _suggestionEvents.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: now,
          surface: 'local_llm_refinement',
          provenance: OnboardingSuggestionProvenance.local,
          promptCategory: p?.id ?? promptId,
          suggestions: selectedItems,
          userAction: const OnboardingSuggestionUserAction(
            type: OnboardingSuggestionActionType.select,
          ),
        ),
      );
    } catch (e, st) {
      developer.log('Failed to apply refinement selection: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Returns the system prompt to inject for local LLM chat, bootstrapping if needed.
  Future<String?> getOrBuildSystemPromptForUser(String userId) async {
    final status = await _packs.getStatus();
    if (!status.isInstalled || status.activePackId == null) return null;

    final existing = await getBootstrapStateForUser(userId);
    if (existing != null && existing.modelPackId == status.activePackId) {
      if (existing.systemPrompt.trim().isEmpty) return null;
      return existing.systemPrompt;
    }

    final built = await maybeBootstrapForUser(userId);
    if (built?.systemPrompt.trim().isEmpty ?? true) return null;
    return built!.systemPrompt;
  }

  /// Best-effort helper for install flows where we don’t have a userId at callsite.
  Future<void> maybeBootstrapCurrentUser() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) return;
      await maybeBootstrapForUser(userId);
    } catch (e, st) {
      developer.log('maybeBootstrapCurrentUser failed: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Build and persist bootstrap state if:
  /// - a local model pack is installed+active
  /// - onboarding data exists
  /// - we haven't already bootstrapped for the active pack id
  Future<LocalLlmBootstrapState?> maybeBootstrapForUser(String userId) async {
    try {
      final status = await _packs.getStatus();
      if (!status.isInstalled || status.activePackId == null) {
        developer.log('Skipping bootstrap: local pack not installed',
            name: _logName);
        return null;
      }

      final onboarding = await _onboardingData.getOnboardingData(userId);
      if (onboarding == null) {
        developer.log('Skipping bootstrap: no onboarding data', name: _logName);
        return null;
      }

      final existing = await getBootstrapStateForUser(userId);
      if (existing != null && existing.modelPackId == status.activePackId) {
        return existing;
      }

      final agentId = await _agentIdService.getUserAgentId(userId);
      final events = await _suggestionEvents.getAllForUser(userId);

      final memory = _buildMemoryProfile(
        onboarding,
        events,
        refinementSelections: const {},
      );
      final systemPrompt = _renderSystemPromptFromMemory(
        memory,
        refinementOptionLabelsByPromptId: const {},
      );
      final refinements = _buildRefinementPrompts(onboarding);
      final needsRefinement = events.any(
            (e) => e.provenance == OnboardingSuggestionProvenance.heuristic,
          ) &&
          refinements.isNotEmpty;

      final now = DateTime.now().millisecondsSinceEpoch;
      final state = LocalLlmBootstrapState(
        agentId: agentId,
        modelPackId: status.activePackId!,
        createdAtMs: now,
        updatedAtMs: now,
        systemPrompt: systemPrompt,
        memoryProfile: memory,
        needsRefinementPicks: needsRefinement,
        pendingRefinementPromptIds:
            needsRefinement ? refinements.map((r) => r.id).toList() : const [],
        refinementSelections: const {},
      );

      await _box.write('$_bootstrapKeyPrefix$agentId', state.toJson());

      // Store refinement prompt definitions so UI can show later.
      if (refinements.isNotEmpty) {
        await _box.write('$_refinementKeyPrefix$agentId', <String, dynamic>{
          'updatedAtMs': now,
          'prompts': refinements.map((r) => r.toJson()).toList(),
        });
      }

      developer.log(
        '✅ Bootstrapped local LLM memory (agentId: ${agentId.substring(0, 10)}..., pack: ${status.activePackId})',
        name: _logName,
      );
      return state;
    } catch (e, st) {
      developer.log('Bootstrap failed: $e',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<LocalLlmRefinementPrompt>> getRefinementPromptsForUser(
      String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final record =
          _box.read<Map<String, dynamic>>('$_refinementKeyPrefix$agentId');
      final prompts = (record?['prompts'] as List?) ?? const [];
      return prompts
          .whereType<Map>()
          .map((e) =>
              LocalLlmRefinementPrompt.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      developer.log('Failed to load refinement prompts: $e',
          name: _logName, error: e, stackTrace: st);
      return const [];
    }
  }

  Future<List<LocalLlmRefinementPrompt>> getPendingRefinementPromptsForUser(
      String userId) async {
    final state = await getBootstrapStateForUser(userId);
    if (state == null || state.pendingRefinementPromptIds.isEmpty) {
      return const [];
    }

    final prompts = await getRefinementPromptsForUser(userId);
    final promptById = {for (final p in prompts) p.id: p};
    final ordered = <LocalLlmRefinementPrompt>[];
    for (final id in state.pendingRefinementPromptIds) {
      final p = promptById[id];
      if (p != null) ordered.add(p);
    }
    return ordered;
  }

  String _buildSystemPrompt(
    OnboardingData data,
    List<OnboardingSuggestionEvent> events, {
    required Map<String, List<String>> refinementSelections,
    required Map<String, Map<String, String>> refinementOptionLabelsByPromptId,
  }) {
    final memory = _buildMemoryProfile(
      data,
      events,
      refinementSelections: refinementSelections,
    );
    return _renderSystemPromptFromMemory(
      memory,
      refinementOptionLabelsByPromptId: refinementOptionLabelsByPromptId,
    );
  }

  LocalLlmMemoryProfile _buildMemoryProfile(
    OnboardingData data,
    List<OnboardingSuggestionEvent> events, {
    required Map<String, List<String>> refinementSelections,
  }) {
    final selectedBaselineLists = _deriveBaselineLists(data, events);
    return LocalLlmMemoryProfile(
      homebase: data.homebase,
      favoritePlaces: data.favoritePlaces.take(10).toList(),
      preferences: data.preferences.map(
        (k, v) => MapEntry(k, v.take(10).toList()),
      ),
      baselineLists: selectedBaselineLists.take(12).toList(),
      refinementSelections: refinementSelections,
    );
  }

  String _renderSystemPromptFromMemory(
    LocalLlmMemoryProfile memory, {
    required Map<String, Map<String, String>> refinementOptionLabelsByPromptId,
  }) {
    final buf = StringBuffer();
    buf.writeln('You are the on-device assistant for SPOTS.');
    buf.writeln(
        'Your job is to help the user discover meaningful places and maintain lists.');
    buf.writeln('');
    buf.writeln('Personalization memory (from onboarding signals):');
    if (memory.homebase != null && memory.homebase!.trim().isNotEmpty) {
      buf.writeln('- Homebase: ${memory.homebase}');
    }
    if (memory.favoritePlaces.isNotEmpty) {
      buf.writeln('- Favorite places: ${memory.favoritePlaces.join(', ')}');
    }
    if (memory.preferences.isNotEmpty) {
      final lines = <String>[];
      for (final entry in memory.preferences.entries) {
        final values = entry.value.join(', ');
        if (values.isNotEmpty) {
          lines.add('${entry.key}: $values');
        }
      }
      if (lines.isNotEmpty) {
        buf.writeln('- Preferences:');
        for (final l in lines.take(12)) {
          buf.writeln('  - $l');
        }
      }
    }
    if (memory.baselineLists.isNotEmpty) {
      buf.writeln('- Seed lists the user started with:');
      for (final l in memory.baselineLists) {
        buf.writeln('  - $l');
      }
    }

    if (memory.refinementSelections.isNotEmpty) {
      buf.writeln('- Refinement picks (post-install):');
      final keys = memory.refinementSelections.keys.toList()..sort();
      for (final k in keys) {
        final ids = memory.refinementSelections[k] ?? const [];
        if (ids.isEmpty) continue;
        final labels = ids
            .map((id) => refinementOptionLabelsByPromptId[k]?[id] ?? id)
            .toList();
        buf.writeln('  - $k: ${labels.join(', ')}');
      }
    }
    buf.writeln('');
    buf.writeln('Response style:');
    buf.writeln('- Be concise and actionable.');
    buf.writeln(
        '- Prefer authentic local spots and community-forward suggestions.');
    buf.writeln('- When unsure, ask 1 clarifying question.');

    return buf.toString().trim();
  }

  List<String> _deriveBaselineLists(
    OnboardingData data,
    List<OnboardingSuggestionEvent> events,
  ) {
    final selected = <String>{...data.baselineLists};
    final sorted = events.toList()
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));

    for (final e in sorted) {
      final action = e.userAction;
      if (action == null || action.item == null) continue;
      if (e.surface != 'baseline_lists') continue;

      final label = action.item!.label;
      switch (action.type) {
        case OnboardingSuggestionActionType.select:
          selected.add(label);
          break;
        case OnboardingSuggestionActionType.deselect:
          selected.remove(label);
          break;
        case OnboardingSuggestionActionType.edit:
          // Treat “edit” as add of edited label, best-effort.
          final edited = action.editedLabel;
          if (edited != null && edited.trim().isNotEmpty) {
            selected.remove(label);
            selected.add(edited.trim());
          }
          break;
        case OnboardingSuggestionActionType.shown:
        case OnboardingSuggestionActionType.skip:
          break;
      }
    }

    final list = selected.toList()..sort();
    return list;
  }

  List<LocalLlmRefinementPrompt> _buildRefinementPrompts(OnboardingData data) {
    // Heuristic: offer a small set of refinements based on strongest categories.
    // UI can decide whether to show these after local becomes ready.
    if (data.preferences.isEmpty) return const [];

    final categories = data.preferences.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = categories.take(3).map((e) => e.key).toList();
    final prompts = <LocalLlmRefinementPrompt>[];

    for (final cat in top) {
      final values = data.preferences[cat] ?? const [];
      if (values.isEmpty) continue;

      final options = values
          .take(6)
          .map((v) => OnboardingSuggestionItem(id: '$cat:$v', label: v))
          .toList();

      prompts.add(
        LocalLlmRefinementPrompt(
          id: 'refine_$cat',
          title: 'Refine your $cat taste',
          description:
              'Pick the options that feel most “you” so offline suggestions get sharper.',
          options: options,
        ),
      );
    }

    return prompts;
  }
}
