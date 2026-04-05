import 'package:avrai_core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai_core/models/misc/local_llm_memory_profile.dart';

/// One-time bootstrap output that “personalizes” the local LLM once a model pack
/// is installed.
///
/// Stored per-agent (agentId), and tied to the currently active model pack id so
/// we can re-bootstrap after a pack upgrade.
class LocalLlmBootstrapState {
  final String agentId;

  /// Active pack id (from `LocalLlmModelPackManager.getStatus().activePackId`).
  final String modelPackId;

  /// When this bootstrap state was created.
  final int createdAtMs;

  /// When this bootstrap state was last updated (e.g., after refinement picks).
  final int updatedAtMs;

  /// The stable “system prompt” / memory blob to inject for local chat.
  final String systemPrompt;

  /// Structured representation of the local memory used to render `systemPrompt`.
  ///
  /// This lets us evolve prompt formatting without losing the underlying signals.
  final LocalLlmMemoryProfile? memoryProfile;

  /// Whether we believe onboarding had to fall back (e.g. heuristic suggestions),
  /// so we should ask 1–3 quick refinement picks once local is ready.
  final bool needsRefinementPicks;

  /// Optional refinement prompt ids that are pending.
  final List<String> pendingRefinementPromptIds;

  /// Refinement selections keyed by prompt id → selected option ids.
  ///
  /// This is used to sharpen the local system prompt after the model pack
  /// becomes available.
  final Map<String, List<String>> refinementSelections;

  const LocalLlmBootstrapState({
    required this.agentId,
    required this.modelPackId,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.systemPrompt,
    this.memoryProfile,
    required this.needsRefinementPicks,
    required this.pendingRefinementPromptIds,
    this.refinementSelections = const {},
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'modelPackId': modelPackId,
        'createdAtMs': createdAtMs,
        'updatedAtMs': updatedAtMs,
        'systemPrompt': systemPrompt,
        if (memoryProfile != null) 'memoryProfile': memoryProfile!.toJson(),
        'needsRefinementPicks': needsRefinementPicks,
        'pendingRefinementPromptIds': pendingRefinementPromptIds,
        'refinementSelections': refinementSelections,
      };

  factory LocalLlmBootstrapState.fromJson(Map<String, dynamic> json) {
    return LocalLlmBootstrapState(
      agentId: json['agentId'] as String,
      modelPackId: json['modelPackId'] as String,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt() ?? 0,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      memoryProfile: (json['memoryProfile'] is Map)
          ? LocalLlmMemoryProfile.fromJson(
              Map<String, dynamic>.from(json['memoryProfile'] as Map),
            )
          : null,
      needsRefinementPicks: json['needsRefinementPicks'] as bool? ?? false,
      pendingRefinementPromptIds:
          List<String>.from(json['pendingRefinementPromptIds'] ?? const []),
      refinementSelections: (json['refinementSelections'] as Map?)?.map(
            (k, v) => MapEntry(
              k.toString(),
              List<String>.from(v as List? ?? const []),
            ),
          ) ??
          const {},
    );
  }
}

/// A lightweight “refinement pick” prompt we can show after local becomes ready.
///
/// This is intentionally simple and UI-friendly.
class LocalLlmRefinementPrompt {
  final String id;
  final String title;
  final String description;
  final List<OnboardingSuggestionItem> options;

  const LocalLlmRefinementPrompt({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory LocalLlmRefinementPrompt.fromJson(Map<String, dynamic> json) {
    return LocalLlmRefinementPrompt(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      options: (json['options'] as List?)
              ?.whereType<Map>()
              .map((e) => OnboardingSuggestionItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}
