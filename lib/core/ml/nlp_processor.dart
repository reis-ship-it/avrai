import 'dart:math' as math;
import 'package:avrai/core/ml/nlp_enums.dart';
import 'package:avrai/core/ml/nlp_classes.dart';

// NLP Processor for text analysis and processing
class NLPProcessor {
  Future<void> initialize() async {}
  Future<Map<String, dynamic>> analyzeText(String text) async =>
      processResult(text);

  // Analyze sentiment of text
  static SentimentAnalysis analyzeSentiment(String text) {
    // Simple sentiment analysis based on keywords
    final positiveWords = [
      'good',
      'great',
      'amazing',
      'love',
      'excellent',
      'perfect'
    ];
    final negativeWords = ['bad', 'terrible', 'hate', 'awful', 'disappointing'];

    final words = text.toLowerCase().split(' ');
    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount) {
      return SentimentAnalysis(
        type: SentimentType.positive,
        confidence: math.min(0.9, (positiveCount / words.length) * 2),
        text: text,
      );
    } else if (negativeCount > positiveCount) {
      return SentimentAnalysis(
        type: SentimentType.negative,
        confidence: math.min(0.9, (negativeCount / words.length) * 2),
        text: text,
      );
    } else {
      return SentimentAnalysis(
        type: SentimentType.neutral,
        confidence: 0.5,
        text: text,
      );
    }
  }

  // Simple unified result for instance method
  Map<String, dynamic> processResult(String text) {
    final sentiment = NLPProcessor.analyzeSentiment(text);
    return {
      'sentiment': sentiment.toJson(),
    };
  }

  // Analyze search intent
  static SearchIntent analyzeSearchIntent(String query) {
    final queryLower = query.toLowerCase();

    // Check for location intent
    if (queryLower.contains('near') ||
        queryLower.contains('in') ||
        queryLower.contains('around')) {
      return SearchIntent(
        type: SearchIntentType.location,
        confidence: 0.8,
        parameters: {'query': query},
      );
    }

    // Check for category intent
    if (queryLower.contains('restaurant') ||
        queryLower.contains('cafe') ||
        queryLower.contains('bar')) {
      return SearchIntent(
        type: SearchIntentType.category,
        confidence: 0.7,
        parameters: {'query': query},
      );
    }

    // Default to name search
    return SearchIntent(
      type: SearchIntentType.name,
      confidence: 0.6,
      parameters: {'query': query},
    );
  }

  // Moderate content
  static ContentModeration moderateContent(String text) {
    final inappropriateWords = ['spam', 'inappropriate', 'offensive'];
    final textLower = text.toLowerCase();

    final issues = <String>[];
    for (final word in inappropriateWords) {
      if (textLower.contains(word)) {
        issues.add(word);
      }
    }

    return ContentModeration(
      isAppropriate: issues.isEmpty,
      issues: issues,
      confidence: issues.isEmpty ? 0.9 : 0.7,
    );
  }

  // Preserve privacy in text
  static PrivacyPreservingText preservePrivacy(
      String text, PrivacyLevel level) {
    String processedText = text;

    switch (level) {
      case PrivacyLevel.anonymous:
        // Remove personal identifiers
        processedText =
            text.replaceAll(RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b'), '[NAME]');
        processedText = processedText.replaceAll(
            RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE]');
        break;
      case PrivacyLevel.private:
        // Keep original text
        break;
      case PrivacyLevel.friends:
        // Keep original text
        break;
      case PrivacyLevel.public:
        // Keep original text
        break;
    }

    return PrivacyPreservingText(
      originalText: text,
      processedText: processedText,
      privacyLevel: level,
    );
  }

  // Process text with all NLP features
  static Map<String, dynamic> processText(String text,
      {PrivacyLevel privacyLevel = PrivacyLevel.public}) {
    final sentiment = analyzeSentiment(text);
    final intent = analyzeSearchIntent(text);
    final moderation = moderateContent(text);
    final privacy = preservePrivacy(text, privacyLevel);

    return {
      'sentiment': sentiment.toJson(),
      'intent': intent.toJson(),
      'moderation': moderation.toJson(),
      'privacy': privacy.toJson(),
    };
  }
}
