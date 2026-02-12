import 'dart:math';

/// Provenance of suggestions shown during onboarding.
///
/// This is critical for later “bootstrap” once a local model pack is installed:
/// onboarding may have used cloud or heuristic suggestions, and we want to
/// understand what the user reacted to (and why).
enum OnboardingSuggestionProvenance {
  cloud,
  local,
  heuristic,
}

/// The type of user action recorded for a suggestion surface.
enum OnboardingSuggestionActionType {
  /// Suggestions were shown to the user.
  shown,

  /// User selected a suggestion item.
  select,

  /// User removed/deselected a suggestion item.
  deselect,

  /// User edited a suggestion item (e.g., renamed).
  edit,

  /// User skipped the surface entirely.
  skip,
}

/// A single suggestion item shown during onboarding.
class OnboardingSuggestionItem {
  final String id;
  final String label;

  const OnboardingSuggestionItem({
    required this.id,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };

  factory OnboardingSuggestionItem.fromJson(Map<String, dynamic> json) {
    return OnboardingSuggestionItem(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

/// User interaction details for a suggestion event.
class OnboardingSuggestionUserAction {
  final OnboardingSuggestionActionType type;

  /// The affected item (if action targets a specific item).
  final OnboardingSuggestionItem? item;

  /// New label if the user edited a suggestion item.
  final String? editedLabel;

  const OnboardingSuggestionUserAction({
    required this.type,
    this.item,
    this.editedLabel,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'item': item?.toJson(),
        'editedLabel': editedLabel,
      };

  factory OnboardingSuggestionUserAction.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? OnboardingSuggestionActionType.shown.name;
    return OnboardingSuggestionUserAction(
      type: OnboardingSuggestionActionType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => OnboardingSuggestionActionType.shown,
      ),
      item: (json['item'] is Map<String, dynamic>)
          ? OnboardingSuggestionItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
      editedLabel: json['editedLabel'] as String?,
    );
  }
}

/// Append-only event log record for onboarding suggestion surfaces.
///
/// This is intentionally compact and backend-agnostic.
class OnboardingSuggestionEvent {
  final String eventId;
  final int createdAtMs;
  final String surface;
  final OnboardingSuggestionProvenance provenance;
  final String promptCategory;

  /// The suggestions shown at the time of the event (usually for `shown` events).
  final List<OnboardingSuggestionItem> suggestions;

  /// Optional user action (select/deselect/edit/skip).
  final OnboardingSuggestionUserAction? userAction;

  const OnboardingSuggestionEvent({
    required this.eventId,
    required this.createdAtMs,
    required this.surface,
    required this.provenance,
    required this.promptCategory,
    required this.suggestions,
    this.userAction,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'createdAtMs': createdAtMs,
        'surface': surface,
        'provenance': provenance.name,
        'promptCategory': promptCategory,
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'userAction': userAction?.toJson(),
      };

  factory OnboardingSuggestionEvent.fromJson(Map<String, dynamic> json) {
    final provenanceName = json['provenance'] as String? ?? OnboardingSuggestionProvenance.heuristic.name;

    return OnboardingSuggestionEvent(
      eventId: json['eventId'] as String,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      surface: json['surface'] as String? ?? 'unknown',
      provenance: OnboardingSuggestionProvenance.values.firstWhere(
        (p) => p.name == provenanceName,
        orElse: () => OnboardingSuggestionProvenance.heuristic,
      ),
      promptCategory: json['promptCategory'] as String? ?? 'unknown',
      suggestions: (json['suggestions'] as List?)
              ?.whereType<Map>()
              .map((e) => OnboardingSuggestionItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      userAction: (json['userAction'] is Map<String, dynamic>)
          ? OnboardingSuggestionUserAction.fromJson(json['userAction'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a reasonably unique event id without extra dependencies.
  static String newEventId({int? nowMicros, Random? random}) {
    final r = random ?? Random.secure();
    final ts = nowMicros ?? DateTime.now().microsecondsSinceEpoch;
    final salt = r.nextInt(1 << 32);
    return 'onb_evt_${ts}_$salt';
  }
}

