import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/services/events/event_template_service.dart';
import 'package:get_it/get_it.dart';

/// Action Parser for Phase 5: Action Execution System
/// Parses user messages to extract action intents
class ActionParser {
  static const String _logName = 'ActionParser';
  
  final LLMService? _llmService;
  
  ActionParser({LLMService? llmService}) : _llmService = llmService;
  
  /// Parse a user message to extract action intent
  /// Returns null if no action intent is detected
  Future<ActionIntent?> parseAction(
    String userMessage, {
    String? userId,
    Position? currentLocation,
  }) async {
    try {
      developer.log('Parsing action from message: $userMessage', name: _logName);
      
      final lowerMessage = userMessage.toLowerCase().trim();
      
      // Try to parse using rule-based approach first (faster, works offline)
      // Pass original message for case-preserving extraction
      final ruleBasedIntent = _parseRuleBased(lowerMessage, userId, currentLocation, originalMessage: userMessage);
      if (ruleBasedIntent != null) {
        developer.log('Parsed intent using rule-based: ${ruleBasedIntent.type}', name: _logName);
        return ruleBasedIntent;
      }
      
      // If LLM is available, use it for more complex parsing
      if (_llmService != null) {
        try {
          final llmIntent = await _parseWithLLM(userMessage, userId, currentLocation);
          if (llmIntent != null) {
            developer.log('Parsed intent using LLM: ${llmIntent.type}', name: _logName);
            return llmIntent;
          }
        } catch (e) {
          developer.log('LLM parsing failed, using rule-based: $e', name: _logName);
        }
      }
      
      developer.log('No action intent detected', name: _logName);
      return null;
    } catch (e) {
      developer.log('Error parsing action: $e', name: _logName);
      return null;
    }
  }
  
  /// Rule-based parsing (works offline)
  ActionIntent? _parseRuleBased(
    String message,
    String? userId,
    Position? currentLocation, {
    String? originalMessage,
  }) {
    final original = originalMessage ?? message;
    // Create list intent
    if (message.contains('create') && message.contains('list')) {
      final listName = _extractListName(original);
      if (listName.isNotEmpty && userId != null) {
        return CreateListIntent(
          title: listName,
          description: 'Created via AI command',
          userId: userId,
          confidence: 0.8,
        );
      }
    }
    
    // Add spot to list intent
    // Pattern: "add X to Y list" or "add spot/location X to list Y"
    if (message.contains('add') && 
        message.contains('to') &&
        message.contains('list')) {
      final spotName = _extractSpotName(original);
      final listName = _extractListName(original);
      if (spotName.isNotEmpty && listName.isNotEmpty && userId != null) {
        // Note: We'll need spotId and listId, but for now we'll use names
        // The executor will need to resolve these
        return AddSpotToListIntent(
          spotId: spotName, // Will be resolved by executor
          listId: listName, // Will be resolved by executor
          userId: userId,
          confidence: 0.7,
          metadata: {
            'spotName': spotName,
            'listName': listName,
          },
        );
      }
    }
    
    // Create spot intent (requires location)
    if ((message.contains('create') || message.contains('add')) &&
        message.contains('spot') &&
        currentLocation != null &&
        userId != null) {
      final spotName = _extractSpotName(original);
      if (spotName.isNotEmpty) {
        final category = _extractCategory(message);
        return CreateSpotIntent(
          name: spotName,
          description: 'Created via AI command',
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          category: category,
          userId: userId,
          confidence: 0.7,
        );
      }
    }
    
    // Create event intent - Phase 5: AI Assistant
    // OUR_GUTS.md: "The key opens doors to events"
    // Examples: "create a coffee tour", "host a bar crawl next weekend", "schedule trivia night"
    if ((message.contains('create') || message.contains('host') || message.contains('schedule')) &&
        (message.contains('event') || message.contains('tour') || message.contains('meetup') ||
         message.contains('workshop') || message.contains('tasting') || message.contains('walk') ||
         message.contains('crawl') || message.contains('night') || message.contains('party')) &&
        userId != null) {
      
      // Try to match event template by keyword
      final templateService = GetIt.I.isRegistered<EventTemplateService>()
          ? GetIt.I<EventTemplateService>()
          : null;
      
      if (templateService != null) {
        // Try to identify template
        String? templateId;
        String? category;
        
        if (message.contains('coffee')) {
          if (message.contains('tour') || message.contains('tasting')) {
            templateId = 'coffee_tasting_tour';
            category = 'Coffee';
          } else if (message.contains('workshop')) {
            templateId = 'coffee_workshop';
            category = 'Coffee';
          }
        } else if (message.contains('bar') && message.contains('crawl')) {
          templateId = 'bar_crawl';
          category = 'Nightlife';
        } else if (message.contains('food') && message.contains('tour')) {
          templateId = 'food_tour';
          category = 'Food';
        } else if (message.contains('trivia')) {
          templateId = 'trivia_night';
          category = 'Social';
        } else if (message.contains('concert') || message.contains('music')) {
          templateId = 'concert_meetup';
          category = 'Music';
        } else if (message.contains('bookstore') || message.contains('book')) {
          templateId = 'bookstore_walk';
          category = 'Books';
        } else if (message.contains('museum') || message.contains('art')) {
          templateId = 'museum_tour';
          category = 'Art';
        } else if (message.contains('sports') || message.contains('game') || message.contains('watch')) {
          templateId = 'sports_watch_party';
          category = 'Sports';
        }
        
        // Extract time if mentioned
        DateTime? startTime = _extractDateTime(message);
        
        return CreateEventIntent(
          userId: userId,
          templateId: templateId,
          category: category,
          startTime: startTime,
          confidence: templateId != null ? 0.8 : 0.6,
          metadata: {'originalMessage': original},
        );
      }
    }
    
    return null;
  }
  
  /// Parse with LLM (more accurate, requires online)
  /// Uses LLM to identify action types and extract structured information
  Future<ActionIntent?> _parseWithLLM(
    String message,
    String? userId,
    Position? currentLocation,
  ) async {
    if (_llmService == null || userId == null) {
      return null;
    }

    try {
      developer.log('Parsing action with LLM: $message', name: _logName);

      // Create a prompt that asks the LLM to identify action intent
      final prompt = '''
Analyze this user message and identify if it contains an action intent. 
If it does, respond with a JSON object containing:
- "actionType": one of "create_list", "create_spot", "add_spot_to_list", or "none"
- "confidence": a number between 0.0 and 1.0
- "listName": the name of the list (if applicable)
- "spotName": the name of the spot (if applicable)
- "category": the category of the spot (if applicable)

User message: "$message"

Respond ONLY with valid JSON, no other text.
Example response: {"actionType": "create_list", "confidence": 0.9, "listName": "Coffee Shops"}
''';

      final response = await _llmService.chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: prompt),
        ],
        maxTokens: 200,
        temperature: 0.3, // Lower temperature for more consistent parsing
      );

      // Try to parse JSON response
      final intent = _parseLLMResponse(response, userId, currentLocation);
      if (intent != null) {
        developer.log('LLM parsed intent: ${intent.type} with confidence ${intent.confidence}', name: _logName);
        return intent;
      }
    } catch (e) {
      developer.log('LLM parsing error: $e', name: _logName);
      // Fall through to return null, which will trigger rule-based fallback
    }

    return null;
  }

  /// Parse LLM response into ActionIntent
  ActionIntent? _parseLLMResponse(
    String llmResponse,
    String userId,
    Position? currentLocation,
  ) {
    try {
      // Try to extract JSON from response (may have extra text)
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(llmResponse);
      if (jsonMatch == null) {
        return null;
      }

      final jsonString = jsonMatch.group(0)!;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final actionType = json['actionType'] as String?;
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.5;

      if (actionType == null || actionType == 'none' || confidence < 0.5) {
        return null;
      }

      switch (actionType) {
        case 'create_list':
          final listName = json['listName'] as String? ?? '';
          if (listName.isEmpty) return null;
          return CreateListIntent(
            title: listName,
            description: 'Created via AI command',
            userId: userId,
            confidence: confidence,
          );

        case 'create_spot':
          final spotName = json['spotName'] as String? ?? '';
          final category = json['category'] as String? ?? 'general';
          if (spotName.isEmpty || currentLocation == null) return null;
          return CreateSpotIntent(
            name: spotName,
            description: 'Created via AI command',
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
            category: category,
            userId: userId,
            confidence: confidence,
          );

        case 'add_spot_to_list':
          final spotName = json['spotName'] as String? ?? '';
          final listName = json['listName'] as String? ?? '';
          if (spotName.isEmpty || listName.isEmpty) return null;
          return AddSpotToListIntent(
            spotId: spotName, // Will be resolved by executor
            listId: listName, // Will be resolved by executor
            userId: userId,
            confidence: confidence,
            metadata: {
              'spotName': spotName,
              'listName': listName,
            },
          );

        default:
          return null;
      }
    } catch (e) {
      developer.log('Error parsing LLM response: $e', name: _logName);
      return null;
    }
  }
  
  /// Extract list name from message
  String _extractListName(String message) {
    // Try quoted name first
    if (message.contains('"')) {
      final start = message.indexOf('"') + 1;
      final end = message.lastIndexOf('"');
      if (start > 0 && end > start) {
        return message.substring(start, end).trim();
      }
    }
    
    // Try "called" pattern
    if (message.contains('called')) {
      final parts = message.split('called');
      if (parts.length > 1) {
        final name = parts[1].split(' ').take(5).join(' ').trim();
        return name.replaceAll(RegExp(r'[^\w\s]'), '');
      }
    }
    
    // Try "for" pattern
    if (message.contains('for')) {
      final parts = message.split('for');
      if (parts.length > 1) {
        final name = parts[1].split(' ').take(5).join(' ').trim();
        return name.replaceAll(RegExp(r'[^\w\s]'), '');
      }
    }
    
    // Try "create a X list" or "create X list" pattern
    if (message.toLowerCase().contains('create')) {
      final createMatch = RegExp(r'create\s+(?:a\s+)?(.+?)\s+list', caseSensitive: false).firstMatch(message);
      if (createMatch != null) {
        return createMatch.group(1)!.trim();
      }
    }
    
    // Try "to my X list" or "to the X list" pattern
    if (message.contains('to')) {
      final toIndex = message.indexOf('to');
      final afterTo = message.substring(toIndex + 2).trim();
      // Remove "my" or "the" if present
      final cleaned = afterTo.replaceAll(RegExp(r'^(my|the)\s+', caseSensitive: false), '');
      // Extract list name (everything before end or before next major word)
      final listMatch = RegExp(r'(.+?)\s+list', caseSensitive: false).firstMatch(cleaned);
      if (listMatch != null) {
        return listMatch.group(1)!.trim();
      }
      // If no "list" word, take first few words after "to"
      final words = cleaned.split(' ').take(3).join(' ').trim();
      if (words.isNotEmpty) {
        return words;
      }
    }
    
    return '';
  }
  
  /// Extract spot name from message
  String _extractSpotName(String message) {
    // Try quoted name first
    if (message.contains('"')) {
      final start = message.indexOf('"') + 1;
      final end = message.lastIndexOf('"');
      if (start > 0 && end > start) {
        return message.substring(start, end).trim();
      }
    }
    
    // Try "add X to" pattern (case-insensitive)
    final addMatch = RegExp(r'add\s+(.+?)\s+to', caseSensitive: false).firstMatch(message);
    if (addMatch != null) {
      final name = addMatch.group(1)!.trim();
      // Remove common words that might be in the middle
      final cleaned = name.replaceAll(RegExp(r'\b(the|a|an|my|this|that)\b', caseSensitive: false), '').trim();
      return cleaned.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    }
    
    return '';
  }
  
  /// Extract category from message
  String _extractCategory(String message) {
    final categories = [
      'restaurant', 'cafe', 'coffee', 'park', 'museum', 'theater',
      'bar', 'club', 'hotel', 'shop', 'store', 'gym', 'beach',
      'hiking', 'trail', 'library', 'school', 'hospital',
    ];
    
    for (final category in categories) {
      if (message.contains(category)) {
        return category;
      }
    }
    
    return 'general';
  }
  
  /// Extract date/time from message
  /// Simple rule-based extraction for common patterns
  DateTime? _extractDateTime(String message) {
    final now = DateTime.now();
    
    // Handle "next weekend" → Saturday 10 AM
    if (message.contains('next weekend') || message.contains('this weekend')) {
      var saturday = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
      if (saturday.isBefore(now)) {
        saturday = saturday.add(const Duration(days: 7));
      }
      return DateTime(saturday.year, saturday.month, saturday.day, 10, 0);
    }
    
    // Handle "tomorrow"
    if (message.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
    }
    
    // Handle "next week"
    if (message.contains('next week')) {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 0);
    }
    
    // Handle specific days (Monday, Tuesday, etc.)
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (int i = 0; i < days.length; i++) {
      if (message.contains(days[i])) {
        final targetDay = i + 1;
        var daysToAdd = (targetDay - now.weekday) % 7;
        if (daysToAdd <= 0) daysToAdd += 7; // Next occurrence
        final target = now.add(Duration(days: daysToAdd));
        return DateTime(target.year, target.month, target.day, 10, 0);
      }
    }
    
    return null; // No date detected
  }
  
  /// Check if an intent can be executed
  Future<bool> canExecute(ActionIntent intent) async {
    // Validate intent has required fields
    if (intent is CreateSpotIntent) {
      return intent.name.isNotEmpty &&
          intent.userId.isNotEmpty &&
          intent.latitude != 0.0 &&
          intent.longitude != 0.0;
    }
    
    if (intent is CreateListIntent) {
      return intent.title.isNotEmpty && intent.userId.isNotEmpty;
    }
    
    if (intent is AddSpotToListIntent) {
      return intent.spotId.isNotEmpty &&
          intent.listId.isNotEmpty &&
          intent.userId.isNotEmpty;
    }
    
    return false;
  }
}

