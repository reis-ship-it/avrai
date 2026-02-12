/// SPOTS LLM Service Language Style Integration Tests
/// Date: December 2025
/// Purpose: Test LLM Service language style integration (Phase 2.4)
/// 
/// Test Coverage:
/// - LLMContext language style field
/// - Language style serialization to JSON
/// - Language style inclusion in Edge Function context
/// - Integration with PersonalityAgentChatService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_core/models/personality_profile.dart';

void main() {
  group('LLM Service Language Style Integration Tests', () {
    group('LLMContext Language Style', () {
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
        final context = LLMContext(
          userId: 'user_123',
          languageStyle: languageStyle,
        );
        
        // Assert
        expect(context.languageStyle, equals(languageStyle));
        expect(context.languageStyle, isNotEmpty);
      });
      
      test('should allow null language style when not available', () {
        // Act
        final context = LLMContext(
          userId: 'user_123',
          languageStyle: null,
        );
        
        // Assert
        expect(context.languageStyle, isNull);
      });
      
      test('should serialize language style to JSON', () {
        // Arrange
        const languageStyle = 'User\'s Communication Style:\n- Vocabulary: cool, awesome';
        final context = LLMContext(
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
        final context = LLMContext(
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
        final context = LLMContext(
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
        const languageStyle = 'User\'s Communication Style:\n- Vocabulary: cool';
        // Phase 8.3: Use agentId for privacy protection
        final personality = PersonalityProfile.initial('agent_user_123', userId: 'user_123');
        
        // Act
        final context = LLMContext(
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
        final context = LLMContext(languageStyle: languageStyle);
        
        // Assert
        expect(context.languageStyle, equals(languageStyle));
        expect(context.languageStyle!.contains('Vocabulary'), isTrue);
        expect(context.languageStyle!.contains('Formality'), isTrue);
      });
    });
  });
}

