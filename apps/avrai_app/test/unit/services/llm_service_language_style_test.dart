/// SPOTS Language Runtime Style Integration Tests
/// Date: December 2025
/// Purpose: Test language runtime style integration (Phase 2.4)
///
/// Test Coverage:
/// - LanguageRuntimeContext language style field
/// - Language style serialization to JSON
/// - Language style inclusion in Edge Function context
/// - Integration with PersonalityAgentChatService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';

void main() {
  group('Language Runtime Style Integration Tests', () {
    group('LanguageRuntimeContext language style', () {
      test('should include language style in context', () {
        // Arrange
        const languageStyle = '''User's Communication Style:
- Vocabulary: cool, awesome, totally
- Common phrases: you know, I mean
- Average sentence length: 12.5 words
- Formality: low
- Enthusiasm: high
- Directness: medium

Match the user's style gradually - do not copy exactly, but adapt naturally.''';

        // Act
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          languageStyle: languageStyle,
        );

        // Assert
        expect(context.languageStyle, equals(languageStyle));
        expect(context.languageStyle, isNotEmpty);
      });

      test('should allow null language style when not available', () {
        // Act
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          languageStyle: null,
        );

        // Assert
        expect(context.languageStyle, isNull);
      });

      test('should serialize language style to JSON', () {
        // Arrange
        const languageStyle =
            'User\'s Communication Style:\n- Vocabulary: cool, awesome';
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          languageStyle: languageStyle,
        );

        // Act
        final json = context.toJson();

        // Assert
        expect(json['languageStyle'], equals(languageStyle));
      });

      test('should not include language style in JSON when null', () {
        // Arrange
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          languageStyle: null,
        );

        // Act
        final json = context.toJson();

        // Assert
        expect(json.containsKey('languageStyle'), isFalse);
      });

      test('should not include empty language style in JSON', () {
        // Arrange
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          languageStyle: '',
        );

        // Act
        final json = context.toJson();

        // Assert
        expect(json.containsKey('languageStyle'), isFalse);
      });

      test('should include language style alongside other context', () {
        // Arrange
        const languageStyle =
            'User\'s Communication Style:\n- Vocabulary: cool';
        // Phase 8.3: Use agentId for privacy protection
        final personality =
            PersonalityProfile.initial('agent_user_123', userId: 'user_123');

        // Act
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          personality: personality,
          languageStyle: languageStyle,
        );

        // Act
        final json = context.toJson();

        // Assert
        expect(json['userId'], equals('user_123'));
        expect(json['personality'], isNotNull);
        expect(json['languageStyle'], equals(languageStyle));
      });

      test(
          'should serialize normalized conversation preference timing for fresh governed locality knowledge',
          () {
        final capturedAt = DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 4))
            .toIso8601String();
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          conversationPreferences: <String, dynamic>{
            'governed_knowledge_phase': 'locality_personal_visit_captured',
            'governed_knowledge_timing_summary':
                'phase locality_personal_visit_captured, effective knowledge $capturedAt',
            'governed_knowledge_captured_at': capturedAt,
          },
        );

        final json = context.toJson();
        final timing =
            json['conversationPreferenceTiming'] as Map<String, dynamic>;

        expect(
          (json['conversationPreferences']
              as Map<String, dynamic>)['governed_knowledge_phase'],
          equals('locality_personal_visit_captured'),
        );
        expect(timing['phase'], equals('locality_personal_visit_captured'));
        expect(timing['freshness'], equals('fresh'));
        expect(timing['capturedAt'], equals(capturedAt));
        expect(
          timing['summary'],
          contains('effective knowledge'),
        );
      });

      test(
          'should serialize stale conversation preference timing for governed locality knowledge',
          () {
        final capturedAt = DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 40))
            .toIso8601String();
        final context = LanguageRuntimeContext(
          userId: 'user_123',
          conversationPreferences: <String, dynamic>{
            'governed_knowledge_phase': 'locality_personal_visit_captured',
            'governed_knowledge_captured_at': capturedAt,
          },
        );

        final json = context.toJson();
        final timing =
            json['conversationPreferenceTiming'] as Map<String, dynamic>;

        expect(timing['freshness'], equals('stale'));
        expect(timing['capturedAt'], equals(capturedAt));
      });
    });

    group('Language Style Format', () {
      test('should accept formatted language style string', () {
        // Arrange
        const languageStyle = '''User's Communication Style:
- Vocabulary: word1, word2, word3
- Common phrases: phrase1, phrase2
- Average sentence length: 15.0 words
- Formality: low
- Enthusiasm: high
- Directness: medium

Match the user's style gradually - do not copy exactly, but adapt naturally.''';

        // Act
        final context = LanguageRuntimeContext(languageStyle: languageStyle);

        // Assert
        expect(context.languageStyle, equals(languageStyle));
        expect(context.languageStyle!.contains('Vocabulary'), isTrue);
        expect(context.languageStyle!.contains('Formality'), isTrue);
      });
    });
  });
}
