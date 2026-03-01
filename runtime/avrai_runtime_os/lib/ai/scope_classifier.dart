/// Scope of a user query for RAG-as-answer: in-scope (answer from RAG) vs out-of-scope (refuse).
enum Scope {
  inScope,
  outOfScope,
}

/// Rule-based classifier for RAG-as-answer scope.
/// Out-of-scope: general knowledge, math, current events, etc. In-scope: preferences, places, traits, social.
///
/// Plan: RAG wiring + RAG-as-answer — Scope classifier.
/// Scope/bypass mitigations: in-scope overrides (e.g. "capital of my heart") before out-of-scope rules.
class ScopeClassifier {
  static final List<RegExp> _inScopeOverrides = [
    RegExp(r'\bcapital of my heart\b', caseSensitive: false),
    RegExp(r'\bcapital of the world\b', caseSensitive: false),
  ];

  static final List<RegExp> _outOfScopePatterns = [
    RegExp(r'\b(what is|who is|when did|where is|capital of|population of)\b',
        caseSensitive: false),
    RegExp(r'\b(solve|calculate|compute|equation|^\s*\d+\s*[\+\-\*\/]\s*\d+)\b',
        caseSensitive: false),
    RegExp(r"\b(today'?s|current|latest|news|headline|weather tomorrow)\b",
        caseSensitive: false),
    RegExp(r'^[\d\s\+\-\*\/\.\(\)]+$'), // pure math expression
  ];

  /// Returns [Scope.outOfScope] for clear general-knowledge/math/current-events queries; otherwise [Scope.inScope].
  Scope classify(String message) {
    final t = message.trim().toLowerCase();
    if (t.isEmpty) return Scope.inScope;
    if (_inScopeOverrides.any((p) => p.hasMatch(t))) return Scope.inScope;
    for (final p in _outOfScopePatterns) {
      if (p.hasMatch(t)) return Scope.outOfScope;
    }
    return Scope.inScope;
  }
}
