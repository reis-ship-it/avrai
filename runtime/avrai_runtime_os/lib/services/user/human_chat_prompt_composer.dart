import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';
import 'package:geolocator/geolocator.dart';

/// Normalized prompt payload for the human-facing agent chat.
class HumanChatPrompt {
  final List<ChatMessage> messages;
  final LLMContext context;

  const HumanChatPrompt({
    required this.messages,
    required this.context,
  });
}

/// Composes a consistent, privacy-conscious human chat prompt contract.
class HumanChatPromptComposer {
  const HumanChatPromptComposer();

  HumanChatPrompt compose({
    required List<ChatMessage> historyMessages,
    required String userId,
    PersonalityProfile? personality,
    String? languageStyle,
    String? userSignatureSummary,
    Map<String, dynamic>? structuredFacts,
    MetroExperienceContext? metroContext,
    Position? currentLocation,
  }) {
    final messages = <ChatMessage>[
      ChatMessage(
        role: ChatRole.system,
        content: _buildSystemInstruction(
          personality: personality,
          languageStyle: languageStyle,
          userSignatureSummary: userSignatureSummary,
          metroContext: metroContext,
          structuredFacts: structuredFacts,
        ),
      ),
      ...historyMessages,
    ];

    return HumanChatPrompt(
      messages: messages,
      context: LLMContext(
        userId: userId,
        location: _coarseLocation(currentLocation),
        preferences: _buildSafePreferences(
          structuredFacts: structuredFacts,
          metroContext: metroContext,
          personality: personality,
          userSignatureSummary: userSignatureSummary,
        ),
        languageStyle: languageStyle != null && languageStyle.trim().isNotEmpty
            ? languageStyle.trim()
            : null,
        conversationPreferences:
            _buildSafeConversationPreferences(metroContext),
      ),
    );
  }

  String _buildSystemInstruction({
    required PersonalityProfile? personality,
    required String? languageStyle,
    required String? userSignatureSummary,
    required MetroExperienceContext? metroContext,
    required Map<String, dynamic>? structuredFacts,
  }) {
    final sections = <String>[
      'You are AVRAI\'s human-facing world-model chat.',
      'Be calm, clear, helpful, and direct.',
      'Help the user understand options, tradeoffs, and what fits them.',
      'Do not ask for unnecessary sensitive personal details.',
      'Do not act as if you have certainty you do not have.',
      'Prefer real-world guidance over hype or engagement theater.',
    ];

    if (metroContext != null) {
      sections.add(
        'Local context: ${metroContext.displayName}. ${metroContext.summary}',
      );
      if (metroContext.spotPriors.isNotEmpty) {
        sections.add(
          'Useful local priors: ${metroContext.spotPriors.take(3).join(', ')}.',
        );
      }
    }

    if (personality != null) {
      sections.add('Personality archetype: ${personality.archetype}.');
      final dominantTraits = personality.getDominantTraits();
      if (dominantTraits.isNotEmpty) {
        sections.add(
          'Dominant traits: ${dominantTraits.take(5).join(', ')}.',
        );
      }
    }

    if (userSignatureSummary != null &&
        userSignatureSummary.trim().isNotEmpty) {
      sections.add('Current signature summary: ${userSignatureSummary.trim()}');
    }

    final traitFacts = structuredFacts?['traits'];
    if (traitFacts is List && traitFacts.isNotEmpty) {
      sections.add(
        'Known preference signals: ${traitFacts.take(6).join(', ')}.',
      );
    }

    if (languageStyle != null && languageStyle.trim().isNotEmpty) {
      sections.add(
        'Communication style guidance: ${languageStyle.trim()}',
      );
    }

    return sections.join(' ');
  }

  Map<String, dynamic>? _buildSafePreferences({
    required Map<String, dynamic>? structuredFacts,
    required MetroExperienceContext? metroContext,
    required PersonalityProfile? personality,
    required String? userSignatureSummary,
  }) {
    final safePreferences = <String, dynamic>{};

    final traitFacts = structuredFacts?['traits'];
    if (traitFacts is List && traitFacts.isNotEmpty) {
      safePreferences['traits'] = traitFacts.take(8).toList();
    }

    final places = structuredFacts?['places'];
    if (places is List) {
      safePreferences['known_places_count'] = places.length;
    }

    final socialGraph = structuredFacts?['social_graph'];
    if (socialGraph is List) {
      safePreferences['social_graph_count'] = socialGraph.length;
    }

    if (personality != null) {
      safePreferences['personality'] = {
        'archetype': personality.archetype,
        'dominant_traits': personality.getDominantTraits().take(5).toList(),
      };
    }

    if (userSignatureSummary != null &&
        userSignatureSummary.trim().isNotEmpty) {
      safePreferences['user_signature_summary'] = userSignatureSummary.trim();
    }

    if (metroContext != null) {
      safePreferences['metro_context'] = _buildSafeConversationPreferences(
        metroContext,
      );
    }

    return safePreferences.isEmpty ? null : safePreferences;
  }

  Map<String, dynamic>? _buildSafeConversationPreferences(
    MetroExperienceContext? metroContext,
  ) {
    if (metroContext == null) {
      return null;
    }

    return <String, dynamic>{
      'metro_key': metroContext.metroKey,
      'display_name': metroContext.displayName,
      'summary': metroContext.summary,
      'spot_priors': metroContext.spotPriors.take(3).toList(),
      'event_priors': metroContext.eventPriors.take(3).toList(),
      'community_priors': metroContext.communityPriors.take(3).toList(),
    };
  }

  Position? _coarseLocation(Position? currentLocation) {
    if (currentLocation == null) {
      return null;
    }

    return Position(
      longitude: double.parse(currentLocation.longitude.toStringAsFixed(2)),
      latitude: double.parse(currentLocation.latitude.toStringAsFixed(2)),
      timestamp: currentLocation.timestamp,
      accuracy: currentLocation.accuracy,
      altitude: currentLocation.altitude,
      altitudeAccuracy: currentLocation.altitudeAccuracy,
      heading: currentLocation.heading,
      headingAccuracy: currentLocation.headingAccuracy,
      speed: currentLocation.speed,
      speedAccuracy: currentLocation.speedAccuracy,
    );
  }
}
