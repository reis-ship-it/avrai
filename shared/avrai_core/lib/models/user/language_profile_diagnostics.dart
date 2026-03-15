import 'package:avrai_core/models/user/language_profile.dart';

class LanguageLearningEvent {
  const LanguageLearningEvent({
    required this.profileRef,
    required this.displayRef,
    required this.learningScope,
    required this.surface,
    required this.source,
    required this.summary,
    required this.vocabularySample,
    required this.phraseSample,
    required this.toneSnapshot,
    required this.messageCountAfter,
    required this.confidenceAfter,
    required this.timestamp,
  });

  final String profileRef;
  final String displayRef;
  final String learningScope;
  final String surface;
  final String source;
  final String summary;
  final List<String> vocabularySample;
  final List<String> phraseSample;
  final Map<String, double> toneSnapshot;
  final int messageCountAfter;
  final double confidenceAfter;
  final DateTime timestamp;

  bool get isGovernanceFeedback =>
      learningScope.startsWith('governance_feedback');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'profileRef': profileRef,
        'displayRef': displayRef,
        'learningScope': learningScope,
        'surface': surface,
        'source': source,
        'summary': summary,
        'vocabularySample': vocabularySample,
        'phraseSample': phraseSample,
        'toneSnapshot': toneSnapshot,
        'messageCountAfter': messageCountAfter,
        'confidenceAfter': confidenceAfter,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LanguageLearningEvent.fromJson(Map<String, dynamic> json) {
    return LanguageLearningEvent(
      profileRef: json['profileRef'] as String? ?? '',
      displayRef: json['displayRef'] as String? ?? '',
      learningScope: json['learningScope'] as String? ?? 'unknown',
      surface: json['surface'] as String? ?? 'unknown',
      source: json['source'] as String? ?? 'unknown',
      summary: json['summary'] as String? ?? '',
      vocabularySample:
          ((json['vocabularySample'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      phraseSample: ((json['phraseSample'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      toneSnapshot: Map<String, double>.from(
        (json['toneSnapshot'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            ) ??
            const <String, double>{},
      ),
      messageCountAfter: (json['messageCountAfter'] as num?)?.toInt() ?? 0,
      confidenceAfter: (json['confidenceAfter'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LanguageProfileDiagnosticsSnapshot {
  const LanguageProfileDiagnosticsSnapshot({
    required this.profileRef,
    required this.displayRef,
    required this.profile,
    required this.recentEvents,
  });

  final String profileRef;
  final String displayRef;
  final LanguageProfile profile;
  final List<LanguageLearningEvent> recentEvents;

  List<MapEntry<String, double>> topVocabulary({int limit = 6}) {
    final entries = profile.vocabulary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList(growable: false);
  }

  List<MapEntry<String, double>> topPhrases({int limit = 4}) {
    final entries = profile.phrases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList(growable: false);
  }
}
