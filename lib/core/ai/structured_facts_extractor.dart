import 'dart:developer' as developer;
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai/core/ai/structured_facts.dart';

/// Structured Facts Extractor
/// 
/// Extracts structured facts from user interaction events.
/// Converts raw interaction events into distilled facts that can be
/// used for LLM context preparation.
/// Phase 11 Section 5: Retrieval + LLM Fusion
class StructuredFactsExtractor {
  static const String _logName = 'StructuredFactsExtractor';
  
  /// Extracts structured facts from a list of interaction events
  /// 
  /// [events] - List of InteractionEvent objects to extract facts from
  /// Returns StructuredFacts containing traits, places, and social graph data
  Future<StructuredFacts> extractFacts(List<InteractionEvent> events) async {
    try {
      developer.log(
        'Extracting facts from ${events.length} events',
        name: _logName,
      );
      
      final traits = <String>[];
      final places = <String>[];
      final socialGraph = <String>[];
      
      for (final event in events) {
        switch (event.eventType) {
          case 'respect_tap':
            final targetType = event.parameters['target_type'] as String?;
            if (targetType == 'list') {
              final category = event.parameters['category'] as String?;
              if (category != null) {
                traits.add('prefers_$category');
              }
            } else if (targetType == 'spot') {
              final spotId = event.parameters['spot_id'] as String?;
              if (spotId != null) {
                places.add(spotId);
              }
            }
            break;
            
          case 'spot_visited':
          case 'spot_tap':
          case 'spot_view_started':
            final spotId = event.parameters['spot_id'] as String?;
            if (spotId != null) {
              places.add(spotId);
            }
            break;
            
          case 'add_spot_to_list':
            final spotId = event.parameters['spot_id'] as String?;
            final listId = event.parameters['list_id'] as String?;
            if (spotId != null) {
              places.add(spotId);
            }
            if (listId != null) {
              final category = event.parameters['category'] as String?;
              if (category != null) {
                traits.add('curates_$category');
              }
            }
            break;
            
          case 'event_attended':
            final eventId = event.parameters['event_id'] as String?;
            if (eventId != null) {
              socialGraph.add('attended_$eventId');
            }
            break;
            
          case 'search_performed':
            final query = event.parameters['query'] as String?;
            if (query != null && query.isNotEmpty) {
              // Extract potential interests from search queries
              final lowerQuery = query.toLowerCase();
              if (lowerQuery.contains('coffee')) traits.add('interested_coffee');
              if (lowerQuery.contains('restaurant') || lowerQuery.contains('food')) {
                traits.add('interested_food');
              }
              if (lowerQuery.contains('park') || lowerQuery.contains('outdoor')) {
                traits.add('interested_outdoor');
              }
            }
            break;
            
          case 'share_spot':
          case 'share_list':
            // Sharing indicates community engagement
            traits.add('community_engaged');
            break;
            
          case 'list_view_started':
          case 'list_view_duration':
            // Viewing lists indicates interest in curation
            final category = event.parameters['category'] as String?;
            if (category != null) {
              traits.add('interested_${category}_lists');
            }
            break;
            
          default:
            // Unknown event type - skip
            break;
        }
      }
      
      // Remove duplicates
      final uniqueTraits = traits.toSet().toList();
      final uniquePlaces = places.toSet().toList();
      final uniqueSocialGraph = socialGraph.toSet().toList();
      
      final facts = StructuredFacts(
        traits: uniqueTraits,
        places: uniquePlaces,
        socialGraph: uniqueSocialGraph,
        timestamp: DateTime.now(),
      );
      
      developer.log(
        'Extracted facts: ${facts.traits.length} traits, ${facts.places.length} places, ${facts.socialGraph.length} social connections',
        name: _logName,
      );
      
      return facts;
    } catch (e, stackTrace) {
      developer.log(
        'Error extracting facts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty facts on error
      return StructuredFacts.empty();
    }
  }
  
  /// Extract facts from a single event (for incremental updates)
  Future<StructuredFacts> extractFactsFromEvent(InteractionEvent event) async {
    return await extractFacts([event]);
  }
}
