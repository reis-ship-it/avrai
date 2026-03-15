import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/user/human_chat_prompt_composer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('HumanChatPromptComposer', () {
    test('builds one normalized human-chat prompt with safe context', () {
      final composer = HumanChatPromptComposer();
      final personality = PersonalityProfile.initial(
        'agent_test',
        userId: 'user_123',
      );
      final metroContext = MetroExperienceService.profileForMetroKey(
        metroKey: 'nyc',
        cityCode: 'us-nyc',
      );

      final prompt = composer.compose(
        historyMessages: [
          LanguageTurnMessage(
            role: LanguageTurnRole.user,
            content: 'What fits me tonight?',
          ),
        ],
        userId: 'user_123',
        personality: personality,
        languageStyle: 'Prefer concise, casual phrasing.',
        structuredFacts: <String, dynamic>{
          'traits': ['coffee', 'art', 'music'],
          'places': ['Place A', 'Place B'],
          'social_graph': ['friend_1'],
        },
        metroContext: metroContext,
        currentLocation: Position(
          longitude: -73.95612,
          latitude: 40.71845,
          timestamp: DateTime(2026),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      expect(prompt.messages.first.role, equals(LanguageTurnRole.system));
      expect(
          prompt.messages.first.content, contains('human-facing world-model'));
      expect(prompt.messages.first.content, contains('NYC'));
      expect(
          prompt.messages.first.content, contains('Known preference signals'));
      expect(prompt.context.userId, equals('user_123'));
      expect(prompt.context.location?.latitude, equals(40.72));
      expect(prompt.context.location?.longitude, equals(-73.96));
      expect(prompt.context.preferences?['known_places_count'], equals(2));
      expect(prompt.context.preferences?['social_graph_count'], equals(1));
      expect(
        (prompt.context.preferences?['metro_context']
            as Map<String, dynamic>)['metro_key'],
        equals('nyc'),
      );
      expect(prompt.context.languageStyle, contains('concise'));
    });
  });
}
