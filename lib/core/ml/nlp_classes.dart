import 'package:avrai/core/ml/nlp_enums.dart';

// Sentiment analysis result
class SentimentAnalysis {
  final SentimentType type;
  final double confidence;
  final String text;

  const SentimentAnalysis({
    required this.type,
    required this.confidence,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'confidence': confidence,
        'text': text,
      };
}

// Search intent result
class SearchIntent {
  final SearchIntentType type;
  final double confidence;
  final Map<String, dynamic> parameters;

  const SearchIntent({
    required this.type,
    required this.confidence,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'confidence': confidence,
        'parameters': parameters,
      };
}

// Content moderation result
class ContentModeration {
  final bool isAppropriate;
  final List<String> issues;
  final double confidence;

  const ContentModeration({
    required this.isAppropriate,
    required this.issues,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'isAppropriate': isAppropriate,
        'issues': issues,
        'confidence': confidence,
      };
}

// Privacy preserving text result
class PrivacyPreservingText {
  final String originalText;
  final String processedText;
  final PrivacyLevel privacyLevel;

  const PrivacyPreservingText({
    required this.originalText,
    required this.processedText,
    required this.privacyLevel,
  });

  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'processedText': processedText,
        'privacyLevel': privacyLevel.name,
      };
}
