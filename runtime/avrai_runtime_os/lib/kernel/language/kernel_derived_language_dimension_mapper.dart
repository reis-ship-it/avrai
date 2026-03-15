import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';

/// Deterministic 12D extraction from language-kernel artifacts.
///
/// This mapper never reads raw human text directly. It operates only on the
/// sanitized artifacts produced by the interpretation + boundary stack.
class KernelDerivedLanguageDimensionMapper {
  static const List<String> _increaseMarkers = <String>[
    'more',
    'more of',
    'be more',
    'want more',
    'want to be more',
    'become more',
    'lean into',
    'increase',
    'higher',
    'stronger',
  ];

  static const List<String> _decreaseMarkers = <String>[
    'less',
    'less of',
    'be less',
    'want less',
    'reduce',
    'lower',
    'tone down',
    'not so',
    'fewer',
  ];

  static const List<String> _aspirationMarkers = <String>[
    'want',
    'wish',
    'need',
    'prefer',
    'trying',
    'try to',
    'would like',
    "i'd like",
    'hope to',
    'become',
    'help me',
  ];

  static const List<String> _intensityMarkers = <String>[
    'really',
    'much',
    'way',
    'a lot',
    'definitely',
  ];

  static const Map<String, _DimensionLexicon> _lexicons =
      <String, _DimensionLexicon>{
    'exploration_eagerness': _DimensionLexicon(
      highEndKeywords: <String>[
        'explore',
        'exploring',
        'adventure',
        'adventurous',
        'discover',
        'discovery',
        'new',
        'wander',
        'try',
      ],
      lowEndKeywords: <String>[
        'familiar',
        'routine',
        'usual',
        'predictable',
        'same places',
      ],
    ),
    'community_orientation': _DimensionLexicon(
      highEndKeywords: <String>[
        'together',
        'group',
        'friends',
        'community',
        'social',
        'meet people',
        'shared',
      ],
      lowEndKeywords: <String>[
        'solo',
        'alone',
        'by myself',
        'private',
        'introvert',
      ],
    ),
    'authenticity_preference': _DimensionLexicon(
      highEndKeywords: <String>[
        'authentic',
        'local',
        'hidden gem',
        'genuine',
        'real',
        'independent',
        'neighborhood',
      ],
      lowEndKeywords: <String>[
        'curated',
        'polished',
        'chain',
        'touristy',
        'mainstream',
      ],
    ),
    'social_discovery_style': _DimensionLexicon(
      highEndKeywords: <String>[
        'word of mouth',
        'friend recommended',
        'through friends',
        'shared',
        'social',
        'network',
      ],
      lowEndKeywords: <String>[
        'on my own',
        'self guided',
        'discover alone',
        'by myself',
      ],
    ),
    'temporal_flexibility': _DimensionLexicon(
      highEndKeywords: <String>[
        'spontaneous',
        'last minute',
        'anytime',
        'flexible',
        'right now',
        'tonight',
        'impulsive',
      ],
      lowEndKeywords: <String>[
        'planned',
        'schedule',
        'itinerary',
        'book ahead',
        'organized',
        'reservation',
      ],
    ),
    'location_adventurousness': _DimensionLexicon(
      highEndKeywords: <String>[
        'far',
        'travel',
        'road trip',
        'across town',
        'different neighborhood',
        'destination',
      ],
      lowEndKeywords: <String>[
        'nearby',
        'close',
        'walkable',
        'around here',
        'local only',
      ],
    ),
    'curation_tendency': _DimensionLexicon(
      highEndKeywords: <String>[
        'curate',
        'list',
        'recommend',
        'suggest',
        'share',
        'put together',
      ],
      lowEndKeywords: <String>[
        'keep to myself',
        'private list',
      ],
    ),
    'trust_network_reliance': _DimensionLexicon(
      highEndKeywords: <String>[
        'trust',
        'trusted',
        'friend said',
        'recommended by',
        'people i know',
        'reliable',
      ],
      lowEndKeywords: <String>[
        'random',
        'independent',
        'decide for myself',
      ],
    ),
    'energy_preference': _DimensionLexicon(
      highEndKeywords: <String>[
        'lively',
        'energetic',
        'active',
        'buzzing',
        'upbeat',
        'late night',
        'dance',
      ],
      lowEndKeywords: <String>[
        'chill',
        'calm',
        'relaxed',
        'quiet',
        'cozy',
        'slow',
      ],
    ),
    'novelty_seeking': _DimensionLexicon(
      highEndKeywords: <String>[
        'new',
        'novel',
        'different',
        'fresh',
        'first time',
        'change',
      ],
      lowEndKeywords: <String>[
        'favorite',
        'familiar',
        'usual',
        'routine',
        'regular',
      ],
    ),
    'value_orientation': _DimensionLexicon(
      highEndKeywords: <String>[
        'premium',
        'upscale',
        'luxury',
        'fine dining',
        'splurge',
        'special occasion',
      ],
      lowEndKeywords: <String>[
        'budget',
        'cheap',
        'affordable',
        'value',
        'low cost',
      ],
    ),
    'crowd_tolerance': _DimensionLexicon(
      highEndKeywords: <String>[
        'crowded',
        'bustling',
        'packed',
        'busy',
        'popular',
        'full',
      ],
      lowEndKeywords: <String>[
        'quiet',
        'intimate',
        'uncrowded',
        'not crowded',
        'calm',
        'small',
      ],
    ),
  };

  Map<String, double> synthesizeBaselineFromTurns(
    Iterable<HumanLanguageKernelTurn> turns,
  ) {
    final baseline = _defaultDimensions();
    var sawEvidence = false;

    for (final turn in turns) {
      if (!turn.boundary.accepted) {
        continue;
      }
      final text = _sanitizedSignalText(turn);
      if (text.isEmpty) {
        continue;
      }

      final turnMultiplier =
          turn.interpretation.intent.toWireValue() == 'prefer' ? 1.15 : 1.0;
      for (final entry in _lexicons.entries) {
        final delta =
            (_baselineDelta(text, entry.value) * turnMultiplier).clamp(
          -0.24,
          0.24,
        );
        if (delta.abs() < 0.01) {
          continue;
        }
        sawEvidence = true;
        baseline[entry.key] = (baseline[entry.key]! + delta).clamp(0.0, 1.0);
      }
    }

    return sawEvidence ? baseline : _defaultDimensions();
  }

  Map<String, double> parseAspirationalShift(HumanLanguageKernelTurn turn) {
    if (!turn.boundary.accepted) {
      return const <String, double>{};
    }

    final text = _sanitizedSignalText(turn);
    if (text.isEmpty || !_isAspirationalTurn(turn, text)) {
      return const <String, double>{};
    }

    final intensityMultiplier =
        _containsAny(text, _intensityMarkers) ? 1.3 : 1.0;
    final shifts = <String, double>{};

    for (final entry in _lexicons.entries) {
      final shift =
          (_shiftDelta(text, entry.value) * intensityMultiplier).clamp(
        -0.35,
        0.35,
      );
      if (shift.abs() < 0.11) {
        continue;
      }
      shifts[entry.key] = shift;
    }

    return shifts;
  }

  Map<String, double> _defaultDimensions() => <String, double>{
        for (final dimension in VibeConstants.coreDimensions)
          dimension: VibeConstants.defaultDimensionValue,
      };

  String _sanitizedSignalText(HumanLanguageKernelTurn turn) {
    final sanitized = turn.boundary.sanitizedArtifact;
    final fragments = <String>[
      sanitized.redactedText,
      ...sanitized.safeQuestions,
      ...sanitized.safePreferenceSignals.map((entry) => entry.value),
      ...sanitized.learningVocabulary,
      ...sanitized.learningPhrases,
    ].where((entry) => entry.trim().isNotEmpty).join(' ');

    return fragments.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _baselineDelta(String text, _DimensionLexicon lexicon) {
    final highMatches = _countMatches(text, lexicon.highEndKeywords);
    final lowMatches = _countMatches(text, lexicon.lowEndKeywords);
    return ((highMatches - lowMatches) * 0.08).toDouble();
  }

  bool _isAspirationalTurn(HumanLanguageKernelTurn turn, String text) {
    if (_containsAny(text, _aspirationMarkers)) {
      return true;
    }
    return switch (turn.interpretation.intent) {
      var intent when intent.toWireValue() == 'prefer' => true,
      var intent when intent.toWireValue() == 'plan' => true,
      _ => false,
    };
  }

  double _shiftDelta(String text, _DimensionLexicon lexicon) {
    var delta = 0.0;
    delta += _directionalKeywordDelta(
      text,
      lexicon.highEndKeywords,
      highEndDirection: 1.0,
    );
    delta += _directionalKeywordDelta(
      text,
      lexicon.lowEndKeywords,
      highEndDirection: -1.0,
    );
    return delta;
  }

  double _directionalKeywordDelta(
    String text,
    List<String> keywords, {
    required double highEndDirection,
  }) {
    var delta = 0.0;
    for (final keyword in keywords) {
      if (_matchesDirectionalPhrase(text, keyword, _increaseMarkers)) {
        delta += 0.18 * highEndDirection;
        continue;
      }
      if (_matchesDirectionalPhrase(text, keyword, _decreaseMarkers)) {
        delta -= 0.18 * highEndDirection;
        continue;
      }
      if (_matchesDirectionalPhrase(text, keyword, _aspirationMarkers)) {
        delta += 0.12 * highEndDirection;
      }
    }
    return delta;
  }

  double _countMatches(String text, List<String> keywords) {
    var matches = 0;
    for (final keyword in keywords) {
      if (_containsKeyword(text, keyword)) {
        matches++;
      }
    }
    return matches.toDouble();
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (_containsKeyword(text, phrase)) {
        return true;
      }
    }
    return false;
  }

  bool _containsKeyword(String text, String keyword) {
    final pattern = _phrasePattern(keyword);
    return RegExp('\\b$pattern\\b').hasMatch(text);
  }

  bool _matchesDirectionalPhrase(
    String text,
    String keyword,
    List<String> markers,
  ) {
    final keywordPattern = _phrasePattern(keyword);
    for (final marker in markers) {
      final markerPattern = _phrasePattern(marker);
      final expression = RegExp(
        '\\b$markerPattern\\b(?:\\s+[a-z\\-\\\']+){0,3}\\s+\\b$keywordPattern\\b',
      );
      if (expression.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  String _phrasePattern(String phrase) => phrase
      .toLowerCase()
      .split(' ')
      .where((entry) => entry.isNotEmpty)
      .map(RegExp.escape)
      .join(r'\s+');
}

class _DimensionLexicon {
  const _DimensionLexicon({
    required this.highEndKeywords,
    required this.lowEndKeywords,
  });

  final List<String> highEndKeywords;
  final List<String> lowEndKeywords;
}
