/// Detects when the user asks to bypass RAG-as-answer (e.g. "tell me more", "continue").
///
/// Plan: RAG wiring + RAG-as-answer — Bypass intent (Phase 4).
/// Scope/bypass mitigations: more phrases, narrow "keep going" to short follow-ups.
class BypassIntentDetector {
  static final List<RegExp> _bypassPhrases = [
    RegExp(r'\b(tell me more|tell me more about)\b', caseSensitive: false),
    RegExp(r'\b(continue|go on)\b', caseSensitive: false),
    RegExp(r'\b(go deeper|elaborate|expand on that)\b', caseSensitive: false),
    RegExp(r'\b(more details?|more specifics?|more info)\b',
        caseSensitive: false),
    RegExp(r'\b(expand|elaborate more)\b', caseSensitive: false),
    RegExp(r'^\s*(and\?|more\?|yes\?|please\?)\s*$', caseSensitive: false),
    RegExp(r'\b(dig deeper|dive deeper|expand further|go further)\b',
        caseSensitive: false),
    RegExp(r'\b(give me more|a bit more|more about that|more on that)\b',
        caseSensitive: false),
    RegExp(r'\b(explain more|break it down more)\b', caseSensitive: false),
  ];

  static final RegExp _keepGoingMatch =
      RegExp(r'\bkeep\s+going\b', caseSensitive: false);
  static final RegExp _shortKeepGoingOnly =
      RegExp(r'^\s*keep\s+going\s*[!.]?\s*$', caseSensitive: false);

  /// Returns true if [userMessage] indicates the user wants to bypass RAG-as-answer.
  /// [lastAssistantMessage] optional (e.g. short follow-ups like "and?" after a RAG reply).
  bool bypassRequested(String userMessage, {String? lastAssistantMessage}) {
    final t = userMessage.trim();
    if (t.isEmpty) return false;

    if (_keepGoingMatch.hasMatch(t)) {
      if (lastAssistantMessage != null || _isShortKeepGoing(t)) {
        return true;
      }
      return false;
    }

    for (final p in _bypassPhrases) {
      if (p.hasMatch(t)) return true;
    }
    return false;
  }

  static bool _isShortKeepGoing(String t) {
    return _shortKeepGoingOnly.hasMatch(t);
  }
}
