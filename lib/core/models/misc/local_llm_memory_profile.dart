/// Structured “local memory” derived from onboarding + early suggestion events.
///
/// This is stored alongside the rendered `systemPrompt` so we can:
/// - re-render prompts deterministically on pack upgrades
/// - evolve prompt formatting without losing the underlying memory
class LocalLlmMemoryProfile {
  final String? homebase;
  final List<String> favoritePlaces;
  final Map<String, List<String>> preferences;
  final List<String> baselineLists;

  /// Refinement selections keyed by prompt id → selected option ids.
  final Map<String, List<String>> refinementSelections;

  const LocalLlmMemoryProfile({
    required this.homebase,
    required this.favoritePlaces,
    required this.preferences,
    required this.baselineLists,
    required this.refinementSelections,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'homebase': homebase,
        'favoritePlaces': favoritePlaces,
        'preferences': preferences,
        'baselineLists': baselineLists,
        'refinementSelections': refinementSelections,
      };

  factory LocalLlmMemoryProfile.fromJson(Map<String, dynamic> json) {
    final prefsRaw = json['preferences'];
    final prefs = <String, List<String>>{};
    if (prefsRaw is Map) {
      for (final entry in prefsRaw.entries) {
        prefs[entry.key.toString()] =
            List<String>.from(entry.value as List? ?? const []);
      }
    }

    final refRaw = json['refinementSelections'];
    final ref = <String, List<String>>{};
    if (refRaw is Map) {
      for (final entry in refRaw.entries) {
        ref[entry.key.toString()] =
            List<String>.from(entry.value as List? ?? const []);
      }
    }

    return LocalLlmMemoryProfile(
      homebase: json['homebase'] as String?,
      favoritePlaces: List<String>.from(json['favoritePlaces'] ?? const []),
      preferences: prefs,
      baselineLists: List<String>.from(json['baselineLists'] ?? const []),
      refinementSelections: ref,
    );
  }
}

